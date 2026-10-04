# jj divergent helpers. Numbering (/0, /1, ...) is jj's own change_offset(),
# matching what `jj log` prints — the same numbers the nvim <leader>gvr
# picker uses.

# jj-pick-divergence [N] [--yes]: resolve @'s divergent versions, keeping
# version N. With no N, lists the versions. Asks for confirmation unless
# --yes (revert with `jj undo`).
function jj-pick-divergence {
    local pick="" yes="" arg
    for arg in "$@"; do
        case "$arg" in
            --yes) yes="1" ;;
            -h|--help)
                echo "usage: jj-pick-divergence [N] [--yes]" >&2
                echo "  resolve @'s divergent versions, keeping /N (lists them with no N)" >&2
                return 0
                ;;
            *)
                case "$arg" in
                    *[!0-9]*|"") echo "usage: jj-pick-divergence [N] [--yes]" >&2; return 1 ;;
                esac
                pick="$arg"
                ;;
        esac
    done
    local cur
    cur=$(jj log --ignore-working-copy -r @ --no-graph -T 'change_id.shortest(8)' 2>/dev/null) || return 1
    [ -n "$cur" ] || { echo "jj-pick-divergence: not in a jj repo" >&2; return 1; }
    # Numbering (/0, /1, ...) comes from jj's own change_offset(), so it
    # matches what `jj log` prints — not list position. Falls back to the
    # old 3-field template (positional numbering) if a future jj drops it.
    local rows
    rows=$(jj log --ignore-working-copy -r 'divergent()' --no-graph -T 'change_id.shortest(8) ++ "\t" ++ commit_id.shortest(8) ++ "\t" ++ self.change_offset() ++ "\t" ++ description.first_line() ++ "\n"' 2>/dev/null) || return 1
    if [ -z "$(printf '%s' "$rows" | tr -d '[:space:]')" ]; then
        rows=$(jj log --ignore-working-copy -r 'divergent()' --no-graph -T 'change_id.shortest(8) ++ "\t" ++ commit_id.shortest(8) ++ "\t" ++ description.first_line() ++ "\n"' 2>/dev/null) || return 1
    fi
    local TAB
    TAB=$(printf '\t')
    local n=0
    # newline-joined positional lists (bourne-compatible indexed access);
    # num_list holds jj's own offsets. Field shape is decided by counting
    # tabs (empty descriptions would fool a naive emptiness check).
    local num_list="" cid_list="" desc_list=""
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        local tabs
        tabs=$(printf '%s' "$line" | tr -cd '\t' | wc -c)
        local ch rest cid num desc
        ch=${line%%"$TAB"*}
        rest=${line#*"$TAB"}
        cid=${rest%%"$TAB"*}
        rest=${rest#*"$TAB"}
        if [ "$tabs" -ge 3 ]; then
            num=${rest%%"$TAB"*}
            desc=${rest#*"$TAB"}
        else
            num="$n"
            desc="$rest"
        fi
        [ "$ch" = "$cur" ] || continue
        [ -n "$cid" ] || continue
        case "$num" in
            *[!0-9]*|"") num="$n" ;;
        esac
        n=$((n + 1))
        num_list="$num_list$num
"
        cid_list="$cid_list$cid
"
        desc_list="$desc_list$desc
"
    done <<< "$rows"
    if [ "$n" -lt 2 ]; then
        echo "jj-pick-divergence: current patch is not divergent" >&2
        return 1
    fi
    if [ -z "$pick" ]; then
        local at_commit
        at_commit=$(jj log --ignore-working-copy -r @ --no-graph -T 'commit_id' 2>/dev/null)
        local i=1
        while [ "$i" -le "$n" ]; do
            local num cid desc suffix
            num=$(printf '%s' "$num_list" | sed -n "${i}p")
            cid=$(printf '%s' "$cid_list" | sed -n "${i}p")
            desc=$(printf '%s' "$desc_list" | sed -n "${i}p")
            suffix=""
            if [ -n "$at_commit" ] && [ "$(printf '%s' "$at_commit" | cut -c1-${#cid})" = "$cid" ]; then
                suffix=" (current @)"
            else
                local stat added deleted
                stat=$(jj diff --ignore-working-copy --from "$at_commit" --to "$cid" --stat 2>/dev/null)
                added=$(printf '%s' "$stat" | sed -n 's/.* \([0-9][0-9]*\) insertion.*/\1/p')
                deleted=$(printf '%s' "$stat" | sed -n 's/.* \([0-9][0-9]*\) deletion.*/\1/p')
                suffix=" (+${added:-0} -${deleted:-0} vs @)"
            fi
            printf '/%s %s %s%s\n' "$num" "$cid" "$desc" "$suffix"
            i=$((i + 1))
        done
        return 0
    fi
    local keep=""
    local losers=""
    local i=1
    while [ "$i" -le "$n" ]; do
        local num cid
        num=$(printf '%s' "$num_list" | sed -n "${i}p")
        cid=$(printf '%s' "$cid_list" | sed -n "${i}p")
        if [ "$num" = "$pick" ]; then
            keep="$cid"
        else
            losers="$losers $cid"
        fi
        i=$((i + 1))
    done
    if [ -z "$keep" ]; then
        echo "jj-pick-divergence: pick one of the listed /N" >&2
        return 1
    fi
    # shellcheck disable=SC2086: intentional word splitting of id list
    set -- $losers
    if [ -z "$yes" ]; then
        printf 'Abandon %d version(s), keep /%d %s? [y/N] ' "$#" "$pick" "$keep"
        local answer
        if ! read -r answer </dev/tty 2>/dev/null; then
            read -r answer || answer=""
        fi
        case "$answer" in
            [yY]*) ;;
            *) echo "aborted"; return 1 ;;
        esac
    fi
    # Divergent versions are usually remote-tracked, hence immutable.
    jj abandon --ignore-immutable "$@" || return 1
    jj workspace update-stale >/dev/null 2>&1
    echo "Resolved to /$pick $keep (revert: jj undo)"
}

# jj-pick-divergents [--yes]: resolve EVERY divergent group on the
# stack, one at a time. For each group, lists its versions (/0, /1,
# ...) and asks which to keep; the rest are abandoned. With --yes,
# keeps the version that is current @ when the group contains it,
# otherwise /0. Revert with `jj undo`.
function jj-pick-divergents {
    local yes="" arg
    for arg in "$@"; do
        case "$arg" in
            --yes) yes="1" ;;
            -h|--help)
                echo "usage: jj-pick-divergents [--yes]" >&2
                echo "  resolve every divergent group, picking a version for each" >&2
                return 0
                ;;
            *)
                echo "usage: jj-pick-divergents [--yes]" >&2
                return 1
                ;;
        esac
    done
    local TAB
    TAB=$(printf '\t')
    local rows
    rows=$(jj log --ignore-working-copy -r 'divergent()' --no-graph -T 'change_id.shortest(8) ++ "\t" ++ commit_id.shortest(8) ++ "\t" ++ self.change_offset() ++ "\t" ++ description.first_line() ++ "\n"' 2>/dev/null) || return 1
    if [ -z "$(printf '%s' "$rows" | tr -d '[:space:]')" ]; then
        rows=$(jj log --ignore-working-copy -r 'divergent()' --no-graph -T 'change_id.shortest(8) ++ "\t" ++ commit_id.shortest(8) ++ "\t" ++ description.first_line() ++ "\n"' 2>/dev/null) || return 1
    fi
    local at_commit
    at_commit=$(jj log --ignore-working-copy -r @ --no-graph -T 'commit_id' 2>/dev/null)
    # Collect groups: gchange_N holds newline-joined cid\tnum\tdesc.
    local gchanges="" gcount=0
    local line ch cid num desc rest tabs
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        tabs=$(printf '%s' "$line" | tr -cd '\t' | wc -c)
        ch=${line%%"$TAB"*}
        rest=${line#*"$TAB"}
        cid=${rest%%"$TAB"*}
        rest=${rest#*"$TAB"}
        if [ "$tabs" -ge 3 ]; then
            num=${rest%%"$TAB"*}
            desc=${rest#*"$TAB"}
        else
            num=""
            desc="$rest"
        fi
        [ -n "$ch" ] && [ -n "$cid" ] || continue
        case "$num" in
            *[!0-9]*|"") num="" ;;
        esac
        local found=0 gi=1 gkey
        while [ "$gi" -le "$gcount" ]; do
            gkey=$(printf '%s' "$gchanges" | sed -n "${gi}p")
            if [ "$gkey" = "$ch" ]; then found=1; break; fi
            gi=$((gi + 1))
        done
        if [ "$found" -eq 0 ]; then
            gchanges="$gchanges$ch
"
            gcount=$((gcount + 1))
        fi
    done <<< "$rows"
    if [ "$gcount" -eq 0 ]; then
        echo "jj-pick-divergents: nothing divergent" >&2
        return 1
    fi
    local resolved=0 gi=1
    while [ "$gi" -le "$gcount" ]; do
        local gch
        gch=$(printf '%s' "$gchanges" | sed -n "${gi}p")
        # Rows of this group, tab-split into cid/num/desc lists
        # (field 1 is the change id itself — already filtered on).
        local grows
        grows=$(printf '%s\n' "$rows" | awk -F '\t' -v c="$gch" '$1 == c {print $2 "\t" $3 "\t" $4}')
        local cids="" nums="" descs="" cnt=0
        local l1 l2 l3
        while IFS="$TAB" read -r l1 l2 l3; do
            [ -n "$l1" ] || continue
            cids="$cids$l1
"
            nums="$nums$l2
"
            descs="$descs$l3
"
            cnt=$((cnt + 1))
        done <<< "$grows"
        if [ "$cnt" -lt 2 ]; then
            gi=$((gi + 1))
            continue
        fi
        echo "== $gch ($cnt versions)"
        local i=1
        while [ "$i" -le "$cnt" ]; do
            local cc nn dd suffix
            cc=$(printf '%s' "$cids" | sed -n "${i}p")
            nn=$(printf '%s' "$nums" | sed -n "${i}p")
            dd=$(printf '%s' "$descs" | sed -n "${i}p")
            suffix=""
            if [ -n "$at_commit" ] && [ "$(printf '%s' "$at_commit" | cut -c1-${#cc})" = "$cc" ]; then
                suffix=" (current @)"
            fi
            printf '  /%s %s %s%s\n' "$nn" "$cc" "$dd" "$suffix"
            i=$((i + 1))
        done
        local pick=""
        if [ -n "$yes" ]; then
            # Default: the @ version if present, else /0.
            i=1
            while [ "$i" -le "$cnt" ]; do
                local cc
                cc=$(printf '%s' "$cids" | sed -n "${i}p")
                if [ -n "$at_commit" ] && [ "$(printf '%s' "$at_commit" | cut -c1-${#cc})" = "$cc" ]; then
                    pick=$(printf '%s' "$nums" | sed -n "${i}p")
                    break
                fi
                i=$((i + 1))
            done
            if [ -z "$pick" ]; then pick=$(printf '%s' "$nums" | sed -n "1p"); fi
            echo "  -> keeping /$pick (--yes)"
        else
            printf '  keep which /N? '
            if ! read -r pick </dev/tty 2>/dev/null; then
                read -r pick || pick=""
            fi
        fi
        local keep="" losers=""
        i=1
        while [ "$i" -le "$cnt" ]; do
            local cc nn
            cc=$(printf '%s' "$cids" | sed -n "${i}p")
            nn=$(printf '%s' "$nums" | sed -n "${i}p")
            if [ "$nn" = "$pick" ]; then
                keep="$cc"
            else
                losers="$losers $cc"
            fi
            i=$((i + 1))
        done
        if [ -z "$keep" ]; then
            echo "  skipped (no match for /$pick)"
            gi=$((gi + 1))
            continue
        fi
        # shellcheck disable=SC2086: intentional word splitting of id list
        set -- $losers
        jj abandon --ignore-immutable "$@" || { echo "abandon failed"; return 1; }
        resolved=$((resolved + 1))
        gi=$((gi + 1))
    done
    jj workspace update-stale >/dev/null 2>&1
    echo "Resolved $resolved group(s) (revert: jj undo)"
}

function _jj-pick-divergence_completion() {
    local curchange
    curchange=$(jj log --ignore-working-copy -r @ --no-graph -T 'change_id.shortest(8)' 2>/dev/null) || return 1
    [ -n "$curchange" ] || return 1
    local TAB
    TAB=$(printf '\t')
    local -a entries
    local n=0
    local rows
    rows=$(jj log --ignore-working-copy -r 'divergent()' --no-graph -T 'change_id.shortest(8) ++ "\t" ++ commit_id.shortest(8) ++ "\t" ++ self.change_offset() ++ "\t" ++ description.first_line() ++ "\n"' 2>/dev/null) || return 1
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        local tabs ch rest cid num desc
        tabs=$(printf '%s' "$line" | tr -cd '\t' | wc -c)
        ch=${line%%"$TAB"*}
        rest=${line#*"$TAB"}
        cid=${rest%%"$TAB"*}
        rest=${rest#*"$TAB"}
        if [ "$tabs" -ge 3 ]; then
            num=${rest%%"$TAB"*}
            desc=${rest#*"$TAB"}
        else
            num="$n"
            desc="$rest"
        fi
        [ "$ch" = "$curchange" ] || continue
        [ -n "$cid" ] || continue
        case "$num" in
            *[!0-9]*|"") num="$n" ;;
        esac
        n=$((n + 1))
        entries+=("$num:$cid -- $desc")
    done <<< "$rows"
    [ "$n" -ge 2 ] || return 1
    _describe 'version' entries
}

[[ -n "$ZSH_VERSION" ]] && compdef _jj-pick-divergence_completion jj-pick-divergence
# Last command decides `source` exit status — always succeed so `set -e`
# and `&&`-chained sourcing never trip on the guard above.
: