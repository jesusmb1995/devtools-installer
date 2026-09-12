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
    local text_874="${1}"
    local delimiter_875="${2}"
    local result_876=()
    # zsh uses -A for array, bash uses -a, ksh is VERY bad at splitting anything
    if [ "$([ "_${EXEC_SHELL}" != "_zsh" ]; echo $?)" != 0 ]; then
        IFS="${delimiter_875}" read -rd '' -A result_876 < <(printf %s "$text_874")
        __status=$?
    elif [ "$([ "_${EXEC_SHELL}" != "_ksh" ]; echo $?)" != 0 ]; then
        if [ "$([ "_${delimiter_875}" != "_
" ]; echo $?)" != 0 ]; then
            while read -r -d $'\n'; do result_876+=("$REPLY"); done < <(echo "$text_874")
            __status=$?
        else
            IFS="${delimiter_875}" read -rd '' -a result_876 < <(printf %s "$text_874")
            __status=$?
        fi
    elif [ "$([ "_${EXEC_SHELL}" != "_bash" ]; echo $?)" != 0 ]; then
        IFS="${delimiter_875}" read -rd '' -a result_876 < <(printf %s "$text_874")
        __status=$?
    fi
    ret_split4_v0=("${result_876[@]}")
    return 0
}

# split_lines(text: Text)
split_lines__5_v0() {
    local text_873="${1}"
    split__4_v0 "${text_873}" "
"
    ret_split_lines5_v0=("${ret_split4_v0[@]}")
    return 0
}

# join(list: [Text], delimiter: Text)
join__7_v0() {
    local list_410=("${!1}")
    local delimiter_411="${2}"
    local command_5
    command_5="$(IFS="${delimiter_411}" ; printf "%s
" "${list_410[*]}")"
    __status=$?
    ret_join7_v0="${command_5}"
    return 0
}

# trim(text: Text)
trim__10_v0() {
    local text_94="${1}"
    local result_95=""
    result_95="${text_94#${text_94%%[![:space:]]*}}"
    __status=$?
    result_95="${result_95%${result_95##*[![:space:]]}}"
    __status=$?
    ret_trim10_v0="${result_95}"
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
    local path_438="${1}"
    local content_439="${2}"
    local command_6
    command_6="$(printf '%s
' "${content_439}" > "${path_438}")"
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
    local path_431="${1}"
    dir_exists__38_v0 "${path_431}"
    local ret_dir_exists38_v0__87_12="${ret_dir_exists38_v0}"
    if [ "$(( ! ret_dir_exists38_v0__87_12 ))" != 0 ]; then
        mkdir -p "${path_431}"
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
    local template_91="${1}"
    local auto_delete_92="${2}"
    local force_delete_93="${3}"
    trim__10_v0 "${template_91}"
    local ret_trim10_v0__113_8="${ret_trim10_v0}"
    if [ "$([ "_${ret_trim10_v0__113_8}" != "_" ]; echo $?)" != 0 ]; then
        echo "The template cannot be an empty string"'!'""
        ret_temp_dir_create46_v0=''
        return 1
    fi
    local filename_96=""
    is_mac_os_mktemp__45_v0 
    local ret_is_mac_os_mktemp45_v0__119_8="${ret_is_mac_os_mktemp45_v0}"
    if [ "${ret_is_mac_os_mktemp45_v0__119_8}" != 0 ]; then
        # usage: mktemp [-d] [-p tmpdir] [-q] [-t prefix] [-u] template ...
        # mktemp [-d] [-p tmpdir] [-q] [-u] -t prefix
        local command_7
        command_7="$(mktemp -d -p "$TMPDIR" "${template_91}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_temp_dir_create46_v0=''
            return "${__status}"
        fi
        filename_96="${command_7}"
    else
        local command_8
        command_8="$(mktemp -d -p "$TMPDIR" -t "${template_91}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_temp_dir_create46_v0=''
            return "${__status}"
        fi
        filename_96="${command_8}"
    fi
    if [ "$([ "_${filename_96}" != "_" ]; echo $?)" != 0 ]; then
        echo "Failed to make a temporary directory"
        ret_temp_dir_create46_v0=''
        return 1
    fi
    if [ "$(( auto_delete_92 && $([ "_${EXEC_SHELL}" == "_ksh" ]; echo $?) ))" != 0 ]; then
        if [ "${force_delete_93}" != 0 ]; then
            trap 'rm -rf '"${filename_96}"'' EXIT
            __status=$?
            if [ "${__status}" != 0 ]; then
                echo "Setting auto deletion fails. You must delete temporary dir ${filename_96}."
            fi
        else
            trap 'rmdir '"${filename_96}"'' EXIT
            __status=$?
            if [ "${__status}" != 0 ]; then
                echo "Setting auto deletion fails. You must delete temporary dir ${filename_96}."
            fi
        fi
    fi
    ret_temp_dir_create46_v0="${filename_96}"
    return 0
}

# env_var_get(name: Text)
env_var_get__124_v0() {
    local name_403="${1}"
    if [ "$([ "_${EXEC_SHELL}" != "_bash" ]; echo $?)" != 0 ]; then
        local command_9
        command_9="$(printf "%s
" "${!name_403}")"
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
" "${(P)name_403}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_env_var_get124_v0=''
            return "${__status}"
        fi
        ret_env_var_get124_v0="${command_10}"
        return 0
    elif [ "$([ "_${EXEC_SHELL}" != "_ksh" ]; echo $?)" != 0 ]; then
        local command_11
        command_11="$(eval "echo \${$name_403}")"
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
    local format_417="${1}"
    local args_418=("${!2}")
    args_418=("${format_417}" "${args_418[@]}")
    __status=$?
    printf "${args_418[@]}"
    __status=$?
}

# echo_warning(message: Text)
echo_warning__141_v0() {
    local message_423="${1}"
    local array_12=("${message_423}")
    printf__132_v0 "\\x1b[1;3;97;43m%s\\x1b[0m
" array_12[@]
}

# echo_error(message: Text, exit_code: Int)
echo_error__142_v0() {
    local message_415="${1}"
    local exit_code_416="${2}"
    local array_13=("${message_415}")
    printf__132_v0 "\\x1b[1;3;97;41m%s\\x1b[0m
" array_13[@]
    if [ "$(( exit_code_416 > 0 ))" != 0 ]; then
        exit "${exit_code_416}"
    fi
}

# has_cmd(cmd: Text)
has_cmd__165_v0() {
    local cmd_408="${1}"
    local found_409=0
    command -v ${cmd_408} >/dev/null 2>&1
    __status=$?
    if [ "${__status}" = 0 ]; then
        found_409=1
    fi
    ret_has_cmd165_v0="${found_409}"
    return 0
}

# echo_error exits the process (default exit_code=1), so no fail needed.
# sudo_cmd(cmd: Text, envvar: [])
sudo_cmd__169_v0() {
    local cmd_406="${1}"
    local envvar_407=("${!2}")
    has_cmd__165_v0 "sudo"
    local ret_has_cmd165_v0__4_8="${ret_has_cmd165_v0}"
    if [ "${ret_has_cmd165_v0__4_8}" != 0 ]; then
        sudo ${envvar_407[@]} ${cmd_406}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd169_v0=''
            return "${__status}"
        fi
    else
        env ${envvar_407[@]} ${cmd_406}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd169_v0=''
            return "${__status}"
        fi
    fi
}

# sudo_cmd(cmd: Text, envvar: [Text])
sudo_cmd__169_v1() {
    local cmd_413="${1}"
    local envvar_414=("${!2}")
    has_cmd__165_v0 "sudo"
    local ret_has_cmd165_v0__4_8="${ret_has_cmd165_v0}"
    if [ "${ret_has_cmd165_v0__4_8}" != 0 ]; then
        sudo ${envvar_414[@]} ${cmd_413}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd169_v1=''
            return "${__status}"
        fi
    else
        env ${envvar_414[@]} ${cmd_413}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd169_v1=''
            return "${__status}"
        fi
    fi
}

# prompt_user(description: Text)
prompt_user__172_v0() {
    local description_402="${1}"
    env_var_get__124_v0 "COPALS_ASK"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_prompt_user172_v0=1
        return 0
    fi
    local ask_404="${ret_env_var_get124_v0}"
    if [ "$([ "_${ask_404}" != "_" ]; echo $?)" != 0 ]; then
        ret_prompt_user172_v0=1
        return 0
    fi
    echo "install: ${description_402}"
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
    local ans_405="${command_14}"
    if [ "$([ "_${ans_405}" != "_" ]; echo $?)" != 0 ]; then
        ret_prompt_user172_v0=1
        return 0
    fi
    if [ "$(( $(( $(( $(( $([ "_${ans_405}" != "_n" ]; echo $?) || $([ "_${ans_405}" != "_N" ]; echo $?) )) || $([ "_${ans_405}" != "_no" ]; echo $?) )) || $([ "_${ans_405}" != "_NO" ]; echo $?) )) || $([ "_${ans_405}" != "_No" ]; echo $?) ))" != 0 ]; then
        echo "skipping"
        ret_prompt_user172_v0=0
        return 0
    fi
    ret_prompt_user172_v0=1
    return 0
}

# has_cmd(cmd: Text)
has_cmd__175_v0() {
    local cmd_421="${1}"
    local found_422=0
    command -v ${cmd_421} >/dev/null 2>&1
    __status=$?
    if [ "${__status}" = 0 ]; then
        found_422=1
    fi
    ret_has_cmd175_v0="${found_422}"
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
    local packages_401=("${!1}")
    prompt_user__172_v0 "apt install: ${packages_401[@]}"
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
    join__7_v0 packages_401[@] " "
    local pkgs_412="${ret_join7_v0}"
    local array_16=("DEBIAN_FRONTEND=noninteractive")
    sudo_cmd__169_v1 "apt-get install -y --no-install-recommends ${pkgs_412}" array_16[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_apt_install181_v0=''
        return "${__status}"
    fi
}

# apt_install_or_die(packages: [Text])
apt_install_or_die__182_v0() {
    local packages_400=("${!1}")
    apt_install__181_v0 packages_400[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to apt install ${packages_400[@]}" 1
    fi
}

# Non-fatal variant of apt_install_or_die: on failure it prints a warning and
# continues instead of exiting. Use for optional packages that may be absent
# from the target distro (e.g. jj, which is not in Debian apt).
# apt_install_or_warning(packages: [Text])
apt_install_or_warning__183_v0() {
    local packages_674=("${!1}")
    apt_install__181_v0 packages_674[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_warning__141_v0 "could not apt install ${packages_674[@]} - skipping"
    fi
}

# apt_install_if_missing_or_die(cmd: Text, pkg: Text)
apt_install_if_missing_or_die__184_v0() {
    local cmd_419="${1}"
    local pkg_420="${2}"
    has_cmd__175_v0 "${cmd_419}"
    local ret_has_cmd175_v0__43_8="${ret_has_cmd175_v0}"
    if [ "${ret_has_cmd175_v0__43_8}" != 0 ]; then
        echo_warning__141_v0 "${cmd_419} already installed, skipping apt install"
    else
        local array_17=("${pkg_420}")
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
    local src_427="${1}"
    local rel_dest_428="${2}"
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_copy_into_home195_v0=''
        return "${__status}"
    fi
    local home_429="${ret_home188_v0}"
    local dest_430="${home_429}/${rel_dest_428}"
    dir_create__44_v0 "${dest_430}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_copy_into_home195_v0=''
        return "${__status}"
    fi
    local __cp_18=
    (( 1 )) && __cp_18="-f" || __cp_18=""
    cp -r ${__cp_18} "${src_427}" "${dest_430}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_copy_into_home195_v0=''
        return "${__status}"
    fi
    ret_copy_into_home195_v0="${dest_430}"
    return 0
}

# copy_into_home_or_die(src: Text, rel_dest: Text)
copy_into_home_or_die__196_v0() {
    local src_425="${1}"
    local rel_dest_426="${2}"
    prompt_user__172_v0 "cp into home: ${rel_dest_426}"
    local ret_prompt_user172_v0__23_12="${ret_prompt_user172_v0}"
    if [ "$(( ! ret_prompt_user172_v0__23_12 ))" != 0 ]; then
        ret_copy_into_home_or_die196_v0=""
        return 0
    fi
    copy_into_home__195_v0 "${src_425}" "${rel_dest_426}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "deploy of ${rel_dest_426} into home failed" 1
    fi
    local dest_432="${ret_copy_into_home195_v0}"
    ret_copy_into_home_or_die196_v0="${dest_432}"
    return 0
}

# dir_create_at_home(rel: Text)
dir_create_at_home__202_v0() {
    local rel_434="${1}"
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_dir_create_at_home202_v0=''
        return "${__status}"
    fi
    local h_435="${ret_home188_v0}"
    dir_create__44_v0 "${h_435}/${rel_434}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_dir_create_at_home202_v0=''
        return "${__status}"
    fi
}

# dir_create_at_home_or_die(rel: Text)
dir_create_at_home_or_die__203_v0() {
    local rel_433="${1}"
    prompt_user__172_v0 "create directory ~/${rel_433}"
    local ret_prompt_user172_v0__12_8="${ret_prompt_user172_v0}"
    if [ "${ret_prompt_user172_v0__12_8}" != 0 ]; then
        dir_create_at_home__202_v0 "${rel_433}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "failed to create directory at home/${rel_433}" 1
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
    local h_436="${1}"
    local path_437="${h_436}/.local/bin/st-zsh"
    ret_make_nnn_desktop210_v0="[Desktop Entry]
Type=Application
Name=File Explorer (nnn)
Comment=Terminal file manager
Exec=${path_437} -e ${h_436}/.local/bin/nnn-launch
Terminal=false
Categories=Utility;FileManager;
Icon=nnn
"
    return 0
}

# make_btop_desktop(h: Text)
make_btop_desktop__211_v0() {
    local h_440="${1}"
    local path_441="${h_440}/.local/bin/st-zsh"
    ret_make_btop_desktop211_v0="[Desktop Entry]
Type=Application
Name=System Monitor (btop)
Comment=Resource monitor
Exec=${path_441} -e btop
Terminal=false
Categories=System;Monitor;
Icon=btop
"
    return 0
}

# make_ncdu_desktop(h: Text)
make_ncdu_desktop__212_v0() {
    local h_442="${1}"
    local path_443="${h_442}/.local/bin/st-zsh"
    ret_make_ncdu_desktop212_v0="[Desktop Entry]
Type=Application
Name=Disk Usage (ncdu)
Comment=Disk usage analyzer
Exec=${path_443} -e ncdu
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
    local h_424="${ret_home207_v0}"
    copy_into_home_or_die__196_v0 "src/apt-essential-tools/.config/nnn" ".config/"
    copy_into_home_or_die__196_v0 "src/apt-essential-tools/.local/bin" ".local/"
    chmod +x ${h_424}/.config/nnn/plugins/zmarks ${h_424}/.config/nnn/plugins/nvim-cd ${h_424}/.config/nnn/plugins/bm-create ${h_424}/.config/nnn/plugins/win-open ${h_424}/.config/nnn/profile ${h_424}/.local/bin/nnn-launch
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to chmod nnn files" 1
    fi
    dir_create_at_home_or_die__203_v0 "${__APPS_DIR_4}"
    make_nnn_desktop__210_v0 "${h_424}"
    local ret_make_nnn_desktop210_v0__40_46="${ret_make_nnn_desktop210_v0}"
    file_write__41_v0 "${h_424}/${__APPS_DIR_4}/nnn.desktop" "${ret_make_nnn_desktop210_v0__40_46}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to write nnn.desktop" 1
    fi
    make_btop_desktop__211_v0 "${h_424}"
    local ret_make_btop_desktop211_v0__43_47="${ret_make_btop_desktop211_v0}"
    file_write__41_v0 "${h_424}/${__APPS_DIR_4}/btop.desktop" "${ret_make_btop_desktop211_v0__43_47}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to write btop.desktop" 1
    fi
    make_ncdu_desktop__212_v0 "${h_424}"
    local ret_make_ncdu_desktop212_v0__46_47="${ret_make_ncdu_desktop212_v0}"
    file_write__41_v0 "${h_424}/${__APPS_DIR_4}/ncdu.desktop" "${ret_make_ncdu_desktop212_v0__46_47}"
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
    local h_578="${ret_home188_v0}"
    file_exists__39_v0 "${h_578}/.gitignore_global"
    local ret_file_exists39_v0__7_12="${ret_file_exists39_v0}"
    if [ "$(( ! ret_file_exists39_v0__7_12 ))" != 0 ]; then
        ret_setup_global_gitignore218_v0=''
        return 1
    fi
    git config --global core.excludesFile ${h_578}/.gitignore_global
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
    local src_557="${1}"
    local target_558="${2}"
    local excludes_559=("${!3}")
    local delete_560="${4}"
    dir_create__44_v0 "${target_558}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync227_v0=''
        return "${__status}"
    fi
    local excludes_arr_561=()
    for exclude_562 in "${excludes_559[@]}"; do
        local s_563="${exclude_562}"
        excludes_arr_561+=("--exclude" "${s_563}")
    done
    local delopt_564=""
    if [ "${delete_560}" != 0 ]; then
        delopt_564="--delete"
    fi
    rsync -a ${delopt_564} ${excludes_arr_561[@]} ${src_557} ${target_558}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync227_v0=''
        return "${__status}"
    fi
}

# rsync(src: Text, target: Text, excludes: [], delete: Bool)
rsync__227_v1() {
    local src_769="${1}"
    local target_770="${2}"
    local excludes_771=("${!3}")
    local delete_772="${4}"
    dir_create__44_v0 "${target_770}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync227_v1=''
        return "${__status}"
    fi
    local excludes_arr_773=()
    for exclude_774 in "${excludes_771[@]}"; do
        local s_775="${exclude_774}"
        excludes_arr_773+=("--exclude" "${s_775}")
    done
    local delopt_776=""
    if [ "${delete_772}" != 0 ]; then
        delopt_776="--delete"
    fi
    rsync -a ${delopt_776} ${excludes_arr_773[@]} ${src_769} ${target_770}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync227_v1=''
        return "${__status}"
    fi
}

# rsync_into_home(src: Text, rel_target: Text, delete: Bool)
rsync_into_home__230_v0() {
    local src_763="${1}"
    local rel_target_764="${2}"
    local delete_765="${3}"
    local excludes_766=()
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync_into_home230_v0=''
        return "${__status}"
    fi
    local h_767="${ret_home188_v0}"
    local target_768="${h_767}/${rel_target_764}"
    dir_create__44_v0 "${target_768}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync_into_home230_v0=''
        return "${__status}"
    fi
    rsync__227_v1 "${src_763}" "${target_768}" excludes_766[@] "${delete_765}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync_into_home230_v0=''
        return "${__status}"
    fi
}

# rsync_or_die_into_home(src: Text, rel_target: Text, delete: Bool)
rsync_or_die_into_home__231_v0() {
    local src_760="${1}"
    local rel_target_761="${2}"
    local delete_762="${3}"
    prompt_user__172_v0 "rsync ${src_760} -> ~/${rel_target_761}"
    local ret_prompt_user172_v0__16_8="${ret_prompt_user172_v0}"
    if [ "${ret_prompt_user172_v0__16_8}" != 0 ]; then
        rsync_into_home__230_v0 "${src_760}" "${rel_target_761}" "${delete_762}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "rsync deploy of ${src_760} into ${rel_target_761} failed" 1
        fi
    fi
}

# rsync_or_die_opts(src: Text, target: Text, excludes: [Text], delete: Bool)
rsync_or_die_opts__232_v0() {
    local src_553="${1}"
    local target_554="${2}"
    local excludes_555=("${!3}")
    local delete_556="${4}"
    prompt_user__172_v0 "rsync ${src_553} -> ${target_554}"
    local ret_prompt_user172_v0__24_8="${ret_prompt_user172_v0}"
    if [ "${ret_prompt_user172_v0__24_8}" != 0 ]; then
        rsync__227_v0 "${src_553}" "${target_554}" excludes_555[@] "${delete_556}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "rsync deploy of ${src_553} into ${target_554} failed" 1
        fi
    fi
}

# rsync_or_die_opts_into_home(src: Text, rel_target: Text, excludes: [Text], delete: Bool)
rsync_or_die_opts_into_home__233_v0() {
    local src_548="${1}"
    local rel_target_549="${2}"
    local excludes_550=("${!3}")
    local delete_551="${4}"
    prompt_user__172_v0 "rsync ${src_548} -> ~/${rel_target_549}"
    local ret_prompt_user172_v0__32_8="${ret_prompt_user172_v0}"
    if [ "${ret_prompt_user172_v0__32_8}" != 0 ]; then
        home__188_v0 
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "rsync_or_die_opts_into_home: failed to resolve home directory" 1
            exit 1
        fi
        local h_552="${ret_home188_v0}"
        rsync_or_die_opts__232_v0 "${src_548}" "${h_552}/${rel_target_549}" excludes_550[@] "${delete_551}"
    fi
}

# project_root() is the single canonical definition (doc 02). vars.ab and
# other modules call it instead of re-defining the same heuristic.
# project_root()
project_root__247_v0() {
    file_exists__39_v0 "src/copals.ab"
    local ret_file_exists39_v0__7_8="${ret_file_exists39_v0}"
    if [ "${ret_file_exists39_v0__7_8}" != 0 ]; then
        local pwd_val_55="$PWD"
        replace_regex__3_v0 "${pwd_val_55}" "/[^/]+\$" "" 1
        ret_project_root247_v0="${ret_replace_regex3_v0}"
        return 0
    fi
    ret_project_root247_v0="$PWD"
    return 0
}

project_root__247_v0 
__PROJECT_ROOT_65="${ret_project_root247_v0}"
project_vendor_66="${__PROJECT_ROOT_65}/copals/vendor"
installed_vendor_67="/usr/lib/copals/vendor"
# The installed vendor dir is authoritative when copals runs inside its own
# container: the host repo is bind-mounted at the same absolute path, so the
# project vendor dir also "exists" but its tools are only populated inside the
# image. Prefer the installed tree whenever it actually holds the binaries.
# resolve_vendor_dir()
resolve_vendor_dir__248_v0() {
    dir_exists__38_v0 "${installed_vendor_67}"
    local ret_dir_exists38_v0__23_8="${ret_dir_exists38_v0}"
    file_exists__39_v0 "${installed_vendor_67}/jsonnet"
    local ret_file_exists39_v0__23_41="${ret_file_exists39_v0}"
    if [ "$(( ret_dir_exists38_v0__23_8 && ret_file_exists39_v0__23_41 ))" != 0 ]; then
        ret_resolve_vendor_dir248_v0="${installed_vendor_67}"
        return 0
    fi
    dir_exists__38_v0 "${project_vendor_66}"
    local ret_dir_exists38_v0__26_8="${ret_dir_exists38_v0}"
    file_exists__39_v0 "${project_vendor_66}/jsonnet"
    local ret_file_exists39_v0__26_39="${ret_file_exists39_v0}"
    if [ "$(( ret_dir_exists38_v0__26_8 && ret_file_exists39_v0__26_39 ))" != 0 ]; then
        ret_resolve_vendor_dir248_v0="${project_vendor_66}"
        return 0
    fi
    dir_exists__38_v0 "${installed_vendor_67}"
    local ret_dir_exists38_v0__29_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__29_8}" != 0 ]; then
        ret_resolve_vendor_dir248_v0="${installed_vendor_67}"
        return 0
    fi
    dir_exists__38_v0 "${project_vendor_66}"
    local ret_dir_exists38_v0__32_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__32_8}" != 0 ]; then
        ret_resolve_vendor_dir248_v0="${project_vendor_66}"
        return 0
    fi
    ret_resolve_vendor_dir248_v0=""
    return 0
}

resolve_vendor_dir__248_v0 
__VENDOR_DIR_74="${ret_resolve_vendor_dir248_v0}"
# resolve_vendor_tool: resolve a vendored binary by name. Falls back to the
# bare name on PATH when no vendor dir is populated (doc 02, change 2: the
# former jq_resolve/j2_resolve/jsonnet_resolve/jsonschema_resolve/lua_resolve
# were 5 copies of this same 2-line rule).
# resolve_vendor_tool(name: Text)
resolve_vendor_tool__249_v0() {
    local name_76="${1}"
    if [ "$([ "_${__VENDOR_DIR_74}" != "_" ]; echo $?)" != 0 ]; then
        ret_resolve_vendor_tool249_v0="${name_76}"
        return 0
    fi
    ret_resolve_vendor_tool249_v0="${__VENDOR_DIR_74}/${name_76}"
    return 0
}

resolve_vendor_tool__249_v0 "jq"
resolve_vendor_tool__249_v0 "j2"
resolve_vendor_tool__249_v0 "jsonnet"
resolve_vendor_tool__249_v0 "jsonschema"
resolve_vendor_tool__249_v0 "lua"
# dirname(path: Text)
dirname__251_v0() {
    local path_573="${1}"
    local command_31
    command_31="$(dirname ${path_573})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_dirname251_v0=''
        return "${__status}"
    fi
    ret_dirname251_v0="${command_31}"
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
__TMP_DIR_97="${ret_temp_dir_create46_v0}"
token_98=1
# temp_file_create(suffix: Text)
temp_file_create__269_v0() {
    local suffix_575="${1}"
    token_98="$(( token_98 + 1 ))"
    local tmp_576="${__TMP_DIR_97}/${token_98}${suffix_575}"
    touch "${tmp_576}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_temp_file_create269_v0=''
        return "${__status}"
    fi
    ret_temp_file_create269_v0="${tmp_576}"
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
__MANAGED_BEGIN_99="# BEGIN ___DEVTOOLS_AUTOGEN___ managed by install.sh - do not edit this block"
__MANAGED_END_100="# END ___DEVTOOLS_AUTOGEN___"
# Verbatim, blank-line-preserving splice. Amber's split()/split_lines() drop
# empty segments, so a pure-amber line-array pass would strip blank lines from
# the user's rc file and from the shipped body. sed's range delete keeps every
# line outside BEGIN..END byte-for-byte; $(cat ...) normalizes trailing
# newlines so the separator before the block is stable across re-runs (no
# blank-line accumulation -> idempotent). Written to a temp file and run with
# bash (amber's $...$ command literal cannot host the helper's $/quotes).
__HELPER_101="#"'!'"/usr/bin/env bash
set -euo pipefail
m1='${__MANAGED_BEGIN_99}'
m2='${__MANAGED_END_100}'
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
managed_block__272_v0() {
    local src_571="${1}"
    local dest_572="${2}"
    dirname__251_v0 "${dest_572}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_managed_block272_v0=''
        return "${__status}"
    fi
    local parent_574="${ret_dirname251_v0}"
    dir_create__44_v0 "${parent_574}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_managed_block272_v0=''
        return "${__status}"
    fi
    temp_file_create__269_v0 "-managed_block.sh"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_managed_block272_v0=''
        return "${__status}"
    fi
    local helper_577="${ret_temp_file_create269_v0}"
    file_write__41_v0 "${helper_577}" "${__HELPER_101}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_managed_block272_v0=''
        return "${__status}"
    fi
    bash ${helper_577} ${src_571} ${dest_572}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_managed_block272_v0=''
        return "${__status}"
    fi
    rm -f ${helper_577}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_managed_block272_v0=''
        return "${__status}"
    fi
}

# managed_block_into_home(src: Text, rel_dest: Text)
managed_block_into_home__273_v0() {
    local src_568="${1}"
    local rel_dest_569="${2}"
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_managed_block_into_home273_v0=''
        return "${__status}"
    fi
    local h_570="${ret_home188_v0}"
    managed_block__272_v0 "${src_568}" "${h_570}/${rel_dest_569}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_managed_block_into_home273_v0=''
        return "${__status}"
    fi
}

# managed_block_or_die_into_home(src: Text, rel_dest: Text)
managed_block_or_die_into_home__275_v0() {
    local src_566="${1}"
    local rel_dest_567="${2}"
    prompt_user__172_v0 "managed-block merge ${src_566} -> ~/${rel_dest_567}"
    local ret_prompt_user172_v0__54_8="${ret_prompt_user172_v0}"
    if [ "${ret_prompt_user172_v0__54_8}" != 0 ]; then
        managed_block_into_home__273_v0 "${src_566}" "${rel_dest_567}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "managed-block merge of ${src_566} into ${rel_dest_567} failed" 1
        fi
    fi
}

# rc/config files that may already exist on the box with user edits. These are
# merge-managed (marker-delimited block) instead of rsync-clobbered, so a
# developer's existing shell config survives reinstall. Everything else in the
# dir (aliases/, Sh/, .local/, .tmux.conf, .gitignore_global, ...) is
# bundle-owned and rsync'd normally. Add filenames here to extend coverage.
# install_dotfiles_personalization()
install_dotfiles_personalization__277_v0() {
    local merge_files_547=(".zshrc" ".bashrc" ".zshenv" ".aliases")
    # rsync the whole tree EXCEPT the merge-managed files, so they are neither
    # created nor clobbered by rsync; managed_block reconciles them below.
    rsync_or_die_opts_into_home__233_v0 "src/dotfiles_personalization/" "" merge_files_547[@] 0
    # merge-manage each rc/config file into home (idempotent; preserves user
    # content outside the marker-delimited block).
    for f_565 in "${merge_files_547[@]}"; do
        managed_block_or_die_into_home__275_v0 "src/dotfiles_personalization/${f_565}" "${f_565}"
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
symlink_create_dir__285_v0() {
    local origin_631="${1}"
    local destination_632="${2}"
    dir_exists__38_v0 "${origin_631}"
    local ret_dir_exists38_v0__4_12="${ret_dir_exists38_v0}"
    if [ "$(( ! ret_dir_exists38_v0__4_12 ))" != 0 ]; then
        echo "The directory ${origin_631} doesn't exist"
        ret_symlink_create_dir285_v0=''
        return 1
    fi
    ln -fsn ${origin_631} ${destination_632}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_create_dir285_v0=''
        return "${__status}"
    fi
}

# TODO test this
# _parent_dir(path: Text)
_parent_dir__288_v0() {
    local path_627="${1}"
    local command_35
    command_35="$(dirname ${path_627})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret__parent_dir288_v0=''
        return "${__status}"
    fi
    local parent_628="${command_35}"
    ret__parent_dir288_v0="${parent_628}"
    return 0
}

# symlink_into_home(src: Text, rel_dest: Text)
symlink_into_home__289_v0() {
    local src_623="${1}"
    local rel_dest_624="${2}"
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home289_v0=''
        return "${__status}"
    fi
    local home_625="${ret_home188_v0}"
    local dest_626="${home_625}/${rel_dest_624}"
    _parent_dir__288_v0 "${dest_626}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home289_v0=''
        return "${__status}"
    fi
    local parent_629="${ret__parent_dir288_v0}"
    dir_create__44_v0 "${parent_629}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home289_v0=''
        return "${__status}"
    fi
    local command_36
    command_36="$(readlink -f ${src_623})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home289_v0=''
        return "${__status}"
    fi
    local abs_src_630="${command_36}"
    symlink_create_dir__285_v0 "${abs_src_630}" "${dest_626}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home289_v0=''
        return "${__status}"
    fi
    ret_symlink_into_home289_v0="${dest_626}"
    return 0
}

# symlink_into_home_or_die(src: Text, rel_dest: Text)
symlink_into_home_or_die__290_v0() {
    local src_621="${1}"
    local rel_dest_622="${2}"
    prompt_user__172_v0 "symlink ${src_621} -> ~/${rel_dest_622}"
    local ret_prompt_user172_v0__26_12="${ret_prompt_user172_v0}"
    if [ "$(( ! ret_prompt_user172_v0__26_12 ))" != 0 ]; then
        ret_symlink_into_home_or_die290_v0=""
        return 0
    fi
    symlink_into_home__289_v0 "${src_621}" "${rel_dest_622}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "deploy of ${src_621} symlink ${rel_dest_622}  into home failed" 1
    fi
    local dest_633="${ret_symlink_into_home289_v0}"
    ret_symlink_into_home_or_die290_v0="${dest_633}"
    return 0
}

# Symlink a home-relative path to another home-relative path (both resolved
# against home()). Works for files (e.g. bridging a data file from one config
# location to the path a plugin expects).
# symlink_at_home(src_rel: Text, dest_rel: Text)
symlink_at_home__291_v0() {
    local src_rel_705="${1}"
    local dest_rel_706="${2}"
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_at_home291_v0=''
        return "${__status}"
    fi
    local h_707="${ret_home188_v0}"
    local src_708="${h_707}/${src_rel_705}"
    local dest_709="${h_707}/${dest_rel_706}"
    file_exists__39_v0 "${src_708}"
    local ret_file_exists39_v0__43_12="${ret_file_exists39_v0}"
    if [ "$(( ! ret_file_exists39_v0__43_12 ))" != 0 ]; then
        echo_error__142_v0 "symlink source ${src_708} missing" 1
        ret_symlink_at_home291_v0=''
        return 1
    fi
    _parent_dir__288_v0 "${dest_709}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_at_home291_v0=''
        return "${__status}"
    fi
    local parent_710="${ret__parent_dir288_v0}"
    dir_create__44_v0 "${parent_710}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_at_home291_v0=''
        return "${__status}"
    fi
    ln -fsn ${src_708} ${dest_709}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_at_home291_v0=''
        return "${__status}"
    fi
    ret_symlink_at_home291_v0="${dest_709}"
    return 0
}

# symlink_at_home_or_die(src_rel: Text, dest_rel: Text)
symlink_at_home_or_die__292_v0() {
    local src_rel_703="${1}"
    local dest_rel_704="${2}"
    prompt_user__172_v0 "symlink ~/${src_rel_703} -> ~/${dest_rel_704}"
    local ret_prompt_user172_v0__57_12="${ret_prompt_user172_v0}"
    if [ "$(( ! ret_prompt_user172_v0__57_12 ))" != 0 ]; then
        ret_symlink_at_home_or_die292_v0=""
        return 0
    fi
    symlink_at_home__291_v0 "${src_rel_703}" "${dest_rel_704}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "symlink ${src_rel_703} -> ${dest_rel_704} in home failed" 1
    fi
    local dest_711="${ret_symlink_at_home291_v0}"
    ret_symlink_at_home_or_die292_v0="${dest_711}"
    return 0
}

# install_nerd_fonts()
install_nerd_fonts__294_v0() {
    local subpath_620=".local/share/fonts/NerdFonts"
    symlink_into_home_or_die__290_v0 "src/${subpath_620}" "${subpath_620}"
}

# set_only_user_write_or_die(path: Text)
set_only_user_write_or_die__299_v0() {
    local path_645="${1}"
    chmod -R g-w,o-w ${path_645}
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to set ${path_645} perms to user-only write" 1
    fi
}

# set_only_user_write_or_die_at_home(rel_path: Text)
set_only_user_write_or_die_at_home__300_v0() {
    local rel_path_643="${1}"
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "cannot determine home directory for ${rel_path_643}" 1
    fi
    local h_644="${ret_home188_v0}"
    set_only_user_write_or_die__299_v0 "${h_644}/${rel_path_643}"
}

# install_omz_config()
install_omz_config__303_v0() {
    local subpath_642=".oh-my-zsh"
    local array_37=("custom/plugins/")
    rsync_or_die_opts_into_home__233_v0 "src/${subpath_642}/" "${subpath_642}" array_37[@] 1
    set_only_user_write_or_die_at_home__300_v0 "${subpath_642}"
}

# execute(bin: Text, sh_path: Text)
execute__307_v0() {
    local bin_664="${1}"
    local sh_path_665="${2}"
    ${bin_664} ${sh_path_665}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute307_v0=''
        return "${__status}"
    fi
}

# execute_sh(sh_path: Text)
execute_sh__308_v0() {
    local sh_path_800="${1}"
    execute__307_v0 "bash" "${sh_path_800}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_sh308_v0=''
        return "${__status}"
    fi
}

# execute_zsh(sh_path: Text)
execute_zsh__309_v0() {
    local sh_path_663="${1}"
    execute__307_v0 "zsh" "${sh_path_663}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_zsh309_v0=''
        return "${__status}"
    fi
}

# execute_zsh_at_home(rel_sh_path: Text)
execute_zsh_at_home__312_v0() {
    local rel_sh_path_661="${1}"
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_zsh_at_home312_v0=''
        return "${__status}"
    fi
    local h_662="${ret_home188_v0}"
    execute_zsh__309_v0 "${h_662}/${rel_sh_path_661}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_zsh_at_home312_v0=''
        return "${__status}"
    fi
}

# install_zshmarks()
install_zshmarks__315_v0() {
    mkdir -p ~/.oh-my-zsh/custom/plugins/zshmarks
    __status=$?
    cp src/zshmarks.plugin.zsh ~/.oh-my-zsh/custom/plugins/zshmarks/zshmarks.plugin.zsh
    __status=$?
    execute_zsh_at_home__312_v0 ".oh-my-zsh/custom/plugins/zshmarks/zshmarks.plugin.zsh"
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
has_cmd__320_v0() {
    local cmd_672="${1}"
    local found_673=0
    command -v ${cmd_672} >/dev/null 2>&1
    __status=$?
    if [ "${__status}" = 0 ]; then
        found_673=1
    fi
    ret_has_cmd320_v0="${found_673}"
    return 0
}

# echo_error exits the process (default exit_code=1), so no fail needed.
# install_system_tools()
install_system_tools__349_v0() {
    local array_38=("ncdu")
    apt_install_or_die__182_v0 array_38[@]
    has_cmd__320_v0 "jj"
    local ret_has_cmd320_v0__12_12="${ret_has_cmd320_v0}"
    if [ "$(( ! ret_has_cmd320_v0__12_12 ))" != 0 ]; then
        local array_39=("jj")
        apt_install_or_warning__183_v0 array_39[@]
    fi
}

# install_nvim()
install_nvim__354_v0() {
    local array_40=("fd-find" "clang" "g++")
    apt_install_or_die__182_v0 array_40[@]
    local subpath_701=".config/nvim"
    symlink_into_home_or_die__290_v0 "src/${subpath_701}" "${subpath_701}"
    local lazy_dir_702="${subpath_701}/lazy"
    symlink_into_home_or_die__290_v0 "src/${lazy_dir_702}" ".local/share/nvim/lazy"
    # quicksheet reads ~/.config/quicksheet.txt; the data ships from the nvim
    # repo as ~/.config/nvim/quicksheet.txt. Symlink it so quicksheet finds it.
    symlink_at_home_or_die__292_v0 ".config/nvim/quicksheet.txt" ".config/quicksheet.txt"
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
install_quicksheet__356_v0() {
    :
}

# install_tmux_warm_daemon()
install_tmux_warm_daemon__360_v0() {
    copy_into_home_or_die__196_v0 "src/.tmux_warm_daemon/attach_warm.sh" ".local/bin/"
    copy_into_home_or_die__196_v0 "src/.tmux_warm_daemon/restart_daemon.sh" ".local/bin/"
    copy_into_home_or_die__196_v0 "src/.tmux_warm_daemon/agent-warm.sh" ".local/bin/"
    copy_into_home_or_die__196_v0 "src/.tmux_warm_daemon/bootstrap-warm-daemon.sh" ".local/bin/"
    # Idle-session reaper: separate, non-blocking service that kills detached
    # tmux sessions idle > idle_reaper_hours (default 26h). Started/stopped
    # alongside the warm daemon by restart_daemon.sh (which looks for it on
    # $HOME/.local/bin first). Deployed next to the other helper scripts.
    copy_into_home_or_die__196_v0 "src/.tmux_warm_daemon/tmux_session_reaper.sh" ".local/bin/"
    # was-agent: sqlite-backed agent-workspace registry. attach_warm.sh, nvim
    # and the bash daemon call it to mark/list workspaces; it dual-writes the
    # legacy /tmp json so the Rust daemon keeps working. Deployed under its
    # command name (no .sh) like the other PATH helpers.
    copy_into_home_or_die__196_v0 "src/.tmux_warm_daemon/was-agent.sh" ".local/bin/"
    mv -f ~/.local/bin/was-agent.sh ~/.local/bin/was-agent && chmod +x ~/.local/bin/was-agent || true
    __status=$?
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
install_tmux_wm__366_v0() {
    local array_41=("tmux")
    apt_install_or_die__182_v0 array_41[@]
    copy_into_home_or_die__196_v0 "src/tmux_wm/.config/tmux" ".config/"
    copy_into_home_or_die__196_v0 "src/tmux_wm/.local/bin" ".local/"
    home__207_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "tmux_wm: cannot resolve HOME" 1
    fi
    local h_778="${ret_home207_v0}"
    chmod +x ${h_778}/.local/bin/tmux-wm ${h_778}/.local/bin/tmux-default ${h_778}/.local/bin/fzf-launcher ${h_778}/.local/bin/tmux-wm-move ${h_778}/.local/bin/tmux-wm-terminal ${h_778}/.local/bin/tmux-wm-open ${h_778}/.local/bin/tmux-wm-swap ${h_778}/.local/bin/nnn-wm
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "tmux_wm: failed to chmod scripts" 1
    fi
}

# install_cmd_bookmarks()
install_cmd_bookmarks__369_v0() {
    symlink_into_home_or_die__290_v0 "src/cmd_bookmarks" ".local/share/cmd_bookmarks"
}

# No-op install hook.
# 
# The nvim_bazel_launcher plugin body is staged into the build tree by
# generate_nvim_bazel_launcher.ab (filtered rsync into
# src/.config/nvim/lazy/nvim_bazel_launcher) and the lazy spec by
# generate_nvim_bazel_launcher_postrender.ab. install_nvim then symlinks
# ~/.local/share/nvim/lazy -> src/.config/nvim/lazy, so the plugin is
# reachable at runtime via that symlink. Nothing to do here. Do NOT rsync
# src/.config/nvim/lazy/nvim_bazel_launcher into
# ~/.local/share/nvim/lazy/nvim_bazel_launcher: that target is the symlink
# above, so it would rsync the directory onto itself.
# 
# This hook exists only because install.ab.j2 imports install_{repo.id}() for
# every enabled repo.
# install_nvim_bazel_launcher()
install_nvim_bazel_launcher__371_v0() {
    :
}

# execute_sh_at_home(rel_sh_path: Text)
execute_sh_at_home__378_v0() {
    local rel_sh_path_798="${1}"
    home__188_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_sh_at_home378_v0=''
        return "${__status}"
    fi
    local h_799="${ret_home188_v0}"
    execute_sh__308_v0 "${h_799}/${rel_sh_path_798}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_sh_at_home378_v0=''
        return "${__status}"
    fi
}

# execute_sh_at_home_or_die(rel_sh_path: Text)
execute_sh_at_home_or_die__379_v0() {
    local rel_sh_path_797="${1}"
    prompt_user__172_v0 "execute ~/${rel_sh_path_797}"
    local ret_prompt_user172_v0__12_8="${ret_prompt_user172_v0}"
    if [ "${ret_prompt_user172_v0__12_8}" != 0 ]; then
        execute_sh_at_home__378_v0 "${rel_sh_path_797}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "failed to run ${rel_sh_path_797}" 1
        fi
    fi
}

# install_agent_global_config()
install_agent_global_config__384_v0() {
    rsync_or_die_into_home__231_v0 "src/.agent/" ".agent" 1
    home__207_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "install_agent_global_config: home unresolved" 1
        exit 1
    fi
    local h_794="${ret_home207_v0}"
    local scripts_795=("sync-permissions-from-cli.sh" "sync-permissions.sh" "sync-antigravity-permissions.sh" "sync-kilocode-permissions.sh")
    for script_796 in "${scripts_795[@]}"; do
        file_exists__39_v0 "${h_794}/.agent/${script_796}"
        local ret_file_exists39_v0__20_12="${ret_file_exists39_v0}"
        if [ "${ret_file_exists39_v0__20_12}" != 0 ]; then
            execute_sh_at_home_or_die__379_v0 ".agent/${script_796}"
        fi
    done
}

# project_root() is the single canonical definition (doc 02). vars.ab and
# other modules call it instead of re-defining the same heuristic.
# project_root()
project_root__393_v0() {
    file_exists__39_v0 "src/copals.ab"
    local ret_file_exists39_v0__7_8="${ret_file_exists39_v0}"
    if [ "${ret_file_exists39_v0__7_8}" != 0 ]; then
        local pwd_val_104="$PWD"
        replace_regex__3_v0 "${pwd_val_104}" "/[^/]+\$" "" 1
        ret_project_root393_v0="${ret_replace_regex3_v0}"
        return 0
    fi
    ret_project_root393_v0="$PWD"
    return 0
}

project_root__393_v0 
__PROJECT_ROOT_105="${ret_project_root393_v0}"
project_vendor_106="${__PROJECT_ROOT_105}/copals/vendor"
installed_vendor_107="/usr/lib/copals/vendor"
# The installed vendor dir is authoritative when copals runs inside its own
# container: the host repo is bind-mounted at the same absolute path, so the
# project vendor dir also "exists" but its tools are only populated inside the
# image. Prefer the installed tree whenever it actually holds the binaries.
# resolve_vendor_dir()
resolve_vendor_dir__394_v0() {
    dir_exists__38_v0 "${installed_vendor_107}"
    local ret_dir_exists38_v0__23_8="${ret_dir_exists38_v0}"
    file_exists__39_v0 "${installed_vendor_107}/jsonnet"
    local ret_file_exists39_v0__23_41="${ret_file_exists39_v0}"
    if [ "$(( ret_dir_exists38_v0__23_8 && ret_file_exists39_v0__23_41 ))" != 0 ]; then
        ret_resolve_vendor_dir394_v0="${installed_vendor_107}"
        return 0
    fi
    dir_exists__38_v0 "${project_vendor_106}"
    local ret_dir_exists38_v0__26_8="${ret_dir_exists38_v0}"
    file_exists__39_v0 "${project_vendor_106}/jsonnet"
    local ret_file_exists39_v0__26_39="${ret_file_exists39_v0}"
    if [ "$(( ret_dir_exists38_v0__26_8 && ret_file_exists39_v0__26_39 ))" != 0 ]; then
        ret_resolve_vendor_dir394_v0="${project_vendor_106}"
        return 0
    fi
    dir_exists__38_v0 "${installed_vendor_107}"
    local ret_dir_exists38_v0__29_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__29_8}" != 0 ]; then
        ret_resolve_vendor_dir394_v0="${installed_vendor_107}"
        return 0
    fi
    dir_exists__38_v0 "${project_vendor_106}"
    local ret_dir_exists38_v0__32_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__32_8}" != 0 ]; then
        ret_resolve_vendor_dir394_v0="${project_vendor_106}"
        return 0
    fi
    ret_resolve_vendor_dir394_v0=""
    return 0
}

resolve_vendor_dir__394_v0 
__VENDOR_DIR_108="${ret_resolve_vendor_dir394_v0}"
# resolve_vendor_tool: resolve a vendored binary by name. Falls back to the
# bare name on PATH when no vendor dir is populated (doc 02, change 2: the
# former jq_resolve/j2_resolve/jsonnet_resolve/jsonschema_resolve/lua_resolve
# were 5 copies of this same 2-line rule).
# resolve_vendor_tool(name: Text)
resolve_vendor_tool__395_v0() {
    local name_110="${1}"
    if [ "$([ "_${__VENDOR_DIR_108}" != "_" ]; echo $?)" != 0 ]; then
        ret_resolve_vendor_tool395_v0="${name_110}"
        return 0
    fi
    ret_resolve_vendor_tool395_v0="${__VENDOR_DIR_108}/${name_110}"
    return 0
}

resolve_vendor_tool__395_v0 "jq"
resolve_vendor_tool__395_v0 "j2"
resolve_vendor_tool__395_v0 "jsonnet"
resolve_vendor_tool__395_v0 "jsonschema"
resolve_vendor_tool__395_v0 "lua"
# Inverse of rm_if_feature_not: remove rel_path when features[feature] == expected
# (defaults to "" so an unset feature never triggers removal). Use to drop GUI
# artifacts in pure-TTY presets, e.g. mode == "tmux".
# install_agent_skills_impl()
install_agent_skills_impl__419_v0() {
    home__207_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_agent_skills_impl419_v0=''
        return "${__status}"
    fi
    local h_809="${ret_home207_v0}"
    local canon_810="${h_809}/.agents/skills"
    local skills_src_811="src/agent-skills/.agents/skills"
    rsync_or_die_into_home__231_v0 "${skills_src_811}/" ".agents/skills" 0
    dir_exists__38_v0 "${canon_810}"
    local ret_dir_exists38_v0__49_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__49_8}" != 0 ]; then
        local legacy_dir_812="${h_809}/.cursor/skills-cursor"
        dir_exists__38_v0 "${legacy_dir_812}"
        local ret_dir_exists38_v0__51_12="${ret_dir_exists38_v0}"
        if [ "${ret_dir_exists38_v0__51_12}" != 0 ]; then
            local __rm_47=
            (( 1 )) && __rm_47="-r" || __rm_47=""
            local __rm_48=
            rm ${__rm_48} ${__rm_47} "${legacy_dir_812}"
        fi
        # 2. Wire the store into each ENABLED tool. Antigravity reads ~/.agents/skills natively, so it needs no link.
    fi
}

# install_agent_skills()
install_agent_skills__420_v0() {
    install_agent_skills_impl__419_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to install agent skills" 1
    fi
}

# install_skill_caveman()
install_skill_caveman__423_v0() {
    symlink_into_home_or_die__290_v0 "src/.agents/skills/caveman" ".agents/skills/caveman"
}

# install_skill_humanizer()
install_skill_humanizer__426_v0() {
    symlink_into_home_or_die__290_v0 "src/.agents/skills/humanizer" ".agents/skills/humanizer"
}

# install_skill_ponytail()
install_skill_ponytail__429_v0() {
    symlink_into_home_or_die__290_v0 "src/.agents/skills/ponytail" ".agents/skills/ponytail"
}

# Each hook must be IDEMPOTENT and KILL THE PROGRAM on failure.
# Inside the hook, propagate failures with ? via a *_impl(): Null? helper, then
# wrap it once at the installer level:  install_x() { x_impl() failed { exit(1) } }
# So every install_*() is infallible and main() stays a plain sequence of calls.
# print_help()
print_help__431_v0() {
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
    echo "  nvim_bazel_launcher"
    echo "  agent_global_config"
    echo "  agent_skills"
    echo "  skill_caveman"
    echo "  skill_humanizer"
    echo "  skill_ponytail"
}

# run_step(step: Text)
run_step__432_v0() {
    local step_895="${1}"
    local matched_896=0
    if [ "$([ "_${step_895}" != "_help" ]; echo $?)" != 0 ]; then
        print_help__431_v0 
        matched_896=1
    fi
    if [ "$([ "_${step_895}" != "_apt_essential_tools" ]; echo $?)" != 0 ]; then
        install_apt_essential_tools__213_v0 
        matched_896=1
    fi
    if [ "$([ "_${step_895}" != "_dotfiles_personalization" ]; echo $?)" != 0 ]; then
        install_dotfiles_personalization__277_v0 
        matched_896=1
    fi
    if [ "$([ "_${step_895}" != "_nerd_fonts" ]; echo $?)" != 0 ]; then
        install_nerd_fonts__294_v0 
        matched_896=1
    fi
    if [ "$([ "_${step_895}" != "_omz_config" ]; echo $?)" != 0 ]; then
        install_omz_config__303_v0 
        matched_896=1
    fi
    if [ "$([ "_${step_895}" != "_zshmarks" ]; echo $?)" != 0 ]; then
        install_zshmarks__315_v0 
        matched_896=1
    fi
    if [ "$([ "_${step_895}" != "_system_tools" ]; echo $?)" != 0 ]; then
        install_system_tools__349_v0 
        matched_896=1
    fi
    if [ "$([ "_${step_895}" != "_nvim" ]; echo $?)" != 0 ]; then
        install_nvim__354_v0 
        matched_896=1
    fi
    if [ "$([ "_${step_895}" != "_quicksheet" ]; echo $?)" != 0 ]; then
        install_quicksheet__356_v0 
        matched_896=1
    fi
    if [ "$([ "_${step_895}" != "_tmux_warm_daemon" ]; echo $?)" != 0 ]; then
        install_tmux_warm_daemon__360_v0 
        matched_896=1
    fi
    if [ "$([ "_${step_895}" != "_tmux_wm" ]; echo $?)" != 0 ]; then
        install_tmux_wm__366_v0 
        matched_896=1
    fi
    if [ "$([ "_${step_895}" != "_cmd_bookmarks" ]; echo $?)" != 0 ]; then
        install_cmd_bookmarks__369_v0 
        matched_896=1
    fi
    if [ "$([ "_${step_895}" != "_nvim_bazel_launcher" ]; echo $?)" != 0 ]; then
        install_nvim_bazel_launcher__371_v0 
        matched_896=1
    fi
    if [ "$([ "_${step_895}" != "_agent_global_config" ]; echo $?)" != 0 ]; then
        install_agent_global_config__384_v0 
        matched_896=1
    fi
    if [ "$([ "_${step_895}" != "_agent_skills" ]; echo $?)" != 0 ]; then
        install_agent_skills__420_v0 
        matched_896=1
    fi
    if [ "$([ "_${step_895}" != "_skill_caveman" ]; echo $?)" != 0 ]; then
        install_skill_caveman__423_v0 
        matched_896=1
    fi
    if [ "$([ "_${step_895}" != "_skill_humanizer" ]; echo $?)" != 0 ]; then
        install_skill_humanizer__426_v0 
        matched_896=1
    fi
    if [ "$([ "_${step_895}" != "_skill_ponytail" ]; echo $?)" != 0 ]; then
        install_skill_ponytail__429_v0 
        matched_896=1
    fi
    if [ "$(( ! matched_896 ))" != 0 ]; then
        echo "Unknown step: '${step_895}'"
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
cmd_update__433_v0() {
    local command_50
    command_50="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_cmd_update433_v0=''
        return "${__status}"
    fi
    local script_dir_866="${command_50}"
    local meta_path_867="${script_dir_866}/meta.json"
    local state_path_868="${script_dir_866}/.last_installed.json"
    local command_51
    command_51="$(jq -r '.repo_hashes | to_entries[] | "\(.key)	\(.value)"' "${meta_path_867}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_cmd_update433_v0=''
        return "${__status}"
    fi
    local new_lines_869="${command_51}"
    local old_lines_870=""
    file_exists__39_v0 "${state_path_868}"
    local ret_file_exists39_v0__378_8="${ret_file_exists39_v0}"
    if [ "${ret_file_exists39_v0__378_8}" != 0 ]; then
        local command_52
        command_52="$(jq -r '.repo_hashes | to_entries[] | "\(.key)	\(.value)"' "${state_path_868}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_cmd_update433_v0=''
            return "${__status}"
        fi
        old_lines_870="${command_52}"
    fi
    local old_keys_871=()
    local old_vals_872=()
    if [ "$([ "_${old_lines_870}" == "_" ]; echo $?)" != 0 ]; then
        split_lines__5_v0 "${old_lines_870}"
        local rows_877=("${ret_split_lines5_v0[@]}")
        for row_878 in "${rows_877[@]}"; do
            if [ "$([ "_${row_878}" != "_" ]; echo $?)" != 0 ]; then
                continue
            fi
            split__4_v0 "	" "${row_878}"
            local parts_879=("${ret_split4_v0[@]}")
            local __length_57=("${parts_879[@]}")
            if [ "$(( ${#__length_57[@]} >= 2 ))" != 0 ]; then
                old_keys_871+=("${parts_879[0]?"Index out of bounds (at /tmp/jbtd-install-build-tBsNge/install.ab:390:36)"}")
                old_vals_872+=("${parts_879[1]?"Index out of bounds (at /tmp/jbtd-install-build-tBsNge/install.ab:391:36)"}")
            fi
        done
    fi
    local changed_880=()
    split_lines__5_v0 "${new_lines_869}"
    local new_rows_881=("${ret_split_lines5_v0[@]}")
    for row_882 in "${new_rows_881[@]}"; do
        if [ "$([ "_${row_882}" != "_" ]; echo $?)" != 0 ]; then
            continue
        fi
        split__4_v0 "	" "${row_882}"
        local parts_883=("${ret_split4_v0[@]}")
        local __length_63=("${parts_883[@]}")
        if [ "$(( ${#__length_63[@]} < 2 ))" != 0 ]; then
            continue
        fi
        local key_884="${parts_883[0]?"Index out of bounds (at /tmp/jbtd-install-build-tBsNge/install.ab:402:27)"}"
        local val_885="${parts_883[1]?"Index out of bounds (at /tmp/jbtd-install-build-tBsNge/install.ab:403:27)"}"
        local matched_886=0
        local __range_start_887=0
        local __length_64=("${old_keys_871[@]}")
        local __range_end_887="${#__length_64[@]}"
        local __dir_887=$(( ${__range_start_887} <= ${__range_end_887} ? 1 : -1 ))
        for (( i_887=${__range_start_887}; i_887 * ${__dir_887} < ${__range_end_887} * ${__dir_887}; i_887+=${__dir_887} )); do
            if [ "$([ "_${old_keys_871[${i_887}]?"Index out of bounds (at /tmp/jbtd-install-build-tBsNge/install.ab:406:25)"}" != "_${key_884}" ]; echo $?)" != 0 ]; then
                if [ "$([ "_${old_vals_872[${i_887}]?"Index out of bounds (at /tmp/jbtd-install-build-tBsNge/install.ab:407:29)"}" == "_${val_885}" ]; echo $?)" != 0 ]; then
                    local array_65=("${key_884}")
                    changed_880+=("${array_65[@]}")
                fi
                matched_886=1
                break
            fi
done
        if [ "$(( ! matched_886 ))" != 0 ]; then
            changed_880+=("${key_884}")
        fi
    done
    for ok_888 in "${old_keys_871[@]}"; do
        local found_889=0
        for row_890 in "${new_rows_881[@]}"; do
            if [ "$([ "_${row_890}" != "_" ]; echo $?)" != 0 ]; then
                continue
            fi
            split__4_v0 "	" "${row_890}"
            local parts_891=("${ret_split4_v0[@]}")
            local __length_71=("${parts_891[@]}")
            if [ "$(( $(( ${#__length_71[@]} >= 2 )) && $([ "_${parts_891[0]?"Index out of bounds (at /tmp/jbtd-install-build-tBsNge/install.ab:424:42)"}" != "_${ok_888}" ]; echo $?) ))" != 0 ]; then
                found_889=1
                break
            fi
        done
        if [ "$(( ! found_889 ))" != 0 ]; then
            changed_880+=("${ok_888}")
        fi
    done
    local __length_73=("${changed_880[@]}")
    if [ "$(( ${#__length_73[@]} == 0 ))" != 0 ]; then
        echo "update: all repos up to date"
        ret_cmd_update433_v0=''
        return 0
    fi
    local __length_74=("${changed_880[@]}")
    echo "update: ${#__length_74[@]} repo(s) changed:"
    for c_892 in "${changed_880[@]}"; do
        echo "  - ${c_892}"
    done
    echo "Apply updates? [Y/n]"
    local command_77
    command_77="$(read -r line < /dev/tty 2>/dev/null; printf "%s" "$line")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_cmd_update433_v0=''
        return "${__status}"
    fi
    local ans_893="${command_77}"
    if [ "$(( $(( $(( $([ "_${ans_893}" != "_n" ]; echo $?) || $([ "_${ans_893}" != "_N" ]; echo $?) )) || $([ "_${ans_893}" != "_no" ]; echo $?) )) || $([ "_${ans_893}" != "_NO" ]; echo $?) ))" != 0 ]; then
        echo "update: aborted"
        ret_cmd_update433_v0=''
        return 0
    fi
    for c_894 in "${changed_880[@]}"; do
        run_step__432_v0 "${c_894}"
    done
    cp "${meta_path_867}" "${state_path_868}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_cmd_update433_v0=''
        return "${__status}"
    fi
    echo "update: done"
}

typeset -r raw_args_118=("$0" "$@")
__length_82=("${raw_args_118[@]}")
slice_upper_81="${#__length_82[@]}"
slice_offset_83=1
slice_offset_83=$((${slice_offset_83} > 0 ? ${slice_offset_83} : 0))
slice_length_84="$(( slice_upper_81 - slice_offset_83 ))"
slice_length_84=$((${slice_length_84} > 0 ? ${slice_length_84} : 0))
args_119=("${raw_args_118[@]:${slice_offset_83}:${slice_length_84}}")
step_args_120=()
for a_121 in "${args_119[@]}"; do
    if [ "$([ "_${a_121}" != "_--ask" ]; echo $?)" != 0 ]; then
        export COPALS_ASK=1
        __status=$?
    fi
    if [ "$([ "_${a_121}" != "_--trace" ]; echo $?)" != 0 ]; then
        set -x
        __status=$?
    fi
    if [ "$([ "_${a_121}" == "_--ask" ]; echo $?)" != 0 ]; then
        if [ "$([ "_${a_121}" == "_--trace" ]; echo $?)" != 0 ]; then
            step_args_120+=("${a_121}")
        fi
    fi
done
__length_89=("${step_args_120[@]}")
if [ "$(( ${#__length_89[@]} == 0 ))" != 0 ]; then
    install_apt_essential_tools__213_v0 
    install_dotfiles_personalization__277_v0 
    install_nerd_fonts__294_v0 
    install_omz_config__303_v0 
    install_zshmarks__315_v0 
    install_system_tools__349_v0 
    install_nvim__354_v0 
    install_quicksheet__356_v0 
    install_tmux_warm_daemon__360_v0 
    install_tmux_wm__366_v0 
    install_cmd_bookmarks__369_v0 
    install_nvim_bazel_launcher__371_v0 
    install_agent_global_config__384_v0 
    install_agent_skills__420_v0 
    install_skill_caveman__423_v0 
    install_skill_humanizer__426_v0 
    install_skill_ponytail__429_v0 
fi
__length_90=("${step_args_120[@]}")
if [ "$(( ${#__length_90[@]} >= 1 ))" != 0 ]; then
    if [ "$([ "_${step_args_120[0]?"Index out of bounds (at /tmp/jbtd-install-build-tBsNge/install.ab:547:22)"}" != "_update" ]; echo $?)" != 0 ]; then
        __length_91=("${step_args_120[@]}")
        if [ "$(( ${#__length_91[@]} == 1 ))" != 0 ]; then
            cmd_update__433_v0 
            __status=$?
            if [ "${__status}" != 0 ]; then
                exit "${__status}"
            fi
        fi
    else
        for step_897 in "${step_args_120[@]}"; do
            run_step__432_v0 "${step_897}"
        done
    fi
fi
