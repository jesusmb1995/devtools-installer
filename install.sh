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
    local source_77="${1}"
    local search_78="${2}"
    local replace_79="${3}"
    # Here we use a command to avoid #646
    local result_80=""
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
        result_80="${source_77//"${search_78}"/"${replace_79}"}"
        __status=$?
    else
        result_80="${source_77//"${search_78}"/${replace_79}}"
        __status=$?
    fi
    ret_replace0_v0="${result_80}"
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
    local source_72="${1}"
    local search_73="${2}"
    local replace_text_74="${3}"
    local extended_75="${4}"
    sed_version__2_v0 
    local sed_version_76="${ret_sed_version2_v0}"
    replace__0_v0 "${search_73}" "/" "\\/"
    search_73="${ret_replace0_v0}"
    replace__0_v0 "${replace_text_74}" "/" "\\/"
    replace_text_74="${ret_replace0_v0}"
    if [ "$(( $(( sed_version_76 == __SED_VERSION_GNU_1 )) || $(( sed_version_76 == __SED_VERSION_BUSYBOX_2 )) ))" != 0 ]; then
        # '\b' is supported but not in POSIX standards. Disable it
        replace__0_v0 "${search_73}" "\\b" "\\\\b"
        search_73="${ret_replace0_v0}"
    fi
    if [ "${extended_75}" != 0 ]; then
        # GNU sed versions 4.0 through 4.2 support extended regex syntax,
        # but only via the "-r" option
        if [ "$(( sed_version_76 == __SED_VERSION_GNU_1 ))" != 0 ]; then
            local command_1
            command_1="$(sed -r -e "s/${search_73}/${replace_text_74}/g" <<<"${source_72}")"
            __status=$?
            ret_replace_regex3_v0="${command_1}"
            return 0
        else
            local command_2
            command_2="$(sed -E -e "s/${search_73}/${replace_text_74}/g" <<<"${source_72}")"
            __status=$?
            ret_replace_regex3_v0="${command_2}"
            return 0
        fi
    else
        if [ "$(( $(( sed_version_76 == __SED_VERSION_GNU_1 )) || $(( sed_version_76 == __SED_VERSION_BUSYBOX_2 )) ))" != 0 ]; then
            # GNU Sed BRE handle \| as a metacharacter, but it is not POSIX standands. Disable it
            replace__0_v0 "${search_73}" "\\|" "|"
            search_73="${ret_replace0_v0}"
        fi
        local command_3
        command_3="$(sed -e "s/${search_73}/${replace_text_74}/g" <<<"${source_72}")"
        __status=$?
        ret_replace_regex3_v0="${command_3}"
        return 0
    fi
}

# split(text: Text, delimiter: Text)
split__4_v0() {
    local text_806="${1}"
    local delimiter_807="${2}"
    local result_808=()
    # zsh uses -A for array, bash uses -a, ksh is VERY bad at splitting anything
    if [ "$([ "_${EXEC_SHELL}" != "_zsh" ]; echo $?)" != 0 ]; then
        IFS="${delimiter_807}" read -rd '' -A result_808 < <(printf %s "$text_806")
        __status=$?
    elif [ "$([ "_${EXEC_SHELL}" != "_ksh" ]; echo $?)" != 0 ]; then
        if [ "$([ "_${delimiter_807}" != "_
" ]; echo $?)" != 0 ]; then
            while read -r -d $'\n'; do result_808+=("$REPLY"); done < <(echo "$text_806")
            __status=$?
        else
            IFS="${delimiter_807}" read -rd '' -a result_808 < <(printf %s "$text_806")
            __status=$?
        fi
    elif [ "$([ "_${EXEC_SHELL}" != "_bash" ]; echo $?)" != 0 ]; then
        IFS="${delimiter_807}" read -rd '' -a result_808 < <(printf %s "$text_806")
        __status=$?
    fi
    ret_split4_v0=("${result_808[@]}")
    return 0
}

# split_lines(text: Text)
split_lines__5_v0() {
    local text_805="${1}"
    split__4_v0 "${text_805}" "
"
    ret_split_lines5_v0=("${ret_split4_v0[@]}")
    return 0
}

# join(list: [Text], delimiter: Text)
join__7_v0() {
    local list_402=("${!1}")
    local delimiter_403="${2}"
    local command_5
    command_5="$(IFS="${delimiter_403}" ; printf "%s
" "${list_402[*]}")"
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
    local path_89="${1}"
    [ -d "${path_89}" ]
    __status=$?
    ret_dir_exists38_v0="$(( __status == 0 ))"
    return 0
}

# file_exists(path: Text)
file_exists__39_v0() {
    local path_70="${1}"
    [ -f "${path_70}" ]
    __status=$?
    ret_file_exists39_v0="$(( __status == 0 ))"
    return 0
}

# file_write(path: Text, content: Text)
file_write__41_v0() {
    local path_430="${1}"
    local content_431="${2}"
    local command_6
    command_6="$(printf '%s
' "${content_431}" > "${path_430}")"
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
    local path_423="${1}"
    dir_exists__38_v0 "${path_423}"
    local ret_dir_exists38_v0__87_12="${ret_dir_exists38_v0}"
    if [ "$(( ! ret_dir_exists38_v0__87_12 ))" != 0 ]; then
        mkdir -p "${path_423}"
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
    local name_395="${1}"
    if [ "$([ "_${EXEC_SHELL}" != "_bash" ]; echo $?)" != 0 ]; then
        local command_9
        command_9="$(printf "%s
" "${!name_395}")"
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
" "${(P)name_395}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_env_var_get124_v0=''
            return "${__status}"
        fi
        ret_env_var_get124_v0="${command_10}"
        return 0
    elif [ "$([ "_${EXEC_SHELL}" != "_ksh" ]; echo $?)" != 0 ]; then
        local command_11
        command_11="$(eval "echo \${$name_395}")"
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
    local format_409="${1}"
    local args_410=("${!2}")
    args_410=("${format_409}" "${args_410[@]}")
    __status=$?
    printf "${args_410[@]}"
    __status=$?
}

# echo_warning(message: Text)
echo_warning__141_v0() {
    local message_415="${1}"
    local array_12=("${message_415}")
    printf__132_v0 "\\x1b[1;3;97;43m%s\\x1b[0m
" array_12[@]
}

# echo_error(message: Text, exit_code: Int)
echo_error__142_v0() {
    local message_407="${1}"
    local exit_code_408="${2}"
    local array_13=("${message_407}")
    printf__132_v0 "\\x1b[1;3;97;41m%s\\x1b[0m
" array_13[@]
    if [ "$(( exit_code_408 > 0 ))" != 0 ]; then
        exit "${exit_code_408}"
    fi
}

# has_cmd(cmd: Text)
has_cmd__165_v0() {
    local cmd_400="${1}"
    local found_401=0
    command -v ${cmd_400} >/dev/null 2>&1
    __status=$?
    if [ "${__status}" = 0 ]; then
        found_401=1
    fi
    ret_has_cmd165_v0="${found_401}"
    return 0
}

# echo_error exits the process (default exit_code=1), so no fail needed.
# sudo_cmd(cmd: Text, envvar: [])
sudo_cmd__169_v0() {
    local cmd_398="${1}"
    local envvar_399=("${!2}")
    has_cmd__165_v0 "sudo"
    local ret_has_cmd165_v0__4_8="${ret_has_cmd165_v0}"
    if [ "${ret_has_cmd165_v0__4_8}" != 0 ]; then
        sudo ${envvar_399[@]} ${cmd_398}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd169_v0=''
            return "${__status}"
        fi
    else
        env ${envvar_399[@]} ${cmd_398}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd169_v0=''
            return "${__status}"
        fi
    fi
}

# sudo_cmd(cmd: Text, envvar: [Text])
sudo_cmd__169_v1() {
    local cmd_405="${1}"
    local envvar_406=("${!2}")
    has_cmd__165_v0 "sudo"
    local ret_has_cmd165_v0__4_8="${ret_has_cmd165_v0}"
    if [ "${ret_has_cmd165_v0__4_8}" != 0 ]; then
        sudo ${envvar_406[@]} ${cmd_405}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd169_v1=''
            return "${__status}"
        fi
    else
        env ${envvar_406[@]} ${cmd_405}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd169_v1=''
            return "${__status}"
        fi
    fi
}

# prompt_user(description: Text)
prompt_user__172_v0() {
    local description_394="${1}"
    env_var_get__124_v0 "COPALS_ASK"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_prompt_user172_v0=1
        return 0
    fi
    local ask_396="${ret_env_var_get124_v0}"
    if [ "$([ "_${ask_396}" != "_" ]; echo $?)" != 0 ]; then
        ret_prompt_user172_v0=1
        return 0
    fi
    echo "install: ${description_394}"
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
    local ans_397="${command_14}"
    if [ "$([ "_${ans_397}" != "_" ]; echo $?)" != 0 ]; then
        ret_prompt_user172_v0=1
        return 0
    fi
    if [ "$(( $(( $(( $(( $([ "_${ans_397}" != "_n" ]; echo $?) || $([ "_${ans_397}" != "_N" ]; echo $?) )) || $([ "_${ans_397}" != "_no" ]; echo $?) )) || $([ "_${ans_397}" != "_NO" ]; echo $?) )) || $([ "_${ans_397}" != "_No" ]; echo $?) ))" != 0 ]; then
        echo "skipping"
        ret_prompt_user172_v0=0
        return 0
    fi
    ret_prompt_user172_v0=1
    return 0
}

# has_cmd(cmd: Text)
has_cmd__175_v0() {
    local cmd_413="${1}"
    local found_414=0
    command -v ${cmd_413} >/dev/null 2>&1
    __status=$?
    if [ "${__status}" = 0 ]; then
        found_414=1
    fi
    ret_has_cmd175_v0="${found_414}"
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
    local packages_393=("${!1}")
    prompt_user__172_v0 "apt install: ${packages_393[@]}"
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
    join__7_v0 packages_393[@] " "
    local pkgs_404="${ret_join7_v0}"
    local array_16=("DEBIAN_FRONTEND=noninteractive")
    sudo_cmd__169_v1 "apt-get install -y --no-install-recommends ${pkgs_404}" array_16[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_apt_install181_v0=''
        return "${__status}"
    fi
}

# apt_install_or_die(packages: [Text])
apt_install_or_die__182_v0() {
    local packages_392=("${!1}")
    apt_install__181_v0 packages_392[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to apt install ${packages_392[@]}" 1
    fi
}

# Non-fatal variant of apt_install_or_die: on failure it prints a warning and
# continues instead of exiting. Use for optional packages that may be absent
# from the target distro (e.g. jj, which is not in Debian apt).
# apt_install_or_warning(packages: [Text])
apt_install_or_warning__183_v0() {
    local packages_671=("${!1}")
    apt_install__181_v0 packages_671[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_warning__141_v0 "could not apt install ${packages_671[@]} - skipping"
    fi
}

# apt_install_if_missing_or_die(cmd: Text, pkg: Text)
apt_install_if_missing_or_die__184_v0() {
    local cmd_411="${1}"
    local pkg_412="${2}"
    has_cmd__175_v0 "${cmd_411}"
    local ret_has_cmd175_v0__43_8="${ret_has_cmd175_v0}"
    if [ "${ret_has_cmd175_v0__43_8}" != 0 ]; then
        echo_warning__141_v0 "${cmd_411} already installed, skipping apt install"
    else
        local array_17=("${pkg_412}")
        apt_install_or_die__182_v0 array_17[@]
    fi
}

# home()
home__188_v0() {
    env_var_get__124_v0 "HOME"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_home188_v0=''
        return "${__status}"
    fi
    ret_home188_v0="${ret_env_var_get124_v0}"
    return 0
}

# copy_into_home(src: Text, rel_dest: Text)
copy_into_home__195_v0() {
    local src_419="${1}"
    local rel_dest_420="${2}"
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_copy_into_home195_v0=''
        return "${__status}"
    fi
    local home_421="${ret_home188_v0}"
    local dest_422="${home_421}/${rel_dest_420}"
    dir_create__44_v0 "${dest_422}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_copy_into_home195_v0=''
        return "${__status}"
    fi
    local __cp_18=
    (( 1 )) && __cp_18="-f" || __cp_18=""
    cp -r ${__cp_18} "${src_419}" "${dest_422}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_copy_into_home195_v0=''
        return "${__status}"
    fi
    ret_copy_into_home195_v0="${dest_422}"
    return 0
}

# copy_into_home_or_die(src: Text, rel_dest: Text)
copy_into_home_or_die__196_v0() {
    local src_417="${1}"
    local rel_dest_418="${2}"
    prompt_user__172_v0 "cp into home: ${rel_dest_418}"
    local ret_prompt_user172_v0__23_12="${ret_prompt_user172_v0}"
    if [ "$(( ! ret_prompt_user172_v0__23_12 ))" != 0 ]; then
        ret_copy_into_home_or_die196_v0=""
        return 0
    fi
    copy_into_home__195_v0 "${src_417}" "${rel_dest_418}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "deploy of ${rel_dest_418} into home failed" 1
    fi
    local dest_424="${ret_copy_into_home195_v0}"
    ret_copy_into_home_or_die196_v0="${dest_424}"
    return 0
}

# dir_create_at_home(rel: Text)
dir_create_at_home__202_v0() {
    local rel_426="${1}"
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_dir_create_at_home202_v0=''
        return "${__status}"
    fi
    local h_427="${ret_home188_v0}"
    dir_create__44_v0 "${h_427}/${rel_426}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_dir_create_at_home202_v0=''
        return "${__status}"
    fi
}

# dir_create_at_home_or_die(rel: Text)
dir_create_at_home_or_die__203_v0() {
    local rel_425="${1}"
    prompt_user__172_v0 "create directory ~/${rel_425}"
    local ret_prompt_user172_v0__12_8="${ret_prompt_user172_v0}"
    if [ "${ret_prompt_user172_v0__12_8}" != 0 ]; then
        dir_create_at_home__202_v0 "${rel_425}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "failed to create directory at home/${rel_425}" 1
        fi
    fi
}

# home()
home__207_v0() {
    env_var_get__124_v0 "HOME"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_home207_v0=''
        return "${__status}"
    fi
    ret_home207_v0="${ret_env_var_get124_v0}"
    return 0
}

__APPS_DIR_4=".local/share/applications"
# make_nnn_desktop(h: Text)
make_nnn_desktop__210_v0() {
    local h_428="${1}"
    local path_429="${h_428}/.local/bin/st-zsh"
    ret_make_nnn_desktop210_v0="[Desktop Entry]
Type=Application
Name=File Explorer (nnn)
Comment=Terminal file manager
Exec=${path_429} -e ${h_428}/.local/bin/nnn-launch
Terminal=false
Categories=Utility;FileManager;
Icon=nnn
"
    return 0
}

# make_btop_desktop(h: Text)
make_btop_desktop__211_v0() {
    local h_432="${1}"
    local path_433="${h_432}/.local/bin/st-zsh"
    ret_make_btop_desktop211_v0="[Desktop Entry]
Type=Application
Name=System Monitor (btop)
Comment=Resource monitor
Exec=${path_433} -e btop
Terminal=false
Categories=System;Monitor;
Icon=btop
"
    return 0
}

# make_ncdu_desktop(h: Text)
make_ncdu_desktop__212_v0() {
    local h_434="${1}"
    local path_435="${h_434}/.local/bin/st-zsh"
    ret_make_ncdu_desktop212_v0="[Desktop Entry]
Type=Application
Name=Disk Usage (ncdu)
Comment=Disk usage analyzer
Exec=${path_435} -e ncdu
Terminal=false
Categories=System;Utility;
Icon=ncdu
"
    return 0
}

# install_apt_essential_tools()
install_apt_essential_tools__213_v0() {
    local array_19=("rsync" "git" "tmux" "zsh" "sqlite3" "jq" "curl" "vim" "ripgrep" "pass" "nnn" "fzf" "btop" "ncdu")
    apt_install_or_die__182_v0 array_19[@]
    apt_install_if_missing_or_die__184_v0 "nvim" "neovim"
    home__207_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to resolve HOME" 1
    fi
    local h_416="${ret_home207_v0}"
    copy_into_home_or_die__196_v0 "src/apt-essential-tools/.config/nnn" ".config/"
    copy_into_home_or_die__196_v0 "src/apt-essential-tools/.local/bin" ".local/"
    chmod +x ${h_416}/.config/nnn/plugins/zmarks ${h_416}/.config/nnn/plugins/nvim-cd ${h_416}/.config/nnn/plugins/bm-create ${h_416}/.config/nnn/plugins/win-open ${h_416}/.config/nnn/profile ${h_416}/.local/bin/nnn-launch
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to chmod nnn files" 1
    fi
    dir_create_at_home_or_die__203_v0 "${__APPS_DIR_4}"
    make_nnn_desktop__210_v0 "${h_416}"
    local ret_make_nnn_desktop210_v0__40_46="${ret_make_nnn_desktop210_v0}"
    file_write__41_v0 "${h_416}/${__APPS_DIR_4}/nnn.desktop" "${ret_make_nnn_desktop210_v0__40_46}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to write nnn.desktop" 1
    fi
    make_btop_desktop__211_v0 "${h_416}"
    local ret_make_btop_desktop211_v0__43_47="${ret_make_btop_desktop211_v0}"
    file_write__41_v0 "${h_416}/${__APPS_DIR_4}/btop.desktop" "${ret_make_btop_desktop211_v0__43_47}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to write btop.desktop" 1
    fi
    make_ncdu_desktop__212_v0 "${h_416}"
    local ret_make_ncdu_desktop212_v0__46_47="${ret_make_ncdu_desktop212_v0}"
    file_write__41_v0 "${h_416}/${__APPS_DIR_4}/ncdu.desktop" "${ret_make_ncdu_desktop212_v0__46_47}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to write ncdu.desktop" 1
    fi
}

# setup_global_gitignore()
setup_global_gitignore__218_v0() {
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_setup_global_gitignore218_v0=''
        return "${__status}"
    fi
    local h_512="${ret_home188_v0}"
    file_exists__39_v0 "${h_512}/.gitignore_global"
    local ret_file_exists39_v0__7_12="${ret_file_exists39_v0}"
    if [ "$(( ! ret_file_exists39_v0__7_12 ))" != 0 ]; then
        ret_setup_global_gitignore218_v0=''
        return 1
    fi
    git config --global core.excludesFile ${h_512}/.gitignore_global
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_setup_global_gitignore218_v0=''
        return "${__status}"
    fi
}

# setup_global_gitignore_or_die()
setup_global_gitignore_or_die__219_v0() {
    setup_global_gitignore__218_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to setup global gitignore" 1
    fi
}

# rsync(src: Text, target: Text, excludes: [], delete: Bool)
rsync__227_v0() {
    local src_504="${1}"
    local target_505="${2}"
    local excludes_506=("${!3}")
    local delete_507="${4}"
    dir_create__44_v0 "${target_505}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync227_v0=''
        return "${__status}"
    fi
    local excludes_arr_508=()
    for exclude_509 in "${excludes_506[@]}"; do
        local s_510="${exclude_509}"
        excludes_arr_508+=("--exclude" "${s_510}")
    done
    local delopt_511=""
    if [ "${delete_507}" != 0 ]; then
        delopt_511="--delete"
    fi
    rsync -a ${delopt_511} ${excludes_arr_508[@]} ${src_504} ${target_505}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync227_v0=''
        return "${__status}"
    fi
}

# rsync(src: Text, target: Text, excludes: [Text], delete: Bool)
rsync__227_v1() {
    local src_632="${1}"
    local target_633="${2}"
    local excludes_634=("${!3}")
    local delete_635="${4}"
    dir_create__44_v0 "${target_633}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync227_v1=''
        return "${__status}"
    fi
    local excludes_arr_636=()
    for exclude_637 in "${excludes_634[@]}"; do
        local s_638="${exclude_637}"
        excludes_arr_636+=("--exclude" "${s_638}")
    done
    local delopt_639=""
    if [ "${delete_635}" != 0 ]; then
        delopt_639="--delete"
    fi
    rsync -a ${delopt_639} ${excludes_arr_636[@]} ${src_632} ${target_633}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync227_v1=''
        return "${__status}"
    fi
}

# rsync_into_home(src: Text, rel_target: Text, delete: Bool)
rsync_into_home__230_v0() {
    local src_498="${1}"
    local rel_target_499="${2}"
    local delete_500="${3}"
    local excludes_501=()
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync_into_home230_v0=''
        return "${__status}"
    fi
    local h_502="${ret_home188_v0}"
    local target_503="${h_502}/${rel_target_499}"
    dir_create__44_v0 "${target_503}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync_into_home230_v0=''
        return "${__status}"
    fi
    rsync__227_v0 "${src_498}" "${target_503}" excludes_501[@] "${delete_500}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync_into_home230_v0=''
        return "${__status}"
    fi
}

# rsync_or_die_into_home(src: Text, rel_target: Text, delete: Bool)
rsync_or_die_into_home__231_v0() {
    local src_495="${1}"
    local rel_target_496="${2}"
    local delete_497="${3}"
    prompt_user__172_v0 "rsync ${src_495} -> ~/${rel_target_496}"
    local ret_prompt_user172_v0__16_8="${ret_prompt_user172_v0}"
    if [ "${ret_prompt_user172_v0__16_8}" != 0 ]; then
        rsync_into_home__230_v0 "${src_495}" "${rel_target_496}" "${delete_497}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "rsync deploy of ${src_495} into ${rel_target_496} failed" 1
        fi
    fi
}

# rsync_or_die_opts(src: Text, target: Text, excludes: [Text], delete: Bool)
rsync_or_die_opts__232_v0() {
    local src_628="${1}"
    local target_629="${2}"
    local excludes_630=("${!3}")
    local delete_631="${4}"
    prompt_user__172_v0 "rsync ${src_628} -> ${target_629}"
    local ret_prompt_user172_v0__24_8="${ret_prompt_user172_v0}"
    if [ "${ret_prompt_user172_v0__24_8}" != 0 ]; then
        rsync__227_v1 "${src_628}" "${target_629}" excludes_630[@] "${delete_631}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "rsync deploy of ${src_628} into ${target_629} failed" 1
        fi
    fi
}

# rsync_or_die_opts_into_home(src: Text, rel_target: Text, excludes: [Text], delete: Bool)
rsync_or_die_opts_into_home__233_v0() {
    local src_623="${1}"
    local rel_target_624="${2}"
    local excludes_625=("${!3}")
    local delete_626="${4}"
    prompt_user__172_v0 "rsync ${src_623} -> ~/${rel_target_624}"
    local ret_prompt_user172_v0__32_8="${ret_prompt_user172_v0}"
    if [ "${ret_prompt_user172_v0__32_8}" != 0 ]; then
        home__188_v0 
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "rsync_or_die_opts_into_home: failed to resolve home directory" 1
            exit 1
        fi
        local h_627="${ret_home188_v0}"
        rsync_or_die_opts__232_v0 "${src_623}" "${h_627}/${rel_target_624}" excludes_625[@] "${delete_626}"
    fi
}

# install_dotfiles_personalization()
install_dotfiles_personalization__235_v0() {
    rsync_or_die_into_home__231_v0 "src/dotfiles_personalization/" "" 0
    setup_global_gitignore_or_die__219_v0 
    # applications/ is removed at generate time for the tmux preset; copy only if present.
    test -d "src/dotfiles_personalization/.local/share/applications"
    __status=$?
    if [ "${__status}" = 0 ]; then
        copy_into_home_or_die__196_v0 "src/dotfiles_personalization/.local/share/applications" ".local/share/applications"
    fi
}

# symlink_create_dir(origin: Text, destination: Text)
symlink_create_dir__243_v0() {
    local origin_565="${1}"
    local destination_566="${2}"
    dir_exists__38_v0 "${origin_565}"
    local ret_dir_exists38_v0__4_12="${ret_dir_exists38_v0}"
    if [ "$(( ! ret_dir_exists38_v0__4_12 ))" != 0 ]; then
        echo "The directory ${origin_565} doesn't exist"
        ret_symlink_create_dir243_v0=''
        return 1
    fi
    ln -fsn ${origin_565} ${destination_566}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_create_dir243_v0=''
        return "${__status}"
    fi
}

# TODO test this
# _parent_dir(path: Text)
_parent_dir__246_v0() {
    local path_561="${1}"
    local command_29
    command_29="$(dirname ${path_561})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret__parent_dir246_v0=''
        return "${__status}"
    fi
    local parent_562="${command_29}"
    ret__parent_dir246_v0="${parent_562}"
    return 0
}

# symlink_into_home(src: Text, rel_dest: Text)
symlink_into_home__247_v0() {
    local src_557="${1}"
    local rel_dest_558="${2}"
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home247_v0=''
        return "${__status}"
    fi
    local home_559="${ret_home188_v0}"
    local dest_560="${home_559}/${rel_dest_558}"
    _parent_dir__246_v0 "${dest_560}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home247_v0=''
        return "${__status}"
    fi
    local parent_563="${ret__parent_dir246_v0}"
    dir_create__44_v0 "${parent_563}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home247_v0=''
        return "${__status}"
    fi
    local command_30
    command_30="$(readlink -f ${src_557})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home247_v0=''
        return "${__status}"
    fi
    local abs_src_564="${command_30}"
    symlink_create_dir__243_v0 "${abs_src_564}" "${dest_560}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home247_v0=''
        return "${__status}"
    fi
    ret_symlink_into_home247_v0="${dest_560}"
    return 0
}

# symlink_into_home_or_die(src: Text, rel_dest: Text)
symlink_into_home_or_die__248_v0() {
    local src_555="${1}"
    local rel_dest_556="${2}"
    prompt_user__172_v0 "symlink ${src_555} -> ~/${rel_dest_556}"
    local ret_prompt_user172_v0__26_12="${ret_prompt_user172_v0}"
    if [ "$(( ! ret_prompt_user172_v0__26_12 ))" != 0 ]; then
        ret_symlink_into_home_or_die248_v0=""
        return 0
    fi
    symlink_into_home__247_v0 "${src_555}" "${rel_dest_556}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "deploy of ${src_555} symlink ${rel_dest_556}  into home failed" 1
    fi
    local dest_567="${ret_symlink_into_home247_v0}"
    ret_symlink_into_home_or_die248_v0="${dest_567}"
    return 0
}

# Symlink a home-relative path to another home-relative path (both resolved
# against home()). Works for files (e.g. bridging a data file from one config
# location to the path a plugin expects).
# symlink_at_home(src_rel: Text, dest_rel: Text)
symlink_at_home__249_v0() {
    local src_rel_702="${1}"
    local dest_rel_703="${2}"
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_at_home249_v0=''
        return "${__status}"
    fi
    local h_704="${ret_home188_v0}"
    local src_705="${h_704}/${src_rel_702}"
    local dest_706="${h_704}/${dest_rel_703}"
    file_exists__39_v0 "${src_705}"
    local ret_file_exists39_v0__43_12="${ret_file_exists39_v0}"
    if [ "$(( ! ret_file_exists39_v0__43_12 ))" != 0 ]; then
        echo_error__142_v0 "symlink source ${src_705} missing" 1
        ret_symlink_at_home249_v0=''
        return 1
    fi
    _parent_dir__246_v0 "${dest_706}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_at_home249_v0=''
        return "${__status}"
    fi
    local parent_707="${ret__parent_dir246_v0}"
    dir_create__44_v0 "${parent_707}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_at_home249_v0=''
        return "${__status}"
    fi
    ln -fsn ${src_705} ${dest_706}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_at_home249_v0=''
        return "${__status}"
    fi
    ret_symlink_at_home249_v0="${dest_706}"
    return 0
}

# symlink_at_home_or_die(src_rel: Text, dest_rel: Text)
symlink_at_home_or_die__250_v0() {
    local src_rel_700="${1}"
    local dest_rel_701="${2}"
    prompt_user__172_v0 "symlink ~/${src_rel_700} -> ~/${dest_rel_701}"
    local ret_prompt_user172_v0__57_12="${ret_prompt_user172_v0}"
    if [ "$(( ! ret_prompt_user172_v0__57_12 ))" != 0 ]; then
        ret_symlink_at_home_or_die250_v0=""
        return 0
    fi
    symlink_at_home__249_v0 "${src_rel_700}" "${dest_rel_701}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "symlink ${src_rel_700} -> ${dest_rel_701} in home failed" 1
    fi
    local dest_708="${ret_symlink_at_home249_v0}"
    ret_symlink_at_home_or_die250_v0="${dest_708}"
    return 0
}

# install_nerd_fonts()
install_nerd_fonts__252_v0() {
    local subpath_554=".local/share/fonts/NerdFonts"
    symlink_into_home_or_die__248_v0 "src/${subpath_554}" "${subpath_554}"
}

# set_only_user_write_or_die(path: Text)
set_only_user_write_or_die__257_v0() {
    local path_642="${1}"
    chmod -R g-w,o-w ${path_642}
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to set ${path_642} perms to user-only write" 1
    fi
}

# set_only_user_write_or_die_at_home(rel_path: Text)
set_only_user_write_or_die_at_home__258_v0() {
    local rel_path_640="${1}"
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "cannot determine home directory for ${rel_path_640}" 1
    fi
    local h_641="${ret_home188_v0}"
    set_only_user_write_or_die__257_v0 "${h_641}/${rel_path_640}"
}

# install_omz_config()
install_omz_config__261_v0() {
    local subpath_622=".oh-my-zsh"
    local array_31=("custom/plugins/")
    rsync_or_die_opts_into_home__233_v0 "src/${subpath_622}/" "${subpath_622}" array_31[@] 1
    set_only_user_write_or_die_at_home__258_v0 "${subpath_622}"
}

# execute(bin: Text, sh_path: Text)
execute__265_v0() {
    local bin_661="${1}"
    local sh_path_662="${2}"
    ${bin_661} ${sh_path_662}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute265_v0=''
        return "${__status}"
    fi
}

# execute_sh(sh_path: Text)
execute_sh__266_v0() {
    local sh_path_732="${1}"
    execute__265_v0 "bash" "${sh_path_732}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_sh266_v0=''
        return "${__status}"
    fi
}

# execute_zsh(sh_path: Text)
execute_zsh__267_v0() {
    local sh_path_660="${1}"
    execute__265_v0 "zsh" "${sh_path_660}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_zsh267_v0=''
        return "${__status}"
    fi
}

# execute_zsh_at_home(rel_sh_path: Text)
execute_zsh_at_home__270_v0() {
    local rel_sh_path_658="${1}"
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_zsh_at_home270_v0=''
        return "${__status}"
    fi
    local h_659="${ret_home188_v0}"
    execute_zsh__267_v0 "${h_659}/${rel_sh_path_658}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_zsh_at_home270_v0=''
        return "${__status}"
    fi
}

# install_zshmarks()
install_zshmarks__273_v0() {
    mkdir -p ~/.oh-my-zsh/custom/plugins/zshmarks
    __status=$?
    cp src/zshmarks.plugin.zsh ~/.oh-my-zsh/custom/plugins/zshmarks/zshmarks.plugin.zsh
    __status=$?
    execute_zsh_at_home__270_v0 ".oh-my-zsh/custom/plugins/zshmarks/zshmarks.plugin.zsh"
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

# has_cmd(cmd: Text)
has_cmd__278_v0() {
    local cmd_669="${1}"
    local found_670=0
    command -v ${cmd_669} >/dev/null 2>&1
    __status=$?
    if [ "${__status}" = 0 ]; then
        found_670=1
    fi
    ret_has_cmd278_v0="${found_670}"
    return 0
}

# echo_error exits the process (default exit_code=1), so no fail needed.
temp_dir_create__46_v0 "amber-XXXXXX" 1 1
__status=$?
if [ "${__status}" != 0 ]; then
    :
fi
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
# _project_root()
_project_root__309_v0() {
    file_exists__39_v0 "src/copals.ab"
    local ret_file_exists39_v0__5_8="${ret_file_exists39_v0}"
    if [ "${ret_file_exists39_v0__5_8}" != 0 ]; then
        local pwd_val_71="$PWD"
        replace_regex__3_v0 "${pwd_val_71}" "/[^/]+\$" "" 1
        ret__project_root309_v0="${ret_replace_regex3_v0}"
        return 0
    fi
    ret__project_root309_v0="$PWD"
    return 0
}

_project_root__309_v0 
__PROJECT_ROOT_81="${ret__project_root309_v0}"
project_vendor_82="${__PROJECT_ROOT_81}/copals/vendor"
installed_vendor_83="/usr/lib/copals/vendor"
# The installed vendor dir is authoritative when copals runs inside its own
# container: the host repo is bind-mounted at the same absolute path, so the
# project vendor dir also "exists" but its tools are only populated inside the
# image. Prefer the installed tree whenever it actually holds the binaries.
# resolve_vendor_dir()
resolve_vendor_dir__310_v0() {
    dir_exists__38_v0 "${installed_vendor_83}"
    local ret_dir_exists38_v0__21_8="${ret_dir_exists38_v0}"
    file_exists__39_v0 "${installed_vendor_83}/jsonnet"
    local ret_file_exists39_v0__21_41="${ret_file_exists39_v0}"
    if [ "$(( ret_dir_exists38_v0__21_8 && ret_file_exists39_v0__21_41 ))" != 0 ]; then
        ret_resolve_vendor_dir310_v0="${installed_vendor_83}"
        return 0
    fi
    dir_exists__38_v0 "${project_vendor_82}"
    local ret_dir_exists38_v0__24_8="${ret_dir_exists38_v0}"
    file_exists__39_v0 "${project_vendor_82}/jsonnet"
    local ret_file_exists39_v0__24_39="${ret_file_exists39_v0}"
    if [ "$(( ret_dir_exists38_v0__24_8 && ret_file_exists39_v0__24_39 ))" != 0 ]; then
        ret_resolve_vendor_dir310_v0="${project_vendor_82}"
        return 0
    fi
    dir_exists__38_v0 "${installed_vendor_83}"
    local ret_dir_exists38_v0__27_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__27_8}" != 0 ]; then
        ret_resolve_vendor_dir310_v0="${installed_vendor_83}"
        return 0
    fi
    dir_exists__38_v0 "${project_vendor_82}"
    local ret_dir_exists38_v0__30_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__30_8}" != 0 ]; then
        ret_resolve_vendor_dir310_v0="${project_vendor_82}"
        return 0
    fi
    ret_resolve_vendor_dir310_v0=""
    return 0
}

resolve_vendor_dir__310_v0 
__VENDOR_DIR_90="${ret_resolve_vendor_dir310_v0}"
# jq_resolve()
jq_resolve__311_v0() {
    if [ "$([ "_${__VENDOR_DIR_90}" != "_" ]; echo $?)" != 0 ]; then
        ret_jq_resolve311_v0="jq"
        return 0
    fi
    ret_jq_resolve311_v0="${__VENDOR_DIR_90}/jq"
    return 0
}

# j2_resolve()
j2_resolve__312_v0() {
    if [ "$([ "_${__VENDOR_DIR_90}" != "_" ]; echo $?)" != 0 ]; then
        ret_j2_resolve312_v0="j2"
        return 0
    fi
    ret_j2_resolve312_v0="${__VENDOR_DIR_90}/j2"
    return 0
}

# jsonnet_resolve()
jsonnet_resolve__313_v0() {
    if [ "$([ "_${__VENDOR_DIR_90}" != "_" ]; echo $?)" != 0 ]; then
        ret_jsonnet_resolve313_v0="jsonnet"
        return 0
    fi
    ret_jsonnet_resolve313_v0="${__VENDOR_DIR_90}/jsonnet"
    return 0
}

# jsonschema_resolve()
jsonschema_resolve__314_v0() {
    if [ "$([ "_${__VENDOR_DIR_90}" != "_" ]; echo $?)" != 0 ]; then
        ret_jsonschema_resolve314_v0="jsonschema"
        return 0
    fi
    ret_jsonschema_resolve314_v0="${__VENDOR_DIR_90}/jsonschema"
    return 0
}

# lua_resolve()
lua_resolve__315_v0() {
    if [ "$([ "_${__VENDOR_DIR_90}" != "_" ]; echo $?)" != 0 ]; then
        ret_lua_resolve315_v0="lua"
        return 0
    fi
    ret_lua_resolve315_v0="${__VENDOR_DIR_90}/lua"
    return 0
}

jq_resolve__311_v0 
j2_resolve__312_v0 
jsonnet_resolve__313_v0 
jsonschema_resolve__314_v0 
lua_resolve__315_v0 
# install_system_tools()
install_system_tools__322_v0() {
    local array_34=("ncdu")
    apt_install_or_die__182_v0 array_34[@]
    has_cmd__278_v0 "jj"
    local ret_has_cmd278_v0__12_12="${ret_has_cmd278_v0}"
    if [ "$(( ! ret_has_cmd278_v0__12_12 ))" != 0 ]; then
        local array_35=("jj")
        apt_install_or_warning__183_v0 array_35[@]
    fi
}

# install_nvim()
install_nvim__327_v0() {
    local array_36=("fd-find" "clang" "g++")
    apt_install_or_die__182_v0 array_36[@]
    local subpath_698=".config/nvim"
    symlink_into_home_or_die__248_v0 "src/${subpath_698}" "${subpath_698}"
    local lazy_dir_699="${subpath_698}/lazy"
    symlink_into_home_or_die__248_v0 "src/${lazy_dir_699}" ".local/share/nvim/lazy"
    # quicksheet reads ~/.config/quicksheet.txt; the data ships from the nvim
    # repo as ~/.config/nvim/quicksheet.txt. Symlink it so quicksheet finds it.
    symlink_at_home_or_die__250_v0 ".config/nvim/quicksheet.txt" ".config/quicksheet.txt"
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
install_quicksheet__329_v0() {
    :
}

# install_tmux_warm_daemon()
install_tmux_warm_daemon__333_v0() {
    copy_into_home_or_die__196_v0 "src/.tmux_warm_daemon/attach_warm.sh" ".local/bin/"
    copy_into_home_or_die__196_v0 "src/.tmux_warm_daemon/restart_daemon.sh" ".local/bin/"
    copy_into_home_or_die__196_v0 "src/.tmux_warm_daemon/agent-warm.sh" ".local/bin/"
    copy_into_home_or_die__196_v0 "src/.tmux_warm_daemon/bootstrap-warm-daemon.sh" ".local/bin/"
    # Pool config: defines the `agent` pool so the daemon pre-warms agent
    # sessions (agent-N / agent@<hash>) instead of only `warm-*`. The agent
    # command is agent-warm.sh, which execs whatever `kv agentclitool` points
    # at — so no tool is hardcoded (see ~/.local/bin/agent-warm.sh).
    copy_into_home_or_die__196_v0 "src/.tmux_warm_daemon/config.yaml" ".config/tmux_warm_daemon/"
    rsync_or_die_into_home__231_v0 "src/.tmux_warm_daemon/" ".tmux_warm_daemon/" 1
    # Strict pre-fetch: the bash backend (src/.tmux_warm_daemon/bash/tmux_warm_daemon)
    # is the sole, vendored implementation. No install-time network fetch and no
    # opaque binary — everything that runs ships as reviewable source in the bundle.
    # Seed `agentclitool` from the nvim config default (if unset) and (re)start
    # the daemon so it loads config.yaml + registers the `agent` pool. Without
    # this, nvim's <leader><C-l> can never attach (no agent@<hash> session).
    # Kept in a standalone script because amber's `$...$` literal can't contain
    # `$` (kv/grep/sed use it). Best-effort; never fails the install.
    bash -c 'nohup ~/.local/bin/bootstrap-warm-daemon.sh >/tmp/tmux_warm_daemon.bootstrap.log 2>&1; true'
    __status=$?
}

# tmux_wm: outer "window manager" tmux (i3 replacement) for the terminal-only
# preset. Installs only the signed apt `tmux` package and copies plain-text
# config + 7 shell scripts into the home tree. No pre-fetch, no binaries, no
# opaque blobs. Plain-text only; no system services beyond tmux.
# install_tmux_wm()
install_tmux_wm__339_v0() {
    local array_37=("tmux")
    apt_install_or_die__182_v0 array_37[@]
    copy_into_home_or_die__196_v0 "src/tmux_wm/.config/tmux" ".config/"
    copy_into_home_or_die__196_v0 "src/tmux_wm/.local/bin" ".local/"
    home__207_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "tmux_wm: cannot resolve HOME" 1
    fi
    local h_710="${ret_home207_v0}"
    chmod +x ${h_710}/.local/bin/tmux-wm ${h_710}/.local/bin/tmux-default ${h_710}/.local/bin/fzf-launcher ${h_710}/.local/bin/tmux-wm-move ${h_710}/.local/bin/tmux-wm-terminal ${h_710}/.local/bin/tmux-wm-open ${h_710}/.local/bin/tmux-wm-swap ${h_710}/.local/bin/nnn-wm
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "tmux_wm: failed to chmod scripts" 1
    fi
}

# install_cmd_bookmarks()
install_cmd_bookmarks__342_v0() {
    symlink_into_home_or_die__248_v0 "src/cmd_bookmarks" ".local/share/cmd_bookmarks"
}

# execute_sh_at_home(rel_sh_path: Text)
execute_sh_at_home__349_v0() {
    local rel_sh_path_730="${1}"
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_sh_at_home349_v0=''
        return "${__status}"
    fi
    local h_731="${ret_home188_v0}"
    execute_sh__266_v0 "${h_731}/${rel_sh_path_730}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_sh_at_home349_v0=''
        return "${__status}"
    fi
}

# execute_sh_at_home_or_die(rel_sh_path: Text)
execute_sh_at_home_or_die__350_v0() {
    local rel_sh_path_729="${1}"
    prompt_user__172_v0 "execute ~/${rel_sh_path_729}"
    local ret_prompt_user172_v0__12_8="${ret_prompt_user172_v0}"
    if [ "${ret_prompt_user172_v0__12_8}" != 0 ]; then
        execute_sh_at_home__349_v0 "${rel_sh_path_729}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "failed to run ${rel_sh_path_729}" 1
        fi
    fi
}

# install_agent_global_config()
install_agent_global_config__355_v0() {
    rsync_or_die_into_home__231_v0 "src/.agent/" ".agent" 1
    home__207_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "install_agent_global_config: home unresolved" 1
        exit 1
    fi
    local h_726="${ret_home207_v0}"
    local scripts_727=("sync-permissions-from-cli.sh" "sync-permissions.sh" "sync-antigravity-permissions.sh" "sync-kilocode-permissions.sh")
    for script_728 in "${scripts_727[@]}"; do
        file_exists__39_v0 "${h_726}/.agent/${script_728}"
        local ret_file_exists39_v0__20_12="${ret_file_exists39_v0}"
        if [ "${ret_file_exists39_v0__20_12}" != 0 ]; then
            execute_sh_at_home_or_die__350_v0 ".agent/${script_728}"
        fi
    done
}

# _project_root()
_project_root__364_v0() {
    file_exists__39_v0 "src/copals.ab"
    local ret_file_exists39_v0__5_8="${ret_file_exists39_v0}"
    if [ "${ret_file_exists39_v0__5_8}" != 0 ]; then
        local pwd_val_98="$PWD"
        replace_regex__3_v0 "${pwd_val_98}" "/[^/]+\$" "" 1
        ret__project_root364_v0="${ret_replace_regex3_v0}"
        return 0
    fi
    ret__project_root364_v0="$PWD"
    return 0
}

_project_root__364_v0 
__PROJECT_ROOT_99="${ret__project_root364_v0}"
project_vendor_100="${__PROJECT_ROOT_99}/copals/vendor"
installed_vendor_101="/usr/lib/copals/vendor"
# The installed vendor dir is authoritative when copals runs inside its own
# container: the host repo is bind-mounted at the same absolute path, so the
# project vendor dir also "exists" but its tools are only populated inside the
# image. Prefer the installed tree whenever it actually holds the binaries.
# resolve_vendor_dir()
resolve_vendor_dir__365_v0() {
    dir_exists__38_v0 "${installed_vendor_101}"
    local ret_dir_exists38_v0__21_8="${ret_dir_exists38_v0}"
    file_exists__39_v0 "${installed_vendor_101}/jsonnet"
    local ret_file_exists39_v0__21_41="${ret_file_exists39_v0}"
    if [ "$(( ret_dir_exists38_v0__21_8 && ret_file_exists39_v0__21_41 ))" != 0 ]; then
        ret_resolve_vendor_dir365_v0="${installed_vendor_101}"
        return 0
    fi
    dir_exists__38_v0 "${project_vendor_100}"
    local ret_dir_exists38_v0__24_8="${ret_dir_exists38_v0}"
    file_exists__39_v0 "${project_vendor_100}/jsonnet"
    local ret_file_exists39_v0__24_39="${ret_file_exists39_v0}"
    if [ "$(( ret_dir_exists38_v0__24_8 && ret_file_exists39_v0__24_39 ))" != 0 ]; then
        ret_resolve_vendor_dir365_v0="${project_vendor_100}"
        return 0
    fi
    dir_exists__38_v0 "${installed_vendor_101}"
    local ret_dir_exists38_v0__27_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__27_8}" != 0 ]; then
        ret_resolve_vendor_dir365_v0="${installed_vendor_101}"
        return 0
    fi
    dir_exists__38_v0 "${project_vendor_100}"
    local ret_dir_exists38_v0__30_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__30_8}" != 0 ]; then
        ret_resolve_vendor_dir365_v0="${project_vendor_100}"
        return 0
    fi
    ret_resolve_vendor_dir365_v0=""
    return 0
}

resolve_vendor_dir__365_v0 
__VENDOR_DIR_102="${ret_resolve_vendor_dir365_v0}"
# jq_resolve()
jq_resolve__366_v0() {
    if [ "$([ "_${__VENDOR_DIR_102}" != "_" ]; echo $?)" != 0 ]; then
        ret_jq_resolve366_v0="jq"
        return 0
    fi
    ret_jq_resolve366_v0="${__VENDOR_DIR_102}/jq"
    return 0
}

# j2_resolve()
j2_resolve__367_v0() {
    if [ "$([ "_${__VENDOR_DIR_102}" != "_" ]; echo $?)" != 0 ]; then
        ret_j2_resolve367_v0="j2"
        return 0
    fi
    ret_j2_resolve367_v0="${__VENDOR_DIR_102}/j2"
    return 0
}

# jsonnet_resolve()
jsonnet_resolve__368_v0() {
    if [ "$([ "_${__VENDOR_DIR_102}" != "_" ]; echo $?)" != 0 ]; then
        ret_jsonnet_resolve368_v0="jsonnet"
        return 0
    fi
    ret_jsonnet_resolve368_v0="${__VENDOR_DIR_102}/jsonnet"
    return 0
}

# jsonschema_resolve()
jsonschema_resolve__369_v0() {
    if [ "$([ "_${__VENDOR_DIR_102}" != "_" ]; echo $?)" != 0 ]; then
        ret_jsonschema_resolve369_v0="jsonschema"
        return 0
    fi
    ret_jsonschema_resolve369_v0="${__VENDOR_DIR_102}/jsonschema"
    return 0
}

# lua_resolve()
lua_resolve__370_v0() {
    if [ "$([ "_${__VENDOR_DIR_102}" != "_" ]; echo $?)" != 0 ]; then
        ret_lua_resolve370_v0="lua"
        return 0
    fi
    ret_lua_resolve370_v0="${__VENDOR_DIR_102}/lua"
    return 0
}

jq_resolve__366_v0 
j2_resolve__367_v0 
jsonnet_resolve__368_v0 
jsonschema_resolve__369_v0 
lua_resolve__370_v0 
# Inverse of rm_if_feature_not: remove rel_path when features[feature] == expected
# (defaults to "" so an unset feature never triggers removal). Use to drop GUI
# artifacts in pure-TTY presets, e.g. mode == "tmux".
# install_agent_skills_impl()
install_agent_skills_impl__394_v0() {
    home__207_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_agent_skills_impl394_v0=''
        return "${__status}"
    fi
    local h_741="${ret_home207_v0}"
    local canon_742="${h_741}/.agents/skills"
    local skills_src_743="src/agent-skills/.agents/skills"
    rsync_or_die_into_home__231_v0 "${skills_src_743}/" ".agents/skills" 0
    dir_exists__38_v0 "${canon_742}"
    local ret_dir_exists38_v0__49_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__49_8}" != 0 ]; then
        local legacy_dir_744="${h_741}/.cursor/skills-cursor"
        dir_exists__38_v0 "${legacy_dir_744}"
        local ret_dir_exists38_v0__51_12="${ret_dir_exists38_v0}"
        if [ "${ret_dir_exists38_v0__51_12}" != 0 ]; then
            local __rm_43=
            (( 1 )) && __rm_43="-r" || __rm_43=""
            local __rm_44=
            rm ${__rm_44} ${__rm_43} "${legacy_dir_744}"
        fi
        # 2. Wire the store into each ENABLED tool. Antigravity reads ~/.agents/skills natively, so it needs no link.
    fi
}

# install_agent_skills()
install_agent_skills__395_v0() {
    install_agent_skills_impl__394_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to install agent skills" 1
    fi
}

# install_skill_caveman()
install_skill_caveman__398_v0() {
    symlink_into_home_or_die__248_v0 "src/.agents/skills/caveman" ".agents/skills/caveman"
}

# install_skill_humanizer()
install_skill_humanizer__401_v0() {
    symlink_into_home_or_die__248_v0 "src/.agents/skills/humanizer" ".agents/skills/humanizer"
}

# install_skill_ponytail()
install_skill_ponytail__404_v0() {
    symlink_into_home_or_die__248_v0 "src/.agents/skills/ponytail" ".agents/skills/ponytail"
}

# Each hook must be IDEMPOTENT and KILL THE PROGRAM on failure.
# Inside the hook, propagate failures with ? via a *_impl(): Null? helper, then
# wrap it once at the installer level:  install_x() { x_impl() failed { exit(1) } }
# So every install_*() is infallible and main() stays a plain sequence of calls.
# print_help()
print_help__406_v0() {
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
    echo "  dotfiles_personalization"
    echo "  nerd_fonts"
    echo "  omz_config"
    echo "  zshmarks"
    echo "  system_tools"
    echo "  nvim"
    echo "  quicksheet"
    echo "  tmux_warm_daemon"
    echo "  tmux_wm"
    echo "  cmd_bookmarks"
    echo "  agent_global_config"
    echo "  agent_skills"
    echo "  skill_caveman"
    echo "  skill_humanizer"
    echo "  skill_ponytail"
}

# run_step(step: Text)
run_step__407_v0() {
    local step_827="${1}"
    local matched_828=0
    if [ "$([ "_${step_827}" != "_help" ]; echo $?)" != 0 ]; then
        print_help__406_v0 
        matched_828=1
    fi
    if [ "$([ "_${step_827}" != "_apt_essential_tools" ]; echo $?)" != 0 ]; then
        install_apt_essential_tools__213_v0 
        matched_828=1
    fi
    if [ "$([ "_${step_827}" != "_dotfiles_personalization" ]; echo $?)" != 0 ]; then
        install_dotfiles_personalization__235_v0 
        matched_828=1
    fi
    if [ "$([ "_${step_827}" != "_nerd_fonts" ]; echo $?)" != 0 ]; then
        install_nerd_fonts__252_v0 
        matched_828=1
    fi
    if [ "$([ "_${step_827}" != "_omz_config" ]; echo $?)" != 0 ]; then
        install_omz_config__261_v0 
        matched_828=1
    fi
    if [ "$([ "_${step_827}" != "_zshmarks" ]; echo $?)" != 0 ]; then
        install_zshmarks__273_v0 
        matched_828=1
    fi
    if [ "$([ "_${step_827}" != "_system_tools" ]; echo $?)" != 0 ]; then
        install_system_tools__322_v0 
        matched_828=1
    fi
    if [ "$([ "_${step_827}" != "_nvim" ]; echo $?)" != 0 ]; then
        install_nvim__327_v0 
        matched_828=1
    fi
    if [ "$([ "_${step_827}" != "_quicksheet" ]; echo $?)" != 0 ]; then
        install_quicksheet__329_v0 
        matched_828=1
    fi
    if [ "$([ "_${step_827}" != "_tmux_warm_daemon" ]; echo $?)" != 0 ]; then
        install_tmux_warm_daemon__333_v0 
        matched_828=1
    fi
    if [ "$([ "_${step_827}" != "_tmux_wm" ]; echo $?)" != 0 ]; then
        install_tmux_wm__339_v0 
        matched_828=1
    fi
    if [ "$([ "_${step_827}" != "_cmd_bookmarks" ]; echo $?)" != 0 ]; then
        install_cmd_bookmarks__342_v0 
        matched_828=1
    fi
    if [ "$([ "_${step_827}" != "_agent_global_config" ]; echo $?)" != 0 ]; then
        install_agent_global_config__355_v0 
        matched_828=1
    fi
    if [ "$([ "_${step_827}" != "_agent_skills" ]; echo $?)" != 0 ]; then
        install_agent_skills__395_v0 
        matched_828=1
    fi
    if [ "$([ "_${step_827}" != "_skill_caveman" ]; echo $?)" != 0 ]; then
        install_skill_caveman__398_v0 
        matched_828=1
    fi
    if [ "$([ "_${step_827}" != "_skill_humanizer" ]; echo $?)" != 0 ]; then
        install_skill_humanizer__401_v0 
        matched_828=1
    fi
    if [ "$([ "_${step_827}" != "_skill_ponytail" ]; echo $?)" != 0 ]; then
        install_skill_ponytail__404_v0 
        matched_828=1
    fi
    if [ "$(( ! matched_828 ))" != 0 ]; then
        echo "Unknown step: '${step_827}'"
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
cmd_update__408_v0() {
    local command_46
    command_46="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_cmd_update408_v0=''
        return "${__status}"
    fi
    local script_dir_798="${command_46}"
    local meta_path_799="${script_dir_798}/meta.json"
    local state_path_800="${script_dir_798}/.last_installed.json"
    local command_47
    command_47="$(jq -r '.repo_hashes | to_entries[] | "\(.key)	\(.value)"' "${meta_path_799}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_cmd_update408_v0=''
        return "${__status}"
    fi
    local new_lines_801="${command_47}"
    local old_lines_802=""
    file_exists__39_v0 "${state_path_800}"
    local ret_file_exists39_v0__359_8="${ret_file_exists39_v0}"
    if [ "${ret_file_exists39_v0__359_8}" != 0 ]; then
        local command_48
        command_48="$(jq -r '.repo_hashes | to_entries[] | "\(.key)	\(.value)"' "${state_path_800}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_cmd_update408_v0=''
            return "${__status}"
        fi
        old_lines_802="${command_48}"
    fi
    local old_keys_803=()
    local old_vals_804=()
    if [ "$([ "_${old_lines_802}" == "_" ]; echo $?)" != 0 ]; then
        split_lines__5_v0 "${old_lines_802}"
        local rows_809=("${ret_split_lines5_v0[@]}")
        for row_810 in "${rows_809[@]}"; do
            if [ "$([ "_${row_810}" != "_" ]; echo $?)" != 0 ]; then
                continue
            fi
            split__4_v0 "	" "${row_810}"
            local parts_811=("${ret_split4_v0[@]}")
            local __length_53=("${parts_811[@]}")
            if [ "$(( ${#__length_53[@]} >= 2 ))" != 0 ]; then
                old_keys_803+=("${parts_811[0]?"Index out of bounds (at /tmp/jbtd-install-build-0BXhzL/install.ab:371:36)"}")
                old_vals_804+=("${parts_811[1]?"Index out of bounds (at /tmp/jbtd-install-build-0BXhzL/install.ab:372:36)"}")
            fi
        done
    fi
    local changed_812=()
    split_lines__5_v0 "${new_lines_801}"
    local new_rows_813=("${ret_split_lines5_v0[@]}")
    for row_814 in "${new_rows_813[@]}"; do
        if [ "$([ "_${row_814}" != "_" ]; echo $?)" != 0 ]; then
            continue
        fi
        split__4_v0 "	" "${row_814}"
        local parts_815=("${ret_split4_v0[@]}")
        local __length_59=("${parts_815[@]}")
        if [ "$(( ${#__length_59[@]} < 2 ))" != 0 ]; then
            continue
        fi
        local key_816="${parts_815[0]?"Index out of bounds (at /tmp/jbtd-install-build-0BXhzL/install.ab:383:27)"}"
        local val_817="${parts_815[1]?"Index out of bounds (at /tmp/jbtd-install-build-0BXhzL/install.ab:384:27)"}"
        local matched_818=0
        local __range_start_819=0
        local __length_60=("${old_keys_803[@]}")
        local __range_end_819="${#__length_60[@]}"
        local __dir_819=$(( ${__range_start_819} <= ${__range_end_819} ? 1 : -1 ))
        for (( i_819=${__range_start_819}; i_819 * ${__dir_819} < ${__range_end_819} * ${__dir_819}; i_819+=${__dir_819} )); do
            if [ "$([ "_${old_keys_803[${i_819}]?"Index out of bounds (at /tmp/jbtd-install-build-0BXhzL/install.ab:387:25)"}" != "_${key_816}" ]; echo $?)" != 0 ]; then
                if [ "$([ "_${old_vals_804[${i_819}]?"Index out of bounds (at /tmp/jbtd-install-build-0BXhzL/install.ab:388:29)"}" == "_${val_817}" ]; echo $?)" != 0 ]; then
                    local array_61=("${key_816}")
                    changed_812+=("${array_61[@]}")
                fi
                matched_818=1
                break
            fi
done
        if [ "$(( ! matched_818 ))" != 0 ]; then
            changed_812+=("${key_816}")
        fi
    done
    for ok_820 in "${old_keys_803[@]}"; do
        local found_821=0
        for row_822 in "${new_rows_813[@]}"; do
            if [ "$([ "_${row_822}" != "_" ]; echo $?)" != 0 ]; then
                continue
            fi
            split__4_v0 "	" "${row_822}"
            local parts_823=("${ret_split4_v0[@]}")
            local __length_67=("${parts_823[@]}")
            if [ "$(( $(( ${#__length_67[@]} >= 2 )) && $([ "_${parts_823[0]?"Index out of bounds (at /tmp/jbtd-install-build-0BXhzL/install.ab:405:42)"}" != "_${ok_820}" ]; echo $?) ))" != 0 ]; then
                found_821=1
                break
            fi
        done
        if [ "$(( ! found_821 ))" != 0 ]; then
            changed_812+=("${ok_820}")
        fi
    done
    local __length_69=("${changed_812[@]}")
    if [ "$(( ${#__length_69[@]} == 0 ))" != 0 ]; then
        echo "update: all repos up to date"
        ret_cmd_update408_v0=''
        return 0
    fi
    local __length_70=("${changed_812[@]}")
    echo "update: ${#__length_70[@]} repo(s) changed:"
    for c_824 in "${changed_812[@]}"; do
        echo "  - ${c_824}"
    done
    echo "Apply updates? [Y/n]"
    local command_73
    command_73="$(read -r line < /dev/tty 2>/dev/null; printf "%s" "$line")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_cmd_update408_v0=''
        return "${__status}"
    fi
    local ans_825="${command_73}"
    if [ "$(( $(( $(( $([ "_${ans_825}" != "_n" ]; echo $?) || $([ "_${ans_825}" != "_N" ]; echo $?) )) || $([ "_${ans_825}" != "_no" ]; echo $?) )) || $([ "_${ans_825}" != "_NO" ]; echo $?) ))" != 0 ]; then
        echo "update: aborted"
        ret_cmd_update408_v0=''
        return 0
    fi
    for c_826 in "${changed_812[@]}"; do
        run_step__407_v0 "${c_826}"
    done
    cp "${meta_path_799}" "${state_path_800}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_cmd_update408_v0=''
        return "${__status}"
    fi
    echo "update: done"
}

typeset -r raw_args_110=("$0" "$@")
__length_78=("${raw_args_110[@]}")
slice_upper_77="${#__length_78[@]}"
slice_offset_79=1
slice_offset_79=$((${slice_offset_79} > 0 ? ${slice_offset_79} : 0))
slice_length_80="$(( slice_upper_77 - slice_offset_79 ))"
slice_length_80=$((${slice_length_80} > 0 ? ${slice_length_80} : 0))
args_111=("${raw_args_110[@]:${slice_offset_79}:${slice_length_80}}")
step_args_112=()
for a_113 in "${args_111[@]}"; do
    if [ "$([ "_${a_113}" != "_--ask" ]; echo $?)" != 0 ]; then
        export COPALS_ASK=1
        __status=$?
    fi
    if [ "$([ "_${a_113}" != "_--trace" ]; echo $?)" != 0 ]; then
        set -x
        __status=$?
    fi
    if [ "$([ "_${a_113}" == "_--ask" ]; echo $?)" != 0 ]; then
        if [ "$([ "_${a_113}" == "_--trace" ]; echo $?)" != 0 ]; then
            step_args_112+=("${a_113}")
        fi
    fi
done
__length_85=("${step_args_112[@]}")
if [ "$(( ${#__length_85[@]} == 0 ))" != 0 ]; then
    install_apt_essential_tools__213_v0 
    install_dotfiles_personalization__235_v0 
    install_nerd_fonts__252_v0 
    install_omz_config__261_v0 
    install_zshmarks__273_v0 
    install_system_tools__322_v0 
    install_nvim__327_v0 
    install_quicksheet__329_v0 
    install_tmux_warm_daemon__333_v0 
    install_tmux_wm__339_v0 
    install_cmd_bookmarks__342_v0 
    install_agent_global_config__355_v0 
    install_agent_skills__395_v0 
    install_skill_caveman__398_v0 
    install_skill_humanizer__401_v0 
    install_skill_ponytail__404_v0 
fi
__length_86=("${step_args_112[@]}")
if [ "$(( ${#__length_86[@]} >= 1 ))" != 0 ]; then
    if [ "$([ "_${step_args_112[0]?"Index out of bounds (at /tmp/jbtd-install-build-0BXhzL/install.ab:524:22)"}" != "_update" ]; echo $?)" != 0 ]; then
        __length_87=("${step_args_112[@]}")
        if [ "$(( ${#__length_87[@]} == 1 ))" != 0 ]; then
            cmd_update__408_v0 
            __status=$?
            if [ "${__status}" != 0 ]; then
                exit "${__status}"
            fi
        fi
    else
        for step_829 in "${step_args_112[@]}"; do
            run_step__407_v0 "${step_829}"
        done
    fi
fi
