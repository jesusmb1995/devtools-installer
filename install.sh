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
    local source_61="${1}"
    local search_62="${2}"
    local replace_63="${3}"
    # Here we use a command to avoid #646
    local result_64=""
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
        result_64="${source_61//"${search_62}"/"${replace_63}"}"
        __status=$?
    else
        result_64="${source_61//"${search_62}"/${replace_63}}"
        __status=$?
    fi
    ret_replace0_v0="${result_64}"
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
    local source_56="${1}"
    local search_57="${2}"
    local replace_text_58="${3}"
    local extended_59="${4}"
    sed_version__2_v0 
    local sed_version_60="${ret_sed_version2_v0}"
    replace__0_v0 "${search_57}" "/" "\\/"
    search_57="${ret_replace0_v0}"
    replace__0_v0 "${replace_text_58}" "/" "\\/"
    replace_text_58="${ret_replace0_v0}"
    if [ "$(( $(( sed_version_60 == __SED_VERSION_GNU_1 )) || $(( sed_version_60 == __SED_VERSION_BUSYBOX_2 )) ))" != 0 ]; then
        # '\b' is supported but not in POSIX standards. Disable it
        replace__0_v0 "${search_57}" "\\b" "\\\\b"
        search_57="${ret_replace0_v0}"
    fi
    if [ "${extended_59}" != 0 ]; then
        # GNU sed versions 4.0 through 4.2 support extended regex syntax,
        # but only via the "-r" option
        if [ "$(( sed_version_60 == __SED_VERSION_GNU_1 ))" != 0 ]; then
            local command_1
            command_1="$(sed -r -e "s/${search_57}/${replace_text_58}/g" <<<"${source_56}")"
            __status=$?
            ret_replace_regex3_v0="${command_1}"
            return 0
        else
            local command_2
            command_2="$(sed -E -e "s/${search_57}/${replace_text_58}/g" <<<"${source_56}")"
            __status=$?
            ret_replace_regex3_v0="${command_2}"
            return 0
        fi
    else
        if [ "$(( $(( sed_version_60 == __SED_VERSION_GNU_1 )) || $(( sed_version_60 == __SED_VERSION_BUSYBOX_2 )) ))" != 0 ]; then
            # GNU Sed BRE handle \| as a metacharacter, but it is not POSIX standands. Disable it
            replace__0_v0 "${search_57}" "\\|" "|"
            search_57="${ret_replace0_v0}"
        fi
        local command_3
        command_3="$(sed -e "s/${search_57}/${replace_text_58}/g" <<<"${source_56}")"
        __status=$?
        ret_replace_regex3_v0="${command_3}"
        return 0
    fi
}

# split(text: Text, delimiter: Text)
split__4_v0() {
    local text_870="${1}"
    local delimiter_871="${2}"
    local result_872=()
    # zsh uses -A for array, bash uses -a, ksh is VERY bad at splitting anything
    if [ "$([ "_${EXEC_SHELL}" != "_zsh" ]; echo $?)" != 0 ]; then
        IFS="${delimiter_871}" read -rd '' -A result_872 < <(printf %s "$text_870")
        __status=$?
    elif [ "$([ "_${EXEC_SHELL}" != "_ksh" ]; echo $?)" != 0 ]; then
        if [ "$([ "_${delimiter_871}" != "_
" ]; echo $?)" != 0 ]; then
            while read -r -d $'\n'; do result_872+=("$REPLY"); done < <(echo "$text_870")
            __status=$?
        else
            IFS="${delimiter_871}" read -rd '' -a result_872 < <(printf %s "$text_870")
            __status=$?
        fi
    elif [ "$([ "_${EXEC_SHELL}" != "_bash" ]; echo $?)" != 0 ]; then
        IFS="${delimiter_871}" read -rd '' -a result_872 < <(printf %s "$text_870")
        __status=$?
    fi
    ret_split4_v0=("${result_872[@]}")
    return 0
}

# split_lines(text: Text)
split_lines__5_v0() {
    local text_869="${1}"
    split__4_v0 "${text_869}" "
"
    ret_split_lines5_v0=("${ret_split4_v0[@]}")
    return 0
}

# join(list: [Text], delimiter: Text)
join__7_v0() {
    local list_406=("${!1}")
    local delimiter_407="${2}"
    local command_5
    command_5="$(IFS="${delimiter_407}" ; printf "%s
" "${list_406[*]}")"
    __status=$?
    ret_join7_v0="${command_5}"
    return 0
}

# trim(text: Text)
trim__10_v0() {
    local text_92="${1}"
    local result_93=""
    result_93="${text_92#${text_92%%[![:space:]]*}}"
    __status=$?
    result_93="${result_93%${result_93##*[![:space:]]}}"
    __status=$?
    ret_trim10_v0="${result_93}"
    return 0
}

# dir_exists(path: Text)
dir_exists__38_v0() {
    local path_73="${1}"
    [ -d "${path_73}" ]
    __status=$?
    ret_dir_exists38_v0="$(( __status == 0 ))"
    return 0
}

# file_exists(path: Text)
file_exists__39_v0() {
    local path_54="${1}"
    [ -f "${path_54}" ]
    __status=$?
    ret_file_exists39_v0="$(( __status == 0 ))"
    return 0
}

# file_write(path: Text, content: Text)
file_write__41_v0() {
    local path_434="${1}"
    local content_435="${2}"
    local command_6
    command_6="$(printf '%s
' "${content_435}" > "${path_434}")"
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
    local path_427="${1}"
    dir_exists__38_v0 "${path_427}"
    local ret_dir_exists38_v0__87_12="${ret_dir_exists38_v0}"
    if [ "$(( ! ret_dir_exists38_v0__87_12 ))" != 0 ]; then
        mkdir -p "${path_427}"
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
    local template_89="${1}"
    local auto_delete_90="${2}"
    local force_delete_91="${3}"
    trim__10_v0 "${template_89}"
    local ret_trim10_v0__113_8="${ret_trim10_v0}"
    if [ "$([ "_${ret_trim10_v0__113_8}" != "_" ]; echo $?)" != 0 ]; then
        echo "The template cannot be an empty string"'!'""
        ret_temp_dir_create46_v0=''
        return 1
    fi
    local filename_94=""
    is_mac_os_mktemp__45_v0 
    local ret_is_mac_os_mktemp45_v0__119_8="${ret_is_mac_os_mktemp45_v0}"
    if [ "${ret_is_mac_os_mktemp45_v0__119_8}" != 0 ]; then
        # usage: mktemp [-d] [-p tmpdir] [-q] [-t prefix] [-u] template ...
        # mktemp [-d] [-p tmpdir] [-q] [-u] -t prefix
        local command_7
        command_7="$(mktemp -d -p "$TMPDIR" "${template_89}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_temp_dir_create46_v0=''
            return "${__status}"
        fi
        filename_94="${command_7}"
    else
        local command_8
        command_8="$(mktemp -d -p "$TMPDIR" -t "${template_89}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_temp_dir_create46_v0=''
            return "${__status}"
        fi
        filename_94="${command_8}"
    fi
    if [ "$([ "_${filename_94}" != "_" ]; echo $?)" != 0 ]; then
        echo "Failed to make a temporary directory"
        ret_temp_dir_create46_v0=''
        return 1
    fi
    if [ "$(( auto_delete_90 && $([ "_${EXEC_SHELL}" == "_ksh" ]; echo $?) ))" != 0 ]; then
        if [ "${force_delete_91}" != 0 ]; then
            trap 'rm -rf '"${filename_94}"'' EXIT
            __status=$?
            if [ "${__status}" != 0 ]; then
                echo "Setting auto deletion fails. You must delete temporary dir ${filename_94}."
            fi
        else
            trap 'rmdir '"${filename_94}"'' EXIT
            __status=$?
            if [ "${__status}" != 0 ]; then
                echo "Setting auto deletion fails. You must delete temporary dir ${filename_94}."
            fi
        fi
    fi
    ret_temp_dir_create46_v0="${filename_94}"
    return 0
}

# env_var_get(name: Text)
env_var_get__124_v0() {
    local name_399="${1}"
    if [ "$([ "_${EXEC_SHELL}" != "_bash" ]; echo $?)" != 0 ]; then
        local command_9
        command_9="$(printf "%s
" "${!name_399}")"
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
" "${(P)name_399}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_env_var_get124_v0=''
            return "${__status}"
        fi
        ret_env_var_get124_v0="${command_10}"
        return 0
    elif [ "$([ "_${EXEC_SHELL}" != "_ksh" ]; echo $?)" != 0 ]; then
        local command_11
        command_11="$(eval "echo \${$name_399}")"
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
    local format_413="${1}"
    local args_414=("${!2}")
    args_414=("${format_413}" "${args_414[@]}")
    __status=$?
    printf "${args_414[@]}"
    __status=$?
}

# echo_warning(message: Text)
echo_warning__141_v0() {
    local message_419="${1}"
    local array_12=("${message_419}")
    printf__132_v0 "\\x1b[1;3;97;43m%s\\x1b[0m
" array_12[@]
}

# echo_error(message: Text, exit_code: Int)
echo_error__142_v0() {
    local message_411="${1}"
    local exit_code_412="${2}"
    local array_13=("${message_411}")
    printf__132_v0 "\\x1b[1;3;97;41m%s\\x1b[0m
" array_13[@]
    if [ "$(( exit_code_412 > 0 ))" != 0 ]; then
        exit "${exit_code_412}"
    fi
}

# has_cmd(cmd: Text)
has_cmd__165_v0() {
    local cmd_404="${1}"
    local found_405=0
    command -v ${cmd_404} >/dev/null 2>&1
    __status=$?
    if [ "${__status}" = 0 ]; then
        found_405=1
    fi
    ret_has_cmd165_v0="${found_405}"
    return 0
}

# echo_error exits the process (default exit_code=1), so no fail needed.
# sudo_cmd(cmd: Text, envvar: [])
sudo_cmd__169_v0() {
    local cmd_402="${1}"
    local envvar_403=("${!2}")
    has_cmd__165_v0 "sudo"
    local ret_has_cmd165_v0__4_8="${ret_has_cmd165_v0}"
    if [ "${ret_has_cmd165_v0__4_8}" != 0 ]; then
        sudo ${envvar_403[@]} ${cmd_402}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd169_v0=''
            return "${__status}"
        fi
    else
        env ${envvar_403[@]} ${cmd_402}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd169_v0=''
            return "${__status}"
        fi
    fi
}

# sudo_cmd(cmd: Text, envvar: [Text])
sudo_cmd__169_v1() {
    local cmd_409="${1}"
    local envvar_410=("${!2}")
    has_cmd__165_v0 "sudo"
    local ret_has_cmd165_v0__4_8="${ret_has_cmd165_v0}"
    if [ "${ret_has_cmd165_v0__4_8}" != 0 ]; then
        sudo ${envvar_410[@]} ${cmd_409}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd169_v1=''
            return "${__status}"
        fi
    else
        env ${envvar_410[@]} ${cmd_409}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd169_v1=''
            return "${__status}"
        fi
    fi
}

# prompt_user(description: Text)
prompt_user__172_v0() {
    local description_398="${1}"
    env_var_get__124_v0 "COPALS_ASK"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_prompt_user172_v0=1
        return 0
    fi
    local ask_400="${ret_env_var_get124_v0}"
    if [ "$([ "_${ask_400}" != "_" ]; echo $?)" != 0 ]; then
        ret_prompt_user172_v0=1
        return 0
    fi
    echo "install: ${description_398}"
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
    local ans_401="${command_14}"
    if [ "$([ "_${ans_401}" != "_" ]; echo $?)" != 0 ]; then
        ret_prompt_user172_v0=1
        return 0
    fi
    if [ "$(( $(( $(( $(( $([ "_${ans_401}" != "_n" ]; echo $?) || $([ "_${ans_401}" != "_N" ]; echo $?) )) || $([ "_${ans_401}" != "_no" ]; echo $?) )) || $([ "_${ans_401}" != "_NO" ]; echo $?) )) || $([ "_${ans_401}" != "_No" ]; echo $?) ))" != 0 ]; then
        echo "skipping"
        ret_prompt_user172_v0=0
        return 0
    fi
    ret_prompt_user172_v0=1
    return 0
}

# has_cmd(cmd: Text)
has_cmd__175_v0() {
    local cmd_417="${1}"
    local found_418=0
    command -v ${cmd_417} >/dev/null 2>&1
    __status=$?
    if [ "${__status}" = 0 ]; then
        found_418=1
    fi
    ret_has_cmd175_v0="${found_418}"
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
    local packages_397=("${!1}")
    prompt_user__172_v0 "apt install: ${packages_397[@]}"
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
    join__7_v0 packages_397[@] " "
    local pkgs_408="${ret_join7_v0}"
    local array_16=("DEBIAN_FRONTEND=noninteractive")
    sudo_cmd__169_v1 "apt-get install -y --no-install-recommends ${pkgs_408}" array_16[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_apt_install181_v0=''
        return "${__status}"
    fi
}

# apt_install_or_die(packages: [Text])
apt_install_or_die__182_v0() {
    local packages_396=("${!1}")
    apt_install__181_v0 packages_396[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to apt install ${packages_396[@]}" 1
    fi
}

# Non-fatal variant of apt_install_or_die: on failure it prints a warning and
# continues instead of exiting. Use for optional packages that may be absent
# from the target distro (e.g. jj, which is not in Debian apt).
# apt_install_or_warning(packages: [Text])
apt_install_or_warning__183_v0() {
    local packages_670=("${!1}")
    apt_install__181_v0 packages_670[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_warning__141_v0 "could not apt install ${packages_670[@]} - skipping"
    fi
}

# apt_install_if_missing_or_die(cmd: Text, pkg: Text)
apt_install_if_missing_or_die__184_v0() {
    local cmd_415="${1}"
    local pkg_416="${2}"
    has_cmd__175_v0 "${cmd_415}"
    local ret_has_cmd175_v0__43_8="${ret_has_cmd175_v0}"
    if [ "${ret_has_cmd175_v0__43_8}" != 0 ]; then
        echo_warning__141_v0 "${cmd_415} already installed, skipping apt install"
    else
        local array_17=("${pkg_416}")
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
    local src_423="${1}"
    local rel_dest_424="${2}"
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_copy_into_home195_v0=''
        return "${__status}"
    fi
    local home_425="${ret_home188_v0}"
    local dest_426="${home_425}/${rel_dest_424}"
    dir_create__44_v0 "${dest_426}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_copy_into_home195_v0=''
        return "${__status}"
    fi
    local __cp_18=
    (( 1 )) && __cp_18="-f" || __cp_18=""
    cp -r ${__cp_18} "${src_423}" "${dest_426}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_copy_into_home195_v0=''
        return "${__status}"
    fi
    ret_copy_into_home195_v0="${dest_426}"
    return 0
}

# copy_into_home_or_die(src: Text, rel_dest: Text)
copy_into_home_or_die__196_v0() {
    local src_421="${1}"
    local rel_dest_422="${2}"
    prompt_user__172_v0 "cp into home: ${rel_dest_422}"
    local ret_prompt_user172_v0__23_12="${ret_prompt_user172_v0}"
    if [ "$(( ! ret_prompt_user172_v0__23_12 ))" != 0 ]; then
        ret_copy_into_home_or_die196_v0=""
        return 0
    fi
    copy_into_home__195_v0 "${src_421}" "${rel_dest_422}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "deploy of ${rel_dest_422} into home failed" 1
    fi
    local dest_428="${ret_copy_into_home195_v0}"
    ret_copy_into_home_or_die196_v0="${dest_428}"
    return 0
}

# dir_create_at_home(rel: Text)
dir_create_at_home__202_v0() {
    local rel_430="${1}"
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_dir_create_at_home202_v0=''
        return "${__status}"
    fi
    local h_431="${ret_home188_v0}"
    dir_create__44_v0 "${h_431}/${rel_430}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_dir_create_at_home202_v0=''
        return "${__status}"
    fi
}

# dir_create_at_home_or_die(rel: Text)
dir_create_at_home_or_die__203_v0() {
    local rel_429="${1}"
    prompt_user__172_v0 "create directory ~/${rel_429}"
    local ret_prompt_user172_v0__12_8="${ret_prompt_user172_v0}"
    if [ "${ret_prompt_user172_v0__12_8}" != 0 ]; then
        dir_create_at_home__202_v0 "${rel_429}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "failed to create directory at home/${rel_429}" 1
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
    local h_432="${1}"
    local path_433="${h_432}/.local/bin/st-zsh"
    ret_make_nnn_desktop210_v0="[Desktop Entry]
Type=Application
Name=File Explorer (nnn)
Comment=Terminal file manager
Exec=${path_433} -e ${h_432}/.local/bin/nnn-launch
Terminal=false
Categories=Utility;FileManager;
Icon=nnn
"
    return 0
}

# make_btop_desktop(h: Text)
make_btop_desktop__211_v0() {
    local h_436="${1}"
    local path_437="${h_436}/.local/bin/st-zsh"
    ret_make_btop_desktop211_v0="[Desktop Entry]
Type=Application
Name=System Monitor (btop)
Comment=Resource monitor
Exec=${path_437} -e btop
Terminal=false
Categories=System;Monitor;
Icon=btop
"
    return 0
}

# make_ncdu_desktop(h: Text)
make_ncdu_desktop__212_v0() {
    local h_438="${1}"
    local path_439="${h_438}/.local/bin/st-zsh"
    ret_make_ncdu_desktop212_v0="[Desktop Entry]
Type=Application
Name=Disk Usage (ncdu)
Comment=Disk usage analyzer
Exec=${path_439} -e ncdu
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
    local h_420="${ret_home207_v0}"
    copy_into_home_or_die__196_v0 "src/apt-essential-tools/.config/nnn" ".config/"
    copy_into_home_or_die__196_v0 "src/apt-essential-tools/.local/bin" ".local/"
    chmod +x ${h_420}/.config/nnn/plugins/zmarks ${h_420}/.config/nnn/plugins/nvim-cd ${h_420}/.config/nnn/plugins/bm-create ${h_420}/.config/nnn/plugins/win-open ${h_420}/.config/nnn/profile ${h_420}/.local/bin/nnn-launch
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to chmod nnn files" 1
    fi
    dir_create_at_home_or_die__203_v0 "${__APPS_DIR_4}"
    make_nnn_desktop__210_v0 "${h_420}"
    local ret_make_nnn_desktop210_v0__40_46="${ret_make_nnn_desktop210_v0}"
    file_write__41_v0 "${h_420}/${__APPS_DIR_4}/nnn.desktop" "${ret_make_nnn_desktop210_v0__40_46}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to write nnn.desktop" 1
    fi
    make_btop_desktop__211_v0 "${h_420}"
    local ret_make_btop_desktop211_v0__43_47="${ret_make_btop_desktop211_v0}"
    file_write__41_v0 "${h_420}/${__APPS_DIR_4}/btop.desktop" "${ret_make_btop_desktop211_v0__43_47}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to write btop.desktop" 1
    fi
    make_ncdu_desktop__212_v0 "${h_420}"
    local ret_make_ncdu_desktop212_v0__46_47="${ret_make_ncdu_desktop212_v0}"
    file_write__41_v0 "${h_420}/${__APPS_DIR_4}/ncdu.desktop" "${ret_make_ncdu_desktop212_v0__46_47}"
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
    local h_574="${ret_home188_v0}"
    file_exists__39_v0 "${h_574}/.gitignore_global"
    local ret_file_exists39_v0__7_12="${ret_file_exists39_v0}"
    if [ "$(( ! ret_file_exists39_v0__7_12 ))" != 0 ]; then
        ret_setup_global_gitignore218_v0=''
        return 1
    fi
    git config --global core.excludesFile ${h_574}/.gitignore_global
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

# rsync(src: Text, target: Text, excludes: [Text], delete: Bool)
rsync__227_v0() {
    local src_553="${1}"
    local target_554="${2}"
    local excludes_555=("${!3}")
    local delete_556="${4}"
    dir_create__44_v0 "${target_554}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync227_v0=''
        return "${__status}"
    fi
    local excludes_arr_557=()
    for exclude_558 in "${excludes_555[@]}"; do
        local s_559="${exclude_558}"
        excludes_arr_557+=("--exclude" "${s_559}")
    done
    local delopt_560=""
    if [ "${delete_556}" != 0 ]; then
        delopt_560="--delete"
    fi
    rsync -a ${delopt_560} ${excludes_arr_557[@]} ${src_553} ${target_554}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync227_v0=''
        return "${__status}"
    fi
}

# rsync(src: Text, target: Text, excludes: [], delete: Bool)
rsync__227_v1() {
    local src_765="${1}"
    local target_766="${2}"
    local excludes_767=("${!3}")
    local delete_768="${4}"
    dir_create__44_v0 "${target_766}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync227_v1=''
        return "${__status}"
    fi
    local excludes_arr_769=()
    for exclude_770 in "${excludes_767[@]}"; do
        local s_771="${exclude_770}"
        excludes_arr_769+=("--exclude" "${s_771}")
    done
    local delopt_772=""
    if [ "${delete_768}" != 0 ]; then
        delopt_772="--delete"
    fi
    rsync -a ${delopt_772} ${excludes_arr_769[@]} ${src_765} ${target_766}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync227_v1=''
        return "${__status}"
    fi
}

# rsync_into_home(src: Text, rel_target: Text, delete: Bool)
rsync_into_home__230_v0() {
    local src_759="${1}"
    local rel_target_760="${2}"
    local delete_761="${3}"
    local excludes_762=()
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync_into_home230_v0=''
        return "${__status}"
    fi
    local h_763="${ret_home188_v0}"
    local target_764="${h_763}/${rel_target_760}"
    dir_create__44_v0 "${target_764}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync_into_home230_v0=''
        return "${__status}"
    fi
    rsync__227_v1 "${src_759}" "${target_764}" excludes_762[@] "${delete_761}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync_into_home230_v0=''
        return "${__status}"
    fi
}

# rsync_or_die_into_home(src: Text, rel_target: Text, delete: Bool)
rsync_or_die_into_home__231_v0() {
    local src_756="${1}"
    local rel_target_757="${2}"
    local delete_758="${3}"
    prompt_user__172_v0 "rsync ${src_756} -> ~/${rel_target_757}"
    local ret_prompt_user172_v0__16_8="${ret_prompt_user172_v0}"
    if [ "${ret_prompt_user172_v0__16_8}" != 0 ]; then
        rsync_into_home__230_v0 "${src_756}" "${rel_target_757}" "${delete_758}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "rsync deploy of ${src_756} into ${rel_target_757} failed" 1
        fi
    fi
}

# rsync_or_die_opts(src: Text, target: Text, excludes: [Text], delete: Bool)
rsync_or_die_opts__232_v0() {
    local src_549="${1}"
    local target_550="${2}"
    local excludes_551=("${!3}")
    local delete_552="${4}"
    prompt_user__172_v0 "rsync ${src_549} -> ${target_550}"
    local ret_prompt_user172_v0__24_8="${ret_prompt_user172_v0}"
    if [ "${ret_prompt_user172_v0__24_8}" != 0 ]; then
        rsync__227_v0 "${src_549}" "${target_550}" excludes_551[@] "${delete_552}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "rsync deploy of ${src_549} into ${target_550} failed" 1
        fi
    fi
}

# rsync_or_die_opts_into_home(src: Text, rel_target: Text, excludes: [Text], delete: Bool)
rsync_or_die_opts_into_home__233_v0() {
    local src_544="${1}"
    local rel_target_545="${2}"
    local excludes_546=("${!3}")
    local delete_547="${4}"
    prompt_user__172_v0 "rsync ${src_544} -> ~/${rel_target_545}"
    local ret_prompt_user172_v0__32_8="${ret_prompt_user172_v0}"
    if [ "${ret_prompt_user172_v0__32_8}" != 0 ]; then
        home__188_v0 
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "rsync_or_die_opts_into_home: failed to resolve home directory" 1
            exit 1
        fi
        local h_548="${ret_home188_v0}"
        rsync_or_die_opts__232_v0 "${src_544}" "${h_548}/${rel_target_545}" excludes_546[@] "${delete_547}"
    fi
}

# _project_root()
_project_root__247_v0() {
    file_exists__39_v0 "src/copals.ab"
    local ret_file_exists39_v0__5_8="${ret_file_exists39_v0}"
    if [ "${ret_file_exists39_v0__5_8}" != 0 ]; then
        local pwd_val_55="$PWD"
        replace_regex__3_v0 "${pwd_val_55}" "/[^/]+\$" "" 1
        ret__project_root247_v0="${ret_replace_regex3_v0}"
        return 0
    fi
    ret__project_root247_v0="$PWD"
    return 0
}

_project_root__247_v0 
__PROJECT_ROOT_65="${ret__project_root247_v0}"
project_vendor_66="${__PROJECT_ROOT_65}/copals/vendor"
installed_vendor_67="/usr/lib/copals/vendor"
# The installed vendor dir is authoritative when copals runs inside its own
# container: the host repo is bind-mounted at the same absolute path, so the
# project vendor dir also "exists" but its tools are only populated inside the
# image. Prefer the installed tree whenever it actually holds the binaries.
# resolve_vendor_dir()
resolve_vendor_dir__248_v0() {
    dir_exists__38_v0 "${installed_vendor_67}"
    local ret_dir_exists38_v0__21_8="${ret_dir_exists38_v0}"
    file_exists__39_v0 "${installed_vendor_67}/jsonnet"
    local ret_file_exists39_v0__21_41="${ret_file_exists39_v0}"
    if [ "$(( ret_dir_exists38_v0__21_8 && ret_file_exists39_v0__21_41 ))" != 0 ]; then
        ret_resolve_vendor_dir248_v0="${installed_vendor_67}"
        return 0
    fi
    dir_exists__38_v0 "${project_vendor_66}"
    local ret_dir_exists38_v0__24_8="${ret_dir_exists38_v0}"
    file_exists__39_v0 "${project_vendor_66}/jsonnet"
    local ret_file_exists39_v0__24_39="${ret_file_exists39_v0}"
    if [ "$(( ret_dir_exists38_v0__24_8 && ret_file_exists39_v0__24_39 ))" != 0 ]; then
        ret_resolve_vendor_dir248_v0="${project_vendor_66}"
        return 0
    fi
    dir_exists__38_v0 "${installed_vendor_67}"
    local ret_dir_exists38_v0__27_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__27_8}" != 0 ]; then
        ret_resolve_vendor_dir248_v0="${installed_vendor_67}"
        return 0
    fi
    dir_exists__38_v0 "${project_vendor_66}"
    local ret_dir_exists38_v0__30_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__30_8}" != 0 ]; then
        ret_resolve_vendor_dir248_v0="${project_vendor_66}"
        return 0
    fi
    ret_resolve_vendor_dir248_v0=""
    return 0
}

resolve_vendor_dir__248_v0 
__VENDOR_DIR_74="${ret_resolve_vendor_dir248_v0}"
# jq_resolve()
jq_resolve__249_v0() {
    if [ "$([ "_${__VENDOR_DIR_74}" != "_" ]; echo $?)" != 0 ]; then
        ret_jq_resolve249_v0="jq"
        return 0
    fi
    ret_jq_resolve249_v0="${__VENDOR_DIR_74}/jq"
    return 0
}

# j2_resolve()
j2_resolve__250_v0() {
    if [ "$([ "_${__VENDOR_DIR_74}" != "_" ]; echo $?)" != 0 ]; then
        ret_j2_resolve250_v0="j2"
        return 0
    fi
    ret_j2_resolve250_v0="${__VENDOR_DIR_74}/j2"
    return 0
}

# jsonnet_resolve()
jsonnet_resolve__251_v0() {
    if [ "$([ "_${__VENDOR_DIR_74}" != "_" ]; echo $?)" != 0 ]; then
        ret_jsonnet_resolve251_v0="jsonnet"
        return 0
    fi
    ret_jsonnet_resolve251_v0="${__VENDOR_DIR_74}/jsonnet"
    return 0
}

# jsonschema_resolve()
jsonschema_resolve__252_v0() {
    if [ "$([ "_${__VENDOR_DIR_74}" != "_" ]; echo $?)" != 0 ]; then
        ret_jsonschema_resolve252_v0="jsonschema"
        return 0
    fi
    ret_jsonschema_resolve252_v0="${__VENDOR_DIR_74}/jsonschema"
    return 0
}

# lua_resolve()
lua_resolve__253_v0() {
    if [ "$([ "_${__VENDOR_DIR_74}" != "_" ]; echo $?)" != 0 ]; then
        ret_lua_resolve253_v0="lua"
        return 0
    fi
    ret_lua_resolve253_v0="${__VENDOR_DIR_74}/lua"
    return 0
}

jq_resolve__249_v0 
j2_resolve__250_v0 
jsonnet_resolve__251_v0 
jsonschema_resolve__252_v0 
lua_resolve__253_v0 
# dirname(path: Text)
dirname__255_v0() {
    local path_569="${1}"
    local command_31
    command_31="$(dirname ${path_569})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_dirname255_v0=''
        return "${__status}"
    fi
    ret_dirname255_v0="${command_31}"
    return 0
}

# Inverse of rm_if_feature_not: remove rel_path when features[feature] == expected
# (defaults to "" so an unset feature never triggers removal). Use to drop GUI
# artifacts in pure-TTY presets, e.g. mode == "tmux".
temp_dir_create__46_v0 "amber-XXXXXX" 1 1
__status=$?
if [ "${__status}" != 0 ]; then
    :
fi
__TMP_DIR_95="${ret_temp_dir_create46_v0}"
token_96=1
# temp_file_create(suffix: Text)
temp_file_create__273_v0() {
    local suffix_571="${1}"
    token_96="$(( token_96 + 1 ))"
    local tmp_572="${__TMP_DIR_95}/${token_96}${suffix_571}"
    touch "${tmp_572}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_temp_file_create273_v0=''
        return "${__status}"
    fi
    ret_temp_file_create273_v0="${tmp_572}"
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
# Marker lines wrapping the bundle-managed block. Plain ASCII, no glob/regex
# metacharacters that matter for sed except a single '.' in "install.sh" (a
# harmless wildcard). The "___DEVTOOLS_AUTOGEN___" token scopes this
# installer's block; other tools' managed blocks (nvm/pyenv/pathman, ...) are
# untouched. Begin/end are the single source of truth — they are interpolated
# into HELPER below, so there is no duplicate literal to drift.
__MANAGED_BEGIN_97="# BEGIN ___DEVTOOLS_AUTOGEN___ managed by install.sh - do not edit this block"
__MANAGED_END_98="# END ___DEVTOOLS_AUTOGEN___"
# Verbatim, blank-line-preserving splice. Amber's split()/split_lines() drop
# empty segments, so a pure-amber line-array pass would strip blank lines from
# the user's rc file and from the shipped body. sed's range delete keeps every
# line outside BEGIN..END byte-for-byte; $(cat ...) normalizes trailing
# newlines so the separator before the block is stable across re-runs (no
# blank-line accumulation -> idempotent). Written to a temp file and run with
# bash (amber's $...$ command literal cannot host the helper's $/quotes).
__HELPER_99="#"'!'"/usr/bin/env bash
set -euo pipefail
m1='${__MANAGED_BEGIN_97}'
m2='${__MANAGED_END_98}'
src=\"\$1\"
dest=\"\$2\"
tmp=\"\$(mktemp)\"
if [ -f \"\$dest\" ]; then
    sed \"/\$m1/,/\$m2/d\" \"\$dest\" > \"\$tmp\"
fi
: > \"\$dest\"
if [ -s \"\$tmp\" ]; then
    content=\"\$(cat \"\$tmp\")\"
    if [ -n \"\$content\" ]; then
        printf '%s\\n\\n' \"\$content\" >> \"\$dest\"
    fi
fi
printf '%s\\n' \"\$m1\" >> \"\$dest\"
printf '%s\\n' \"\$(cat \"\$src\")\" >> \"\$dest\"
printf '%s\\n' \"\$m2\" >> \"\$dest\"
rm -f \"\$tmp\"
"
# Refresh the managed block in `dest` (absolute path) so it contains exactly the
# shipped `src` content, wrapped in MANAGED_BEGIN/MANAGED_END. Merge-safe and
# idempotent: user content outside the block is preserved verbatim; re-running
# replaces the block instead of duplicating it. If `dest` is absent it is
# created holding just the block. Reusable for any source/dest pair.
# managed_block(src: Text, dest: Text)
managed_block__276_v0() {
    local src_567="${1}"
    local dest_568="${2}"
    dirname__255_v0 "${dest_568}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_managed_block276_v0=''
        return "${__status}"
    fi
    local parent_570="${ret_dirname255_v0}"
    dir_create__44_v0 "${parent_570}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_managed_block276_v0=''
        return "${__status}"
    fi
    temp_file_create__273_v0 "-managed_block.sh"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_managed_block276_v0=''
        return "${__status}"
    fi
    local helper_573="${ret_temp_file_create273_v0}"
    file_write__41_v0 "${helper_573}" "${__HELPER_99}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_managed_block276_v0=''
        return "${__status}"
    fi
    bash ${helper_573} ${src_567} ${dest_568}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_managed_block276_v0=''
        return "${__status}"
    fi
    rm -f ${helper_573}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_managed_block276_v0=''
        return "${__status}"
    fi
}

# managed_block_into_home(src: Text, rel_dest: Text)
managed_block_into_home__277_v0() {
    local src_564="${1}"
    local rel_dest_565="${2}"
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_managed_block_into_home277_v0=''
        return "${__status}"
    fi
    local h_566="${ret_home188_v0}"
    managed_block__276_v0 "${src_564}" "${h_566}/${rel_dest_565}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_managed_block_into_home277_v0=''
        return "${__status}"
    fi
}

# managed_block_or_die_into_home(src: Text, rel_dest: Text)
managed_block_or_die_into_home__279_v0() {
    local src_562="${1}"
    local rel_dest_563="${2}"
    prompt_user__172_v0 "managed-block merge ${src_562} -> ~/${rel_dest_563}"
    local ret_prompt_user172_v0__54_8="${ret_prompt_user172_v0}"
    if [ "${ret_prompt_user172_v0__54_8}" != 0 ]; then
        managed_block_into_home__277_v0 "${src_562}" "${rel_dest_563}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "managed-block merge of ${src_562} into ${rel_dest_563} failed" 1
        fi
    fi
}

# rc/config files that may already exist on the box with user edits. These are
# merge-managed (marker-delimited block) instead of rsync-clobbered, so a
# developer's existing shell config survives reinstall. Everything else in the
# dir (aliases/, Sh/, .local/, .tmux.conf, .gitignore_global, ...) is
# bundle-owned and rsync'd normally. Add filenames here to extend coverage.
# install_dotfiles_personalization()
install_dotfiles_personalization__281_v0() {
    local merge_files_543=(".zshrc" ".bashrc" ".zshenv" ".aliases")
    # rsync the whole tree EXCEPT the merge-managed files, so they are neither
    # created nor clobbered by rsync; managed_block reconciles them below.
    rsync_or_die_opts_into_home__233_v0 "src/dotfiles_personalization/" "" merge_files_543[@] 0
    # merge-manage each rc/config file into home (idempotent; preserves user
    # content outside the marker-delimited block).
    for f_561 in "${merge_files_543[@]}"; do
        managed_block_or_die_into_home__279_v0 "src/dotfiles_personalization/${f_561}" "${f_561}"
    done
    setup_global_gitignore_or_die__219_v0 
    # applications/ is removed at generate time for the tmux preset; copy only if present.
    test -d "src/dotfiles_personalization/.local/share/applications"
    __status=$?
    if [ "${__status}" = 0 ]; then
        copy_into_home_or_die__196_v0 "src/dotfiles_personalization/.local/share/applications" ".local/share/applications"
    fi
}

# symlink_create_dir(origin: Text, destination: Text)
symlink_create_dir__289_v0() {
    local origin_627="${1}"
    local destination_628="${2}"
    dir_exists__38_v0 "${origin_627}"
    local ret_dir_exists38_v0__4_12="${ret_dir_exists38_v0}"
    if [ "$(( ! ret_dir_exists38_v0__4_12 ))" != 0 ]; then
        echo "The directory ${origin_627} doesn't exist"
        ret_symlink_create_dir289_v0=''
        return 1
    fi
    ln -fsn ${origin_627} ${destination_628}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_create_dir289_v0=''
        return "${__status}"
    fi
}

# TODO test this
# _parent_dir(path: Text)
_parent_dir__292_v0() {
    local path_623="${1}"
    local command_35
    command_35="$(dirname ${path_623})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret__parent_dir292_v0=''
        return "${__status}"
    fi
    local parent_624="${command_35}"
    ret__parent_dir292_v0="${parent_624}"
    return 0
}

# symlink_into_home(src: Text, rel_dest: Text)
symlink_into_home__293_v0() {
    local src_619="${1}"
    local rel_dest_620="${2}"
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home293_v0=''
        return "${__status}"
    fi
    local home_621="${ret_home188_v0}"
    local dest_622="${home_621}/${rel_dest_620}"
    _parent_dir__292_v0 "${dest_622}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home293_v0=''
        return "${__status}"
    fi
    local parent_625="${ret__parent_dir292_v0}"
    dir_create__44_v0 "${parent_625}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home293_v0=''
        return "${__status}"
    fi
    local command_36
    command_36="$(readlink -f ${src_619})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home293_v0=''
        return "${__status}"
    fi
    local abs_src_626="${command_36}"
    symlink_create_dir__289_v0 "${abs_src_626}" "${dest_622}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home293_v0=''
        return "${__status}"
    fi
    ret_symlink_into_home293_v0="${dest_622}"
    return 0
}

# symlink_into_home_or_die(src: Text, rel_dest: Text)
symlink_into_home_or_die__294_v0() {
    local src_617="${1}"
    local rel_dest_618="${2}"
    prompt_user__172_v0 "symlink ${src_617} -> ~/${rel_dest_618}"
    local ret_prompt_user172_v0__26_12="${ret_prompt_user172_v0}"
    if [ "$(( ! ret_prompt_user172_v0__26_12 ))" != 0 ]; then
        ret_symlink_into_home_or_die294_v0=""
        return 0
    fi
    symlink_into_home__293_v0 "${src_617}" "${rel_dest_618}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "deploy of ${src_617} symlink ${rel_dest_618}  into home failed" 1
    fi
    local dest_629="${ret_symlink_into_home293_v0}"
    ret_symlink_into_home_or_die294_v0="${dest_629}"
    return 0
}

# Symlink a home-relative path to another home-relative path (both resolved
# against home()). Works for files (e.g. bridging a data file from one config
# location to the path a plugin expects).
# symlink_at_home(src_rel: Text, dest_rel: Text)
symlink_at_home__295_v0() {
    local src_rel_701="${1}"
    local dest_rel_702="${2}"
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_at_home295_v0=''
        return "${__status}"
    fi
    local h_703="${ret_home188_v0}"
    local src_704="${h_703}/${src_rel_701}"
    local dest_705="${h_703}/${dest_rel_702}"
    file_exists__39_v0 "${src_704}"
    local ret_file_exists39_v0__43_12="${ret_file_exists39_v0}"
    if [ "$(( ! ret_file_exists39_v0__43_12 ))" != 0 ]; then
        echo_error__142_v0 "symlink source ${src_704} missing" 1
        ret_symlink_at_home295_v0=''
        return 1
    fi
    _parent_dir__292_v0 "${dest_705}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_at_home295_v0=''
        return "${__status}"
    fi
    local parent_706="${ret__parent_dir292_v0}"
    dir_create__44_v0 "${parent_706}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_at_home295_v0=''
        return "${__status}"
    fi
    ln -fsn ${src_704} ${dest_705}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_at_home295_v0=''
        return "${__status}"
    fi
    ret_symlink_at_home295_v0="${dest_705}"
    return 0
}

# symlink_at_home_or_die(src_rel: Text, dest_rel: Text)
symlink_at_home_or_die__296_v0() {
    local src_rel_699="${1}"
    local dest_rel_700="${2}"
    prompt_user__172_v0 "symlink ~/${src_rel_699} -> ~/${dest_rel_700}"
    local ret_prompt_user172_v0__57_12="${ret_prompt_user172_v0}"
    if [ "$(( ! ret_prompt_user172_v0__57_12 ))" != 0 ]; then
        ret_symlink_at_home_or_die296_v0=""
        return 0
    fi
    symlink_at_home__295_v0 "${src_rel_699}" "${dest_rel_700}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "symlink ${src_rel_699} -> ${dest_rel_700} in home failed" 1
    fi
    local dest_707="${ret_symlink_at_home295_v0}"
    ret_symlink_at_home_or_die296_v0="${dest_707}"
    return 0
}

# install_nerd_fonts()
install_nerd_fonts__298_v0() {
    local subpath_616=".local/share/fonts/NerdFonts"
    symlink_into_home_or_die__294_v0 "src/${subpath_616}" "${subpath_616}"
}

# set_only_user_write_or_die(path: Text)
set_only_user_write_or_die__303_v0() {
    local path_641="${1}"
    chmod -R g-w,o-w ${path_641}
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to set ${path_641} perms to user-only write" 1
    fi
}

# set_only_user_write_or_die_at_home(rel_path: Text)
set_only_user_write_or_die_at_home__304_v0() {
    local rel_path_639="${1}"
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "cannot determine home directory for ${rel_path_639}" 1
    fi
    local h_640="${ret_home188_v0}"
    set_only_user_write_or_die__303_v0 "${h_640}/${rel_path_639}"
}

# install_omz_config()
install_omz_config__307_v0() {
    local subpath_638=".oh-my-zsh"
    local array_37=("custom/plugins/")
    rsync_or_die_opts_into_home__233_v0 "src/${subpath_638}/" "${subpath_638}" array_37[@] 1
    set_only_user_write_or_die_at_home__304_v0 "${subpath_638}"
}

# execute(bin: Text, sh_path: Text)
execute__311_v0() {
    local bin_660="${1}"
    local sh_path_661="${2}"
    ${bin_660} ${sh_path_661}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute311_v0=''
        return "${__status}"
    fi
}

# execute_sh(sh_path: Text)
execute_sh__312_v0() {
    local sh_path_796="${1}"
    execute__311_v0 "bash" "${sh_path_796}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_sh312_v0=''
        return "${__status}"
    fi
}

# execute_zsh(sh_path: Text)
execute_zsh__313_v0() {
    local sh_path_659="${1}"
    execute__311_v0 "zsh" "${sh_path_659}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_zsh313_v0=''
        return "${__status}"
    fi
}

# execute_zsh_at_home(rel_sh_path: Text)
execute_zsh_at_home__316_v0() {
    local rel_sh_path_657="${1}"
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_zsh_at_home316_v0=''
        return "${__status}"
    fi
    local h_658="${ret_home188_v0}"
    execute_zsh__313_v0 "${h_658}/${rel_sh_path_657}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_zsh_at_home316_v0=''
        return "${__status}"
    fi
}

# install_zshmarks()
install_zshmarks__319_v0() {
    mkdir -p ~/.oh-my-zsh/custom/plugins/zshmarks
    __status=$?
    cp src/zshmarks.plugin.zsh ~/.oh-my-zsh/custom/plugins/zshmarks/zshmarks.plugin.zsh
    __status=$?
    execute_zsh_at_home__316_v0 ".oh-my-zsh/custom/plugins/zshmarks/zshmarks.plugin.zsh"
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
has_cmd__324_v0() {
    local cmd_668="${1}"
    local found_669=0
    command -v ${cmd_668} >/dev/null 2>&1
    __status=$?
    if [ "${__status}" = 0 ]; then
        found_669=1
    fi
    ret_has_cmd324_v0="${found_669}"
    return 0
}

# echo_error exits the process (default exit_code=1), so no fail needed.
# install_system_tools()
install_system_tools__353_v0() {
    local array_38=("ncdu")
    apt_install_or_die__182_v0 array_38[@]
    has_cmd__324_v0 "jj"
    local ret_has_cmd324_v0__12_12="${ret_has_cmd324_v0}"
    if [ "$(( ! ret_has_cmd324_v0__12_12 ))" != 0 ]; then
        local array_39=("jj")
        apt_install_or_warning__183_v0 array_39[@]
    fi
}

# install_nvim()
install_nvim__358_v0() {
    local array_40=("fd-find" "clang" "g++")
    apt_install_or_die__182_v0 array_40[@]
    local subpath_697=".config/nvim"
    symlink_into_home_or_die__294_v0 "src/${subpath_697}" "${subpath_697}"
    local lazy_dir_698="${subpath_697}/lazy"
    symlink_into_home_or_die__294_v0 "src/${lazy_dir_698}" ".local/share/nvim/lazy"
    # quicksheet reads ~/.config/quicksheet.txt; the data ships from the nvim
    # repo as ~/.config/nvim/quicksheet.txt. Symlink it so quicksheet finds it.
    symlink_at_home_or_die__296_v0 ".config/nvim/quicksheet.txt" ".config/quicksheet.txt"
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
install_quicksheet__360_v0() {
    :
}

# install_tmux_warm_daemon()
install_tmux_warm_daemon__364_v0() {
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
install_tmux_wm__370_v0() {
    local array_41=("tmux")
    apt_install_or_die__182_v0 array_41[@]
    copy_into_home_or_die__196_v0 "src/tmux_wm/.config/tmux" ".config/"
    copy_into_home_or_die__196_v0 "src/tmux_wm/.local/bin" ".local/"
    home__207_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "tmux_wm: cannot resolve HOME" 1
    fi
    local h_774="${ret_home207_v0}"
    chmod +x ${h_774}/.local/bin/tmux-wm ${h_774}/.local/bin/tmux-default ${h_774}/.local/bin/fzf-launcher ${h_774}/.local/bin/tmux-wm-move ${h_774}/.local/bin/tmux-wm-terminal ${h_774}/.local/bin/tmux-wm-open ${h_774}/.local/bin/tmux-wm-swap ${h_774}/.local/bin/nnn-wm
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "tmux_wm: failed to chmod scripts" 1
    fi
}

# install_cmd_bookmarks()
install_cmd_bookmarks__373_v0() {
    symlink_into_home_or_die__294_v0 "src/cmd_bookmarks" ".local/share/cmd_bookmarks"
}

# execute_sh_at_home(rel_sh_path: Text)
execute_sh_at_home__380_v0() {
    local rel_sh_path_794="${1}"
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_sh_at_home380_v0=''
        return "${__status}"
    fi
    local h_795="${ret_home188_v0}"
    execute_sh__312_v0 "${h_795}/${rel_sh_path_794}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_sh_at_home380_v0=''
        return "${__status}"
    fi
}

# execute_sh_at_home_or_die(rel_sh_path: Text)
execute_sh_at_home_or_die__381_v0() {
    local rel_sh_path_793="${1}"
    prompt_user__172_v0 "execute ~/${rel_sh_path_793}"
    local ret_prompt_user172_v0__12_8="${ret_prompt_user172_v0}"
    if [ "${ret_prompt_user172_v0__12_8}" != 0 ]; then
        execute_sh_at_home__380_v0 "${rel_sh_path_793}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "failed to run ${rel_sh_path_793}" 1
        fi
    fi
}

# install_agent_global_config()
install_agent_global_config__386_v0() {
    rsync_or_die_into_home__231_v0 "src/.agent/" ".agent" 1
    home__207_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "install_agent_global_config: home unresolved" 1
        exit 1
    fi
    local h_790="${ret_home207_v0}"
    local scripts_791=("sync-permissions-from-cli.sh" "sync-permissions.sh" "sync-antigravity-permissions.sh" "sync-kilocode-permissions.sh")
    for script_792 in "${scripts_791[@]}"; do
        file_exists__39_v0 "${h_790}/.agent/${script_792}"
        local ret_file_exists39_v0__20_12="${ret_file_exists39_v0}"
        if [ "${ret_file_exists39_v0__20_12}" != 0 ]; then
            execute_sh_at_home_or_die__381_v0 ".agent/${script_792}"
        fi
    done
}

# _project_root()
_project_root__395_v0() {
    file_exists__39_v0 "src/copals.ab"
    local ret_file_exists39_v0__5_8="${ret_file_exists39_v0}"
    if [ "${ret_file_exists39_v0__5_8}" != 0 ]; then
        local pwd_val_102="$PWD"
        replace_regex__3_v0 "${pwd_val_102}" "/[^/]+\$" "" 1
        ret__project_root395_v0="${ret_replace_regex3_v0}"
        return 0
    fi
    ret__project_root395_v0="$PWD"
    return 0
}

_project_root__395_v0 
__PROJECT_ROOT_103="${ret__project_root395_v0}"
project_vendor_104="${__PROJECT_ROOT_103}/copals/vendor"
installed_vendor_105="/usr/lib/copals/vendor"
# The installed vendor dir is authoritative when copals runs inside its own
# container: the host repo is bind-mounted at the same absolute path, so the
# project vendor dir also "exists" but its tools are only populated inside the
# image. Prefer the installed tree whenever it actually holds the binaries.
# resolve_vendor_dir()
resolve_vendor_dir__396_v0() {
    dir_exists__38_v0 "${installed_vendor_105}"
    local ret_dir_exists38_v0__21_8="${ret_dir_exists38_v0}"
    file_exists__39_v0 "${installed_vendor_105}/jsonnet"
    local ret_file_exists39_v0__21_41="${ret_file_exists39_v0}"
    if [ "$(( ret_dir_exists38_v0__21_8 && ret_file_exists39_v0__21_41 ))" != 0 ]; then
        ret_resolve_vendor_dir396_v0="${installed_vendor_105}"
        return 0
    fi
    dir_exists__38_v0 "${project_vendor_104}"
    local ret_dir_exists38_v0__24_8="${ret_dir_exists38_v0}"
    file_exists__39_v0 "${project_vendor_104}/jsonnet"
    local ret_file_exists39_v0__24_39="${ret_file_exists39_v0}"
    if [ "$(( ret_dir_exists38_v0__24_8 && ret_file_exists39_v0__24_39 ))" != 0 ]; then
        ret_resolve_vendor_dir396_v0="${project_vendor_104}"
        return 0
    fi
    dir_exists__38_v0 "${installed_vendor_105}"
    local ret_dir_exists38_v0__27_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__27_8}" != 0 ]; then
        ret_resolve_vendor_dir396_v0="${installed_vendor_105}"
        return 0
    fi
    dir_exists__38_v0 "${project_vendor_104}"
    local ret_dir_exists38_v0__30_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__30_8}" != 0 ]; then
        ret_resolve_vendor_dir396_v0="${project_vendor_104}"
        return 0
    fi
    ret_resolve_vendor_dir396_v0=""
    return 0
}

resolve_vendor_dir__396_v0 
__VENDOR_DIR_106="${ret_resolve_vendor_dir396_v0}"
# jq_resolve()
jq_resolve__397_v0() {
    if [ "$([ "_${__VENDOR_DIR_106}" != "_" ]; echo $?)" != 0 ]; then
        ret_jq_resolve397_v0="jq"
        return 0
    fi
    ret_jq_resolve397_v0="${__VENDOR_DIR_106}/jq"
    return 0
}

# j2_resolve()
j2_resolve__398_v0() {
    if [ "$([ "_${__VENDOR_DIR_106}" != "_" ]; echo $?)" != 0 ]; then
        ret_j2_resolve398_v0="j2"
        return 0
    fi
    ret_j2_resolve398_v0="${__VENDOR_DIR_106}/j2"
    return 0
}

# jsonnet_resolve()
jsonnet_resolve__399_v0() {
    if [ "$([ "_${__VENDOR_DIR_106}" != "_" ]; echo $?)" != 0 ]; then
        ret_jsonnet_resolve399_v0="jsonnet"
        return 0
    fi
    ret_jsonnet_resolve399_v0="${__VENDOR_DIR_106}/jsonnet"
    return 0
}

# jsonschema_resolve()
jsonschema_resolve__400_v0() {
    if [ "$([ "_${__VENDOR_DIR_106}" != "_" ]; echo $?)" != 0 ]; then
        ret_jsonschema_resolve400_v0="jsonschema"
        return 0
    fi
    ret_jsonschema_resolve400_v0="${__VENDOR_DIR_106}/jsonschema"
    return 0
}

# lua_resolve()
lua_resolve__401_v0() {
    if [ "$([ "_${__VENDOR_DIR_106}" != "_" ]; echo $?)" != 0 ]; then
        ret_lua_resolve401_v0="lua"
        return 0
    fi
    ret_lua_resolve401_v0="${__VENDOR_DIR_106}/lua"
    return 0
}

jq_resolve__397_v0 
j2_resolve__398_v0 
jsonnet_resolve__399_v0 
jsonschema_resolve__400_v0 
lua_resolve__401_v0 
# Inverse of rm_if_feature_not: remove rel_path when features[feature] == expected
# (defaults to "" so an unset feature never triggers removal). Use to drop GUI
# artifacts in pure-TTY presets, e.g. mode == "tmux".
# install_agent_skills_impl()
install_agent_skills_impl__425_v0() {
    home__207_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_agent_skills_impl425_v0=''
        return "${__status}"
    fi
    local h_805="${ret_home207_v0}"
    local canon_806="${h_805}/.agents/skills"
    local skills_src_807="src/agent-skills/.agents/skills"
    rsync_or_die_into_home__231_v0 "${skills_src_807}/" ".agents/skills" 0
    dir_exists__38_v0 "${canon_806}"
    local ret_dir_exists38_v0__49_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__49_8}" != 0 ]; then
        local legacy_dir_808="${h_805}/.cursor/skills-cursor"
        dir_exists__38_v0 "${legacy_dir_808}"
        local ret_dir_exists38_v0__51_12="${ret_dir_exists38_v0}"
        if [ "${ret_dir_exists38_v0__51_12}" != 0 ]; then
            local __rm_47=
            (( 1 )) && __rm_47="-r" || __rm_47=""
            local __rm_48=
            rm ${__rm_48} ${__rm_47} "${legacy_dir_808}"
        fi
        # 2. Wire the store into each ENABLED tool. Antigravity reads ~/.agents/skills natively, so it needs no link.
    fi
}

# install_agent_skills()
install_agent_skills__426_v0() {
    install_agent_skills_impl__425_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to install agent skills" 1
    fi
}

# install_skill_caveman()
install_skill_caveman__429_v0() {
    symlink_into_home_or_die__294_v0 "src/.agents/skills/caveman" ".agents/skills/caveman"
}

# install_skill_humanizer()
install_skill_humanizer__432_v0() {
    symlink_into_home_or_die__294_v0 "src/.agents/skills/humanizer" ".agents/skills/humanizer"
}

# install_skill_ponytail()
install_skill_ponytail__435_v0() {
    symlink_into_home_or_die__294_v0 "src/.agents/skills/ponytail" ".agents/skills/ponytail"
}

# Each hook must be IDEMPOTENT and KILL THE PROGRAM on failure.
# Inside the hook, propagate failures with ? via a *_impl(): Null? helper, then
# wrap it once at the installer level:  install_x() { x_impl() failed { exit(1) } }
# So every install_*() is infallible and main() stays a plain sequence of calls.
# print_help()
print_help__437_v0() {
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
run_step__438_v0() {
    local step_891="${1}"
    local matched_892=0
    if [ "$([ "_${step_891}" != "_help" ]; echo $?)" != 0 ]; then
        print_help__437_v0 
        matched_892=1
    fi
    if [ "$([ "_${step_891}" != "_apt_essential_tools" ]; echo $?)" != 0 ]; then
        install_apt_essential_tools__213_v0 
        matched_892=1
    fi
    if [ "$([ "_${step_891}" != "_dotfiles_personalization" ]; echo $?)" != 0 ]; then
        install_dotfiles_personalization__281_v0 
        matched_892=1
    fi
    if [ "$([ "_${step_891}" != "_nerd_fonts" ]; echo $?)" != 0 ]; then
        install_nerd_fonts__298_v0 
        matched_892=1
    fi
    if [ "$([ "_${step_891}" != "_omz_config" ]; echo $?)" != 0 ]; then
        install_omz_config__307_v0 
        matched_892=1
    fi
    if [ "$([ "_${step_891}" != "_zshmarks" ]; echo $?)" != 0 ]; then
        install_zshmarks__319_v0 
        matched_892=1
    fi
    if [ "$([ "_${step_891}" != "_system_tools" ]; echo $?)" != 0 ]; then
        install_system_tools__353_v0 
        matched_892=1
    fi
    if [ "$([ "_${step_891}" != "_nvim" ]; echo $?)" != 0 ]; then
        install_nvim__358_v0 
        matched_892=1
    fi
    if [ "$([ "_${step_891}" != "_quicksheet" ]; echo $?)" != 0 ]; then
        install_quicksheet__360_v0 
        matched_892=1
    fi
    if [ "$([ "_${step_891}" != "_tmux_warm_daemon" ]; echo $?)" != 0 ]; then
        install_tmux_warm_daemon__364_v0 
        matched_892=1
    fi
    if [ "$([ "_${step_891}" != "_tmux_wm" ]; echo $?)" != 0 ]; then
        install_tmux_wm__370_v0 
        matched_892=1
    fi
    if [ "$([ "_${step_891}" != "_cmd_bookmarks" ]; echo $?)" != 0 ]; then
        install_cmd_bookmarks__373_v0 
        matched_892=1
    fi
    if [ "$([ "_${step_891}" != "_agent_global_config" ]; echo $?)" != 0 ]; then
        install_agent_global_config__386_v0 
        matched_892=1
    fi
    if [ "$([ "_${step_891}" != "_agent_skills" ]; echo $?)" != 0 ]; then
        install_agent_skills__426_v0 
        matched_892=1
    fi
    if [ "$([ "_${step_891}" != "_skill_caveman" ]; echo $?)" != 0 ]; then
        install_skill_caveman__429_v0 
        matched_892=1
    fi
    if [ "$([ "_${step_891}" != "_skill_humanizer" ]; echo $?)" != 0 ]; then
        install_skill_humanizer__432_v0 
        matched_892=1
    fi
    if [ "$([ "_${step_891}" != "_skill_ponytail" ]; echo $?)" != 0 ]; then
        install_skill_ponytail__435_v0 
        matched_892=1
    fi
    if [ "$(( ! matched_892 ))" != 0 ]; then
        echo "Unknown step: '${step_891}'"
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
cmd_update__439_v0() {
    local command_50
    command_50="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_cmd_update439_v0=''
        return "${__status}"
    fi
    local script_dir_862="${command_50}"
    local meta_path_863="${script_dir_862}/meta.json"
    local state_path_864="${script_dir_862}/.last_installed.json"
    local command_51
    command_51="$(jq -r '.repo_hashes | to_entries[] | "\(.key)	\(.value)"' "${meta_path_863}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_cmd_update439_v0=''
        return "${__status}"
    fi
    local new_lines_865="${command_51}"
    local old_lines_866=""
    file_exists__39_v0 "${state_path_864}"
    local ret_file_exists39_v0__359_8="${ret_file_exists39_v0}"
    if [ "${ret_file_exists39_v0__359_8}" != 0 ]; then
        local command_52
        command_52="$(jq -r '.repo_hashes | to_entries[] | "\(.key)	\(.value)"' "${state_path_864}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_cmd_update439_v0=''
            return "${__status}"
        fi
        old_lines_866="${command_52}"
    fi
    local old_keys_867=()
    local old_vals_868=()
    if [ "$([ "_${old_lines_866}" == "_" ]; echo $?)" != 0 ]; then
        split_lines__5_v0 "${old_lines_866}"
        local rows_873=("${ret_split_lines5_v0[@]}")
        for row_874 in "${rows_873[@]}"; do
            if [ "$([ "_${row_874}" != "_" ]; echo $?)" != 0 ]; then
                continue
            fi
            split__4_v0 "	" "${row_874}"
            local parts_875=("${ret_split4_v0[@]}")
            local __length_57=("${parts_875[@]}")
            if [ "$(( ${#__length_57[@]} >= 2 ))" != 0 ]; then
                old_keys_867+=("${parts_875[0]?"Index out of bounds (at /tmp/jbtd-install-build-pU9sr2/install.ab:371:36)"}")
                old_vals_868+=("${parts_875[1]?"Index out of bounds (at /tmp/jbtd-install-build-pU9sr2/install.ab:372:36)"}")
            fi
        done
    fi
    local changed_876=()
    split_lines__5_v0 "${new_lines_865}"
    local new_rows_877=("${ret_split_lines5_v0[@]}")
    for row_878 in "${new_rows_877[@]}"; do
        if [ "$([ "_${row_878}" != "_" ]; echo $?)" != 0 ]; then
            continue
        fi
        split__4_v0 "	" "${row_878}"
        local parts_879=("${ret_split4_v0[@]}")
        local __length_63=("${parts_879[@]}")
        if [ "$(( ${#__length_63[@]} < 2 ))" != 0 ]; then
            continue
        fi
        local key_880="${parts_879[0]?"Index out of bounds (at /tmp/jbtd-install-build-pU9sr2/install.ab:383:27)"}"
        local val_881="${parts_879[1]?"Index out of bounds (at /tmp/jbtd-install-build-pU9sr2/install.ab:384:27)"}"
        local matched_882=0
        local __range_start_883=0
        local __length_64=("${old_keys_867[@]}")
        local __range_end_883="${#__length_64[@]}"
        local __dir_883=$(( ${__range_start_883} <= ${__range_end_883} ? 1 : -1 ))
        for (( i_883=${__range_start_883}; i_883 * ${__dir_883} < ${__range_end_883} * ${__dir_883}; i_883+=${__dir_883} )); do
            if [ "$([ "_${old_keys_867[${i_883}]?"Index out of bounds (at /tmp/jbtd-install-build-pU9sr2/install.ab:387:25)"}" != "_${key_880}" ]; echo $?)" != 0 ]; then
                if [ "$([ "_${old_vals_868[${i_883}]?"Index out of bounds (at /tmp/jbtd-install-build-pU9sr2/install.ab:388:29)"}" == "_${val_881}" ]; echo $?)" != 0 ]; then
                    local array_65=("${key_880}")
                    changed_876+=("${array_65[@]}")
                fi
                matched_882=1
                break
            fi
done
        if [ "$(( ! matched_882 ))" != 0 ]; then
            changed_876+=("${key_880}")
        fi
    done
    for ok_884 in "${old_keys_867[@]}"; do
        local found_885=0
        for row_886 in "${new_rows_877[@]}"; do
            if [ "$([ "_${row_886}" != "_" ]; echo $?)" != 0 ]; then
                continue
            fi
            split__4_v0 "	" "${row_886}"
            local parts_887=("${ret_split4_v0[@]}")
            local __length_71=("${parts_887[@]}")
            if [ "$(( $(( ${#__length_71[@]} >= 2 )) && $([ "_${parts_887[0]?"Index out of bounds (at /tmp/jbtd-install-build-pU9sr2/install.ab:405:42)"}" != "_${ok_884}" ]; echo $?) ))" != 0 ]; then
                found_885=1
                break
            fi
        done
        if [ "$(( ! found_885 ))" != 0 ]; then
            changed_876+=("${ok_884}")
        fi
    done
    local __length_73=("${changed_876[@]}")
    if [ "$(( ${#__length_73[@]} == 0 ))" != 0 ]; then
        echo "update: all repos up to date"
        ret_cmd_update439_v0=''
        return 0
    fi
    local __length_74=("${changed_876[@]}")
    echo "update: ${#__length_74[@]} repo(s) changed:"
    for c_888 in "${changed_876[@]}"; do
        echo "  - ${c_888}"
    done
    echo "Apply updates? [Y/n]"
    local command_77
    command_77="$(read -r line < /dev/tty 2>/dev/null; printf "%s" "$line")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_cmd_update439_v0=''
        return "${__status}"
    fi
    local ans_889="${command_77}"
    if [ "$(( $(( $(( $([ "_${ans_889}" != "_n" ]; echo $?) || $([ "_${ans_889}" != "_N" ]; echo $?) )) || $([ "_${ans_889}" != "_no" ]; echo $?) )) || $([ "_${ans_889}" != "_NO" ]; echo $?) ))" != 0 ]; then
        echo "update: aborted"
        ret_cmd_update439_v0=''
        return 0
    fi
    for c_890 in "${changed_876[@]}"; do
        run_step__438_v0 "${c_890}"
    done
    cp "${meta_path_863}" "${state_path_864}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_cmd_update439_v0=''
        return "${__status}"
    fi
    echo "update: done"
}

typeset -r raw_args_114=("$0" "$@")
__length_82=("${raw_args_114[@]}")
slice_upper_81="${#__length_82[@]}"
slice_offset_83=1
slice_offset_83=$((${slice_offset_83} > 0 ? ${slice_offset_83} : 0))
slice_length_84="$(( slice_upper_81 - slice_offset_83 ))"
slice_length_84=$((${slice_length_84} > 0 ? ${slice_length_84} : 0))
args_115=("${raw_args_114[@]:${slice_offset_83}:${slice_length_84}}")
step_args_116=()
for a_117 in "${args_115[@]}"; do
    if [ "$([ "_${a_117}" != "_--ask" ]; echo $?)" != 0 ]; then
        export COPALS_ASK=1
        __status=$?
    fi
    if [ "$([ "_${a_117}" != "_--trace" ]; echo $?)" != 0 ]; then
        set -x
        __status=$?
    fi
    if [ "$([ "_${a_117}" == "_--ask" ]; echo $?)" != 0 ]; then
        if [ "$([ "_${a_117}" == "_--trace" ]; echo $?)" != 0 ]; then
            step_args_116+=("${a_117}")
        fi
    fi
done
__length_89=("${step_args_116[@]}")
if [ "$(( ${#__length_89[@]} == 0 ))" != 0 ]; then
    install_apt_essential_tools__213_v0 
    install_dotfiles_personalization__281_v0 
    install_nerd_fonts__298_v0 
    install_omz_config__307_v0 
    install_zshmarks__319_v0 
    install_system_tools__353_v0 
    install_nvim__358_v0 
    install_quicksheet__360_v0 
    install_tmux_warm_daemon__364_v0 
    install_tmux_wm__370_v0 
    install_cmd_bookmarks__373_v0 
    install_agent_global_config__386_v0 
    install_agent_skills__426_v0 
    install_skill_caveman__429_v0 
    install_skill_humanizer__432_v0 
    install_skill_ponytail__435_v0 
fi
__length_90=("${step_args_116[@]}")
if [ "$(( ${#__length_90[@]} >= 1 ))" != 0 ]; then
    if [ "$([ "_${step_args_116[0]?"Index out of bounds (at /tmp/jbtd-install-build-pU9sr2/install.ab:524:22)"}" != "_update" ]; echo $?)" != 0 ]; then
        __length_91=("${step_args_116[@]}")
        if [ "$(( ${#__length_91[@]} == 1 ))" != 0 ]; then
            cmd_update__439_v0 
            __status=$?
            if [ "${__status}" != 0 ]; then
                exit "${__status}"
            fi
        fi
    else
        for step_893 in "${step_args_116[@]}"; do
            run_step__438_v0 "${step_893}"
        done
    fi
fi
