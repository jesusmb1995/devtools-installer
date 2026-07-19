#!/bin/bash

function ac-power-watts {
  local -a active_sources
  local d name raw current voltage watts found

  for d in /sys/class/power_supply/*; do
    [ -d "$d" ] || continue
    [ -r "$d/online" ] || continue
    if [ "$(cat "$d/online")" = "1" ]; then
      active_sources+=("$d")
    fi
  done

  if (( ${#active_sources[@]} == 0 )); then
    echo "No online AC source found in /sys/class/power_supply."
    return 1
  fi

  for d in "${active_sources[@]}"; do
    name=$(basename "$d")
    if [ -r "$d/power_now" ]; then
      raw=$(cat "$d/power_now")
      if [[ "$raw" =~ ^[0-9]+$ ]] && (( raw > 0 )); then
        watts=$(awk -v p="$raw" 'BEGIN {printf "%.2f", p / 1000000}')
        printf "%s: %s W\n" "$name" "$watts"
        found=1
      fi
    fi
  done

  for d in "${active_sources[@]}"; do
    [ -r "$d/current_now" ] || continue
    [ -r "$d/voltage_now" ] || continue
    name=$(basename "$d")
    current=$(cat "$d/current_now")
    voltage=$(cat "$d/voltage_now")
    if [[ "$current" =~ ^[0-9]+$ ]] && [[ "$voltage" =~ ^[0-9]+$ ]]; then
      watts=$(awk -v c="$current" -v v="$voltage" 'BEGIN {printf "%.2f", (c * v) / 1000000000000}')
      if (( $(awk -v w="$watts" 'BEGIN {print (w > 0.00)}') )); then
        printf "%s: %s W\n" "$name" "$watts"
        found=1
      fi
    fi
  done

  if (( found )); then
    return 0
  fi

  echo "No wattage data exposed by online AC source."
  return 1
}

alias acwp='ac-power-watts'

function _cpu_rapl_path {
  local f
  for f in \
    /sys/class/powercap/intel-rapl:0/intel-rapl:0:0/energy_uj \
    /sys/class/powercap/intel-rapl:0/energy_uj \
    /sys/class/powercap/intel-rapl:0:intel-rapl:0:0/energy_uj \
    /sys/class/powercap/intel_rapl:0/intel-rapl:0:0/energy_uj \
    /sys/class/powercap/intel_rapl:0/energy_uj \
    /sys/class/powercap/amd_energy/energy_uj \
    /sys/class/powercap/*/energy_uw \
    /sys/class/powercap/*/energy_uj \
    /sys/class/powercap/*/*/energy_uj \
    ; do
    if [ -r "$f" ]; then
      echo "$f"
      return 0
    fi
  done
  return 1
}

function _cpu_hwmon_power_path {
  local f d name val
  for f in /sys/class/hwmon/*/power1_input; do
    [ -r "$f" ] || continue
    val="$(cat "$f" 2>/dev/null)"
    [[ "$val" =~ ^[0-9]+$ ]] || continue
    (( val > 0 )) || continue
    d="${f%/*}"
    name="$(cat "$d/name" 2>/dev/null)"
    case "${name:l}" in
      *cpu*|*package*|*rapl*|*core*|*ryzen*|*intel*)
        echo "$f"
        return 0
        ;;
    esac
  done

  for f in /sys/class/hwmon/*/power1_input; do
    [ -r "$f" ] || continue
    val="$(cat "$f" 2>/dev/null)"
    [[ "$val" =~ ^[0-9]+$ ]] || continue
    (( val > 0 )) || continue
    echo "$f"
    return 0
  done
  return 1
}

function cpu-power {
  local interval path path_name path_type e1 e2 t1 t2 dE dt watts unit
  interval="${1:-1}"
  if ! [[ "$interval" =~ '^[0-9]+([.][0-9]+)?$' ]]; then
    path="$1"
    interval="${2:-1}"
  else
    path="${2:-$(_cpu_rapl_path)}"
    if [ -z "$path" ]; then
      path="$(_cpu_hwmon_power_path)"
      path_type="hwmon"
    else
      path_type="energy_uj"
    fi
  fi

  if [ -z "$path" ]; then
    echo "CPU power source not readable by current user."
    echo "Intel/AMD RAPL entries exist but are root-only in /sys/class/powercap on this system."
    echo "Example: sudo -n cat /sys/class/powercap/intel-rapl:0/energy_uj (if you allow passwordless sudo)"
    echo "Fallback: using readable hwmon power1_input if present."
    return 1
  fi
  if [ ! -r "$path" ]; then
    echo "CPU power source not readable: $path"
    return 1
  fi

  e1=$(cat "$path")
  if [ "$path_type" != "hwmon" ] && [[ "$path" != */power1_input ]]; then
    t1=$(date +%s.%N)
    sleep "$interval"
    e2=$(cat "$path")
    t2=$(date +%s.%N)
  else
    interval=0
    t1=0
    t2=0
    e2="$e1"
  fi

  if [ "$path_type" = "hwmon" ] || [[ "$path" == */power1_input ]]; then
    watts=$(awk -v p="$e1" 'BEGIN { print p / 1000000 }')
    unit="W"
  else
    watts=$(awk -v e1="$e1" -v e2="$e2" -v t1="$t1" -v t2="$t2" 'BEGIN {
      dt = t2 - t1
      dE = e2 - e1
      if (dt <= 0 || dE <= 0) { exit 1 }
      print dE / 1000000 / dt
    }')
    unit="W"
  fi
  if [ -z "$watts" ]; then
    echo "Could not compute power from path: $path"
    return 1
  fi
  if [[ "$path" == */power1_input ]]; then
    path_name="$(cat "${path%/power1_input}/name" 2>/dev/null || echo hwmon)"
  else
    path_name="$(basename "$path")"
  fi
  printf "%s: %.2f %s (interval %.2fs)\n" "$path_name" "$watts" "$unit" "$interval"
}

function battery-drop-rate {
  local interval battery_path p1 p2 dt drop_pph ppc
  interval="${1:-60}"
  battery_path="${2:-/sys/class/power_supply/BAT0/capacity}"

  if [ ! -r "$battery_path" ]; then
    echo "Battery percentage file not readable: $battery_path"
    return 1
  fi

  p1=$(cat "$battery_path")
  sleep "$interval"
  p2=$(cat "$battery_path")
  dt=$interval

  ppc=$(awk -v p1="$p1" -v p2="$p2" -v dt="$dt" 'BEGIN { print (p1 - p2) * 3600 / dt }')
  drop_pph=$(awk -v d=$(printf "%s" "$ppc") 'BEGIN { printf "%.2f", d }')
  printf "Battery %s: %s %%/h (from %s%% to %s%% in %ss)\n" "$battery_path" "$drop_pph" "$p1" "$p2" "$dt"
}
