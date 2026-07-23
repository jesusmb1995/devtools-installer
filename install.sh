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
    local source_1011="${1}"
    local search_1012="${2}"
    local replace_1013="${3}"
    # Here we use a command to avoid #646
    local result_1014=""
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
        result_1014="${source_1011//"${search_1012}"/"${replace_1013}"}"
        __status=$?
    else
        result_1014="${source_1011//"${search_1012}"/${replace_1013}}"
        __status=$?
    fi
    ret_replace0_v0="${result_1014}"
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
    local source_1006="${1}"
    local search_1007="${2}"
    local replace_text_1008="${3}"
    local extended_1009="${4}"
    sed_version__2_v0 
    local sed_version_1010="${ret_sed_version2_v0}"
    replace__0_v0 "${search_1007}" "/" "\\/"
    search_1007="${ret_replace0_v0}"
    replace__0_v0 "${replace_text_1008}" "/" "\\/"
    replace_text_1008="${ret_replace0_v0}"
    if [ "$(( $(( sed_version_1010 == __SED_VERSION_GNU_1 )) || $(( sed_version_1010 == __SED_VERSION_BUSYBOX_2 )) ))" != 0 ]; then
        # '\b' is supported but not in POSIX standards. Disable it
        replace__0_v0 "${search_1007}" "\\b" "\\\\b"
        search_1007="${ret_replace0_v0}"
    fi
    if [ "${extended_1009}" != 0 ]; then
        # GNU sed versions 4.0 through 4.2 support extended regex syntax,
        # but only via the "-r" option
        if [ "$(( sed_version_1010 == __SED_VERSION_GNU_1 ))" != 0 ]; then
            local command_1
            command_1="$(sed -r -e "s/${search_1007}/${replace_text_1008}/g" <<<"${source_1006}")"
            __status=$?
            ret_replace_regex3_v0="${command_1}"
            return 0
        else
            local command_2
            command_2="$(sed -E -e "s/${search_1007}/${replace_text_1008}/g" <<<"${source_1006}")"
            __status=$?
            ret_replace_regex3_v0="${command_2}"
            return 0
        fi
    else
        if [ "$(( $(( sed_version_1010 == __SED_VERSION_GNU_1 )) || $(( sed_version_1010 == __SED_VERSION_BUSYBOX_2 )) ))" != 0 ]; then
            # GNU Sed BRE handle \| as a metacharacter, but it is not POSIX standands. Disable it
            replace__0_v0 "${search_1007}" "\\|" "|"
            search_1007="${ret_replace0_v0}"
        fi
        local command_3
        command_3="$(sed -e "s/${search_1007}/${replace_text_1008}/g" <<<"${source_1006}")"
        __status=$?
        ret_replace_regex3_v0="${command_3}"
        return 0
    fi
}

# split(text: Text, delimiter: Text)
split__4_v0() {
    local text_1313="${1}"
    local delimiter_1314="${2}"
    local result_1315=()
    # zsh uses -A for array, bash uses -a, ksh is VERY bad at splitting anything
    if [ "$([ "_${EXEC_SHELL}" != "_zsh" ]; echo $?)" != 0 ]; then
        IFS="${delimiter_1314}" read -rd '' -A result_1315 < <(printf %s "$text_1313")
        __status=$?
    elif [ "$([ "_${EXEC_SHELL}" != "_ksh" ]; echo $?)" != 0 ]; then
        if [ "$([ "_${delimiter_1314}" != "_
" ]; echo $?)" != 0 ]; then
            while read -r -d $'\n'; do result_1315+=("$REPLY"); done < <(echo "$text_1313")
            __status=$?
        else
            IFS="${delimiter_1314}" read -rd '' -a result_1315 < <(printf %s "$text_1313")
            __status=$?
        fi
    elif [ "$([ "_${EXEC_SHELL}" != "_bash" ]; echo $?)" != 0 ]; then
        IFS="${delimiter_1314}" read -rd '' -a result_1315 < <(printf %s "$text_1313")
        __status=$?
    fi
    ret_split4_v0=("${result_1315[@]}")
    return 0
}

# split_lines(text: Text)
split_lines__5_v0() {
    local text_1312="${1}"
    split__4_v0 "${text_1312}" "
"
    ret_split_lines5_v0=("${ret_split4_v0[@]}")
    return 0
}

# join(list: [Text], delimiter: Text)
join__7_v0() {
    local list_289=("${!1}")
    local delimiter_290="${2}"
    local command_5
    command_5="$(IFS="${delimiter_290}" ; printf "%s
" "${list_289[*]}")"
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
    local path_312="${1}"
    local content_313="${2}"
    local command_6
    command_6="$(printf '%s
' "${content_313}" > "${path_312}")"
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
    local path_305="${1}"
    dir_exists__38_v0 "${path_305}"
    local ret_dir_exists38_v0__87_12="${ret_dir_exists38_v0}"
    if [ "$(( ! ret_dir_exists38_v0__87_12 ))" != 0 ]; then
        mkdir -p "${path_305}"
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
    local name_282="${1}"
    if [ "$([ "_${EXEC_SHELL}" != "_bash" ]; echo $?)" != 0 ]; then
        local command_9
        command_9="$(printf "%s
" "${!name_282}")"
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
" "${(P)name_282}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_env_var_get124_v0=''
            return "${__status}"
        fi
        ret_env_var_get124_v0="${command_10}"
        return 0
    elif [ "$([ "_${EXEC_SHELL}" != "_ksh" ]; echo $?)" != 0 ]; then
        local command_11
        command_11="$(eval "echo \${$name_282}")"
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
    local format_296="${1}"
    local args_297=("${!2}")
    args_297=("${format_296}" "${args_297[@]}")
    __status=$?
    printf "${args_297[@]}"
    __status=$?
}

# echo_error(message: Text, exit_code: Int)
echo_error__142_v0() {
    local message_294="${1}"
    local exit_code_295="${2}"
    local array_12=("${message_294}")
    printf__132_v0 "\\x1b[1;3;97;41m%s\\x1b[0m
" array_12[@]
    if [ "$(( exit_code_295 > 0 ))" != 0 ]; then
        exit "${exit_code_295}"
    fi
}

# has_cmd(cmd: Text)
has_cmd__164_v0() {
    local cmd_287="${1}"
    local found_288=0
    command -v ${cmd_287} >/dev/null 2>&1
    __status=$?
    if [ "${__status}" = 0 ]; then
        found_288=1
    fi
    ret_has_cmd164_v0="${found_288}"
    return 0
}

# echo_error exits the process (default exit_code=1), so no fail needed.
# sudo_cmd(cmd: Text, envvar: [])
sudo_cmd__168_v0() {
    local cmd_285="${1}"
    local envvar_286=("${!2}")
    has_cmd__164_v0 "sudo"
    local ret_has_cmd164_v0__4_8="${ret_has_cmd164_v0}"
    if [ "${ret_has_cmd164_v0__4_8}" != 0 ]; then
        sudo ${envvar_286[@]} ${cmd_285}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd168_v0=''
            return "${__status}"
        fi
    else
        env ${envvar_286[@]} ${cmd_285}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd168_v0=''
            return "${__status}"
        fi
    fi
}

# sudo_cmd(cmd: Text, envvar: [Text])
sudo_cmd__168_v1() {
    local cmd_292="${1}"
    local envvar_293=("${!2}")
    has_cmd__164_v0 "sudo"
    local ret_has_cmd164_v0__4_8="${ret_has_cmd164_v0}"
    if [ "${ret_has_cmd164_v0__4_8}" != 0 ]; then
        sudo ${envvar_293[@]} ${cmd_292}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd168_v1=''
            return "${__status}"
        fi
    else
        env ${envvar_293[@]} ${cmd_292}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd168_v1=''
            return "${__status}"
        fi
    fi
}

# prompt_user(description: Text)
prompt_user__171_v0() {
    local description_281="${1}"
    env_var_get__124_v0 "COPALS_ASK"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_prompt_user171_v0=1
        return 0
    fi
    local ask_283="${ret_env_var_get124_v0}"
    if [ "$([ "_${ask_283}" != "_" ]; echo $?)" != 0 ]; then
        ret_prompt_user171_v0=1
        return 0
    fi
    echo "install: ${description_281}"
    printf "Proceed? [Y/n] " >&2
    __status=$?
    local command_13
    command_13="$(read -r line < /dev/tty 2>/dev/null; printf "%s" "$line")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        printf "
" >&2
        __status=$?
        ret_prompt_user171_v0=1
        return 0
    fi
    local ans_284="${command_13}"
    if [ "$([ "_${ans_284}" != "_" ]; echo $?)" != 0 ]; then
        ret_prompt_user171_v0=1
        return 0
    fi
    if [ "$(( $(( $(( $(( $([ "_${ans_284}" != "_n" ]; echo $?) || $([ "_${ans_284}" != "_N" ]; echo $?) )) || $([ "_${ans_284}" != "_no" ]; echo $?) )) || $([ "_${ans_284}" != "_NO" ]; echo $?) )) || $([ "_${ans_284}" != "_No" ]; echo $?) ))" != 0 ]; then
        echo "skipping"
        ret_prompt_user171_v0=0
        return 0
    fi
    ret_prompt_user171_v0=1
    return 0
}

was_updated_3=0
# update()
update__173_v0() {
    local array_14=()
    sudo_cmd__168_v0 "apt-get update" array_14[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_update173_v0=''
        return "${__status}"
    fi
}

# ensure_updated()
ensure_updated__174_v0() {
    if [ "$(( ! was_updated_3 ))" != 0 ]; then
        update__173_v0 
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_ensure_updated174_v0=''
            return "${__status}"
        fi
        was_updated_3=1
    fi
}

# apt_install(packages: [Text])
apt_install__175_v0() {
    local packages_280=("${!1}")
    prompt_user__171_v0 "apt install: ${packages_280[@]}"
    local ret_prompt_user171_v0__18_12="${ret_prompt_user171_v0}"
    if [ "$(( ! ret_prompt_user171_v0__18_12 ))" != 0 ]; then
        ret_apt_install175_v0=''
        return 0
    fi
    ensure_updated__174_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_apt_install175_v0=''
        return "${__status}"
    fi
    join__7_v0 packages_280[@] " "
    local pkgs_291="${ret_join7_v0}"
    local array_15=("DEBIAN_FRONTEND=noninteractive")
    sudo_cmd__168_v1 "apt-get install -y --no-install-recommends ${pkgs_291}" array_15[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_apt_install175_v0=''
        return "${__status}"
    fi
}

# apt_install_or_die(packages: [Text])
apt_install_or_die__176_v0() {
    local packages_279=("${!1}")
    apt_install__175_v0 packages_279[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to apt install ${packages_279[@]}" 1
    fi
}

# home()
home__179_v0() {
    env_var_get__124_v0 "HOME"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_home179_v0=''
        return "${__status}"
    fi
    ret_home179_v0="${ret_env_var_get124_v0}"
    return 0
}

# copy_into_home(src: Text, rel_dest: Text)
copy_into_home__186_v0() {
    local src_301="${1}"
    local rel_dest_302="${2}"
    home__179_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_copy_into_home186_v0=''
        return "${__status}"
    fi
    local home_303="${ret_home179_v0}"
    local dest_304="${home_303}/${rel_dest_302}"
    dir_create__44_v0 "${dest_304}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_copy_into_home186_v0=''
        return "${__status}"
    fi
    local __cp_16=
    (( 1 )) && __cp_16="-f" || __cp_16=""
    cp -r ${__cp_16} "${src_301}" "${dest_304}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_copy_into_home186_v0=''
        return "${__status}"
    fi
    ret_copy_into_home186_v0="${dest_304}"
    return 0
}

# copy_into_home_or_die(src: Text, rel_dest: Text)
copy_into_home_or_die__187_v0() {
    local src_299="${1}"
    local rel_dest_300="${2}"
    prompt_user__171_v0 "cp into home: ${rel_dest_300}"
    local ret_prompt_user171_v0__23_12="${ret_prompt_user171_v0}"
    if [ "$(( ! ret_prompt_user171_v0__23_12 ))" != 0 ]; then
        ret_copy_into_home_or_die187_v0=""
        return 0
    fi
    copy_into_home__186_v0 "${src_299}" "${rel_dest_300}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "deploy of ${rel_dest_300} into home failed" 1
    fi
    local dest_306="${ret_copy_into_home186_v0}"
    ret_copy_into_home_or_die187_v0="${dest_306}"
    return 0
}

# dir_create_at_home(rel: Text)
dir_create_at_home__193_v0() {
    local rel_308="${1}"
    home__179_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_dir_create_at_home193_v0=''
        return "${__status}"
    fi
    local h_309="${ret_home179_v0}"
    dir_create__44_v0 "${h_309}/${rel_308}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_dir_create_at_home193_v0=''
        return "${__status}"
    fi
}

# dir_create_at_home_or_die(rel: Text)
dir_create_at_home_or_die__194_v0() {
    local rel_307="${1}"
    prompt_user__171_v0 "create directory ~/${rel_307}"
    local ret_prompt_user171_v0__12_8="${ret_prompt_user171_v0}"
    if [ "${ret_prompt_user171_v0__12_8}" != 0 ]; then
        dir_create_at_home__193_v0 "${rel_307}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "failed to create directory at home/${rel_307}" 1
        fi
    fi
}

# home()
home__198_v0() {
    env_var_get__124_v0 "HOME"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_home198_v0=''
        return "${__status}"
    fi
    ret_home198_v0="${ret_env_var_get124_v0}"
    return 0
}

__APPS_DIR_4=".local/share/applications"
# make_nnn_desktop(h: Text)
make_nnn_desktop__201_v0() {
    local h_310="${1}"
    local path_311="${h_310}/.local/bin/st-zsh"
    ret_make_nnn_desktop201_v0="[Desktop Entry]
Type=Application
Name=File Explorer (nnn)
Comment=Terminal file manager
Exec=${path_311} -e ${h_310}/.local/bin/nnn-launch
Terminal=false
Categories=Utility;FileManager;
Icon=nnn
"
    return 0
}

# make_btop_desktop(h: Text)
make_btop_desktop__202_v0() {
    local h_314="${1}"
    local path_315="${h_314}/.local/bin/st-zsh"
    ret_make_btop_desktop202_v0="[Desktop Entry]
Type=Application
Name=System Monitor (btop)
Comment=Resource monitor
Exec=${path_315} -e btop
Terminal=false
Categories=System;Monitor;
Icon=btop
"
    return 0
}

# make_ncdu_desktop(h: Text)
make_ncdu_desktop__203_v0() {
    local h_316="${1}"
    local path_317="${h_316}/.local/bin/st-zsh"
    ret_make_ncdu_desktop203_v0="[Desktop Entry]
Type=Application
Name=Disk Usage (ncdu)
Comment=Disk usage analyzer
Exec=${path_317} -e ncdu
Terminal=false
Categories=System;Utility;
Icon=ncdu
"
    return 0
}

# install_apt_essential_tools()
install_apt_essential_tools__204_v0() {
    local array_17=("rsync" "git" "tmux" "zsh" "sqlite3" "jq" "curl" "vim" "neovim" "ca-certificates" "ripgrep" "nnn" "fzf" "zenity" "btop" "ncdu")
    apt_install_or_die__176_v0 array_17[@]
    home__198_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to resolve HOME" 1
    fi
    local h_298="${ret_home198_v0}"
    copy_into_home_or_die__187_v0 "src/apt-essential-tools/.config/nnn" ".config/"
    copy_into_home_or_die__187_v0 "src/apt-essential-tools/.local/bin" ".local/"
    chmod +x ${h_298}/.config/nnn/plugins/dragdrop ${h_298}/.config/nnn/plugins/zmarks ${h_298}/.config/nnn/plugins/nvim-cd ${h_298}/.config/nnn/plugins/bm-create ${h_298}/.config/nnn/plugins/win-open ${h_298}/.config/nnn/profile ${h_298}/.local/bin/nnn-launch
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to chmod nnn files" 1
    fi
    dir_create_at_home_or_die__194_v0 "${__APPS_DIR_4}"
    make_nnn_desktop__201_v0 "${h_298}"
    local ret_make_nnn_desktop201_v0__39_46="${ret_make_nnn_desktop201_v0}"
    file_write__41_v0 "${h_298}/${__APPS_DIR_4}/nnn.desktop" "${ret_make_nnn_desktop201_v0__39_46}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to write nnn.desktop" 1
    fi
    make_btop_desktop__202_v0 "${h_298}"
    local ret_make_btop_desktop202_v0__42_47="${ret_make_btop_desktop202_v0}"
    file_write__41_v0 "${h_298}/${__APPS_DIR_4}/btop.desktop" "${ret_make_btop_desktop202_v0__42_47}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to write btop.desktop" 1
    fi
    make_ncdu_desktop__203_v0 "${h_298}"
    local ret_make_ncdu_desktop203_v0__45_47="${ret_make_ncdu_desktop203_v0}"
    file_write__41_v0 "${h_298}/${__APPS_DIR_4}/ncdu.desktop" "${ret_make_ncdu_desktop203_v0__45_47}"
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
install_apt_essential_ui__207_v0() {
    local array_18=("stterm" "i3" "suckless-tools" "dbus" "dbus-x11" "xss-lock" "x11-xserver-utils" "libgl1-mesa-dri" "libgl1" "libegl1" "libegl-mesa0")
    apt_install_or_die__176_v0 array_18[@]
    local array_19=("xfce4-settings")
    apt_install_or_die__176_v0 array_19[@]
    local array_20=("x11vnc" "xvfb")
    apt_install_or_die__176_v0 array_20[@]
}

# rsync(src: Text, target: Text, excludes: [], delete: Bool)
rsync__214_v0() {
    local src_383="${1}"
    local target_384="${2}"
    local excludes_385=("${!3}")
    local delete_386="${4}"
    dir_create__44_v0 "${target_384}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync214_v0=''
        return "${__status}"
    fi
    local excludes_arr_387=()
    for exclude_388 in "${excludes_385[@]}"; do
        local s_389="${exclude_388}"
        excludes_arr_387+=("--exclude" "${s_389}")
    done
    local delopt_390=""
    if [ "${delete_386}" != 0 ]; then
        delopt_390="--delete"
    fi
    rsync -a ${delopt_390} ${excludes_arr_387[@]} ${src_383} ${target_384}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync214_v0=''
        return "${__status}"
    fi
}

# rsync(src: Text, target: Text, excludes: [Text], delete: Bool)
rsync__214_v1() {
    local src_569="${1}"
    local target_570="${2}"
    local excludes_571=("${!3}")
    local delete_572="${4}"
    dir_create__44_v0 "${target_570}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync214_v1=''
        return "${__status}"
    fi
    local excludes_arr_573=()
    for exclude_574 in "${excludes_571[@]}"; do
        local s_575="${exclude_574}"
        excludes_arr_573+=("--exclude" "${s_575}")
    done
    local delopt_576=""
    if [ "${delete_572}" != 0 ]; then
        delopt_576="--delete"
    fi
    rsync -a ${delopt_576} ${excludes_arr_573[@]} ${src_569} ${target_570}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync214_v1=''
        return "${__status}"
    fi
}

# rsync_into_home(src: Text, rel_target: Text, delete: Bool)
rsync_into_home__217_v0() {
    local src_377="${1}"
    local rel_target_378="${2}"
    local delete_379="${3}"
    local excludes_380=()
    home__179_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync_into_home217_v0=''
        return "${__status}"
    fi
    local h_381="${ret_home179_v0}"
    local target_382="${h_381}/${rel_target_378}"
    dir_create__44_v0 "${target_382}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync_into_home217_v0=''
        return "${__status}"
    fi
    rsync__214_v0 "${src_377}" "${target_382}" excludes_380[@] "${delete_379}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync_into_home217_v0=''
        return "${__status}"
    fi
}

# rsync_or_die_into_home(src: Text, rel_target: Text, delete: Bool)
rsync_or_die_into_home__218_v0() {
    local src_374="${1}"
    local rel_target_375="${2}"
    local delete_376="${3}"
    prompt_user__171_v0 "rsync ${src_374} -> ~/${rel_target_375}"
    local ret_prompt_user171_v0__16_8="${ret_prompt_user171_v0}"
    if [ "${ret_prompt_user171_v0__16_8}" != 0 ]; then
        rsync_into_home__217_v0 "${src_374}" "${rel_target_375}" "${delete_376}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "rsync deploy of ${src_374} into ${rel_target_375} failed" 1
        fi
    fi
}

# rsync_or_die_opts(src: Text, target: Text, excludes: [Text], delete: Bool)
rsync_or_die_opts__219_v0() {
    local src_565="${1}"
    local target_566="${2}"
    local excludes_567=("${!3}")
    local delete_568="${4}"
    prompt_user__171_v0 "rsync ${src_565} -> ${target_566}"
    local ret_prompt_user171_v0__24_8="${ret_prompt_user171_v0}"
    if [ "${ret_prompt_user171_v0__24_8}" != 0 ]; then
        rsync__214_v1 "${src_565}" "${target_566}" excludes_567[@] "${delete_568}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "rsync deploy of ${src_565} into ${target_566} failed" 1
        fi
    fi
}

# rsync_or_die_opts_into_home(src: Text, rel_target: Text, excludes: [Text], delete: Bool)
rsync_or_die_opts_into_home__220_v0() {
    local src_560="${1}"
    local rel_target_561="${2}"
    local excludes_562=("${!3}")
    local delete_563="${4}"
    prompt_user__171_v0 "rsync ${src_560} -> ~/${rel_target_561}"
    local ret_prompt_user171_v0__32_8="${ret_prompt_user171_v0}"
    if [ "${ret_prompt_user171_v0__32_8}" != 0 ]; then
        home__179_v0 
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "rsync_or_die_opts_into_home: failed to resolve home directory" 1
            exit 1
        fi
        local h_564="${ret_home179_v0}"
        rsync_or_die_opts__219_v0 "${src_560}" "${h_564}/${rel_target_561}" excludes_562[@] "${delete_563}"
    fi
}

# install_dotfiles_essential()
install_dotfiles_essential__222_v0() {
    rsync_or_die_into_home__218_v0 "src/dotfiles_essential/.config/" ".config" 0
}

# setup_global_gitignore()
setup_global_gitignore__227_v0() {
    home__179_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_setup_global_gitignore227_v0=''
        return "${__status}"
    fi
    local h_394="${ret_home179_v0}"
    file_exists__39_v0 "${h_394}/.gitignore_global"
    local ret_file_exists39_v0__7_12="${ret_file_exists39_v0}"
    if [ "$(( ! ret_file_exists39_v0__7_12 ))" != 0 ]; then
        ret_setup_global_gitignore227_v0=''
        return 1
    fi
    git config --global core.excludesFile ${h_394}/.gitignore_global
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_setup_global_gitignore227_v0=''
        return "${__status}"
    fi
}

# setup_global_gitignore_or_die()
setup_global_gitignore_or_die__228_v0() {
    setup_global_gitignore__227_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to setup global gitignore" 1
    fi
}

# install_dotfiles_personalization()
install_dotfiles_personalization__232_v0() {
    rsync_or_die_into_home__218_v0 "src/dotfiles_personalization/" "" 0
    setup_global_gitignore_or_die__228_v0 
    copy_into_home_or_die__187_v0 "src/dotfiles_personalization/.local/share/applications" ".local/share/applications"
}

# has_cmd(cmd: Text)
has_cmd__236_v0() {
    local cmd_447="${1}"
    local found_448=0
    command -v ${cmd_447} >/dev/null 2>&1
    __status=$?
    if [ "${__status}" = 0 ]; then
        found_448=1
    fi
    ret_has_cmd236_v0="${found_448}"
    return 0
}

# echo_error exits the process (default exit_code=1), so no fail needed.
# sudo_cmd(cmd: Text, envvar: [])
sudo_cmd__240_v0() {
    local cmd_445="${1}"
    local envvar_446=("${!2}")
    has_cmd__236_v0 "sudo"
    local ret_has_cmd236_v0__4_8="${ret_has_cmd236_v0}"
    if [ "${ret_has_cmd236_v0__4_8}" != 0 ]; then
        sudo ${envvar_446[@]} ${cmd_445}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd240_v0=''
            return "${__status}"
        fi
    else
        env ${envvar_446[@]} ${cmd_445}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd240_v0=''
            return "${__status}"
        fi
    fi
}

# has_cmd(cmd: Text)
has_cmd__243_v0() {
    local cmd_439="${1}"
    local found_440=0
    command -v ${cmd_439} >/dev/null 2>&1
    __status=$?
    if [ "${__status}" = 0 ]; then
        found_440=1
    fi
    ret_has_cmd243_v0="${found_440}"
    return 0
}

# which_cmd(cmd: Text)
which_cmd__244_v0() {
    local cmd_441="${1}"
    local command_30
    command_30="$(command -v ${cmd_441} 2>/dev/null)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_which_cmd244_v0=''
        return "${__status}"
    fi
    ret_which_cmd244_v0="${command_30}"
    return 0
}

# echo_error exits the process (default exit_code=1), so no fail needed.
# set_terminal_alternative()
set_terminal_alternative__251_v0() {
    local command_31
    command_31="$(command -v st)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_set_terminal_alternative251_v0=''
        return "${__status}"
    fi
    local st_bin_437="${command_31}"
    local term_path_438="${st_bin_437}"
    has_cmd__243_v0 "zsh"
    local ret_has_cmd243_v0__11_8="${ret_has_cmd243_v0}"
    if [ "${ret_has_cmd243_v0__11_8}" != 0 ]; then
        which_cmd__244_v0 "zsh"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative251_v0=''
            return "${__status}"
        fi
        local zsh_bin_442="${ret_which_cmd244_v0}"
        home__198_v0 
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative251_v0=''
            return "${__status}"
        fi
        local h_443="${ret_home198_v0}"
        local wrapper_444="${h_443}/.local/bin/st-zsh"
        mkdir -p "${h_443}/.local/bin"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative251_v0=''
            return "${__status}"
        fi
        echo '#!/bin/sh' > "${wrapper_444}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative251_v0=''
            return "${__status}"
        fi
        echo '[ "$1" = "-e" ] && shift' >> "${wrapper_444}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative251_v0=''
            return "${__status}"
        fi
        echo 'if [ "$#" -eq 0 ]; then' >> "${wrapper_444}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative251_v0=''
            return "${__status}"
        fi
        echo "    exec ${st_bin_437} -f 'monospace:size=12' -e ${h_443}/.local/bin/st-init.sh ${zsh_bin_442}" >> "${wrapper_444}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative251_v0=''
            return "${__status}"
        fi
        echo 'else' >> "${wrapper_444}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative251_v0=''
            return "${__status}"
        fi
        echo "    exec ${st_bin_437} -f 'monospace:size=12' -e ${h_443}/.local/bin/st-init.sh" '"$@"' >> "${wrapper_444}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative251_v0=''
            return "${__status}"
        fi
        echo 'fi' >> "${wrapper_444}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative251_v0=''
            return "${__status}"
        fi
        chmod +x "${wrapper_444}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative251_v0=''
            return "${__status}"
        fi
        term_path_438="${wrapper_444}"
    fi
    local array_32=()
    sudo_cmd__240_v0 "update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator ${term_path_438} 10" array_32[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_set_terminal_alternative251_v0=''
        return "${__status}"
    fi
    local array_33=()
    sudo_cmd__240_v0 "update-alternatives --set x-terminal-emulator ${term_path_438}" array_33[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_set_terminal_alternative251_v0=''
        return "${__status}"
    fi
}

# install_st()
install_st__252_v0() {
    set_terminal_alternative__251_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "st: failed to register x-terminal-emulator alternative" 1
    fi
    dir_create_at_home_or_die__194_v0 ".config/fontconfig"
    copy_into_home_or_die__187_v0 "src/st/.config/fontconfig/fonts.conf" ".config/fontconfig"
    home__198_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "st: cannot resolve HOME" 1
    fi
    local h_449="${ret_home198_v0}"
    mkdir -p "${h_449}/.local/bin"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "st: failed to create ~/.local/bin" 1
    fi
    cp "src/st/.local/bin/st-init.sh" "${h_449}/.local/bin/st-init.sh"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "st: failed to copy st-init.sh" 1
    fi
    chmod +x "${h_449}/.local/bin/st-init.sh"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "st: failed to chmod st-init.sh" 1
    fi
}

# symlink_create_dir(origin: Text, destination: Text)
symlink_create_dir__260_v0() {
    local origin_502="${1}"
    local destination_503="${2}"
    dir_exists__38_v0 "${origin_502}"
    local ret_dir_exists38_v0__4_12="${ret_dir_exists38_v0}"
    if [ "$(( ! ret_dir_exists38_v0__4_12 ))" != 0 ]; then
        echo "The directory ${origin_502} doesn't exist"
        ret_symlink_create_dir260_v0=''
        return 1
    fi
    ln -fsn ${origin_502} ${destination_503}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_create_dir260_v0=''
        return "${__status}"
    fi
}

# TODO test this
# _parent_dir(path: Text)
_parent_dir__263_v0() {
    local path_498="${1}"
    local command_34
    command_34="$(dirname ${path_498})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret__parent_dir263_v0=''
        return "${__status}"
    fi
    local parent_499="${command_34}"
    ret__parent_dir263_v0="${parent_499}"
    return 0
}

# symlink_into_home(src: Text, rel_dest: Text)
symlink_into_home__264_v0() {
    local src_494="${1}"
    local rel_dest_495="${2}"
    home__179_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home264_v0=''
        return "${__status}"
    fi
    local home_496="${ret_home179_v0}"
    local dest_497="${home_496}/${rel_dest_495}"
    _parent_dir__263_v0 "${dest_497}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home264_v0=''
        return "${__status}"
    fi
    local parent_500="${ret__parent_dir263_v0}"
    dir_create__44_v0 "${parent_500}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home264_v0=''
        return "${__status}"
    fi
    local command_35
    command_35="$(readlink -f ${src_494})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home264_v0=''
        return "${__status}"
    fi
    local abs_src_501="${command_35}"
    symlink_create_dir__260_v0 "${abs_src_501}" "${dest_497}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home264_v0=''
        return "${__status}"
    fi
    ret_symlink_into_home264_v0="${dest_497}"
    return 0
}

# symlink_into_home_or_die(src: Text, rel_dest: Text)
symlink_into_home_or_die__265_v0() {
    local src_492="${1}"
    local rel_dest_493="${2}"
    prompt_user__171_v0 "symlink ${src_492} -> ~/${rel_dest_493}"
    local ret_prompt_user171_v0__26_12="${ret_prompt_user171_v0}"
    if [ "$(( ! ret_prompt_user171_v0__26_12 ))" != 0 ]; then
        ret_symlink_into_home_or_die265_v0=""
        return 0
    fi
    symlink_into_home__264_v0 "${src_492}" "${rel_dest_493}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "deploy of ${src_492} symlink ${rel_dest_493}  into home failed" 1
    fi
    local dest_504="${ret_symlink_into_home264_v0}"
    ret_symlink_into_home_or_die265_v0="${dest_504}"
    return 0
}

# Symlink a home-relative path to another home-relative path (both resolved
# against home()). Works for files (e.g. bridging a data file from one config
# location to the path a plugin expects).
# symlink_at_home(src_rel: Text, dest_rel: Text)
symlink_at_home__266_v0() {
    local src_rel_1071="${1}"
    local dest_rel_1072="${2}"
    home__179_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_at_home266_v0=''
        return "${__status}"
    fi
    local h_1073="${ret_home179_v0}"
    local src_1074="${h_1073}/${src_rel_1071}"
    local dest_1075="${h_1073}/${dest_rel_1072}"
    file_exists__39_v0 "${src_1074}"
    local ret_file_exists39_v0__43_12="${ret_file_exists39_v0}"
    if [ "$(( ! ret_file_exists39_v0__43_12 ))" != 0 ]; then
        echo_error__142_v0 "symlink source ${src_1074} missing" 1
        ret_symlink_at_home266_v0=''
        return 1
    fi
    _parent_dir__263_v0 "${dest_1075}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_at_home266_v0=''
        return "${__status}"
    fi
    local parent_1076="${ret__parent_dir263_v0}"
    dir_create__44_v0 "${parent_1076}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_at_home266_v0=''
        return "${__status}"
    fi
    ln -fsn ${src_1074} ${dest_1075}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_at_home266_v0=''
        return "${__status}"
    fi
    ret_symlink_at_home266_v0="${dest_1075}"
    return 0
}

# symlink_at_home_or_die(src_rel: Text, dest_rel: Text)
symlink_at_home_or_die__267_v0() {
    local src_rel_1069="${1}"
    local dest_rel_1070="${2}"
    prompt_user__171_v0 "symlink ~/${src_rel_1069} -> ~/${dest_rel_1070}"
    local ret_prompt_user171_v0__57_12="${ret_prompt_user171_v0}"
    if [ "$(( ! ret_prompt_user171_v0__57_12 ))" != 0 ]; then
        ret_symlink_at_home_or_die267_v0=""
        return 0
    fi
    symlink_at_home__266_v0 "${src_rel_1069}" "${dest_rel_1070}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "symlink ${src_rel_1069} -> ${dest_rel_1070} in home failed" 1
    fi
    local dest_1077="${ret_symlink_at_home266_v0}"
    ret_symlink_at_home_or_die267_v0="${dest_1077}"
    return 0
}

# install_nerd_fonts()
install_nerd_fonts__269_v0() {
    local subpath_491=".local/share/fonts/NerdFonts"
    symlink_into_home_or_die__265_v0 "src/${subpath_491}" "${subpath_491}"
}

# install_rofi()
install_rofi__273_v0() {
    local array_36=("rofi")
    apt_install_or_die__176_v0 array_36[@]
    copy_into_home_or_die__187_v0 "src/rofi/.config/rofi" ".config/"
}

# set_only_user_write_or_die(path: Text)
set_only_user_write_or_die__278_v0() {
    local path_579="${1}"
    chmod -R g-w,o-w ${path_579}
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to set ${path_579} perms to user-only write" 1
    fi
}

# set_only_user_write_or_die_at_home(rel_path: Text)
set_only_user_write_or_die_at_home__279_v0() {
    local rel_path_577="${1}"
    home__179_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "cannot determine home directory for ${rel_path_577}" 1
    fi
    local h_578="${ret_home179_v0}"
    set_only_user_write_or_die__278_v0 "${h_578}/${rel_path_577}"
}

# make_executable(path: Text)
make_executable__280_v0() {
    local path_1165="${1}"
    chmod +x ${path_1165}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_make_executable280_v0=''
        return "${__status}"
    fi
}

# install_omz_config()
install_omz_config__282_v0() {
    local subpath_559=".oh-my-zsh"
    local array_37=("custom/plugins/")
    rsync_or_die_opts_into_home__220_v0 "src/${subpath_559}/" "${subpath_559}" array_37[@] 1
    set_only_user_write_or_die_at_home__279_v0 "${subpath_559}"
}

# execute(bin: Text, sh_path: Text)
execute__286_v0() {
    local bin_598="${1}"
    local sh_path_599="${2}"
    ${bin_598} ${sh_path_599}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute286_v0=''
        return "${__status}"
    fi
}

# execute_sh(sh_path: Text)
execute_sh__287_v0() {
    local sh_path_1187="${1}"
    execute__286_v0 "bash" "${sh_path_1187}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_sh287_v0=''
        return "${__status}"
    fi
}

# execute_zsh(sh_path: Text)
execute_zsh__288_v0() {
    local sh_path_597="${1}"
    execute__286_v0 "zsh" "${sh_path_597}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_zsh288_v0=''
        return "${__status}"
    fi
}

# execute_zsh_at_home(rel_sh_path: Text)
execute_zsh_at_home__291_v0() {
    local rel_sh_path_595="${1}"
    home__179_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_zsh_at_home291_v0=''
        return "${__status}"
    fi
    local h_596="${ret_home179_v0}"
    execute_zsh__288_v0 "${h_596}/${rel_sh_path_595}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_zsh_at_home291_v0=''
        return "${__status}"
    fi
}

# install_zshmarks()
install_zshmarks__294_v0() {
    mkdir -p ~/.oh-my-zsh/custom/plugins/zshmarks
    __status=$?
    cp src/zshmarks.plugin.zsh ~/.oh-my-zsh/custom/plugins/zshmarks/zshmarks.plugin.zsh
    __status=$?
    execute_zsh_at_home__291_v0 ".oh-my-zsh/custom/plugins/zshmarks/zshmarks.plugin.zsh"
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
temp_file_create__304_v0() {
    local suffix_750="${1}"
    token_20="$(( token_20 + 1 ))"
    local tmp_751="${__TMP_DIR_19}/${token_20}${suffix_750}"
    touch "${tmp_751}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_temp_file_create304_v0=''
        return "${__status}"
    fi
    ret_temp_file_create304_v0="${tmp_751}"
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
download_to__307_v0() {
    local url_753="${1}"
    local target_754="${2}"
    curl -fsSL ${url_753} -o ${target_754}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_to307_v0=''
        return "${__status}"
    fi
}

# download_tmp(url: Text)
download_tmp__308_v0() {
    local url_749="${1}"
    temp_file_create__304_v0 ""
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_tmp308_v0=''
        return "${__status}"
    fi
    local target_752="${ret_temp_file_create304_v0}"
    download_to__307_v0 "${url_749}" "${target_752}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_tmp308_v0=''
        return "${__status}"
    fi
    ret_download_tmp308_v0="${target_752}"
    return 0
}

# url_status(url: Text)
url_status__309_v0() {
    local url_1016="${1}"
    local command_38
    command_38="$(curl -sIL ${url_1016} | head -1 | tr -s ' ' | cut -d' ' -f2)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_url_status309_v0=''
        return "${__status}"
    fi
    ret_url_status309_v0="${command_38}"
    return 0
}

# download_verified_url_to(url: Text, target: Text, expected_hash: Text)
download_verified_url_to__310_v0() {
    local url_1160="${1}"
    local target_1161="${2}"
    local expected_hash_1162="${3}"
    download_to__307_v0 "${url_1160}" "${target_1161}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_url_to310_v0=''
        return 0
    fi
    local command_39
    command_39="$(sha256sum ${target_1161} | cut -d' ' -f1)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_url_to310_v0=''
        return "${__status}"
    fi
    local actual_1163="${command_39}"
    if [ "$([ "_${actual_1163}" == "_${expected_hash_1162}" ]; echo $?)" != 0 ]; then
        echo_error__142_v0 "sha256 mismatch for ${target_1161}: expected ${expected_hash_1162}, got ${actual_1163}" 1
        rm -f ${target_1161}
        __status=$?
        ret_download_verified_url_to310_v0=''
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
resolve_vendor_dir__324_v0() {
    dir_exists__38_v0 "${installed_vendor_23}"
    local ret_dir_exists38_v0__12_8="${ret_dir_exists38_v0}"
    file_exists__39_v0 "${installed_vendor_23}/jsonnet"
    local ret_file_exists39_v0__12_41="${ret_file_exists39_v0}"
    if [ "$(( ret_dir_exists38_v0__12_8 && ret_file_exists39_v0__12_41 ))" != 0 ]; then
        ret_resolve_vendor_dir324_v0="${installed_vendor_23}"
        return 0
    fi
    dir_exists__38_v0 "${project_vendor_22}"
    local ret_dir_exists38_v0__15_8="${ret_dir_exists38_v0}"
    file_exists__39_v0 "${project_vendor_22}/jsonnet"
    local ret_file_exists39_v0__15_39="${ret_file_exists39_v0}"
    if [ "$(( ret_dir_exists38_v0__15_8 && ret_file_exists39_v0__15_39 ))" != 0 ]; then
        ret_resolve_vendor_dir324_v0="${project_vendor_22}"
        return 0
    fi
    dir_exists__38_v0 "${installed_vendor_23}"
    local ret_dir_exists38_v0__18_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__18_8}" != 0 ]; then
        ret_resolve_vendor_dir324_v0="${installed_vendor_23}"
        return 0
    fi
    dir_exists__38_v0 "${project_vendor_22}"
    local ret_dir_exists38_v0__21_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__21_8}" != 0 ]; then
        ret_resolve_vendor_dir324_v0="${project_vendor_22}"
        return 0
    fi
    ret_resolve_vendor_dir324_v0=""
    return 0
}

resolve_vendor_dir__324_v0 
__VENDOR_DIR_34="${ret_resolve_vendor_dir324_v0}"
# jq_resolve()
jq_resolve__325_v0() {
    if [ "$([ "_${__VENDOR_DIR_34}" != "_" ]; echo $?)" != 0 ]; then
        ret_jq_resolve325_v0="jq"
        return 0
    fi
    ret_jq_resolve325_v0="${__VENDOR_DIR_34}/jq"
    return 0
}

# j2_resolve()
j2_resolve__326_v0() {
    if [ "$([ "_${__VENDOR_DIR_34}" != "_" ]; echo $?)" != 0 ]; then
        ret_j2_resolve326_v0="j2"
        return 0
    fi
    ret_j2_resolve326_v0="${__VENDOR_DIR_34}/j2"
    return 0
}

# jsonnet_resolve()
jsonnet_resolve__327_v0() {
    if [ "$([ "_${__VENDOR_DIR_34}" != "_" ]; echo $?)" != 0 ]; then
        ret_jsonnet_resolve327_v0="jsonnet"
        return 0
    fi
    ret_jsonnet_resolve327_v0="${__VENDOR_DIR_34}/jsonnet"
    return 0
}

# jsonschema_resolve()
jsonschema_resolve__328_v0() {
    if [ "$([ "_${__VENDOR_DIR_34}" != "_" ]; echo $?)" != 0 ]; then
        ret_jsonschema_resolve328_v0="jsonschema"
        return 0
    fi
    ret_jsonschema_resolve328_v0="${__VENDOR_DIR_34}/jsonschema"
    return 0
}

# lua_resolve()
lua_resolve__329_v0() {
    if [ "$([ "_${__VENDOR_DIR_34}" != "_" ]; echo $?)" != 0 ]; then
        ret_lua_resolve329_v0="lua"
        return 0
    fi
    ret_lua_resolve329_v0="${__VENDOR_DIR_34}/lua"
    return 0
}

jq_resolve__325_v0 
__JQ_35="${ret_jq_resolve325_v0}"
j2_resolve__326_v0 
jsonnet_resolve__327_v0 
jsonschema_resolve__328_v0 
lua_resolve__329_v0 
# tag_verified(repo: Text, tag: Text)
tag_verified__330_v0() {
    local repo_758="${1}"
    local tag_759="${2}"
    local ref_url_760="https://api.github.com/repos/${repo_758}/git/ref/tags/${tag_759}"
    download_tmp__308_v0 "${ref_url_760}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_tag_verified330_v0=''
        return "${__status}"
    fi
    local ref_data_761="${ret_download_tmp308_v0}"
    local command_41
    command_41="$(${__JQ_35} -r .object.type ${ref_data_761})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_tag_verified330_v0=''
        return "${__status}"
    fi
    local obj_type_762="${command_41}"
    if [ "$([ "_${obj_type_762}" == "_tag" ]; echo $?)" != 0 ]; then
        ret_tag_verified330_v0=1
        return 0
    fi
    local command_42
    command_42="$(${__JQ_35} -r .object.sha ${ref_data_761})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_tag_verified330_v0=''
        return "${__status}"
    fi
    local sha_763="${command_42}"
    local tag_url_764="https://api.github.com/repos/${repo_758}/git/tags/${sha_763}"
    local command_43
    command_43="$(curl -fsSL ${tag_url_764} | ${__JQ_35} -r .verification.verified)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_tag_verified330_v0=''
        return "${__status}"
    fi
    local verified_765="${command_43}"
    ret_tag_verified330_v0="$([ "_${verified_765}" != "_true" ]; echo $?)"
    return 0
}

# install_github_binary(repo: Text, asset_suffix: Text, binary_name: Text, install_dir: Text)
install_github_binary__333_v0() {
    local repo_744="${1}"
    local asset_suffix_745="${2}"
    local binary_name_746="${3}"
    local install_dir_747="${4}"
    local api_748="https://api.github.com/repos/${repo_744}/releases/latest"
    download_tmp__308_v0 "${api_748}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_github_binary333_v0=''
        return "${__status}"
    fi
    local rel_755="${ret_download_tmp308_v0}"
    local command_44
    command_44="$(${__JQ_35} -r '.assets[] | select(.name | endswith("'"${asset_suffix_745}"'")) | .browser_download_url' ${rel_755})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_github_binary333_v0=''
        return "${__status}"
    fi
    local url_756="${command_44}"
    local command_45
    command_45="$(${__JQ_35} -r .tag_name ${rel_755})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_github_binary333_v0=''
        return "${__status}"
    fi
    local tag_757="${command_45}"
    tag_verified__330_v0 "${repo_744}" "${tag_757}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_github_binary333_v0=''
        return "${__status}"
    fi
    local ret_tag_verified330_v0__46_12="${ret_tag_verified330_v0}"
    if [ "$(( ! ret_tag_verified330_v0__46_12 ))" != 0 ]; then
        ret_install_github_binary333_v0=''
        return 1
    fi
    download_tmp__308_v0 "${url_756}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_github_binary333_v0=''
        return "${__status}"
    fi
    local tarball_766="${ret_download_tmp308_v0}"
    temp_dir_create__46_v0 "gh-bin-XXXXXX" 0 0
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_github_binary333_v0=''
        return "${__status}"
    fi
    local tmp_767="${ret_temp_dir_create46_v0}"
    tar -xzf ${tarball_766} -C ${tmp_767}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_github_binary333_v0=''
        return "${__status}"
    fi
    local array_46=()
    sudo_cmd__168_v0 "install -m755 ${tmp_767}/${binary_name_746} ${install_dir_747}" array_46[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        local array_47=()
        sudo_cmd__168_v0 "install -m755 ${tmp_767}/*/${binary_name_746} ${install_dir_747}" array_47[@]
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_install_github_binary333_v0=''
            return "${__status}"
        fi
    fi
}

# install_github_binary_or_die(repo: Text, asset_suffix: Text, binary_name: Text, install_dir: Text)
install_github_binary_or_die__334_v0() {
    local repo_740="${1}"
    local asset_suffix_741="${2}"
    local binary_name_742="${3}"
    local install_dir_743="${4}"
    prompt_user__171_v0 "install ${binary_name_742} from ${repo_740} -> ${install_dir_743}"
    local ret_prompt_user171_v0__58_8="${ret_prompt_user171_v0}"
    if [ "${ret_prompt_user171_v0__58_8}" != 0 ]; then
        install_github_binary__333_v0 "${repo_740}" "${asset_suffix_741}" "${binary_name_742}" "${install_dir_743}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "failed to install ${binary_name_742} from ${repo_740}" 1
        fi
    fi
}

# install_system_tools()
install_system_tools__336_v0() {
    local array_48=("ncdu")
    apt_install_or_die__176_v0 array_48[@]
    has_cmd__243_v0 "jj"
    local ret_has_cmd243_v0__12_12="${ret_has_cmd243_v0}"
    if [ "$(( ! ret_has_cmd243_v0__12_12 ))" != 0 ]; then
        install_github_binary_or_die__334_v0 "jj-vcs/jj" "x86_64-unknown-linux-musl.tar.gz" "jj" "/usr/local/bin"
    fi
}

# install_deb(deb_path: Text)
install_deb__344_v0() {
    local deb_path_1002="${1}"
    local array_49=()
    sudo_cmd__168_v0 "dpkg -i ${deb_path_1002}" array_49[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        # dpkg may fail due to missing deps; fix them below
        :
    fi
    local array_50=()
    sudo_cmd__168_v0 "apt-get install -f -y" array_50[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_deb344_v0=''
        return "${__status}"
    fi
}

# install_deb_url(url: Text)
install_deb_url__346_v0() {
    local url_1001="${1}"
    download_tmp__308_v0 "${url_1001}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_deb_url346_v0=''
        return "${__status}"
    fi
    local ret_download_tmp308_v0__19_17="${ret_download_tmp308_v0}"
    install_deb__344_v0 "${ret_download_tmp308_v0__19_17}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_deb_url346_v0=''
        return "${__status}"
    fi
}

# install_deb_url_or_die(url: Text)
install_deb_url_or_die__347_v0() {
    local url_1000="${1}"
    install_deb_url__346_v0 "${url_1000}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to install .deb from ${url_1000}" 1
    fi
}

# has_cmd(cmd: Text)
has_cmd__354_v0() {
    local cmd_1019="${1}"
    local found_1020=0
    command -v ${cmd_1019} >/dev/null 2>&1
    __status=$?
    if [ "${__status}" = 0 ]; then
        found_1020=1
    fi
    ret_has_cmd354_v0="${found_1020}"
    return 0
}

# echo_error exits the process (default exit_code=1), so no fail needed.
# extract_extension_id(url: Text)
extract_extension_id__358_v0() {
    local url_1005="${1}"
    replace_regex__3_v0 "${url_1005}" "^https?://[^/]+/.+/([^/]+)\$" "" 1
    local ret_replace_regex3_v0__8_8="${ret_replace_regex3_v0}"
    if [ "$([ "_${ret_replace_regex3_v0__8_8}" != "_${url_1005}" ]; echo $?)" != 0 ]; then
        echo_error__142_v0 "malformed extension url: ${url_1005}" 1
    fi
    replace_regex__3_v0 "${url_1005}" "^.*/([^/]+)\$" "\\1" 1
    ret_extract_extension_id358_v0="${ret_replace_regex3_v0}"
    return 0
}

# install_chrome_extension(url: Text)
install_chrome_extension__359_v0() {
    local url_1004="${1}"
    prompt_user__171_v0 "install chrome extension from ${url_1004}"
    local ret_prompt_user171_v0__15_12="${ret_prompt_user171_v0}"
    if [ "$(( ! ret_prompt_user171_v0__15_12 ))" != 0 ]; then
        ret_install_chrome_extension359_v0=''
        return 0
    fi
    extract_extension_id__358_v0 "${url_1004}"
    local id_1015="${ret_extract_extension_id358_v0}"
    url_status__309_v0 "${url_1004}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_chrome_extension359_v0=''
        return "${__status}"
    fi
    local http_code_1017="${ret_url_status309_v0}"
    if [ "$([ "_${http_code_1017}" == "_200" ]; echo $?)" != 0 ]; then
        echo_error__142_v0 "extension url returned HTTP ${http_code_1017} (expected 200): ${url_1004}" 1
    fi
    local dir_1018="/etc/opt/chrome/policies/managed"
    has_cmd__354_v0 "sudo"
    local ret_has_cmd354_v0__24_8="${ret_has_cmd354_v0}"
    if [ "${ret_has_cmd354_v0__24_8}" != 0 ]; then
        sudo mkdir -p ${dir_1018}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_install_chrome_extension359_v0=''
            return "${__status}"
        fi
        sudo chmod 755 /etc/opt/chrome
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_install_chrome_extension359_v0=''
            return "${__status}"
        fi
        sudo sh -c "printf '\x7b\"ExtensionInstallForcelist\":[\"%s;https://clients2.google.com/service/update2/crx\"]\x7d
' ${id_1015} > ${dir_1018}/vimium.json"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_install_chrome_extension359_v0=''
            return "${__status}"
        fi
    else
        mkdir -p ${dir_1018}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_install_chrome_extension359_v0=''
            return "${__status}"
        fi
        chmod 755 /etc/opt/chrome
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_install_chrome_extension359_v0=''
            return "${__status}"
        fi
        printf '\x7b"ExtensionInstallForcelist":["%s;https://clients2.google.com/service/update2/crx"]\x7d
' ${id_1015} > ${dir_1018}/vimium.json
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_install_chrome_extension359_v0=''
            return "${__status}"
        fi
    fi
}

# install_chrome_extension_or_die(url: Text)
install_chrome_extension_or_die__360_v0() {
    local url_1003="${1}"
    install_chrome_extension__359_v0 "${url_1003}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to install chrome extension ${url_1003}" 1
    fi
}

__VIMIUM_URL_41="https://chromewebstore.google.com/detail/vimium/dbepggeogbaibhgnhhndojpepiihcmeb"
# install_browsers()
install_browsers__362_v0() {
    has_cmd__243_v0 "google-chrome-stable"
    local ret_has_cmd243_v0__14_12="${ret_has_cmd243_v0}"
    if [ "$(( ! ret_has_cmd243_v0__14_12 ))" != 0 ]; then
        install_deb_url_or_die__347_v0 "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    fi
    install_chrome_extension_or_die__360_v0 "${__VIMIUM_URL_41}"
}

# TODO cleanup this file... too bashish
# Source brew's shellenv so `brew` is on PATH after a same-session install.
# On container overlay filesystems brew lock filenames can exceed NAME_MAX;
# symlink the locks dir to /tmp to keep them short.
# install_via_curl(url: Text)
install_via_curl__384_v0() {
    local url_1036="${1}"
    NONINTERACTIVE=1 curl -fsSL ${url_1036} | bash
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_via_curl384_v0=''
        return "${__status}"
    fi
}

was_updated_42=0
# update()
update__393_v0() {
    local array_51=()
    sudo_cmd__168_v0 "apt-get update" array_51[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_update393_v0=''
        return "${__status}"
    fi
}

# ensure_updated()
ensure_updated__394_v0() {
    if [ "$(( ! was_updated_42 ))" != 0 ]; then
        update__393_v0 
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_ensure_updated394_v0=''
            return "${__status}"
        fi
        was_updated_42=1
    fi
}

# apt_install(packages: [Text])
apt_install__395_v0() {
    local packages_1039=("${!1}")
    prompt_user__171_v0 "apt install: ${packages_1039[@]}"
    local ret_prompt_user171_v0__18_12="${ret_prompt_user171_v0}"
    if [ "$(( ! ret_prompt_user171_v0__18_12 ))" != 0 ]; then
        ret_apt_install395_v0=''
        return 0
    fi
    ensure_updated__394_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_apt_install395_v0=''
        return "${__status}"
    fi
    join__7_v0 packages_1039[@] " "
    local pkgs_1040="${ret_join7_v0}"
    local array_52=("DEBIAN_FRONTEND=noninteractive")
    sudo_cmd__168_v1 "apt-get install -y --no-install-recommends ${pkgs_1040}" array_52[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_apt_install395_v0=''
        return "${__status}"
    fi
}

# install_via_npm(packages: [Text])
install_via_npm__399_v0() {
    local packages_1038=("${!1}")
    has_cmd__354_v0 "npm"
    local ret_has_cmd354_v0__7_12="${ret_has_cmd354_v0}"
    if [ "$(( ! ret_has_cmd354_v0__7_12 ))" != 0 ]; then
        local array_53=("npm")
        apt_install__395_v0 array_53[@]
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_install_via_npm399_v0=''
            return "${__status}"
        fi
    fi
    local array_54=()
    sudo_cmd__168_v0 "npm install -g ${packages_1038[@]}" array_54[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_via_npm399_v0=''
        return "${__status}"
    fi
}

# install_via_npm_or_die(packages: [Text])
install_via_npm_or_die__400_v0() {
    local packages_1037=("${!1}")
    install_via_npm__399_v0 packages_1037[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to npm install ${packages_1037[@]}" 1
    fi
}

# install_ai_tools()
install_ai_tools__402_v0() {
    install_via_curl__384_v0 "https://antigravity.google/cli/install.sh"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "skipping agy" 1
    fi
    local array_55=("@kilocode/cli")
    install_via_npm_or_die__400_v0 array_55[@]
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
install_quicksheet__404_v0() {
    :
}

# install_nvim()
install_nvim__409_v0() {
    local array_56=("fd-find" "clang" "g++")
    apt_install_or_die__176_v0 array_56[@]
    local subpath_1067=".config/nvim"
    symlink_into_home_or_die__265_v0 "src/${subpath_1067}" "${subpath_1067}"
    local lazy_dir_1068="${subpath_1067}/lazy"
    symlink_into_home_or_die__265_v0 "src/${lazy_dir_1068}" ".local/share/nvim/lazy"
    # quicksheet reads ~/.config/quicksheet.txt; the data ships from the nvim
    # repo as ~/.config/nvim/quicksheet.txt. Symlink it so quicksheet finds it.
    symlink_at_home_or_die__267_v0 ".config/nvim/quicksheet.txt" ".config/quicksheet.txt"
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
download_verified_url_to_home__428_v0() {
    local url_1154="${1}"
    local rel_path_1155="${2}"
    local expected_hash_1156="${3}"
    home__179_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_url_to_home428_v0=''
        return "${__status}"
    fi
    local h_1157="${ret_home179_v0}"
    local full_1158="${h_1157}/${rel_path_1155}"
    local command_57
    command_57="$(dirname ${full_1158})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_url_to_home428_v0=''
        return "${__status}"
    fi
    local parent_1159="${command_57}"
    dir_create__44_v0 "${parent_1159}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_url_to_home428_v0=''
        return "${__status}"
    fi
    download_verified_url_to__310_v0 "${url_1154}" "${full_1158}" "${expected_hash_1156}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_url_to_home428_v0=''
        return "${__status}"
    fi
}

# download_verified_executable_to_home(url: Text, rel_path: Text, expected_hash: Text)
download_verified_executable_to_home__430_v0() {
    local url_1151="${1}"
    local rel_path_1152="${2}"
    local expected_hash_1153="${3}"
    download_verified_url_to_home__428_v0 "${url_1151}" "${rel_path_1152}" "${expected_hash_1153}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_executable_to_home430_v0=''
        return "${__status}"
    fi
    home__179_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_executable_to_home430_v0=''
        return "${__status}"
    fi
    local h_1164="${ret_home179_v0}"
    make_executable__280_v0 "${h_1164}/${rel_path_1152}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_executable_to_home430_v0=''
        return "${__status}"
    fi
}

# download_verified_executable_to_home_or_die(url: Text, rel_path: Text, expected_hash: Text)
download_verified_executable_to_home_or_die__431_v0() {
    local url_1148="${1}"
    local rel_path_1149="${2}"
    local expected_hash_1150="${3}"
    download_verified_executable_to_home__430_v0 "${url_1148}" "${rel_path_1149}" "${expected_hash_1150}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to download, verify, or make executable ${url_1148} to ~/${rel_path_1149}" 1
    fi
}

# install_tmux_warm_daemon()
install_tmux_warm_daemon__433_v0() {
    copy_into_home_or_die__187_v0 "src/.tmux_warm_daemon/attach_warm.sh" ".local/bin/"
    copy_into_home_or_die__187_v0 "src/.tmux_warm_daemon/restart_daemon.sh" ".local/bin/"
    copy_into_home_or_die__187_v0 "src/.tmux_warm_daemon/agent-warm.sh" ".local/bin/"
    copy_into_home_or_die__187_v0 "src/.tmux_warm_daemon/bootstrap-warm-daemon.sh" ".local/bin/"
    # Pool config: defines the `agent` pool so the daemon pre-warms agent
    # sessions (agent-N / agent@<hash>) instead of only `warm-*`. The agent
    # command is agent-warm.sh, which execs whatever `kv agentclitool` points
    # at — so no tool is hardcoded (see ~/.local/bin/agent-warm.sh).
    copy_into_home_or_die__187_v0 "src/.tmux_warm_daemon/config.yaml" ".config/tmux_warm_daemon/"
    rsync_or_die_into_home__218_v0 "src/.tmux_warm_daemon/" ".tmux_warm_daemon/" 1
    # Only fetch Rust binary when the bash backend was stripped during generation
    # (i.e. user chose impl: 'rust' or didn't set impl). When bash is present,
    # the backend-agnostic launcher will fall through to it.
    local command_58
    command_58="$(test -f ~/.tmux_warm_daemon/bash/tmux_warm_daemon && echo "yes" || echo "")"
    __status=$?
    local bash_present_1146="${command_58}"
    if [ "$([ "_${bash_present_1146}" != "_" ]; echo $?)" != 0 ]; then
        local rel_bin_1147=".tmux_warm_daemon/rust/target/release/tmux_warm_daemon"
        download_verified_executable_to_home_or_die__431_v0 "https://github.com/jesusmb1995/tmux-warm-daemon/releases/download/v0.1.0-prealpha/tmux_warm_daemon" "${rel_bin_1147}" "95a6727f495b4e3970084e20efe12e93427bb90b7dc7e8dac3605c7a5e48b902"
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
install_cmd_bookmarks__436_v0() {
    symlink_into_home_or_die__265_v0 "src/cmd_bookmarks" ".local/share/cmd_bookmarks"
}

# execute_sh_at_home(rel_sh_path: Text)
execute_sh_at_home__443_v0() {
    local rel_sh_path_1185="${1}"
    home__179_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_sh_at_home443_v0=''
        return "${__status}"
    fi
    local h_1186="${ret_home179_v0}"
    execute_sh__287_v0 "${h_1186}/${rel_sh_path_1185}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_sh_at_home443_v0=''
        return "${__status}"
    fi
}

# execute_sh_at_home_or_die(rel_sh_path: Text)
execute_sh_at_home_or_die__444_v0() {
    local rel_sh_path_1184="${1}"
    prompt_user__171_v0 "execute ~/${rel_sh_path_1184}"
    local ret_prompt_user171_v0__12_8="${ret_prompt_user171_v0}"
    if [ "${ret_prompt_user171_v0__12_8}" != 0 ]; then
        execute_sh_at_home__443_v0 "${rel_sh_path_1184}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "failed to run ${rel_sh_path_1184}" 1
        fi
    fi
}

# install_agent_global_config()
install_agent_global_config__449_v0() {
    rsync_or_die_into_home__218_v0 "src/.agent/" ".agent" 1
    home__198_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "install_agent_global_config: home unresolved" 1
        exit 1
    fi
    local h_1181="${ret_home198_v0}"
    local scripts_1182=("sync-permissions-from-cli.sh" "sync-permissions.sh" "sync-antigravity-permissions.sh" "sync-kilocode-permissions.sh")
    for script_1183 in "${scripts_1182[@]}"; do
        file_exists__39_v0 "${h_1181}/.agent/${script_1183}"
        local ret_file_exists39_v0__20_12="${ret_file_exists39_v0}"
        if [ "${ret_file_exists39_v0__20_12}" != 0 ]; then
            execute_sh_at_home_or_die__444_v0 ".agent/${script_1183}"
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
resolve_vendor_dir__457_v0() {
    dir_exists__38_v0 "${installed_vendor_45}"
    local ret_dir_exists38_v0__12_8="${ret_dir_exists38_v0}"
    file_exists__39_v0 "${installed_vendor_45}/jsonnet"
    local ret_file_exists39_v0__12_41="${ret_file_exists39_v0}"
    if [ "$(( ret_dir_exists38_v0__12_8 && ret_file_exists39_v0__12_41 ))" != 0 ]; then
        ret_resolve_vendor_dir457_v0="${installed_vendor_45}"
        return 0
    fi
    dir_exists__38_v0 "${project_vendor_44}"
    local ret_dir_exists38_v0__15_8="${ret_dir_exists38_v0}"
    file_exists__39_v0 "${project_vendor_44}/jsonnet"
    local ret_file_exists39_v0__15_39="${ret_file_exists39_v0}"
    if [ "$(( ret_dir_exists38_v0__15_8 && ret_file_exists39_v0__15_39 ))" != 0 ]; then
        ret_resolve_vendor_dir457_v0="${project_vendor_44}"
        return 0
    fi
    dir_exists__38_v0 "${installed_vendor_45}"
    local ret_dir_exists38_v0__18_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__18_8}" != 0 ]; then
        ret_resolve_vendor_dir457_v0="${installed_vendor_45}"
        return 0
    fi
    dir_exists__38_v0 "${project_vendor_44}"
    local ret_dir_exists38_v0__21_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__21_8}" != 0 ]; then
        ret_resolve_vendor_dir457_v0="${project_vendor_44}"
        return 0
    fi
    ret_resolve_vendor_dir457_v0=""
    return 0
}

resolve_vendor_dir__457_v0 
__VENDOR_DIR_46="${ret_resolve_vendor_dir457_v0}"
# jq_resolve()
jq_resolve__458_v0() {
    if [ "$([ "_${__VENDOR_DIR_46}" != "_" ]; echo $?)" != 0 ]; then
        ret_jq_resolve458_v0="jq"
        return 0
    fi
    ret_jq_resolve458_v0="${__VENDOR_DIR_46}/jq"
    return 0
}

# j2_resolve()
j2_resolve__459_v0() {
    if [ "$([ "_${__VENDOR_DIR_46}" != "_" ]; echo $?)" != 0 ]; then
        ret_j2_resolve459_v0="j2"
        return 0
    fi
    ret_j2_resolve459_v0="${__VENDOR_DIR_46}/j2"
    return 0
}

# jsonnet_resolve()
jsonnet_resolve__460_v0() {
    if [ "$([ "_${__VENDOR_DIR_46}" != "_" ]; echo $?)" != 0 ]; then
        ret_jsonnet_resolve460_v0="jsonnet"
        return 0
    fi
    ret_jsonnet_resolve460_v0="${__VENDOR_DIR_46}/jsonnet"
    return 0
}

# jsonschema_resolve()
jsonschema_resolve__461_v0() {
    if [ "$([ "_${__VENDOR_DIR_46}" != "_" ]; echo $?)" != 0 ]; then
        ret_jsonschema_resolve461_v0="jsonschema"
        return 0
    fi
    ret_jsonschema_resolve461_v0="${__VENDOR_DIR_46}/jsonschema"
    return 0
}

# lua_resolve()
lua_resolve__462_v0() {
    if [ "$([ "_${__VENDOR_DIR_46}" != "_" ]; echo $?)" != 0 ]; then
        ret_lua_resolve462_v0="lua"
        return 0
    fi
    ret_lua_resolve462_v0="${__VENDOR_DIR_46}/lua"
    return 0
}

jq_resolve__458_v0 
j2_resolve__459_v0 
jsonnet_resolve__460_v0 
jsonschema_resolve__461_v0 
lua_resolve__462_v0 
# link_store(link: Text, canon: Text)
link_store__481_v0() {
    local link_1218="${1}"
    local canon_1219="${2}"
    local target_1220="../.agents/skills"
    local command_63
    command_63="$(dirname ${link_1218})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_link_store481_v0=''
        return "${__status}"
    fi
    local dir_1221="${command_63}"
    dir_create__44_v0 "${dir_1221}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_link_store481_v0=''
        return "${__status}"
    fi
    local is_real_dir_1222=0
    [ ! -L ${link_1218} ] && [ -d ${link_1218} ]
    __status=$?
    if [ "${__status}" = 0 ]; then
        is_real_dir_1222=1
    fi
    if [ "${is_real_dir_1222}" != 0 ]; then
        local __cp_64=
        (( 1 )) && __cp_64="-f" || __cp_64=""
        cp -r ${__cp_64} "${link_1218}" "${canon_1219}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_link_store481_v0=''
            return "${__status}"
        fi
        local __rm_65=
        (( 1 )) && __rm_65="-r" || __rm_65=""
        local __rm_66=
        rm ${__rm_66} ${__rm_65} "${link_1218}"
        ln -sfn ${target_1220} ${link_1218}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_link_store481_v0=''
            return "${__status}"
        fi
    else
        local exists_plain_1223=0
        [ -e ${link_1218} ] && [ ! -L ${link_1218} ]
        __status=$?
        if [ "${__status}" = 0 ]; then
            exists_plain_1223=1
        fi
        if [ "$(( ! exists_plain_1223 ))" != 0 ]; then
            ln -sfn ${target_1220} ${link_1218}
            __status=$?
            if [ "${__status}" != 0 ]; then
                ret_link_store481_v0=''
                return "${__status}"
            fi
        fi
    fi
}

# install_agent_skills_impl()
install_agent_skills_impl__483_v0() {
    home__198_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_agent_skills_impl483_v0=''
        return "${__status}"
    fi
    local h_1214="${ret_home198_v0}"
    local canon_1215="${h_1214}/.agents/skills"
    local skills_src_1216="src/agent-skills/.agents/skills"
    rsync_or_die_into_home__218_v0 "${skills_src_1216}/" ".agents/skills" 0
    dir_exists__38_v0 "${canon_1215}"
    local ret_dir_exists38_v0__49_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__49_8}" != 0 ]; then
        local legacy_dir_1217="${h_1214}/.cursor/skills-cursor"
        dir_exists__38_v0 "${legacy_dir_1217}"
        local ret_dir_exists38_v0__51_12="${ret_dir_exists38_v0}"
        if [ "${ret_dir_exists38_v0__51_12}" != 0 ]; then
            local __rm_67=
            (( 1 )) && __rm_67="-r" || __rm_67=""
            local __rm_68=
            rm ${__rm_68} ${__rm_67} "${legacy_dir_1217}"
        fi
        # 2. Wire the store into each ENABLED tool. Antigravity reads ~/.agents/skills natively, so it needs no link.
        link_store__481_v0 "${h_1214}/.kilo/skills" "${canon_1215}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_install_agent_skills_impl483_v0=''
            return "${__status}"
        fi
    fi
}

# install_agent_skills()
install_agent_skills__484_v0() {
    install_agent_skills_impl__483_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to install agent skills" 1
    fi
}

# install_skill_caveman()
install_skill_caveman__487_v0() {
    symlink_into_home_or_die__265_v0 "src/.agents/skills/caveman" ".agents/skills/caveman"
}

# install_skill_humanizer()
install_skill_humanizer__490_v0() {
    symlink_into_home_or_die__265_v0 "src/.agents/skills/humanizer" ".agents/skills/humanizer"
}

# install_skill_ponytail()
install_skill_ponytail__493_v0() {
    symlink_into_home_or_die__265_v0 "src/.agents/skills/ponytail" ".agents/skills/ponytail"
}

temp_dir_create__46_v0 "amber-XXXXXX" 1 1
__status=$?
if [ "${__status}" != 0 ]; then
    :
fi
__TMP_DIR_53="${ret_temp_dir_create46_v0}"
token_54=1
# temp_file_create(suffix: Text)
temp_file_create__500_v0() {
    local suffix_1243="${1}"
    token_54="$(( token_54 + 1 ))"
    local tmp_1244="${__TMP_DIR_53}/${token_54}${suffix_1243}"
    touch "${tmp_1244}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_temp_file_create500_v0=''
        return "${__status}"
    fi
    ret_temp_file_create500_v0="${tmp_1244}"
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
download_to__503_v0() {
    local url_1249="${1}"
    local target_1250="${2}"
    curl -fsSL ${url_1249} -o ${target_1250}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_to503_v0=''
        return "${__status}"
    fi
}

# download_verified_url_to(url: Text, target: Text, expected_hash: Text)
download_verified_url_to__506_v0() {
    local url_1246="${1}"
    local target_1247="${2}"
    local expected_hash_1248="${3}"
    download_to__503_v0 "${url_1246}" "${target_1247}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_url_to506_v0=''
        return 0
    fi
    local command_69
    command_69="$(sha256sum ${target_1247} | cut -d' ' -f1)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_url_to506_v0=''
        return "${__status}"
    fi
    local actual_1251="${command_69}"
    if [ "$([ "_${actual_1251}" == "_${expected_hash_1248}" ]; echo $?)" != 0 ]; then
        echo_error__142_v0 "sha256 mismatch for ${target_1247}: expected ${expected_hash_1248}, got ${actual_1251}" 1
        rm -f ${target_1247}
        __status=$?
        ret_download_verified_url_to506_v0=''
        return 0
    fi
}

__BAZELISK_URL_55="https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64"
__BAZELISK_HASH_56="5a408715e932c0250d28bd84555f12edbf70117de42f9181691c736eacc4a992"
# install_bazelisk()
install_bazelisk__511_v0() {
    has_cmd__243_v0 "bazelisk"
    local ret_has_cmd243_v0__11_12="${ret_has_cmd243_v0}"
    if [ "$(( ! ret_has_cmd243_v0__11_12 ))" != 0 ]; then
        temp_file_create__500_v0 ""
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "bazelisk: failed to create temp file" 1
        fi
        local tmp_1245="${ret_temp_file_create500_v0}"
        download_verified_url_to__506_v0 "${__BAZELISK_URL_55}" "${tmp_1245}" "${__BAZELISK_HASH_56}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "bazelisk: sha256 mismatch, expected ${__BAZELISK_HASH_56}" 1
        fi
        local array_70=()
        sudo_cmd__240_v0 "install -m755 ${tmp_1245} /usr/local/bin/bazelisk" array_70[@]
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
print_help__513_v0() {
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
run_step__514_v0() {
    local step_1334="${1}"
    local matched_1335=0
    if [ "$([ "_${step_1334}" != "_help" ]; echo $?)" != 0 ]; then
        print_help__513_v0 
        matched_1335=1
    fi
    if [ "$([ "_${step_1334}" != "_apt_essential_tools" ]; echo $?)" != 0 ]; then
        install_apt_essential_tools__204_v0 
        matched_1335=1
    fi
    if [ "$([ "_${step_1334}" != "_apt_essential_ui" ]; echo $?)" != 0 ]; then
        install_apt_essential_ui__207_v0 
        matched_1335=1
    fi
    if [ "$([ "_${step_1334}" != "_dotfiles_essential" ]; echo $?)" != 0 ]; then
        install_dotfiles_essential__222_v0 
        matched_1335=1
    fi
    if [ "$([ "_${step_1334}" != "_dotfiles_personalization" ]; echo $?)" != 0 ]; then
        install_dotfiles_personalization__232_v0 
        matched_1335=1
    fi
    if [ "$([ "_${step_1334}" != "_st" ]; echo $?)" != 0 ]; then
        install_st__252_v0 
        matched_1335=1
    fi
    if [ "$([ "_${step_1334}" != "_nerd_fonts" ]; echo $?)" != 0 ]; then
        install_nerd_fonts__269_v0 
        matched_1335=1
    fi
    if [ "$([ "_${step_1334}" != "_rofi" ]; echo $?)" != 0 ]; then
        install_rofi__273_v0 
        matched_1335=1
    fi
    if [ "$([ "_${step_1334}" != "_omz_config" ]; echo $?)" != 0 ]; then
        install_omz_config__282_v0 
        matched_1335=1
    fi
    if [ "$([ "_${step_1334}" != "_zshmarks" ]; echo $?)" != 0 ]; then
        install_zshmarks__294_v0 
        matched_1335=1
    fi
    if [ "$([ "_${step_1334}" != "_system_tools" ]; echo $?)" != 0 ]; then
        install_system_tools__336_v0 
        matched_1335=1
    fi
    if [ "$([ "_${step_1334}" != "_browsers" ]; echo $?)" != 0 ]; then
        install_browsers__362_v0 
        matched_1335=1
    fi
    if [ "$([ "_${step_1334}" != "_ai_tools" ]; echo $?)" != 0 ]; then
        install_ai_tools__402_v0 
        matched_1335=1
    fi
    if [ "$([ "_${step_1334}" != "_quicksheet" ]; echo $?)" != 0 ]; then
        install_quicksheet__404_v0 
        matched_1335=1
    fi
    if [ "$([ "_${step_1334}" != "_nvim" ]; echo $?)" != 0 ]; then
        install_nvim__409_v0 
        matched_1335=1
    fi
    if [ "$([ "_${step_1334}" != "_tmux_warm_daemon" ]; echo $?)" != 0 ]; then
        install_tmux_warm_daemon__433_v0 
        matched_1335=1
    fi
    if [ "$([ "_${step_1334}" != "_cmd_bookmarks" ]; echo $?)" != 0 ]; then
        install_cmd_bookmarks__436_v0 
        matched_1335=1
    fi
    if [ "$([ "_${step_1334}" != "_agent_global_config" ]; echo $?)" != 0 ]; then
        install_agent_global_config__449_v0 
        matched_1335=1
    fi
    if [ "$([ "_${step_1334}" != "_agent_skills" ]; echo $?)" != 0 ]; then
        install_agent_skills__484_v0 
        matched_1335=1
    fi
    if [ "$([ "_${step_1334}" != "_skill_caveman" ]; echo $?)" != 0 ]; then
        install_skill_caveman__487_v0 
        matched_1335=1
    fi
    if [ "$([ "_${step_1334}" != "_skill_humanizer" ]; echo $?)" != 0 ]; then
        install_skill_humanizer__490_v0 
        matched_1335=1
    fi
    if [ "$([ "_${step_1334}" != "_skill_ponytail" ]; echo $?)" != 0 ]; then
        install_skill_ponytail__493_v0 
        matched_1335=1
    fi
    if [ "$([ "_${step_1334}" != "_bazelisk" ]; echo $?)" != 0 ]; then
        install_bazelisk__511_v0 
        matched_1335=1
    fi
    if [ "$(( ! matched_1335 ))" != 0 ]; then
        echo "Unknown step: '${step_1334}'"
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
cmd_update__515_v0() {
    local command_72
    command_72="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_cmd_update515_v0=''
        return "${__status}"
    fi
    local script_dir_1305="${command_72}"
    local meta_path_1306="${script_dir_1305}/meta.json"
    local state_path_1307="${script_dir_1305}/.last_installed.json"
    local command_73
    command_73="$(jq -r '.repo_hashes | to_entries[] | "\(.key)	\(.value)"' "${meta_path_1306}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_cmd_update515_v0=''
        return "${__status}"
    fi
    local new_lines_1308="${command_73}"
    local old_lines_1309=""
    file_exists__39_v0 "${state_path_1307}"
    local ret_file_exists39_v0__473_8="${ret_file_exists39_v0}"
    if [ "${ret_file_exists39_v0__473_8}" != 0 ]; then
        local command_74
        command_74="$(jq -r '.repo_hashes | to_entries[] | "\(.key)	\(.value)"' "${state_path_1307}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_cmd_update515_v0=''
            return "${__status}"
        fi
        old_lines_1309="${command_74}"
    fi
    local old_keys_1310=()
    local old_vals_1311=()
    if [ "$([ "_${old_lines_1309}" == "_" ]; echo $?)" != 0 ]; then
        split_lines__5_v0 "${old_lines_1309}"
        local rows_1316=("${ret_split_lines5_v0[@]}")
        for row_1317 in "${rows_1316[@]}"; do
            if [ "$([ "_${row_1317}" != "_" ]; echo $?)" != 0 ]; then
                continue
            fi
            split__4_v0 "	" "${row_1317}"
            local parts_1318=("${ret_split4_v0[@]}")
            local __length_79=("${parts_1318[@]}")
            if [ "$(( ${#__length_79[@]} >= 2 ))" != 0 ]; then
                old_keys_1310+=("${parts_1318[0]?"Index out of bounds (at /tmp/jbtd-install-build-P8pY09/install.ab:485:36)"}")
                old_vals_1311+=("${parts_1318[1]?"Index out of bounds (at /tmp/jbtd-install-build-P8pY09/install.ab:486:36)"}")
            fi
        done
    fi
    local changed_1319=()
    split_lines__5_v0 "${new_lines_1308}"
    local new_rows_1320=("${ret_split_lines5_v0[@]}")
    for row_1321 in "${new_rows_1320[@]}"; do
        if [ "$([ "_${row_1321}" != "_" ]; echo $?)" != 0 ]; then
            continue
        fi
        split__4_v0 "	" "${row_1321}"
        local parts_1322=("${ret_split4_v0[@]}")
        local __length_85=("${parts_1322[@]}")
        if [ "$(( ${#__length_85[@]} < 2 ))" != 0 ]; then
            continue
        fi
        local key_1323="${parts_1322[0]?"Index out of bounds (at /tmp/jbtd-install-build-P8pY09/install.ab:497:27)"}"
        local val_1324="${parts_1322[1]?"Index out of bounds (at /tmp/jbtd-install-build-P8pY09/install.ab:498:27)"}"
        local matched_1325=0
        local __range_start_1326=0
        local __length_86=("${old_keys_1310[@]}")
        local __range_end_1326="${#__length_86[@]}"
        local __dir_1326=$(( ${__range_start_1326} <= ${__range_end_1326} ? 1 : -1 ))
        for (( i_1326=${__range_start_1326}; i_1326 * ${__dir_1326} < ${__range_end_1326} * ${__dir_1326}; i_1326+=${__dir_1326} )); do
            if [ "$([ "_${old_keys_1310[${i_1326}]?"Index out of bounds (at /tmp/jbtd-install-build-P8pY09/install.ab:501:25)"}" != "_${key_1323}" ]; echo $?)" != 0 ]; then
                if [ "$([ "_${old_vals_1311[${i_1326}]?"Index out of bounds (at /tmp/jbtd-install-build-P8pY09/install.ab:502:29)"}" == "_${val_1324}" ]; echo $?)" != 0 ]; then
                    local array_87=("${key_1323}")
                    changed_1319+=("${array_87[@]}")
                fi
                matched_1325=1
                break
            fi
done
        if [ "$(( ! matched_1325 ))" != 0 ]; then
            changed_1319+=("${key_1323}")
        fi
    done
    for ok_1327 in "${old_keys_1310[@]}"; do
        local found_1328=0
        for row_1329 in "${new_rows_1320[@]}"; do
            if [ "$([ "_${row_1329}" != "_" ]; echo $?)" != 0 ]; then
                continue
            fi
            split__4_v0 "	" "${row_1329}"
            local parts_1330=("${ret_split4_v0[@]}")
            local __length_93=("${parts_1330[@]}")
            if [ "$(( $(( ${#__length_93[@]} >= 2 )) && $([ "_${parts_1330[0]?"Index out of bounds (at /tmp/jbtd-install-build-P8pY09/install.ab:519:42)"}" != "_${ok_1327}" ]; echo $?) ))" != 0 ]; then
                found_1328=1
                break
            fi
        done
        if [ "$(( ! found_1328 ))" != 0 ]; then
            changed_1319+=("${ok_1327}")
        fi
    done
    local __length_95=("${changed_1319[@]}")
    if [ "$(( ${#__length_95[@]} == 0 ))" != 0 ]; then
        echo "update: all repos up to date"
        ret_cmd_update515_v0=''
        return 0
    fi
    local __length_96=("${changed_1319[@]}")
    echo "update: ${#__length_96[@]} repo(s) changed:"
    for c_1331 in "${changed_1319[@]}"; do
        echo "  - ${c_1331}"
    done
    echo "Apply updates? [Y/n]"
    local command_99
    command_99="$(read -r line < /dev/tty 2>/dev/null; printf "%s" "$line")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_cmd_update515_v0=''
        return "${__status}"
    fi
    local ans_1332="${command_99}"
    if [ "$(( $(( $(( $([ "_${ans_1332}" != "_n" ]; echo $?) || $([ "_${ans_1332}" != "_N" ]; echo $?) )) || $([ "_${ans_1332}" != "_no" ]; echo $?) )) || $([ "_${ans_1332}" != "_NO" ]; echo $?) ))" != 0 ]; then
        echo "update: aborted"
        ret_cmd_update515_v0=''
        return 0
    fi
    for c_1333 in "${changed_1319[@]}"; do
        run_step__514_v0 "${c_1333}"
    done
    cp "${meta_path_1306}" "${state_path_1307}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_cmd_update515_v0=''
        return "${__status}"
    fi
    echo "update: done"
}

typeset -r raw_args_58=("$0" "$@")
__length_104=("${raw_args_58[@]}")
slice_upper_103="${#__length_104[@]}"
slice_offset_105=1
slice_offset_105=$((${slice_offset_105} > 0 ? ${slice_offset_105} : 0))
slice_length_106="$(( slice_upper_103 - slice_offset_105 ))"
slice_length_106=$((${slice_length_106} > 0 ? ${slice_length_106} : 0))
args_59=("${raw_args_58[@]:${slice_offset_105}:${slice_length_106}}")
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
__length_111=("${step_args_60[@]}")
if [ "$(( ${#__length_111[@]} == 0 ))" != 0 ]; then
    install_apt_essential_tools__204_v0 
    install_apt_essential_ui__207_v0 
    install_dotfiles_essential__222_v0 
    install_dotfiles_personalization__232_v0 
    install_st__252_v0 
    install_nerd_fonts__269_v0 
    install_rofi__273_v0 
    install_omz_config__282_v0 
    install_zshmarks__294_v0 
    install_system_tools__336_v0 
    install_browsers__362_v0 
    install_ai_tools__402_v0 
    install_quicksheet__404_v0 
    install_nvim__409_v0 
    install_tmux_warm_daemon__433_v0 
    install_cmd_bookmarks__436_v0 
    install_agent_global_config__449_v0 
    install_agent_skills__484_v0 
    install_skill_caveman__487_v0 
    install_skill_humanizer__490_v0 
    install_skill_ponytail__493_v0 
    install_bazelisk__511_v0 
fi
__length_112=("${step_args_60[@]}")
if [ "$(( ${#__length_112[@]} >= 1 ))" != 0 ]; then
    if [ "$([ "_${step_args_60[0]?"Index out of bounds (at /tmp/jbtd-install-build-P8pY09/install.ab:662:22)"}" != "_update" ]; echo $?)" != 0 ]; then
        __length_113=("${step_args_60[@]}")
        if [ "$(( ${#__length_113[@]} == 1 ))" != 0 ]; then
            cmd_update__515_v0 
            __status=$?
            if [ "${__status}" != 0 ]; then
                exit "${__status}"
            fi
        fi
    else
        for step_1336 in "${step_args_60[@]}"; do
            run_step__514_v0 "${step_1336}"
        done
    fi
fi
