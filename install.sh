#!/usr/bin/env bash
# Written in [Amber](https://amber-lang.com/)
# version: 0.6.0-alpha
[ "$EUID" -ne 0 ] && { { command -v sudo >/dev/null 2>&1 && __sudo=sudo; } || { command -v doas >/dev/null 2>&1 && __sudo=doas; }; }
if [ -n "$ZSH_VERSION" ]; then
    EXEC_SHELL="zsh"
    IFS='.' read -A EXEC_SHELL_VERSION <<< "$ZSH_VERSION"
elif [ -n "$KSH_VERSION" ]; then
    EXEC_SHELL="ksh"
    __exec_shell_version="${.sh.version##*/}"
    IFS='.' read -a EXEC_SHELL_VERSION <<< "${__exec_shell_version%% *}"
else
    EXEC_SHELL="bash"
    EXEC_SHELL_VERSION=("${BASH_VERSINFO[0]}" "${BASH_VERSINFO[1]}" "${BASH_VERSINFO[2]}")
fi
# replace(source: Text, search: Text, replace: Text)
replace__0_v0() {
    local source_1069="${1}"
    local search_1070="${2}"
    local replace_1071="${3}"
    # Here we use a command to avoid #646
    local result_1072=""
    left_comp=("${EXEC_SHELL_VERSION[@]}")
    right_comp=(4 3)
    local comp
    comp="$(
        # Compare if left array >= right array
        len_comp="$( (( "${#left_comp[@]}" < "${#right_comp[@]}" )) && echo "${#left_comp[@]}"|| echo "${#right_comp[@]}")"
        for (( i=0; i<len_comp; i++ )); do
            left="${left_comp[i]?"Index out of bounds (at unknown)"}"
            right="${right_comp[i]?"Index out of bounds (at unknown)"}"
            if (( "${left}" > "${right}" )); then
                echo 1
                exit
            elif (( "${left}" < "${right}" )); then
                echo 0
                exit
            fi
        done
        (( "${#left_comp[@]}" == "${#right_comp[@]}" || "${#left_comp[@]}" > "${#right_comp[@]}" )) && echo 1 || echo 0
)"
    if [ "$(( $([ "_${EXEC_SHELL}" != "_ksh" ]; echo $?) || $(( $([ "_${EXEC_SHELL}" != "_bash" ]; echo $?) && comp )) ))" != 0 ]; then
        result_1072="${source_1069//"${search_1070}"/"${replace_1071}"}"
        __status=$?
    else
        result_1072="${source_1069//"${search_1070}"/${replace_1071}}"
        __status=$?
    fi
    ret_replace0_v0="${result_1072}"
    return 0
}

__SED_VERSION_UNKNOWN_0=0
__SED_VERSION_GNU_1=1
__SED_VERSION_BUSYBOX_2=2
# sed_version()
sed_version__2_v0() {
    # We can't match against a word "GNU" because
    # alpine's busybox sed returns "This is not GNU sed version"
    re='Copyright.+Free Software Foundation'; [[ $(sed --version 2>/dev/null) =~ $re ]]
    __status=$?
    if [ "$(( __status == 0 ))" != 0 ]; then
        ret_sed_version2_v0="${__SED_VERSION_GNU_1}"
        return 0
    fi
    # On BSD single `sed` waits for stdin. We must use `sed --help` to avoid this.
    re='BusyBox'; [[ $(sed --help 2>&1) =~ $re ]]
    __status=$?
    if [ "$(( __status == 0 ))" != 0 ]; then
        ret_sed_version2_v0="${__SED_VERSION_BUSYBOX_2}"
        return 0
    fi
    ret_sed_version2_v0="${__SED_VERSION_UNKNOWN_0}"
    return 0
}

# replace_regex(source: Text, search: Text, replace_text: Text, extended: Bool)
replace_regex__3_v0() {
    local source_1064="${1}"
    local search_1065="${2}"
    local replace_text_1066="${3}"
    local extended_1067="${4}"
    sed_version__2_v0 
    local sed_version_1068="${ret_sed_version2_v0}"
    replace__0_v0 "${search_1065}" "/" "\\/"
    search_1065="${ret_replace0_v0}"
    replace__0_v0 "${replace_text_1066}" "/" "\\/"
    replace_text_1066="${ret_replace0_v0}"
    if [ "$(( $(( sed_version_1068 == __SED_VERSION_GNU_1 )) || $(( sed_version_1068 == __SED_VERSION_BUSYBOX_2 )) ))" != 0 ]; then
        # '\b' is supported but not in POSIX standards. Disable it
        replace__0_v0 "${search_1065}" "\\b" "\\\\b"
        search_1065="${ret_replace0_v0}"
    fi
    if [ "${extended_1067}" != 0 ]; then
        # GNU sed versions 4.0 through 4.2 support extended regex syntax,
        # but only via the "-r" option
        if [ "$(( sed_version_1068 == __SED_VERSION_GNU_1 ))" != 0 ]; then
            local command_1
            command_1="$(sed -r -e "s/${search_1065}/${replace_text_1066}/g" <<<"${source_1064}")"
            __status=$?
            ret_replace_regex3_v0="${command_1}"
            return 0
        else
            local command_2
            command_2="$(sed -E -e "s/${search_1065}/${replace_text_1066}/g" <<<"${source_1064}")"
            __status=$?
            ret_replace_regex3_v0="${command_2}"
            return 0
        fi
    else
        if [ "$(( $(( sed_version_1068 == __SED_VERSION_GNU_1 )) || $(( sed_version_1068 == __SED_VERSION_BUSYBOX_2 )) ))" != 0 ]; then
            # GNU Sed BRE handle \| as a metacharacter, but it is not POSIX standands. Disable it
            replace__0_v0 "${search_1065}" "\\|" "|"
            search_1065="${ret_replace0_v0}"
        fi
        local command_3
        command_3="$(sed -e "s/${search_1065}/${replace_text_1066}/g" <<<"${source_1064}")"
        __status=$?
        ret_replace_regex3_v0="${command_3}"
        return 0
    fi
}

# split(text: Text, delimiter: Text)
split__4_v0() {
    local text_1369="${1}"
    local delimiter_1370="${2}"
    local result_1371=()
    # zsh uses -A for array, bash uses -a, ksh is VERY bad at splitting anything
    if [ "$([ "_${EXEC_SHELL}" != "_zsh" ]; echo $?)" != 0 ]; then
        IFS="${delimiter_1370}" read -rd '' -A result_1371 < <(printf %s "$text_1369")
        __status=$?
    elif [ "$([ "_${EXEC_SHELL}" != "_ksh" ]; echo $?)" != 0 ]; then
        if [ "$([ "_${delimiter_1370}" != "_
" ]; echo $?)" != 0 ]; then
            while read -r -d $'\n'; do result_1371+=("$REPLY"); done < <(echo "$text_1369")
            __status=$?
        else
            IFS="${delimiter_1370}" read -rd '' -a result_1371 < <(printf %s "$text_1369")
            __status=$?
        fi
    elif [ "$([ "_${EXEC_SHELL}" != "_bash" ]; echo $?)" != 0 ]; then
        IFS="${delimiter_1370}" read -rd '' -a result_1371 < <(printf %s "$text_1369")
        __status=$?
    fi
    ret_split4_v0=("${result_1371[@]}")
    return 0
}

# split_lines(text: Text)
split_lines__5_v0() {
    local text_1368="${1}"
    split__4_v0 "${text_1368}" "
"
    ret_split_lines5_v0=("${ret_split4_v0[@]}")
    return 0
}

# join(list: [Text], delimiter: Text)
join__7_v0() {
    local list_350=("${!1}")
    local delimiter_351="${2}"
    local command_5
    command_5="$(IFS="${delimiter_351}" ; printf "%s
" "${list_350[*]}")"
    __status=$?
    ret_join7_v0="${command_5}"
    return 0
}

# trim(text: Text)
trim__10_v0() {
    local text_16="${1}"
    local result_17=""
    result_17="${text_16#${text_16%%[![:space:]]*}}"
    __status=$?
    result_17="${result_17%${result_17##*[![:space:]]}}"
    __status=$?
    ret_trim10_v0="${result_17}"
    return 0
}

# dir_exists(path: Text)
dir_exists__38_v0() {
    local path_32="${1}"
    [ -d "${path_32}" ]
    __status=$?
    ret_dir_exists38_v0="$(( __status == 0 ))"
    return 0
}

# file_exists(path: Text)
file_exists__39_v0() {
    local path_33="${1}"
    [ -f "${path_33}" ]
    __status=$?
    ret_file_exists39_v0="$(( __status == 0 ))"
    return 0
}

# file_write(path: Text, content: Text)
file_write__41_v0() {
    local path_378="${1}"
    local content_379="${2}"
    local command_6
    command_6="$(printf '%s
' "${content_379}" > "${path_378}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_file_write41_v0=''
        return "${__status}"
    fi
    ret_file_write41_v0="${command_6}"
    return 0
}

# dir_create(path: Text)
dir_create__44_v0() {
    local path_371="${1}"
    dir_exists__38_v0 "${path_371}"
    local ret_dir_exists38_v0__87_12="${ret_dir_exists38_v0}"
    if [ "$(( ! ret_dir_exists38_v0__87_12 ))" != 0 ]; then
        mkdir -p "${path_371}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_dir_create44_v0=''
            return "${__status}"
        fi
    fi
}

# is_mac_os_mktemp()
is_mac_os_mktemp__45_v0() {
    # macOS's mktemp does not have --version
    mktemp --version>/dev/null 2>&1
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_is_mac_os_mktemp45_v0=1
        return 0
    fi
    ret_is_mac_os_mktemp45_v0=0
    return 0
}

# temp_dir_create(template: Text, auto_delete: Bool, force_delete: Bool)
temp_dir_create__46_v0() {
    local template_13="${1}"
    local auto_delete_14="${2}"
    local force_delete_15="${3}"
    trim__10_v0 "${template_13}"
    local ret_trim10_v0__113_8="${ret_trim10_v0}"
    if [ "$([ "_${ret_trim10_v0__113_8}" != "_" ]; echo $?)" != 0 ]; then
        echo "The template cannot be an empty string"'!'""
        ret_temp_dir_create46_v0=''
        return 1
    fi
    local filename_18=""
    is_mac_os_mktemp__45_v0 
    local ret_is_mac_os_mktemp45_v0__119_8="${ret_is_mac_os_mktemp45_v0}"
    if [ "${ret_is_mac_os_mktemp45_v0__119_8}" != 0 ]; then
        # usage: mktemp [-d] [-p tmpdir] [-q] [-t prefix] [-u] template ...
        # mktemp [-d] [-p tmpdir] [-q] [-u] -t prefix
        local command_7
        command_7="$(mktemp -d -p "$TMPDIR" "${template_13}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_temp_dir_create46_v0=''
            return "${__status}"
        fi
        filename_18="${command_7}"
    else
        local command_8
        command_8="$(mktemp -d -p "$TMPDIR" -t "${template_13}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_temp_dir_create46_v0=''
            return "${__status}"
        fi
        filename_18="${command_8}"
    fi
    if [ "$([ "_${filename_18}" != "_" ]; echo $?)" != 0 ]; then
        echo "Failed to make a temporary directory"
        ret_temp_dir_create46_v0=''
        return 1
    fi
    if [ "$(( auto_delete_14 && $([ "_${EXEC_SHELL}" == "_ksh" ]; echo $?) ))" != 0 ]; then
        if [ "${force_delete_15}" != 0 ]; then
            trap 'rm -rf '"${filename_18}"'' EXIT
            __status=$?
            if [ "${__status}" != 0 ]; then
                echo "Setting auto deletion fails. You must delete temporary dir ${filename_18}."
            fi
        else
            trap 'rmdir '"${filename_18}"'' EXIT
            __status=$?
            if [ "${__status}" != 0 ]; then
                echo "Setting auto deletion fails. You must delete temporary dir ${filename_18}."
            fi
        fi
    fi
    ret_temp_dir_create46_v0="${filename_18}"
    return 0
}

# env_var_get(name: Text)
env_var_get__124_v0() {
    local name_343="${1}"
    if [ "$([ "_${EXEC_SHELL}" != "_bash" ]; echo $?)" != 0 ]; then
        local command_9
        command_9="$(printf "%s
" "${!name_343}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_env_var_get124_v0=''
            return "${__status}"
        fi
        ret_env_var_get124_v0="${command_9}"
        return 0
    elif [ "$([ "_${EXEC_SHELL}" != "_zsh" ]; echo $?)" != 0 ]; then
        local command_10
        command_10="$(printf "%s
" "${(P)name_343}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_env_var_get124_v0=''
            return "${__status}"
        fi
        ret_env_var_get124_v0="${command_10}"
        return 0
    elif [ "$([ "_${EXEC_SHELL}" != "_ksh" ]; echo $?)" != 0 ]; then
        local command_11
        command_11="$(eval "echo \${$name_343}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_env_var_get124_v0=''
            return "${__status}"
        fi
        ret_env_var_get124_v0="${command_11}"
        return 0
    fi
}

# printf(format: Text, args: [Text])
printf__132_v0() {
    local format_357="${1}"
    local args_358=("${!2}")
    args_358=("${format_357}" "${args_358[@]}")
    __status=$?
    printf "${args_358[@]}"
    __status=$?
}

# echo_warning(message: Text)
echo_warning__141_v0() {
    local message_363="${1}"
    local array_12=("${message_363}")
    printf__132_v0 "\\x1b[1;3;97;43m%s\\x1b[0m
" array_12[@]
}

# echo_error(message: Text, exit_code: Int)
echo_error__142_v0() {
    local message_355="${1}"
    local exit_code_356="${2}"
    local array_13=("${message_355}")
    printf__132_v0 "\\x1b[1;3;97;41m%s\\x1b[0m
" array_13[@]
    if [ "$(( exit_code_356 > 0 ))" != 0 ]; then
        exit "${exit_code_356}"
    fi
}

# has_cmd(cmd: Text)
has_cmd__165_v0() {
    local cmd_348="${1}"
    local found_349=0
    command -v ${cmd_348} >/dev/null 2>&1
    __status=$?
    if [ "${__status}" = 0 ]; then
        found_349=1
    fi
    ret_has_cmd165_v0="${found_349}"
    return 0
}

# echo_error exits the process (default exit_code=1), so no fail needed.
# sudo_cmd(cmd: Text, envvar: [])
sudo_cmd__169_v0() {
    local cmd_346="${1}"
    local envvar_347=("${!2}")
    has_cmd__165_v0 "sudo"
    local ret_has_cmd165_v0__4_8="${ret_has_cmd165_v0}"
    if [ "${ret_has_cmd165_v0__4_8}" != 0 ]; then
        sudo ${envvar_347[@]} ${cmd_346}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd169_v0=''
            return "${__status}"
        fi
    else
        env ${envvar_347[@]} ${cmd_346}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd169_v0=''
            return "${__status}"
        fi
    fi
}

# sudo_cmd(cmd: Text, envvar: [Text])
sudo_cmd__169_v1() {
    local cmd_353="${1}"
    local envvar_354=("${!2}")
    has_cmd__165_v0 "sudo"
    local ret_has_cmd165_v0__4_8="${ret_has_cmd165_v0}"
    if [ "${ret_has_cmd165_v0__4_8}" != 0 ]; then
        sudo ${envvar_354[@]} ${cmd_353}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd169_v1=''
            return "${__status}"
        fi
    else
        env ${envvar_354[@]} ${cmd_353}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd169_v1=''
            return "${__status}"
        fi
    fi
}

# prompt_user(description: Text)
prompt_user__172_v0() {
    local description_342="${1}"
    env_var_get__124_v0 "COPALS_ASK"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_prompt_user172_v0=1
        return 0
    fi
    local ask_344="${ret_env_var_get124_v0}"
    if [ "$([ "_${ask_344}" != "_" ]; echo $?)" != 0 ]; then
        ret_prompt_user172_v0=1
        return 0
    fi
    echo "install: ${description_342}"
    printf "Proceed? [Y/n] " >&2
    __status=$?
    local command_14
    command_14="$(read -r line < /dev/tty 2>/dev/null; printf "%s" "$line")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        printf "
" >&2
        __status=$?
        ret_prompt_user172_v0=1
        return 0
    fi
    local ans_345="${command_14}"
    if [ "$([ "_${ans_345}" != "_" ]; echo $?)" != 0 ]; then
        ret_prompt_user172_v0=1
        return 0
    fi
    if [ "$(( $(( $(( $(( $([ "_${ans_345}" != "_n" ]; echo $?) || $([ "_${ans_345}" != "_N" ]; echo $?) )) || $([ "_${ans_345}" != "_no" ]; echo $?) )) || $([ "_${ans_345}" != "_NO" ]; echo $?) )) || $([ "_${ans_345}" != "_No" ]; echo $?) ))" != 0 ]; then
        echo "skipping"
        ret_prompt_user172_v0=0
        return 0
    fi
    ret_prompt_user172_v0=1
    return 0
}

# has_cmd(cmd: Text)
has_cmd__175_v0() {
    local cmd_361="${1}"
    local found_362=0
    command -v ${cmd_361} >/dev/null 2>&1
    __status=$?
    if [ "${__status}" = 0 ]; then
        found_362=1
    fi
    ret_has_cmd175_v0="${found_362}"
    return 0
}

# echo_error exits the process (default exit_code=1), so no fail needed.
was_updated_3=0
# update()
update__179_v0() {
    local array_15=()
    sudo_cmd__169_v0 "apt-get update" array_15[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_update179_v0=''
        return "${__status}"
    fi
}

# ensure_updated()
ensure_updated__180_v0() {
    if [ "$(( ! was_updated_3 ))" != 0 ]; then
        update__179_v0 
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_ensure_updated180_v0=''
            return "${__status}"
        fi
        was_updated_3=1
    fi
}

# apt_install(packages: [Text])
apt_install__181_v0() {
    local packages_341=("${!1}")
    prompt_user__172_v0 "apt install: ${packages_341[@]}"
    local ret_prompt_user172_v0__19_12="${ret_prompt_user172_v0}"
    if [ "$(( ! ret_prompt_user172_v0__19_12 ))" != 0 ]; then
        ret_apt_install181_v0=''
        return 0
    fi
    ensure_updated__180_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_apt_install181_v0=''
        return "${__status}"
    fi
    join__7_v0 packages_341[@] " "
    local pkgs_352="${ret_join7_v0}"
    local array_16=("DEBIAN_FRONTEND=noninteractive")
    sudo_cmd__169_v1 "apt-get install -y --no-install-recommends ${pkgs_352}" array_16[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_apt_install181_v0=''
        return "${__status}"
    fi
}

# apt_install_or_die(packages: [Text])
apt_install_or_die__182_v0() {
    local packages_340=("${!1}")
    apt_install__181_v0 packages_340[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to apt install ${packages_340[@]}" 1
    fi
}

# apt_install_if_missing_or_die(cmd: Text, pkg: Text)
apt_install_if_missing_or_die__183_v0() {
    local cmd_359="${1}"
    local pkg_360="${2}"
    has_cmd__175_v0 "${cmd_359}"
    local ret_has_cmd175_v0__34_8="${ret_has_cmd175_v0}"
    if [ "${ret_has_cmd175_v0__34_8}" != 0 ]; then
        echo_warning__141_v0 "${cmd_359} already installed, skipping apt install"
    else
        local array_17=("${pkg_360}")
        apt_install_or_die__182_v0 array_17[@]
    fi
}

# home()
home__187_v0() {
    env_var_get__124_v0 "HOME"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_home187_v0=''
        return "${__status}"
    fi
    ret_home187_v0="${ret_env_var_get124_v0}"
    return 0
}

# copy_into_home(src: Text, rel_dest: Text)
copy_into_home__194_v0() {
    local src_367="${1}"
    local rel_dest_368="${2}"
    home__187_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_copy_into_home194_v0=''
        return "${__status}"
    fi
    local home_369="${ret_home187_v0}"
    local dest_370="${home_369}/${rel_dest_368}"
    dir_create__44_v0 "${dest_370}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_copy_into_home194_v0=''
        return "${__status}"
    fi
    local __cp_18=
    (( 1 )) && __cp_18="-f" || __cp_18=""
    cp -r ${__cp_18} "${src_367}" "${dest_370}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_copy_into_home194_v0=''
        return "${__status}"
    fi
    ret_copy_into_home194_v0="${dest_370}"
    return 0
}

# copy_into_home_or_die(src: Text, rel_dest: Text)
copy_into_home_or_die__195_v0() {
    local src_365="${1}"
    local rel_dest_366="${2}"
    prompt_user__172_v0 "cp into home: ${rel_dest_366}"
    local ret_prompt_user172_v0__23_12="${ret_prompt_user172_v0}"
    if [ "$(( ! ret_prompt_user172_v0__23_12 ))" != 0 ]; then
        ret_copy_into_home_or_die195_v0=""
        return 0
    fi
    copy_into_home__194_v0 "${src_365}" "${rel_dest_366}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "deploy of ${rel_dest_366} into home failed" 1
    fi
    local dest_372="${ret_copy_into_home194_v0}"
    ret_copy_into_home_or_die195_v0="${dest_372}"
    return 0
}

# dir_create_at_home(rel: Text)
dir_create_at_home__201_v0() {
    local rel_374="${1}"
    home__187_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_dir_create_at_home201_v0=''
        return "${__status}"
    fi
    local h_375="${ret_home187_v0}"
    dir_create__44_v0 "${h_375}/${rel_374}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_dir_create_at_home201_v0=''
        return "${__status}"
    fi
}

# dir_create_at_home_or_die(rel: Text)
dir_create_at_home_or_die__202_v0() {
    local rel_373="${1}"
    prompt_user__172_v0 "create directory ~/${rel_373}"
    local ret_prompt_user172_v0__12_8="${ret_prompt_user172_v0}"
    if [ "${ret_prompt_user172_v0__12_8}" != 0 ]; then
        dir_create_at_home__201_v0 "${rel_373}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "failed to create directory at home/${rel_373}" 1
        fi
    fi
}

# home()
home__206_v0() {
    env_var_get__124_v0 "HOME"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_home206_v0=''
        return "${__status}"
    fi
    ret_home206_v0="${ret_env_var_get124_v0}"
    return 0
}

__APPS_DIR_4=".local/share/applications"
# make_nnn_desktop(h: Text)
make_nnn_desktop__209_v0() {
    local h_376="${1}"
    local path_377="${h_376}/.local/bin/st-zsh"
    ret_make_nnn_desktop209_v0="[Desktop Entry]
Type=Application
Name=File Explorer (nnn)
Comment=Terminal file manager
Exec=${path_377} -e ${h_376}/.local/bin/nnn-launch
Terminal=false
Categories=Utility;FileManager;
Icon=nnn
"
    return 0
}

# make_btop_desktop(h: Text)
make_btop_desktop__210_v0() {
    local h_380="${1}"
    local path_381="${h_380}/.local/bin/st-zsh"
    ret_make_btop_desktop210_v0="[Desktop Entry]
Type=Application
Name=System Monitor (btop)
Comment=Resource monitor
Exec=${path_381} -e btop
Terminal=false
Categories=System;Monitor;
Icon=btop
"
    return 0
}

# make_ncdu_desktop(h: Text)
make_ncdu_desktop__211_v0() {
    local h_382="${1}"
    local path_383="${h_382}/.local/bin/st-zsh"
    ret_make_ncdu_desktop211_v0="[Desktop Entry]
Type=Application
Name=Disk Usage (ncdu)
Comment=Disk usage analyzer
Exec=${path_383} -e ncdu
Terminal=false
Categories=System;Utility;
Icon=ncdu
"
    return 0
}

# install_apt_essential_tools()
install_apt_essential_tools__212_v0() {
    local array_19=("rsync" "git" "tmux" "zsh" "sqlite3" "jq" "curl" "vim" "ca-certificates" "ripgrep" "nnn" "fzf" "zenity" "btop" "ncdu")
    apt_install_or_die__182_v0 array_19[@]
    apt_install_if_missing_or_die__183_v0 "nvim" "neovim"
    home__206_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to resolve HOME" 1
    fi
    local h_364="${ret_home206_v0}"
    copy_into_home_or_die__195_v0 "src/apt-essential-tools/.config/nnn" ".config/"
    copy_into_home_or_die__195_v0 "src/apt-essential-tools/.local/bin" ".local/"
    chmod +x ${h_364}/.config/nnn/plugins/dragdrop ${h_364}/.config/nnn/plugins/zmarks ${h_364}/.config/nnn/plugins/nvim-cd ${h_364}/.config/nnn/plugins/bm-create ${h_364}/.config/nnn/plugins/win-open ${h_364}/.config/nnn/profile ${h_364}/.local/bin/nnn-launch
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to chmod nnn files" 1
    fi
    dir_create_at_home_or_die__202_v0 "${__APPS_DIR_4}"
    make_nnn_desktop__209_v0 "${h_364}"
    local ret_make_nnn_desktop209_v0__40_46="${ret_make_nnn_desktop209_v0}"
    file_write__41_v0 "${h_364}/${__APPS_DIR_4}/nnn.desktop" "${ret_make_nnn_desktop209_v0__40_46}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to write nnn.desktop" 1
    fi
    make_btop_desktop__210_v0 "${h_364}"
    local ret_make_btop_desktop210_v0__43_47="${ret_make_btop_desktop210_v0}"
    file_write__41_v0 "${h_364}/${__APPS_DIR_4}/btop.desktop" "${ret_make_btop_desktop210_v0__43_47}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to write btop.desktop" 1
    fi
    make_ncdu_desktop__211_v0 "${h_364}"
    local ret_make_ncdu_desktop211_v0__46_47="${ret_make_ncdu_desktop211_v0}"
    file_write__41_v0 "${h_364}/${__APPS_DIR_4}/ncdu.desktop" "${ret_make_ncdu_desktop211_v0__46_47}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to write ncdu.desktop" 1
    fi
}

# Terminal package is installed here; the x-terminal-emulator alternative and
# per-terminal personalization belong to the terminal's own hook
# (install_alacritty/install_st).
# TODO: this should be addressed directly by copals in the future with a few
# re-usable preset hooks (e.g. a copals-provided "gui-vnc" preset). The x11vnc
# and xvfb packages below are a temporary stopgap so `container launch-window`
# can serve the i3 desktop over VNC on macOS hosts. x11-xserver-utils (xsetroot)
# is needed by both the i3 desktop and the launcher.
# install_apt_essential_ui()
install_apt_essential_ui__215_v0() {
    local array_20=("stterm" "i3" "suckless-tools" "dbus" "dbus-x11" "xss-lock" "x11-xserver-utils" "libgl1-mesa-dri" "libgl1" "libegl1" "libegl-mesa0")
    apt_install_or_die__182_v0 array_20[@]
    local array_21=("xfce4-settings")
    apt_install_or_die__182_v0 array_21[@]
    local array_22=("x11vnc" "xvfb")
    apt_install_or_die__182_v0 array_22[@]
}

# rsync(src: Text, target: Text, excludes: [], delete: Bool)
rsync__222_v0() {
    local src_449="${1}"
    local target_450="${2}"
    local excludes_451=("${!3}")
    local delete_452="${4}"
    dir_create__44_v0 "${target_450}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync222_v0=''
        return "${__status}"
    fi
    local excludes_arr_453=()
    for exclude_454 in "${excludes_451[@]}"; do
        local s_455="${exclude_454}"
        excludes_arr_453+=("--exclude" "${s_455}")
    done
    local delopt_456=""
    if [ "${delete_452}" != 0 ]; then
        delopt_456="--delete"
    fi
    rsync -a ${delopt_456} ${excludes_arr_453[@]} ${src_449} ${target_450}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync222_v0=''
        return "${__status}"
    fi
}

# rsync(src: Text, target: Text, excludes: [Text], delete: Bool)
rsync__222_v1() {
    local src_635="${1}"
    local target_636="${2}"
    local excludes_637=("${!3}")
    local delete_638="${4}"
    dir_create__44_v0 "${target_636}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync222_v1=''
        return "${__status}"
    fi
    local excludes_arr_639=()
    for exclude_640 in "${excludes_637[@]}"; do
        local s_641="${exclude_640}"
        excludes_arr_639+=("--exclude" "${s_641}")
    done
    local delopt_642=""
    if [ "${delete_638}" != 0 ]; then
        delopt_642="--delete"
    fi
    rsync -a ${delopt_642} ${excludes_arr_639[@]} ${src_635} ${target_636}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync222_v1=''
        return "${__status}"
    fi
}

# rsync_into_home(src: Text, rel_target: Text, delete: Bool)
rsync_into_home__225_v0() {
    local src_443="${1}"
    local rel_target_444="${2}"
    local delete_445="${3}"
    local excludes_446=()
    home__187_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync_into_home225_v0=''
        return "${__status}"
    fi
    local h_447="${ret_home187_v0}"
    local target_448="${h_447}/${rel_target_444}"
    dir_create__44_v0 "${target_448}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync_into_home225_v0=''
        return "${__status}"
    fi
    rsync__222_v0 "${src_443}" "${target_448}" excludes_446[@] "${delete_445}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync_into_home225_v0=''
        return "${__status}"
    fi
}

# rsync_or_die_into_home(src: Text, rel_target: Text, delete: Bool)
rsync_or_die_into_home__226_v0() {
    local src_440="${1}"
    local rel_target_441="${2}"
    local delete_442="${3}"
    prompt_user__172_v0 "rsync ${src_440} -> ~/${rel_target_441}"
    local ret_prompt_user172_v0__16_8="${ret_prompt_user172_v0}"
    if [ "${ret_prompt_user172_v0__16_8}" != 0 ]; then
        rsync_into_home__225_v0 "${src_440}" "${rel_target_441}" "${delete_442}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "rsync deploy of ${src_440} into ${rel_target_441} failed" 1
        fi
    fi
}

# rsync_or_die_opts(src: Text, target: Text, excludes: [Text], delete: Bool)
rsync_or_die_opts__227_v0() {
    local src_631="${1}"
    local target_632="${2}"
    local excludes_633=("${!3}")
    local delete_634="${4}"
    prompt_user__172_v0 "rsync ${src_631} -> ${target_632}"
    local ret_prompt_user172_v0__24_8="${ret_prompt_user172_v0}"
    if [ "${ret_prompt_user172_v0__24_8}" != 0 ]; then
        rsync__222_v1 "${src_631}" "${target_632}" excludes_633[@] "${delete_634}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "rsync deploy of ${src_631} into ${target_632} failed" 1
        fi
    fi
}

# rsync_or_die_opts_into_home(src: Text, rel_target: Text, excludes: [Text], delete: Bool)
rsync_or_die_opts_into_home__228_v0() {
    local src_626="${1}"
    local rel_target_627="${2}"
    local excludes_628=("${!3}")
    local delete_629="${4}"
    prompt_user__172_v0 "rsync ${src_626} -> ~/${rel_target_627}"
    local ret_prompt_user172_v0__32_8="${ret_prompt_user172_v0}"
    if [ "${ret_prompt_user172_v0__32_8}" != 0 ]; then
        home__187_v0 
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "rsync_or_die_opts_into_home: failed to resolve home directory" 1
            exit 1
        fi
        local h_630="${ret_home187_v0}"
        rsync_or_die_opts__227_v0 "${src_626}" "${h_630}/${rel_target_627}" excludes_628[@] "${delete_629}"
    fi
}

# install_dotfiles_essential()
install_dotfiles_essential__230_v0() {
    rsync_or_die_into_home__226_v0 "src/dotfiles_essential/.config/" ".config" 0
}

# setup_global_gitignore()
setup_global_gitignore__235_v0() {
    home__187_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_setup_global_gitignore235_v0=''
        return "${__status}"
    fi
    local h_460="${ret_home187_v0}"
    file_exists__39_v0 "${h_460}/.gitignore_global"
    local ret_file_exists39_v0__7_12="${ret_file_exists39_v0}"
    if [ "$(( ! ret_file_exists39_v0__7_12 ))" != 0 ]; then
        ret_setup_global_gitignore235_v0=''
        return 1
    fi
    git config --global core.excludesFile ${h_460}/.gitignore_global
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_setup_global_gitignore235_v0=''
        return "${__status}"
    fi
}

# setup_global_gitignore_or_die()
setup_global_gitignore_or_die__236_v0() {
    setup_global_gitignore__235_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to setup global gitignore" 1
    fi
}

# install_dotfiles_personalization()
install_dotfiles_personalization__240_v0() {
    rsync_or_die_into_home__226_v0 "src/dotfiles_personalization/" "" 0
    setup_global_gitignore_or_die__236_v0 
    copy_into_home_or_die__195_v0 "src/dotfiles_personalization/.local/share/applications" ".local/share/applications"
}

# has_cmd(cmd: Text)
has_cmd__244_v0() {
    local cmd_513="${1}"
    local found_514=0
    command -v ${cmd_513} >/dev/null 2>&1
    __status=$?
    if [ "${__status}" = 0 ]; then
        found_514=1
    fi
    ret_has_cmd244_v0="${found_514}"
    return 0
}

# echo_error exits the process (default exit_code=1), so no fail needed.
# sudo_cmd(cmd: Text, envvar: [])
sudo_cmd__248_v0() {
    local cmd_511="${1}"
    local envvar_512=("${!2}")
    has_cmd__244_v0 "sudo"
    local ret_has_cmd244_v0__4_8="${ret_has_cmd244_v0}"
    if [ "${ret_has_cmd244_v0__4_8}" != 0 ]; then
        sudo ${envvar_512[@]} ${cmd_511}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd248_v0=''
            return "${__status}"
        fi
    else
        env ${envvar_512[@]} ${cmd_511}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd248_v0=''
            return "${__status}"
        fi
    fi
}

# has_cmd(cmd: Text)
has_cmd__251_v0() {
    local cmd_505="${1}"
    local found_506=0
    command -v ${cmd_505} >/dev/null 2>&1
    __status=$?
    if [ "${__status}" = 0 ]; then
        found_506=1
    fi
    ret_has_cmd251_v0="${found_506}"
    return 0
}

# which_cmd(cmd: Text)
which_cmd__252_v0() {
    local cmd_507="${1}"
    local command_32
    command_32="$(command -v ${cmd_507} 2>/dev/null)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_which_cmd252_v0=''
        return "${__status}"
    fi
    ret_which_cmd252_v0="${command_32}"
    return 0
}

# echo_error exits the process (default exit_code=1), so no fail needed.
# set_terminal_alternative()
set_terminal_alternative__259_v0() {
    local command_33
    command_33="$(command -v st)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_set_terminal_alternative259_v0=''
        return "${__status}"
    fi
    local st_bin_503="${command_33}"
    local term_path_504="${st_bin_503}"
    has_cmd__251_v0 "zsh"
    local ret_has_cmd251_v0__11_8="${ret_has_cmd251_v0}"
    if [ "${ret_has_cmd251_v0__11_8}" != 0 ]; then
        which_cmd__252_v0 "zsh"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative259_v0=''
            return "${__status}"
        fi
        local zsh_bin_508="${ret_which_cmd252_v0}"
        home__206_v0 
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative259_v0=''
            return "${__status}"
        fi
        local h_509="${ret_home206_v0}"
        local wrapper_510="${h_509}/.local/bin/st-zsh"
        mkdir -p "${h_509}/.local/bin"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative259_v0=''
            return "${__status}"
        fi
        echo '#!/bin/sh' > "${wrapper_510}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative259_v0=''
            return "${__status}"
        fi
        echo '[ "$1" = "-e" ] && shift' >> "${wrapper_510}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative259_v0=''
            return "${__status}"
        fi
        echo 'if [ "$#" -eq 0 ]; then' >> "${wrapper_510}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative259_v0=''
            return "${__status}"
        fi
        echo "    exec ${st_bin_503} -f 'monospace:size=12' -e ${h_509}/.local/bin/st-init.sh ${zsh_bin_508}" >> "${wrapper_510}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative259_v0=''
            return "${__status}"
        fi
        echo 'else' >> "${wrapper_510}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative259_v0=''
            return "${__status}"
        fi
        echo "    exec ${st_bin_503} -f 'monospace:size=12' -e ${h_509}/.local/bin/st-init.sh" '"$@"' >> "${wrapper_510}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative259_v0=''
            return "${__status}"
        fi
        echo 'fi' >> "${wrapper_510}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative259_v0=''
            return "${__status}"
        fi
        chmod +x "${wrapper_510}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative259_v0=''
            return "${__status}"
        fi
        term_path_504="${wrapper_510}"
    fi
    local array_34=()
    sudo_cmd__248_v0 "update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator ${term_path_504} 10" array_34[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_set_terminal_alternative259_v0=''
        return "${__status}"
    fi
    local array_35=()
    sudo_cmd__248_v0 "update-alternatives --set x-terminal-emulator ${term_path_504}" array_35[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_set_terminal_alternative259_v0=''
        return "${__status}"
    fi
}

# install_st()
install_st__260_v0() {
    set_terminal_alternative__259_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "st: failed to register x-terminal-emulator alternative" 1
    fi
    dir_create_at_home_or_die__202_v0 ".config/fontconfig"
    copy_into_home_or_die__195_v0 "src/st/.config/fontconfig/fonts.conf" ".config/fontconfig"
    home__206_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "st: cannot resolve HOME" 1
    fi
    local h_515="${ret_home206_v0}"
    mkdir -p "${h_515}/.local/bin"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "st: failed to create ~/.local/bin" 1
    fi
    cp "src/st/.local/bin/st-init.sh" "${h_515}/.local/bin/st-init.sh"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "st: failed to copy st-init.sh" 1
    fi
    chmod +x "${h_515}/.local/bin/st-init.sh"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "st: failed to chmod st-init.sh" 1
    fi
}

# symlink_create_dir(origin: Text, destination: Text)
symlink_create_dir__268_v0() {
    local origin_568="${1}"
    local destination_569="${2}"
    dir_exists__38_v0 "${origin_568}"
    local ret_dir_exists38_v0__4_12="${ret_dir_exists38_v0}"
    if [ "$(( ! ret_dir_exists38_v0__4_12 ))" != 0 ]; then
        echo "The directory ${origin_568} doesn't exist"
        ret_symlink_create_dir268_v0=''
        return 1
    fi
    ln -fsn ${origin_568} ${destination_569}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_create_dir268_v0=''
        return "${__status}"
    fi
}

# TODO test this
# _parent_dir(path: Text)
_parent_dir__271_v0() {
    local path_564="${1}"
    local command_36
    command_36="$(dirname ${path_564})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret__parent_dir271_v0=''
        return "${__status}"
    fi
    local parent_565="${command_36}"
    ret__parent_dir271_v0="${parent_565}"
    return 0
}

# symlink_into_home(src: Text, rel_dest: Text)
symlink_into_home__272_v0() {
    local src_560="${1}"
    local rel_dest_561="${2}"
    home__187_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home272_v0=''
        return "${__status}"
    fi
    local home_562="${ret_home187_v0}"
    local dest_563="${home_562}/${rel_dest_561}"
    _parent_dir__271_v0 "${dest_563}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home272_v0=''
        return "${__status}"
    fi
    local parent_566="${ret__parent_dir271_v0}"
    dir_create__44_v0 "${parent_566}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home272_v0=''
        return "${__status}"
    fi
    local command_37
    command_37="$(readlink -f ${src_560})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home272_v0=''
        return "${__status}"
    fi
    local abs_src_567="${command_37}"
    symlink_create_dir__268_v0 "${abs_src_567}" "${dest_563}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home272_v0=''
        return "${__status}"
    fi
    ret_symlink_into_home272_v0="${dest_563}"
    return 0
}

# symlink_into_home_or_die(src: Text, rel_dest: Text)
symlink_into_home_or_die__273_v0() {
    local src_558="${1}"
    local rel_dest_559="${2}"
    prompt_user__172_v0 "symlink ${src_558} -> ~/${rel_dest_559}"
    local ret_prompt_user172_v0__26_12="${ret_prompt_user172_v0}"
    if [ "$(( ! ret_prompt_user172_v0__26_12 ))" != 0 ]; then
        ret_symlink_into_home_or_die273_v0=""
        return 0
    fi
    symlink_into_home__272_v0 "${src_558}" "${rel_dest_559}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "deploy of ${src_558} symlink ${rel_dest_559}  into home failed" 1
    fi
    local dest_570="${ret_symlink_into_home272_v0}"
    ret_symlink_into_home_or_die273_v0="${dest_570}"
    return 0
}

# Symlink a home-relative path to another home-relative path (both resolved
# against home()). Works for files (e.g. bridging a data file from one config
# location to the path a plugin expects).
# symlink_at_home(src_rel: Text, dest_rel: Text)
symlink_at_home__274_v0() {
    local src_rel_1127="${1}"
    local dest_rel_1128="${2}"
    home__187_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_at_home274_v0=''
        return "${__status}"
    fi
    local h_1129="${ret_home187_v0}"
    local src_1130="${h_1129}/${src_rel_1127}"
    local dest_1131="${h_1129}/${dest_rel_1128}"
    file_exists__39_v0 "${src_1130}"
    local ret_file_exists39_v0__43_12="${ret_file_exists39_v0}"
    if [ "$(( ! ret_file_exists39_v0__43_12 ))" != 0 ]; then
        echo_error__142_v0 "symlink source ${src_1130} missing" 1
        ret_symlink_at_home274_v0=''
        return 1
    fi
    _parent_dir__271_v0 "${dest_1131}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_at_home274_v0=''
        return "${__status}"
    fi
    local parent_1132="${ret__parent_dir271_v0}"
    dir_create__44_v0 "${parent_1132}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_at_home274_v0=''
        return "${__status}"
    fi
    ln -fsn ${src_1130} ${dest_1131}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_at_home274_v0=''
        return "${__status}"
    fi
    ret_symlink_at_home274_v0="${dest_1131}"
    return 0
}

# symlink_at_home_or_die(src_rel: Text, dest_rel: Text)
symlink_at_home_or_die__275_v0() {
    local src_rel_1125="${1}"
    local dest_rel_1126="${2}"
    prompt_user__172_v0 "symlink ~/${src_rel_1125} -> ~/${dest_rel_1126}"
    local ret_prompt_user172_v0__57_12="${ret_prompt_user172_v0}"
    if [ "$(( ! ret_prompt_user172_v0__57_12 ))" != 0 ]; then
        ret_symlink_at_home_or_die275_v0=""
        return 0
    fi
    symlink_at_home__274_v0 "${src_rel_1125}" "${dest_rel_1126}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "symlink ${src_rel_1125} -> ${dest_rel_1126} in home failed" 1
    fi
    local dest_1133="${ret_symlink_at_home274_v0}"
    ret_symlink_at_home_or_die275_v0="${dest_1133}"
    return 0
}

# install_nerd_fonts()
install_nerd_fonts__277_v0() {
    local subpath_557=".local/share/fonts/NerdFonts"
    symlink_into_home_or_die__273_v0 "src/${subpath_557}" "${subpath_557}"
}

# install_rofi()
install_rofi__281_v0() {
    local array_38=("rofi")
    apt_install_or_die__182_v0 array_38[@]
    copy_into_home_or_die__195_v0 "src/rofi/.config/rofi" ".config/"
}

# set_only_user_write_or_die(path: Text)
set_only_user_write_or_die__286_v0() {
    local path_645="${1}"
    chmod -R g-w,o-w ${path_645}
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to set ${path_645} perms to user-only write" 1
    fi
}

# set_only_user_write_or_die_at_home(rel_path: Text)
set_only_user_write_or_die_at_home__287_v0() {
    local rel_path_643="${1}"
    home__187_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "cannot determine home directory for ${rel_path_643}" 1
    fi
    local h_644="${ret_home187_v0}"
    set_only_user_write_or_die__286_v0 "${h_644}/${rel_path_643}"
}

# make_executable(path: Text)
make_executable__288_v0() {
    local path_1221="${1}"
    chmod +x ${path_1221}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_make_executable288_v0=''
        return "${__status}"
    fi
}

# install_omz_config()
install_omz_config__290_v0() {
    local subpath_625=".oh-my-zsh"
    local array_39=("custom/plugins/")
    rsync_or_die_opts_into_home__228_v0 "src/${subpath_625}/" "${subpath_625}" array_39[@] 1
    set_only_user_write_or_die_at_home__287_v0 "${subpath_625}"
}

# execute(bin: Text, sh_path: Text)
execute__294_v0() {
    local bin_664="${1}"
    local sh_path_665="${2}"
    ${bin_664} ${sh_path_665}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute294_v0=''
        return "${__status}"
    fi
}

# execute_sh(sh_path: Text)
execute_sh__295_v0() {
    local sh_path_1243="${1}"
    execute__294_v0 "bash" "${sh_path_1243}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_sh295_v0=''
        return "${__status}"
    fi
}

# execute_zsh(sh_path: Text)
execute_zsh__296_v0() {
    local sh_path_663="${1}"
    execute__294_v0 "zsh" "${sh_path_663}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_zsh296_v0=''
        return "${__status}"
    fi
}

# execute_zsh_at_home(rel_sh_path: Text)
execute_zsh_at_home__299_v0() {
    local rel_sh_path_661="${1}"
    home__187_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_zsh_at_home299_v0=''
        return "${__status}"
    fi
    local h_662="${ret_home187_v0}"
    execute_zsh__296_v0 "${h_662}/${rel_sh_path_661}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_zsh_at_home299_v0=''
        return "${__status}"
    fi
}

# install_zshmarks()
install_zshmarks__302_v0() {
    mkdir -p ~/.oh-my-zsh/custom/plugins/zshmarks
    __status=$?
    cp src/zshmarks.plugin.zsh ~/.oh-my-zsh/custom/plugins/zshmarks/zshmarks.plugin.zsh
    __status=$?
    execute_zsh_at_home__299_v0 ".oh-my-zsh/custom/plugins/zshmarks/zshmarks.plugin.zsh"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to source zshmarks plugin" 1
    fi
    # ponytail: seed two default bookmarks the user asked for. Merge-safe —
    # only appends a name if absent, never clobbers user edits. Path kept as
    # literal $HOME (zshmarks convention). devtools assumes the canonical clone.
    touch ~/.bookmarks
    __status=$?
    grep -q '|nvim$' ~/.bookmarks || echo '$HOME/.config/nvim|nvim' >> ~/.bookmarks
    __status=$?
    grep -q '|devtools$' ~/.bookmarks || echo '$HOME/jberlanga-devtools|devtools' >> ~/.bookmarks
    __status=$?
}

temp_dir_create__46_v0 "amber-XXXXXX" 1 1
__status=$?
if [ "${__status}" != 0 ]; then
    :
fi
__TMP_DIR_19="${ret_temp_dir_create46_v0}"
token_20=1
# temp_file_create(suffix: Text)
temp_file_create__312_v0() {
    local suffix_816="${1}"
    token_20="$(( token_20 + 1 ))"
    local tmp_817="${__TMP_DIR_19}/${token_20}${suffix_816}"
    touch "${tmp_817}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_temp_file_create312_v0=''
        return "${__status}"
    fi
    ret_temp_file_create312_v0="${tmp_817}"
    return 0
}

# Works differently on amber
# pub fun filename(): Text? {
# return $ realpath \$BASH_SOURCE[0] $?
# }
# 
# pub fun script_dir(): Text? {
# const fn = filename()?
# return $ dirname {fn} $ ?
# }
# 
# const fn = trust filename()
# const dir = trust script_dir()
# echo("The absolute path to this script is {fn}, dir {dir}")
# / direct lines compiler bug in .6 workaround by writing to temp file
# pub fun lines_from_raw(raw: Text): [Text]? {
# const tmp = temp_file_create()?
# file_write(raw, tmp)?
# return lines(file_read(tmp)?)?
# }
# download_to(url: Text, target: Text)
download_to__315_v0() {
    local url_819="${1}"
    local target_820="${2}"
    curl -fsSL ${url_819} -o ${target_820}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_to315_v0=''
        return "${__status}"
    fi
}

# download_tmp(url: Text)
download_tmp__316_v0() {
    local url_815="${1}"
    temp_file_create__312_v0 ""
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_tmp316_v0=''
        return "${__status}"
    fi
    local target_818="${ret_temp_file_create312_v0}"
    download_to__315_v0 "${url_815}" "${target_818}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_tmp316_v0=''
        return "${__status}"
    fi
    ret_download_tmp316_v0="${target_818}"
    return 0
}

# url_status(url: Text)
url_status__317_v0() {
    local url_1074="${1}"
    local command_40
    command_40="$(curl -sIL ${url_1074} | head -1 | tr -s ' ' | cut -d' ' -f2)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_url_status317_v0=''
        return "${__status}"
    fi
    ret_url_status317_v0="${command_40}"
    return 0
}

# download_verified_url_to(url: Text, target: Text, expected_hash: Text)
download_verified_url_to__318_v0() {
    local url_1216="${1}"
    local target_1217="${2}"
    local expected_hash_1218="${3}"
    download_to__315_v0 "${url_1216}" "${target_1217}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_url_to318_v0=''
        return 0
    fi
    local command_41
    command_41="$(sha256sum ${target_1217} | cut -d' ' -f1)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_url_to318_v0=''
        return "${__status}"
    fi
    local actual_1219="${command_41}"
    if [ "$([ "_${actual_1219}" == "_${expected_hash_1218}" ]; echo $?)" != 0 ]; then
        echo_error__142_v0 "sha256 mismatch for ${target_1217}: expected ${expected_hash_1218}, got ${actual_1219}" 1
        rm -f ${target_1217}
        __status=$?
        ret_download_verified_url_to318_v0=''
        return 0
    fi
}

__PROJECT_ROOT_21="$PWD"
project_vendor_22="${__PROJECT_ROOT_21}/copals/vendor"
installed_vendor_23="/usr/lib/copals/vendor"
# The installed vendor dir is authoritative when copals runs inside its own
# container: the host repo is bind-mounted at the same absolute path, so the
# project vendor dir also "exists" but its tools are only populated inside the
# image. Prefer the installed tree whenever it actually holds the binaries.
# resolve_vendor_dir()
resolve_vendor_dir__332_v0() {
    dir_exists__38_v0 "${installed_vendor_23}"
    local ret_dir_exists38_v0__12_8="${ret_dir_exists38_v0}"
    file_exists__39_v0 "${installed_vendor_23}/jsonnet"
    local ret_file_exists39_v0__12_41="${ret_file_exists39_v0}"
    if [ "$(( ret_dir_exists38_v0__12_8 && ret_file_exists39_v0__12_41 ))" != 0 ]; then
        ret_resolve_vendor_dir332_v0="${installed_vendor_23}"
        return 0
    fi
    dir_exists__38_v0 "${project_vendor_22}"
    local ret_dir_exists38_v0__15_8="${ret_dir_exists38_v0}"
    file_exists__39_v0 "${project_vendor_22}/jsonnet"
    local ret_file_exists39_v0__15_39="${ret_file_exists39_v0}"
    if [ "$(( ret_dir_exists38_v0__15_8 && ret_file_exists39_v0__15_39 ))" != 0 ]; then
        ret_resolve_vendor_dir332_v0="${project_vendor_22}"
        return 0
    fi
    dir_exists__38_v0 "${installed_vendor_23}"
    local ret_dir_exists38_v0__18_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__18_8}" != 0 ]; then
        ret_resolve_vendor_dir332_v0="${installed_vendor_23}"
        return 0
    fi
    dir_exists__38_v0 "${project_vendor_22}"
    local ret_dir_exists38_v0__21_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__21_8}" != 0 ]; then
        ret_resolve_vendor_dir332_v0="${project_vendor_22}"
        return 0
    fi
    ret_resolve_vendor_dir332_v0=""
    return 0
}

resolve_vendor_dir__332_v0 
__VENDOR_DIR_34="${ret_resolve_vendor_dir332_v0}"
# jq_resolve()
jq_resolve__333_v0() {
    if [ "$([ "_${__VENDOR_DIR_34}" != "_" ]; echo $?)" != 0 ]; then
        ret_jq_resolve333_v0="jq"
        return 0
    fi
    ret_jq_resolve333_v0="${__VENDOR_DIR_34}/jq"
    return 0
}

# j2_resolve()
j2_resolve__334_v0() {
    if [ "$([ "_${__VENDOR_DIR_34}" != "_" ]; echo $?)" != 0 ]; then
        ret_j2_resolve334_v0="j2"
        return 0
    fi
    ret_j2_resolve334_v0="${__VENDOR_DIR_34}/j2"
    return 0
}

# jsonnet_resolve()
jsonnet_resolve__335_v0() {
    if [ "$([ "_${__VENDOR_DIR_34}" != "_" ]; echo $?)" != 0 ]; then
        ret_jsonnet_resolve335_v0="jsonnet"
        return 0
    fi
    ret_jsonnet_resolve335_v0="${__VENDOR_DIR_34}/jsonnet"
    return 0
}

# jsonschema_resolve()
jsonschema_resolve__336_v0() {
    if [ "$([ "_${__VENDOR_DIR_34}" != "_" ]; echo $?)" != 0 ]; then
        ret_jsonschema_resolve336_v0="jsonschema"
        return 0
    fi
    ret_jsonschema_resolve336_v0="${__VENDOR_DIR_34}/jsonschema"
    return 0
}

# lua_resolve()
lua_resolve__337_v0() {
    if [ "$([ "_${__VENDOR_DIR_34}" != "_" ]; echo $?)" != 0 ]; then
        ret_lua_resolve337_v0="lua"
        return 0
    fi
    ret_lua_resolve337_v0="${__VENDOR_DIR_34}/lua"
    return 0
}

jq_resolve__333_v0 
__JQ_35="${ret_jq_resolve333_v0}"
j2_resolve__334_v0 
jsonnet_resolve__335_v0 
jsonschema_resolve__336_v0 
lua_resolve__337_v0 
# tag_verified(repo: Text, tag: Text)
tag_verified__338_v0() {
    local repo_824="${1}"
    local tag_825="${2}"
    local ref_url_826="https://api.github.com/repos/${repo_824}/git/ref/tags/${tag_825}"
    download_tmp__316_v0 "${ref_url_826}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_tag_verified338_v0=''
        return "${__status}"
    fi
    local ref_data_827="${ret_download_tmp316_v0}"
    local command_43
    command_43="$(${__JQ_35} -r .object.type ${ref_data_827})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_tag_verified338_v0=''
        return "${__status}"
    fi
    local obj_type_828="${command_43}"
    if [ "$([ "_${obj_type_828}" == "_tag" ]; echo $?)" != 0 ]; then
        ret_tag_verified338_v0=1
        return 0
    fi
    local command_44
    command_44="$(${__JQ_35} -r .object.sha ${ref_data_827})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_tag_verified338_v0=''
        return "${__status}"
    fi
    local sha_829="${command_44}"
    local tag_url_830="https://api.github.com/repos/${repo_824}/git/tags/${sha_829}"
    local command_45
    command_45="$(curl -fsSL ${tag_url_830} | ${__JQ_35} -r .verification.verified)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_tag_verified338_v0=''
        return "${__status}"
    fi
    local verified_831="${command_45}"
    ret_tag_verified338_v0="$([ "_${verified_831}" != "_true" ]; echo $?)"
    return 0
}

# install_github_binary(repo: Text, asset_suffix: Text, binary_name: Text, install_dir: Text)
install_github_binary__341_v0() {
    local repo_810="${1}"
    local asset_suffix_811="${2}"
    local binary_name_812="${3}"
    local install_dir_813="${4}"
    local api_814="https://api.github.com/repos/${repo_810}/releases/latest"
    download_tmp__316_v0 "${api_814}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_github_binary341_v0=''
        return "${__status}"
    fi
    local rel_821="${ret_download_tmp316_v0}"
    local command_46
    command_46="$(${__JQ_35} -r '.assets[] | select(.name | endswith("'"${asset_suffix_811}"'")) | .browser_download_url' ${rel_821})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_github_binary341_v0=''
        return "${__status}"
    fi
    local url_822="${command_46}"
    local command_47
    command_47="$(${__JQ_35} -r .tag_name ${rel_821})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_github_binary341_v0=''
        return "${__status}"
    fi
    local tag_823="${command_47}"
    tag_verified__338_v0 "${repo_810}" "${tag_823}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_github_binary341_v0=''
        return "${__status}"
    fi
    local ret_tag_verified338_v0__46_12="${ret_tag_verified338_v0}"
    if [ "$(( ! ret_tag_verified338_v0__46_12 ))" != 0 ]; then
        ret_install_github_binary341_v0=''
        return 1
    fi
    download_tmp__316_v0 "${url_822}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_github_binary341_v0=''
        return "${__status}"
    fi
    local tarball_832="${ret_download_tmp316_v0}"
    temp_dir_create__46_v0 "gh-bin-XXXXXX" 0 0
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_github_binary341_v0=''
        return "${__status}"
    fi
    local tmp_833="${ret_temp_dir_create46_v0}"
    tar -xzf ${tarball_832} -C ${tmp_833}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_github_binary341_v0=''
        return "${__status}"
    fi
    local array_48=()
    sudo_cmd__169_v0 "install -m755 ${tmp_833}/${binary_name_812} ${install_dir_813}" array_48[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        local array_49=()
        sudo_cmd__169_v0 "install -m755 ${tmp_833}/*/${binary_name_812} ${install_dir_813}" array_49[@]
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_install_github_binary341_v0=''
            return "${__status}"
        fi
    fi
}

# install_github_binary_or_die(repo: Text, asset_suffix: Text, binary_name: Text, install_dir: Text)
install_github_binary_or_die__342_v0() {
    local repo_806="${1}"
    local asset_suffix_807="${2}"
    local binary_name_808="${3}"
    local install_dir_809="${4}"
    prompt_user__172_v0 "install ${binary_name_808} from ${repo_806} -> ${install_dir_809}"
    local ret_prompt_user172_v0__58_8="${ret_prompt_user172_v0}"
    if [ "${ret_prompt_user172_v0__58_8}" != 0 ]; then
        install_github_binary__341_v0 "${repo_806}" "${asset_suffix_807}" "${binary_name_808}" "${install_dir_809}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "failed to install ${binary_name_808} from ${repo_806}" 1
        fi
    fi
}

# install_system_tools()
install_system_tools__344_v0() {
    local array_50=("ncdu")
    apt_install_or_die__182_v0 array_50[@]
    has_cmd__251_v0 "jj"
    local ret_has_cmd251_v0__12_12="${ret_has_cmd251_v0}"
    if [ "$(( ! ret_has_cmd251_v0__12_12 ))" != 0 ]; then
        install_github_binary_or_die__342_v0 "jj-vcs/jj" "x86_64-unknown-linux-musl.tar.gz" "jj" "/usr/local/bin"
    fi
}

# install_deb(deb_path: Text)
install_deb__352_v0() {
    local deb_path_1060="${1}"
    local array_51=()
    sudo_cmd__169_v0 "dpkg -i ${deb_path_1060}" array_51[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        # dpkg may fail due to missing deps; fix them below
        :
    fi
    local array_52=()
    sudo_cmd__169_v0 "apt-get install -f -y" array_52[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_deb352_v0=''
        return "${__status}"
    fi
}

# install_deb_url(url: Text)
install_deb_url__354_v0() {
    local url_1059="${1}"
    download_tmp__316_v0 "${url_1059}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_deb_url354_v0=''
        return "${__status}"
    fi
    local ret_download_tmp316_v0__19_17="${ret_download_tmp316_v0}"
    install_deb__352_v0 "${ret_download_tmp316_v0__19_17}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_deb_url354_v0=''
        return "${__status}"
    fi
}

# install_deb_url_or_die(url: Text)
install_deb_url_or_die__355_v0() {
    local url_1058="${1}"
    install_deb_url__354_v0 "${url_1058}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to install .deb from ${url_1058}" 1
    fi
}

# extract_extension_id(url: Text)
extract_extension_id__362_v0() {
    local url_1063="${1}"
    replace_regex__3_v0 "${url_1063}" "^https?://[^/]+/.+/([^/]+)\$" "" 1
    local ret_replace_regex3_v0__8_8="${ret_replace_regex3_v0}"
    if [ "$([ "_${ret_replace_regex3_v0__8_8}" != "_${url_1063}" ]; echo $?)" != 0 ]; then
        echo_error__142_v0 "malformed extension url: ${url_1063}" 1
    fi
    replace_regex__3_v0 "${url_1063}" "^.*/([^/]+)\$" "\\1" 1
    ret_extract_extension_id362_v0="${ret_replace_regex3_v0}"
    return 0
}

# install_chrome_extension(url: Text)
install_chrome_extension__363_v0() {
    local url_1062="${1}"
    prompt_user__172_v0 "install chrome extension from ${url_1062}"
    local ret_prompt_user172_v0__15_12="${ret_prompt_user172_v0}"
    if [ "$(( ! ret_prompt_user172_v0__15_12 ))" != 0 ]; then
        ret_install_chrome_extension363_v0=''
        return 0
    fi
    extract_extension_id__362_v0 "${url_1062}"
    local id_1073="${ret_extract_extension_id362_v0}"
    url_status__317_v0 "${url_1062}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_chrome_extension363_v0=''
        return "${__status}"
    fi
    local http_code_1075="${ret_url_status317_v0}"
    if [ "$([ "_${http_code_1075}" == "_200" ]; echo $?)" != 0 ]; then
        echo_error__142_v0 "extension url returned HTTP ${http_code_1075} (expected 200): ${url_1062}" 1
    fi
    local dir_1076="/etc/opt/chrome/policies/managed"
    has_cmd__175_v0 "sudo"
    local ret_has_cmd175_v0__24_8="${ret_has_cmd175_v0}"
    if [ "${ret_has_cmd175_v0__24_8}" != 0 ]; then
        sudo mkdir -p ${dir_1076}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_install_chrome_extension363_v0=''
            return "${__status}"
        fi
        sudo chmod 755 /etc/opt/chrome
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_install_chrome_extension363_v0=''
            return "${__status}"
        fi
        sudo sh -c "printf '\x7b\"ExtensionInstallForcelist\":[\"%s;https://clients2.google.com/service/update2/crx\"]\x7d
' ${id_1073} > ${dir_1076}/vimium.json"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_install_chrome_extension363_v0=''
            return "${__status}"
        fi
    else
        mkdir -p ${dir_1076}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_install_chrome_extension363_v0=''
            return "${__status}"
        fi
        chmod 755 /etc/opt/chrome
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_install_chrome_extension363_v0=''
            return "${__status}"
        fi
        printf '\x7b"ExtensionInstallForcelist":["%s;https://clients2.google.com/service/update2/crx"]\x7d
' ${id_1073} > ${dir_1076}/vimium.json
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_install_chrome_extension363_v0=''
            return "${__status}"
        fi
    fi
}

# install_chrome_extension_or_die(url: Text)
install_chrome_extension_or_die__364_v0() {
    local url_1061="${1}"
    install_chrome_extension__363_v0 "${url_1061}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to install chrome extension ${url_1061}" 1
    fi
}

__VIMIUM_URL_41="https://chromewebstore.google.com/detail/vimium/dbepggeogbaibhgnhhndojpepiihcmeb"
# install_browsers()
install_browsers__366_v0() {
    has_cmd__251_v0 "google-chrome-stable"
    local ret_has_cmd251_v0__14_12="${ret_has_cmd251_v0}"
    if [ "$(( ! ret_has_cmd251_v0__14_12 ))" != 0 ]; then
        install_deb_url_or_die__355_v0 "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    fi
    install_chrome_extension_or_die__364_v0 "${__VIMIUM_URL_41}"
}

# TODO cleanup this file... too bashish
# Source brew's shellenv so `brew` is on PATH after a same-session install.
# On container overlay filesystems brew lock filenames can exceed NAME_MAX;
# symlink the locks dir to /tmp to keep them short.
# install_via_curl(url: Text)
install_via_curl__388_v0() {
    local url_1092="${1}"
    NONINTERACTIVE=1 curl -fsSL ${url_1092} | bash
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_via_curl388_v0=''
        return "${__status}"
    fi
}

was_updated_42=0
# update()
update__399_v0() {
    local array_53=()
    sudo_cmd__169_v0 "apt-get update" array_53[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_update399_v0=''
        return "${__status}"
    fi
}

# ensure_updated()
ensure_updated__400_v0() {
    if [ "$(( ! was_updated_42 ))" != 0 ]; then
        update__399_v0 
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_ensure_updated400_v0=''
            return "${__status}"
        fi
        was_updated_42=1
    fi
}

# apt_install(packages: [Text])
apt_install__401_v0() {
    local packages_1095=("${!1}")
    prompt_user__172_v0 "apt install: ${packages_1095[@]}"
    local ret_prompt_user172_v0__19_12="${ret_prompt_user172_v0}"
    if [ "$(( ! ret_prompt_user172_v0__19_12 ))" != 0 ]; then
        ret_apt_install401_v0=''
        return 0
    fi
    ensure_updated__400_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_apt_install401_v0=''
        return "${__status}"
    fi
    join__7_v0 packages_1095[@] " "
    local pkgs_1096="${ret_join7_v0}"
    local array_54=("DEBIAN_FRONTEND=noninteractive")
    sudo_cmd__169_v1 "apt-get install -y --no-install-recommends ${pkgs_1096}" array_54[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_apt_install401_v0=''
        return "${__status}"
    fi
}

# install_via_npm(packages: [Text])
install_via_npm__406_v0() {
    local packages_1094=("${!1}")
    has_cmd__175_v0 "npm"
    local ret_has_cmd175_v0__7_12="${ret_has_cmd175_v0}"
    if [ "$(( ! ret_has_cmd175_v0__7_12 ))" != 0 ]; then
        local array_55=("npm")
        apt_install__401_v0 array_55[@]
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_install_via_npm406_v0=''
            return "${__status}"
        fi
    fi
    local array_56=()
    sudo_cmd__169_v0 "npm install -g ${packages_1094[@]}" array_56[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_via_npm406_v0=''
        return "${__status}"
    fi
}

# install_via_npm_or_die(packages: [Text])
install_via_npm_or_die__407_v0() {
    local packages_1093=("${!1}")
    install_via_npm__406_v0 packages_1093[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to npm install ${packages_1093[@]}" 1
    fi
}

# install_ai_tools()
install_ai_tools__409_v0() {
    install_via_curl__388_v0 "https://antigravity.google/cli/install.sh"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "skipping agy" 1
    fi
    local array_57=("@kilocode/cli")
    install_via_npm_or_die__407_v0 array_57[@]
}

# No-op install hook.
# 
# The quicksheet plugin is staged into the build tree by the default
# process-repo copy (generate phase): the host clone at user/repos/quicksheet
# (cloned by `copals user-clone` at the commit pinned in
# user/repos/nvim/lazy-lock.json) is rsync'd into src/.config/nvim/lazy/quicksheet
# (excluding .git). install_nvim then symlinks ~/.local/share/nvim/lazy ->
# src/.config/nvim/lazy, so quicksheet is reachable at runtime via that symlink.
# Nothing to do here. Do NOT rsync src/.config/nvim/lazy/quicksheet into
# ~/.local/share/nvim/lazy/quicksheet: that target is the symlink above, so it
# would rsync the directory onto itself.
# 
# This hook exists only because install.ab.j2 imports install_{repo.id}() for
# every enabled repo.
# install_quicksheet()
install_quicksheet__411_v0() {
    :
}

# install_nvim()
install_nvim__416_v0() {
    local array_58=("fd-find" "clang" "g++")
    apt_install_or_die__182_v0 array_58[@]
    local subpath_1123=".config/nvim"
    symlink_into_home_or_die__273_v0 "src/${subpath_1123}" "${subpath_1123}"
    local lazy_dir_1124="${subpath_1123}/lazy"
    symlink_into_home_or_die__273_v0 "src/${lazy_dir_1124}" ".local/share/nvim/lazy"
    # quicksheet reads ~/.config/quicksheet.txt; the data ships from the nvim
    # repo as ~/.config/nvim/quicksheet.txt. Symlink it so quicksheet finds it.
    symlink_at_home_or_die__275_v0 ".config/nvim/quicksheet.txt" ".config/quicksheet.txt"
    # base46's compiled cache (~/.local/share/nvim/base46/) is produced only by
    # its `build` hook, which lazy.nvim skips for pre-fetched plugins (once
    # state.json marks them installed). When plugins were pre-fetched and the
    # cache is missing, pre-compile it headlessly with the target's own LuaJIT.
    # --clean + manual rtp so the user init.lua is NOT loaded (avoids the
    # circular dofile that needs this very cache).
    test -d ~/.local/share/nvim/lazy/base46 && ! test -f ~/.local/share/nvim/base46/defaults
    __status=$?
    if [ "${__status}" = 0 ]; then
        timeout 120 nvim --headless --clean -c 'lua vim.g.base46_cache=vim.fn.stdpath("data").."/base46/" local d=vim.fn.stdpath("data") local c=vim.fn.stdpath("config") vim.opt.rtp:prepend(c) vim.opt.rtp:prepend(d.."/lazy/ui") vim.opt.rtp:prepend(d.."/lazy/plenary.nvim") vim.opt.rtp:prepend(d.."/lazy/base46") require("nvconfig") require("base46").load_all_highlights()' +qa
        __status=$?
    fi
    # Ensure the kv-store is initialized (sqlite DB + table) so the agent
    # terminal's `kv agentclitool` read and :AiSelect's `kv-put` work on
    # first launch. Source kv-store.sh if deployed; harmless if absent.
    # NOTE: no `$` inside the `$...$` literal (amber treats `$` as special);
    # `trust` keeps this hook infallible (the bash ends with `; true`).
    bash -c 'source ~/aliases/kv-store.sh 2>/dev/null; source ~/.local/bin/kv-store.sh 2>/dev/null; kv agentclitool >/dev/null 2>&1; true'
    __status=$?
}

# download_verified_url_to_home(url: Text, rel_path: Text, expected_hash: Text)
download_verified_url_to_home__435_v0() {
    local url_1210="${1}"
    local rel_path_1211="${2}"
    local expected_hash_1212="${3}"
    home__187_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_url_to_home435_v0=''
        return "${__status}"
    fi
    local h_1213="${ret_home187_v0}"
    local full_1214="${h_1213}/${rel_path_1211}"
    local command_59
    command_59="$(dirname ${full_1214})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_url_to_home435_v0=''
        return "${__status}"
    fi
    local parent_1215="${command_59}"
    dir_create__44_v0 "${parent_1215}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_url_to_home435_v0=''
        return "${__status}"
    fi
    download_verified_url_to__318_v0 "${url_1210}" "${full_1214}" "${expected_hash_1212}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_url_to_home435_v0=''
        return "${__status}"
    fi
}

# download_verified_executable_to_home(url: Text, rel_path: Text, expected_hash: Text)
download_verified_executable_to_home__437_v0() {
    local url_1207="${1}"
    local rel_path_1208="${2}"
    local expected_hash_1209="${3}"
    download_verified_url_to_home__435_v0 "${url_1207}" "${rel_path_1208}" "${expected_hash_1209}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_executable_to_home437_v0=''
        return "${__status}"
    fi
    home__187_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_executable_to_home437_v0=''
        return "${__status}"
    fi
    local h_1220="${ret_home187_v0}"
    make_executable__288_v0 "${h_1220}/${rel_path_1208}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_executable_to_home437_v0=''
        return "${__status}"
    fi
}

# download_verified_executable_to_home_or_die(url: Text, rel_path: Text, expected_hash: Text)
download_verified_executable_to_home_or_die__438_v0() {
    local url_1204="${1}"
    local rel_path_1205="${2}"
    local expected_hash_1206="${3}"
    download_verified_executable_to_home__437_v0 "${url_1204}" "${rel_path_1205}" "${expected_hash_1206}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to download, verify, or make executable ${url_1204} to ~/${rel_path_1205}" 1
    fi
}

# install_tmux_warm_daemon()
install_tmux_warm_daemon__440_v0() {
    copy_into_home_or_die__195_v0 "src/.tmux_warm_daemon/attach_warm.sh" ".local/bin/"
    copy_into_home_or_die__195_v0 "src/.tmux_warm_daemon/restart_daemon.sh" ".local/bin/"
    copy_into_home_or_die__195_v0 "src/.tmux_warm_daemon/agent-warm.sh" ".local/bin/"
    copy_into_home_or_die__195_v0 "src/.tmux_warm_daemon/bootstrap-warm-daemon.sh" ".local/bin/"
    # Pool config: defines the `agent` pool so the daemon pre-warms agent
    # sessions (agent-N / agent@<hash>) instead of only `warm-*`. The agent
    # command is agent-warm.sh, which execs whatever `kv agentclitool` points
    # at — so no tool is hardcoded (see ~/.local/bin/agent-warm.sh).
    copy_into_home_or_die__195_v0 "src/.tmux_warm_daemon/config.yaml" ".config/tmux_warm_daemon/"
    rsync_or_die_into_home__226_v0 "src/.tmux_warm_daemon/" ".tmux_warm_daemon/" 1
    # Only fetch Rust binary when the bash backend was stripped during generation
    # (i.e. user chose impl: 'rust' or didn't set impl). When bash is present,
    # the backend-agnostic launcher will fall through to it.
    local command_60
    command_60="$(test -f ~/.tmux_warm_daemon/bash/tmux_warm_daemon && echo "yes" || echo "")"
    __status=$?
    local bash_present_1202="${command_60}"
    if [ "$([ "_${bash_present_1202}" != "_" ]; echo $?)" != 0 ]; then
        local rel_bin_1203=".tmux_warm_daemon/rust/target/release/tmux_warm_daemon"
        download_verified_executable_to_home_or_die__438_v0 "https://github.com/jesusmb1995/tmux-warm-daemon/releases/download/v0.1.0-prealpha/tmux_warm_daemon" "${rel_bin_1203}" "95a6727f495b4e3970084e20efe12e93427bb90b7dc7e8dac3605c7a5e48b902"
    fi
    # Seed `agentclitool` from the nvim config default (if unset) and (re)start
    # the daemon so it loads config.yaml + registers the `agent` pool. Without
    # this, nvim's <leader><C-l> can never attach (no agent@<hash> session).
    # Kept in a standalone script because amber's `$...$` literal can't contain
    # `$` (kv/grep/sed use it). Best-effort; never fails the install.
    bash -c 'nohup ~/.local/bin/bootstrap-warm-daemon.sh >/tmp/tmux_warm_daemon.bootstrap.log 2>&1; true'
    __status=$?
}

# install_cmd_bookmarks()
install_cmd_bookmarks__443_v0() {
    symlink_into_home_or_die__273_v0 "src/cmd_bookmarks" ".local/share/cmd_bookmarks"
}

# execute_sh_at_home(rel_sh_path: Text)
execute_sh_at_home__450_v0() {
    local rel_sh_path_1241="${1}"
    home__187_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_sh_at_home450_v0=''
        return "${__status}"
    fi
    local h_1242="${ret_home187_v0}"
    execute_sh__295_v0 "${h_1242}/${rel_sh_path_1241}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_sh_at_home450_v0=''
        return "${__status}"
    fi
}

# execute_sh_at_home_or_die(rel_sh_path: Text)
execute_sh_at_home_or_die__451_v0() {
    local rel_sh_path_1240="${1}"
    prompt_user__172_v0 "execute ~/${rel_sh_path_1240}"
    local ret_prompt_user172_v0__12_8="${ret_prompt_user172_v0}"
    if [ "${ret_prompt_user172_v0__12_8}" != 0 ]; then
        execute_sh_at_home__450_v0 "${rel_sh_path_1240}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "failed to run ${rel_sh_path_1240}" 1
        fi
    fi
}

# install_agent_global_config()
install_agent_global_config__456_v0() {
    rsync_or_die_into_home__226_v0 "src/.agent/" ".agent" 1
    home__206_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "install_agent_global_config: home unresolved" 1
        exit 1
    fi
    local h_1237="${ret_home206_v0}"
    local scripts_1238=("sync-permissions-from-cli.sh" "sync-permissions.sh" "sync-antigravity-permissions.sh" "sync-kilocode-permissions.sh")
    for script_1239 in "${scripts_1238[@]}"; do
        file_exists__39_v0 "${h_1237}/.agent/${script_1239}"
        local ret_file_exists39_v0__20_12="${ret_file_exists39_v0}"
        if [ "${ret_file_exists39_v0__20_12}" != 0 ]; then
            execute_sh_at_home_or_die__451_v0 ".agent/${script_1239}"
        fi
    done
}

__PROJECT_ROOT_43="$PWD"
project_vendor_44="${__PROJECT_ROOT_43}/copals/vendor"
installed_vendor_45="/usr/lib/copals/vendor"
# The installed vendor dir is authoritative when copals runs inside its own
# container: the host repo is bind-mounted at the same absolute path, so the
# project vendor dir also "exists" but its tools are only populated inside the
# image. Prefer the installed tree whenever it actually holds the binaries.
# resolve_vendor_dir()
resolve_vendor_dir__464_v0() {
    dir_exists__38_v0 "${installed_vendor_45}"
    local ret_dir_exists38_v0__12_8="${ret_dir_exists38_v0}"
    file_exists__39_v0 "${installed_vendor_45}/jsonnet"
    local ret_file_exists39_v0__12_41="${ret_file_exists39_v0}"
    if [ "$(( ret_dir_exists38_v0__12_8 && ret_file_exists39_v0__12_41 ))" != 0 ]; then
        ret_resolve_vendor_dir464_v0="${installed_vendor_45}"
        return 0
    fi
    dir_exists__38_v0 "${project_vendor_44}"
    local ret_dir_exists38_v0__15_8="${ret_dir_exists38_v0}"
    file_exists__39_v0 "${project_vendor_44}/jsonnet"
    local ret_file_exists39_v0__15_39="${ret_file_exists39_v0}"
    if [ "$(( ret_dir_exists38_v0__15_8 && ret_file_exists39_v0__15_39 ))" != 0 ]; then
        ret_resolve_vendor_dir464_v0="${project_vendor_44}"
        return 0
    fi
    dir_exists__38_v0 "${installed_vendor_45}"
    local ret_dir_exists38_v0__18_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__18_8}" != 0 ]; then
        ret_resolve_vendor_dir464_v0="${installed_vendor_45}"
        return 0
    fi
    dir_exists__38_v0 "${project_vendor_44}"
    local ret_dir_exists38_v0__21_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__21_8}" != 0 ]; then
        ret_resolve_vendor_dir464_v0="${project_vendor_44}"
        return 0
    fi
    ret_resolve_vendor_dir464_v0=""
    return 0
}

resolve_vendor_dir__464_v0 
__VENDOR_DIR_46="${ret_resolve_vendor_dir464_v0}"
# jq_resolve()
jq_resolve__465_v0() {
    if [ "$([ "_${__VENDOR_DIR_46}" != "_" ]; echo $?)" != 0 ]; then
        ret_jq_resolve465_v0="jq"
        return 0
    fi
    ret_jq_resolve465_v0="${__VENDOR_DIR_46}/jq"
    return 0
}

# j2_resolve()
j2_resolve__466_v0() {
    if [ "$([ "_${__VENDOR_DIR_46}" != "_" ]; echo $?)" != 0 ]; then
        ret_j2_resolve466_v0="j2"
        return 0
    fi
    ret_j2_resolve466_v0="${__VENDOR_DIR_46}/j2"
    return 0
}

# jsonnet_resolve()
jsonnet_resolve__467_v0() {
    if [ "$([ "_${__VENDOR_DIR_46}" != "_" ]; echo $?)" != 0 ]; then
        ret_jsonnet_resolve467_v0="jsonnet"
        return 0
    fi
    ret_jsonnet_resolve467_v0="${__VENDOR_DIR_46}/jsonnet"
    return 0
}

# jsonschema_resolve()
jsonschema_resolve__468_v0() {
    if [ "$([ "_${__VENDOR_DIR_46}" != "_" ]; echo $?)" != 0 ]; then
        ret_jsonschema_resolve468_v0="jsonschema"
        return 0
    fi
    ret_jsonschema_resolve468_v0="${__VENDOR_DIR_46}/jsonschema"
    return 0
}

# lua_resolve()
lua_resolve__469_v0() {
    if [ "$([ "_${__VENDOR_DIR_46}" != "_" ]; echo $?)" != 0 ]; then
        ret_lua_resolve469_v0="lua"
        return 0
    fi
    ret_lua_resolve469_v0="${__VENDOR_DIR_46}/lua"
    return 0
}

jq_resolve__465_v0 
j2_resolve__466_v0 
jsonnet_resolve__467_v0 
jsonschema_resolve__468_v0 
lua_resolve__469_v0 
# link_store(link: Text, canon: Text)
link_store__488_v0() {
    local link_1274="${1}"
    local canon_1275="${2}"
    local target_1276="../.agents/skills"
    local command_65
    command_65="$(dirname ${link_1274})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_link_store488_v0=''
        return "${__status}"
    fi
    local dir_1277="${command_65}"
    dir_create__44_v0 "${dir_1277}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_link_store488_v0=''
        return "${__status}"
    fi
    local is_real_dir_1278=0
    [ ! -L ${link_1274} ] && [ -d ${link_1274} ]
    __status=$?
    if [ "${__status}" = 0 ]; then
        is_real_dir_1278=1
    fi
    if [ "${is_real_dir_1278}" != 0 ]; then
        local __cp_66=
        (( 1 )) && __cp_66="-f" || __cp_66=""
        cp -r ${__cp_66} "${link_1274}" "${canon_1275}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_link_store488_v0=''
            return "${__status}"
        fi
        local __rm_67=
        (( 1 )) && __rm_67="-r" || __rm_67=""
        local __rm_68=
        rm ${__rm_68} ${__rm_67} "${link_1274}"
        ln -sfn ${target_1276} ${link_1274}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_link_store488_v0=''
            return "${__status}"
        fi
    else
        local exists_plain_1279=0
        [ -e ${link_1274} ] && [ ! -L ${link_1274} ]
        __status=$?
        if [ "${__status}" = 0 ]; then
            exists_plain_1279=1
        fi
        if [ "$(( ! exists_plain_1279 ))" != 0 ]; then
            ln -sfn ${target_1276} ${link_1274}
            __status=$?
            if [ "${__status}" != 0 ]; then
                ret_link_store488_v0=''
                return "${__status}"
            fi
        fi
    fi
}

# install_agent_skills_impl()
install_agent_skills_impl__490_v0() {
    home__206_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_agent_skills_impl490_v0=''
        return "${__status}"
    fi
    local h_1270="${ret_home206_v0}"
    local canon_1271="${h_1270}/.agents/skills"
    local skills_src_1272="src/agent-skills/.agents/skills"
    rsync_or_die_into_home__226_v0 "${skills_src_1272}/" ".agents/skills" 0
    dir_exists__38_v0 "${canon_1271}"
    local ret_dir_exists38_v0__49_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__49_8}" != 0 ]; then
        local legacy_dir_1273="${h_1270}/.cursor/skills-cursor"
        dir_exists__38_v0 "${legacy_dir_1273}"
        local ret_dir_exists38_v0__51_12="${ret_dir_exists38_v0}"
        if [ "${ret_dir_exists38_v0__51_12}" != 0 ]; then
            local __rm_69=
            (( 1 )) && __rm_69="-r" || __rm_69=""
            local __rm_70=
            rm ${__rm_70} ${__rm_69} "${legacy_dir_1273}"
        fi
        # 2. Wire the store into each ENABLED tool. Antigravity reads ~/.agents/skills natively, so it needs no link.
        link_store__488_v0 "${h_1270}/.kilo/skills" "${canon_1271}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_install_agent_skills_impl490_v0=''
            return "${__status}"
        fi
    fi
}

# install_agent_skills()
install_agent_skills__491_v0() {
    install_agent_skills_impl__490_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to install agent skills" 1
    fi
}

# install_skill_caveman()
install_skill_caveman__494_v0() {
    symlink_into_home_or_die__273_v0 "src/.agents/skills/caveman" ".agents/skills/caveman"
}

# install_skill_humanizer()
install_skill_humanizer__497_v0() {
    symlink_into_home_or_die__273_v0 "src/.agents/skills/humanizer" ".agents/skills/humanizer"
}

# install_skill_ponytail()
install_skill_ponytail__500_v0() {
    symlink_into_home_or_die__273_v0 "src/.agents/skills/ponytail" ".agents/skills/ponytail"
}

temp_dir_create__46_v0 "amber-XXXXXX" 1 1
__status=$?
if [ "${__status}" != 0 ]; then
    :
fi
__TMP_DIR_53="${ret_temp_dir_create46_v0}"
token_54=1
# temp_file_create(suffix: Text)
temp_file_create__507_v0() {
    local suffix_1299="${1}"
    token_54="$(( token_54 + 1 ))"
    local tmp_1300="${__TMP_DIR_53}/${token_54}${suffix_1299}"
    touch "${tmp_1300}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_temp_file_create507_v0=''
        return "${__status}"
    fi
    ret_temp_file_create507_v0="${tmp_1300}"
    return 0
}

# Works differently on amber
# pub fun filename(): Text? {
# return $ realpath \$BASH_SOURCE[0] $?
# }
# 
# pub fun script_dir(): Text? {
# const fn = filename()?
# return $ dirname {fn} $ ?
# }
# 
# const fn = trust filename()
# const dir = trust script_dir()
# echo("The absolute path to this script is {fn}, dir {dir}")
# / direct lines compiler bug in .6 workaround by writing to temp file
# pub fun lines_from_raw(raw: Text): [Text]? {
# const tmp = temp_file_create()?
# file_write(raw, tmp)?
# return lines(file_read(tmp)?)?
# }
# download_to(url: Text, target: Text)
download_to__510_v0() {
    local url_1305="${1}"
    local target_1306="${2}"
    curl -fsSL ${url_1305} -o ${target_1306}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_to510_v0=''
        return "${__status}"
    fi
}

# download_verified_url_to(url: Text, target: Text, expected_hash: Text)
download_verified_url_to__513_v0() {
    local url_1302="${1}"
    local target_1303="${2}"
    local expected_hash_1304="${3}"
    download_to__510_v0 "${url_1302}" "${target_1303}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_url_to513_v0=''
        return 0
    fi
    local command_71
    command_71="$(sha256sum ${target_1303} | cut -d' ' -f1)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_url_to513_v0=''
        return "${__status}"
    fi
    local actual_1307="${command_71}"
    if [ "$([ "_${actual_1307}" == "_${expected_hash_1304}" ]; echo $?)" != 0 ]; then
        echo_error__142_v0 "sha256 mismatch for ${target_1303}: expected ${expected_hash_1304}, got ${actual_1307}" 1
        rm -f ${target_1303}
        __status=$?
        ret_download_verified_url_to513_v0=''
        return 0
    fi
}

__BAZELISK_URL_55="https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64"
__BAZELISK_HASH_56="5a408715e932c0250d28bd84555f12edbf70117de42f9181691c736eacc4a992"
# install_bazelisk()
install_bazelisk__518_v0() {
    has_cmd__251_v0 "bazelisk"
    local ret_has_cmd251_v0__11_12="${ret_has_cmd251_v0}"
    if [ "$(( ! ret_has_cmd251_v0__11_12 ))" != 0 ]; then
        temp_file_create__507_v0 ""
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "bazelisk: failed to create temp file" 1
        fi
        local tmp_1301="${ret_temp_file_create507_v0}"
        download_verified_url_to__513_v0 "${__BAZELISK_URL_55}" "${tmp_1301}" "${__BAZELISK_HASH_56}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "bazelisk: sha256 mismatch, expected ${__BAZELISK_HASH_56}" 1
        fi
        local array_72=()
        sudo_cmd__248_v0 "install -m755 ${tmp_1301} /usr/local/bin/bazelisk" array_72[@]
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "bazelisk: failed to install binary to /usr/local/bin" 1
        fi
    fi
}

# Each hook must be IDEMPOTENT and KILL THE PROGRAM on failure.
# Inside the hook, propagate failures with ? via a *_impl(): Null? helper, then
# wrap it once at the installer level:  install_x() { x_impl() failed { exit(1) } }
# So every install_*() is infallible and main() stays a plain sequence of calls.
# print_help()
print_help__520_v0() {
    echo "Usage: ./install.sh [--ask] [--trace] [step ...]"
    printf '%s\n' ""
    echo "Install all steps by default. Pass one or more step names to run"
    echo "only those steps. Use 'help' to print this message."
    printf '%s\n' ""
    echo "Flags:"
    echo "  --ask     Prompt before each install action (apt, brew, cp, symlink, etc.)"
    echo "  --trace   Enable shell debug output (set -x)"
    printf '%s\n' ""
    echo "Available steps:"
    echo "  apt_essential_tools"
    echo "  apt_essential_ui"
    echo "  dotfiles_essential"
    echo "  dotfiles_personalization"
    echo "  st"
    echo "  nerd_fonts"
    echo "  rofi"
    echo "  omz_config"
    echo "  zshmarks"
    echo "  system_tools"
    echo "  browsers"
    echo "  ai_tools"
    echo "  quicksheet"
    echo "  nvim"
    echo "  tmux_warm_daemon"
    echo "  cmd_bookmarks"
    echo "  agent_global_config"
    echo "  agent_skills"
    echo "  skill_caveman"
    echo "  skill_humanizer"
    echo "  skill_ponytail"
    echo "  bazelisk"
}

# run_step(step: Text)
run_step__521_v0() {
    local step_1390="${1}"
    local matched_1391=0
    if [ "$([ "_${step_1390}" != "_help" ]; echo $?)" != 0 ]; then
        print_help__520_v0 
        matched_1391=1
    fi
    if [ "$([ "_${step_1390}" != "_apt_essential_tools" ]; echo $?)" != 0 ]; then
        install_apt_essential_tools__212_v0 
        matched_1391=1
    fi
    if [ "$([ "_${step_1390}" != "_apt_essential_ui" ]; echo $?)" != 0 ]; then
        install_apt_essential_ui__215_v0 
        matched_1391=1
    fi
    if [ "$([ "_${step_1390}" != "_dotfiles_essential" ]; echo $?)" != 0 ]; then
        install_dotfiles_essential__230_v0 
        matched_1391=1
    fi
    if [ "$([ "_${step_1390}" != "_dotfiles_personalization" ]; echo $?)" != 0 ]; then
        install_dotfiles_personalization__240_v0 
        matched_1391=1
    fi
    if [ "$([ "_${step_1390}" != "_st" ]; echo $?)" != 0 ]; then
        install_st__260_v0 
        matched_1391=1
    fi
    if [ "$([ "_${step_1390}" != "_nerd_fonts" ]; echo $?)" != 0 ]; then
        install_nerd_fonts__277_v0 
        matched_1391=1
    fi
    if [ "$([ "_${step_1390}" != "_rofi" ]; echo $?)" != 0 ]; then
        install_rofi__281_v0 
        matched_1391=1
    fi
    if [ "$([ "_${step_1390}" != "_omz_config" ]; echo $?)" != 0 ]; then
        install_omz_config__290_v0 
        matched_1391=1
    fi
    if [ "$([ "_${step_1390}" != "_zshmarks" ]; echo $?)" != 0 ]; then
        install_zshmarks__302_v0 
        matched_1391=1
    fi
    if [ "$([ "_${step_1390}" != "_system_tools" ]; echo $?)" != 0 ]; then
        install_system_tools__344_v0 
        matched_1391=1
    fi
    if [ "$([ "_${step_1390}" != "_browsers" ]; echo $?)" != 0 ]; then
        install_browsers__366_v0 
        matched_1391=1
    fi
    if [ "$([ "_${step_1390}" != "_ai_tools" ]; echo $?)" != 0 ]; then
        install_ai_tools__409_v0 
        matched_1391=1
    fi
    if [ "$([ "_${step_1390}" != "_quicksheet" ]; echo $?)" != 0 ]; then
        install_quicksheet__411_v0 
        matched_1391=1
    fi
    if [ "$([ "_${step_1390}" != "_nvim" ]; echo $?)" != 0 ]; then
        install_nvim__416_v0 
        matched_1391=1
    fi
    if [ "$([ "_${step_1390}" != "_tmux_warm_daemon" ]; echo $?)" != 0 ]; then
        install_tmux_warm_daemon__440_v0 
        matched_1391=1
    fi
    if [ "$([ "_${step_1390}" != "_cmd_bookmarks" ]; echo $?)" != 0 ]; then
        install_cmd_bookmarks__443_v0 
        matched_1391=1
    fi
    if [ "$([ "_${step_1390}" != "_agent_global_config" ]; echo $?)" != 0 ]; then
        install_agent_global_config__456_v0 
        matched_1391=1
    fi
    if [ "$([ "_${step_1390}" != "_agent_skills" ]; echo $?)" != 0 ]; then
        install_agent_skills__491_v0 
        matched_1391=1
    fi
    if [ "$([ "_${step_1390}" != "_skill_caveman" ]; echo $?)" != 0 ]; then
        install_skill_caveman__494_v0 
        matched_1391=1
    fi
    if [ "$([ "_${step_1390}" != "_skill_humanizer" ]; echo $?)" != 0 ]; then
        install_skill_humanizer__497_v0 
        matched_1391=1
    fi
    if [ "$([ "_${step_1390}" != "_skill_ponytail" ]; echo $?)" != 0 ]; then
        install_skill_ponytail__500_v0 
        matched_1391=1
    fi
    if [ "$([ "_${step_1390}" != "_bazelisk" ]; echo $?)" != 0 ]; then
        install_bazelisk__518_v0 
        matched_1391=1
    fi
    if [ "$(( ! matched_1391 ))" != 0 ]; then
        echo "Unknown step: '${step_1390}'"
        echo "Run './install.sh help' for the list of available steps."
        exit 1
    fi
}

# ---- update subcommand ----
# Per-repo content hashes are baked into meta.json at generate time via
# backfill_repo_hashes in generate.ab.  This subcommand diffs them against
# the last-installed state, lists changes, asks Y/n, and re-runs installer
# steps only for the changed repos.
# cmd_update()
cmd_update__522_v0() {
    local command_74
    command_74="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_cmd_update522_v0=''
        return "${__status}"
    fi
    local script_dir_1361="${command_74}"
    local meta_path_1362="${script_dir_1361}/meta.json"
    local state_path_1363="${script_dir_1361}/.last_installed.json"
    local command_75
    command_75="$(jq -r '.repo_hashes | to_entries[] | "\(.key)	\(.value)"' "${meta_path_1362}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_cmd_update522_v0=''
        return "${__status}"
    fi
    local new_lines_1364="${command_75}"
    local old_lines_1365=""
    file_exists__39_v0 "${state_path_1363}"
    local ret_file_exists39_v0__473_8="${ret_file_exists39_v0}"
    if [ "${ret_file_exists39_v0__473_8}" != 0 ]; then
        local command_76
        command_76="$(jq -r '.repo_hashes | to_entries[] | "\(.key)	\(.value)"' "${state_path_1363}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_cmd_update522_v0=''
            return "${__status}"
        fi
        old_lines_1365="${command_76}"
    fi
    local old_keys_1366=()
    local old_vals_1367=()
    if [ "$([ "_${old_lines_1365}" == "_" ]; echo $?)" != 0 ]; then
        split_lines__5_v0 "${old_lines_1365}"
        local rows_1372=("${ret_split_lines5_v0[@]}")
        for row_1373 in "${rows_1372[@]}"; do
            if [ "$([ "_${row_1373}" != "_" ]; echo $?)" != 0 ]; then
                continue
            fi
            split__4_v0 "	" "${row_1373}"
            local parts_1374=("${ret_split4_v0[@]}")
            local __length_81=("${parts_1374[@]}")
            if [ "$(( ${#__length_81[@]} >= 2 ))" != 0 ]; then
                old_keys_1366+=("${parts_1374[0]?"Index out of bounds (at /tmp/jbtd-install-build-3z6a8F/install.ab:485:36)"}")
                old_vals_1367+=("${parts_1374[1]?"Index out of bounds (at /tmp/jbtd-install-build-3z6a8F/install.ab:486:36)"}")
            fi
        done
    fi
    local changed_1375=()
    split_lines__5_v0 "${new_lines_1364}"
    local new_rows_1376=("${ret_split_lines5_v0[@]}")
    for row_1377 in "${new_rows_1376[@]}"; do
        if [ "$([ "_${row_1377}" != "_" ]; echo $?)" != 0 ]; then
            continue
        fi
        split__4_v0 "	" "${row_1377}"
        local parts_1378=("${ret_split4_v0[@]}")
        local __length_87=("${parts_1378[@]}")
        if [ "$(( ${#__length_87[@]} < 2 ))" != 0 ]; then
            continue
        fi
        local key_1379="${parts_1378[0]?"Index out of bounds (at /tmp/jbtd-install-build-3z6a8F/install.ab:497:27)"}"
        local val_1380="${parts_1378[1]?"Index out of bounds (at /tmp/jbtd-install-build-3z6a8F/install.ab:498:27)"}"
        local matched_1381=0
        local __range_start_1382=0
        local __length_88=("${old_keys_1366[@]}")
        local __range_end_1382="${#__length_88[@]}"
        local __dir_1382=$(( ${__range_start_1382} <= ${__range_end_1382} ? 1 : -1 ))
        for (( i_1382=${__range_start_1382}; i_1382 * ${__dir_1382} < ${__range_end_1382} * ${__dir_1382}; i_1382+=${__dir_1382} )); do
            if [ "$([ "_${old_keys_1366[${i_1382}]?"Index out of bounds (at /tmp/jbtd-install-build-3z6a8F/install.ab:501:25)"}" != "_${key_1379}" ]; echo $?)" != 0 ]; then
                if [ "$([ "_${old_vals_1367[${i_1382}]?"Index out of bounds (at /tmp/jbtd-install-build-3z6a8F/install.ab:502:29)"}" == "_${val_1380}" ]; echo $?)" != 0 ]; then
                    local array_89=("${key_1379}")
                    changed_1375+=("${array_89[@]}")
                fi
                matched_1381=1
                break
            fi
done
        if [ "$(( ! matched_1381 ))" != 0 ]; then
            changed_1375+=("${key_1379}")
        fi
    done
    for ok_1383 in "${old_keys_1366[@]}"; do
        local found_1384=0
        for row_1385 in "${new_rows_1376[@]}"; do
            if [ "$([ "_${row_1385}" != "_" ]; echo $?)" != 0 ]; then
                continue
            fi
            split__4_v0 "	" "${row_1385}"
            local parts_1386=("${ret_split4_v0[@]}")
            local __length_95=("${parts_1386[@]}")
            if [ "$(( $(( ${#__length_95[@]} >= 2 )) && $([ "_${parts_1386[0]?"Index out of bounds (at /tmp/jbtd-install-build-3z6a8F/install.ab:519:42)"}" != "_${ok_1383}" ]; echo $?) ))" != 0 ]; then
                found_1384=1
                break
            fi
        done
        if [ "$(( ! found_1384 ))" != 0 ]; then
            changed_1375+=("${ok_1383}")
        fi
    done
    local __length_97=("${changed_1375[@]}")
    if [ "$(( ${#__length_97[@]} == 0 ))" != 0 ]; then
        echo "update: all repos up to date"
        ret_cmd_update522_v0=''
        return 0
    fi
    local __length_98=("${changed_1375[@]}")
    echo "update: ${#__length_98[@]} repo(s) changed:"
    for c_1387 in "${changed_1375[@]}"; do
        echo "  - ${c_1387}"
    done
    echo "Apply updates? [Y/n]"
    local command_101
    command_101="$(read -r line < /dev/tty 2>/dev/null; printf "%s" "$line")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_cmd_update522_v0=''
        return "${__status}"
    fi
    local ans_1388="${command_101}"
    if [ "$(( $(( $(( $([ "_${ans_1388}" != "_n" ]; echo $?) || $([ "_${ans_1388}" != "_N" ]; echo $?) )) || $([ "_${ans_1388}" != "_no" ]; echo $?) )) || $([ "_${ans_1388}" != "_NO" ]; echo $?) ))" != 0 ]; then
        echo "update: aborted"
        ret_cmd_update522_v0=''
        return 0
    fi
    for c_1389 in "${changed_1375[@]}"; do
        run_step__521_v0 "${c_1389}"
    done
    cp "${meta_path_1362}" "${state_path_1363}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_cmd_update522_v0=''
        return "${__status}"
    fi
    echo "update: done"
}

typeset -r raw_args_58=("$0" "$@")
__length_106=("${raw_args_58[@]}")
slice_upper_105="${#__length_106[@]}"
slice_offset_107=1
slice_offset_107=$((${slice_offset_107} > 0 ? ${slice_offset_107} : 0))
slice_length_108="$(( slice_upper_105 - slice_offset_107 ))"
slice_length_108=$((${slice_length_108} > 0 ? ${slice_length_108} : 0))
args_59=("${raw_args_58[@]:${slice_offset_107}:${slice_length_108}}")
step_args_60=()
for a_61 in "${args_59[@]}"; do
    if [ "$([ "_${a_61}" != "_--ask" ]; echo $?)" != 0 ]; then
        export COPALS_ASK=1
        __status=$?
    fi
    if [ "$([ "_${a_61}" != "_--trace" ]; echo $?)" != 0 ]; then
        set -x
        __status=$?
    fi
    if [ "$([ "_${a_61}" == "_--ask" ]; echo $?)" != 0 ]; then
        if [ "$([ "_${a_61}" == "_--trace" ]; echo $?)" != 0 ]; then
            step_args_60+=("${a_61}")
        fi
    fi
done
__length_113=("${step_args_60[@]}")
if [ "$(( ${#__length_113[@]} == 0 ))" != 0 ]; then
    install_apt_essential_tools__212_v0 
    install_apt_essential_ui__215_v0 
    install_dotfiles_essential__230_v0 
    install_dotfiles_personalization__240_v0 
    install_st__260_v0 
    install_nerd_fonts__277_v0 
    install_rofi__281_v0 
    install_omz_config__290_v0 
    install_zshmarks__302_v0 
    install_system_tools__344_v0 
    install_browsers__366_v0 
    install_ai_tools__409_v0 
    install_quicksheet__411_v0 
    install_nvim__416_v0 
    install_tmux_warm_daemon__440_v0 
    install_cmd_bookmarks__443_v0 
    install_agent_global_config__456_v0 
    install_agent_skills__491_v0 
    install_skill_caveman__494_v0 
    install_skill_humanizer__497_v0 
    install_skill_ponytail__500_v0 
    install_bazelisk__518_v0 
fi
__length_114=("${step_args_60[@]}")
if [ "$(( ${#__length_114[@]} >= 1 ))" != 0 ]; then
    if [ "$([ "_${step_args_60[0]?"Index out of bounds (at /tmp/jbtd-install-build-3z6a8F/install.ab:662:22)"}" != "_update" ]; echo $?)" != 0 ]; then
        __length_115=("${step_args_60[@]}")
        if [ "$(( ${#__length_115[@]} == 1 ))" != 0 ]; then
            cmd_update__522_v0 
            __status=$?
            if [ "${__status}" != 0 ]; then
                exit "${__status}"
            fi
        fi
    else
        for step_1392 in "${step_args_60[@]}"; do
            run_step__521_v0 "${step_1392}"
        done
    fi
fi
