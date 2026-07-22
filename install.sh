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
    local source_962="${1}"
    local search_963="${2}"
    local replace_964="${3}"
    # Here we use a command to avoid #646
    local result_965=""
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
        result_965="${source_962//"${search_963}"/"${replace_964}"}"
        __status=$?
    else
        result_965="${source_962//"${search_963}"/${replace_964}}"
        __status=$?
    fi
    ret_replace0_v0="${result_965}"
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
    local source_957="${1}"
    local search_958="${2}"
    local replace_text_959="${3}"
    local extended_960="${4}"
    sed_version__2_v0 
    local sed_version_961="${ret_sed_version2_v0}"
    replace__0_v0 "${search_958}" "/" "\\/"
    search_958="${ret_replace0_v0}"
    replace__0_v0 "${replace_text_959}" "/" "\\/"
    replace_text_959="${ret_replace0_v0}"
    if [ "$(( $(( sed_version_961 == __SED_VERSION_GNU_1 )) || $(( sed_version_961 == __SED_VERSION_BUSYBOX_2 )) ))" != 0 ]; then
        # '\b' is supported but not in POSIX standards. Disable it
        replace__0_v0 "${search_958}" "\\b" "\\\\b"
        search_958="${ret_replace0_v0}"
    fi
    if [ "${extended_960}" != 0 ]; then
        # GNU sed versions 4.0 through 4.2 support extended regex syntax,
        # but only via the "-r" option
        if [ "$(( sed_version_961 == __SED_VERSION_GNU_1 ))" != 0 ]; then
            local command_1
            command_1="$(sed -r -e "s/${search_958}/${replace_text_959}/g" <<<"${source_957}")"
            __status=$?
            ret_replace_regex3_v0="${command_1}"
            return 0
        else
            local command_2
            command_2="$(sed -E -e "s/${search_958}/${replace_text_959}/g" <<<"${source_957}")"
            __status=$?
            ret_replace_regex3_v0="${command_2}"
            return 0
        fi
    else
        if [ "$(( $(( sed_version_961 == __SED_VERSION_GNU_1 )) || $(( sed_version_961 == __SED_VERSION_BUSYBOX_2 )) ))" != 0 ]; then
            # GNU Sed BRE handle \| as a metacharacter, but it is not POSIX standands. Disable it
            replace__0_v0 "${search_958}" "\\|" "|"
            search_958="${ret_replace0_v0}"
        fi
        local command_3
        command_3="$(sed -e "s/${search_958}/${replace_text_959}/g" <<<"${source_957}")"
        __status=$?
        ret_replace_regex3_v0="${command_3}"
        return 0
    fi
}

# split(text: Text, delimiter: Text)
split__4_v0() {
    local text_1272="${1}"
    local delimiter_1273="${2}"
    local result_1274=()
    # zsh uses -A for array, bash uses -a, ksh is VERY bad at splitting anything
    if [ "$([ "_${EXEC_SHELL}" != "_zsh" ]; echo $?)" != 0 ]; then
        IFS="${delimiter_1273}" read -rd '' -A result_1274 < <(printf %s "$text_1272")
        __status=$?
    elif [ "$([ "_${EXEC_SHELL}" != "_ksh" ]; echo $?)" != 0 ]; then
        if [ "$([ "_${delimiter_1273}" != "_
" ]; echo $?)" != 0 ]; then
            while read -r -d $'\n'; do result_1274+=("$REPLY"); done < <(echo "$text_1272")
            __status=$?
        else
            IFS="${delimiter_1273}" read -rd '' -a result_1274 < <(printf %s "$text_1272")
            __status=$?
        fi
    elif [ "$([ "_${EXEC_SHELL}" != "_bash" ]; echo $?)" != 0 ]; then
        IFS="${delimiter_1273}" read -rd '' -a result_1274 < <(printf %s "$text_1272")
        __status=$?
    fi
    ret_split4_v0=("${result_1274[@]}")
    return 0
}

# split_lines(text: Text)
split_lines__5_v0() {
    local text_1271="${1}"
    split__4_v0 "${text_1271}" "
"
    ret_split_lines5_v0=("${ret_split4_v0[@]}")
    return 0
}

# join(list: [Text], delimiter: Text)
join__7_v0() {
    local list_247=("${!1}")
    local delimiter_248="${2}"
    local command_5
    command_5="$(IFS="${delimiter_248}" ; printf "%s
" "${list_247[*]}")"
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
    local path_271="${1}"
    local content_272="${2}"
    local command_6
    command_6="$(printf '%s
' "${content_272}" > "${path_271}")"
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
    local path_264="${1}"
    dir_exists__38_v0 "${path_264}"
    local ret_dir_exists38_v0__87_12="${ret_dir_exists38_v0}"
    if [ "$(( ! ret_dir_exists38_v0__87_12 ))" != 0 ]; then
        mkdir -p "${path_264}"
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
    local name_256="${1}"
    if [ "$([ "_${EXEC_SHELL}" != "_bash" ]; echo $?)" != 0 ]; then
        local command_9
        command_9="$(printf "%s
" "${!name_256}")"
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
" "${(P)name_256}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_env_var_get124_v0=''
            return "${__status}"
        fi
        ret_env_var_get124_v0="${command_10}"
        return 0
    elif [ "$([ "_${EXEC_SHELL}" != "_ksh" ]; echo $?)" != 0 ]; then
        local command_11
        command_11="$(eval "echo \${$name_256}")"
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
    local format_254="${1}"
    local args_255=("${!2}")
    args_255=("${format_254}" "${args_255[@]}")
    __status=$?
    printf "${args_255[@]}"
    __status=$?
}

# echo_error(message: Text, exit_code: Int)
echo_error__142_v0() {
    local message_252="${1}"
    local exit_code_253="${2}"
    local array_12=("${message_252}")
    printf__132_v0 "\\x1b[1;3;97;41m%s\\x1b[0m
" array_12[@]
    if [ "$(( exit_code_253 > 0 ))" != 0 ]; then
        exit "${exit_code_253}"
    fi
}

# has_cmd(cmd: Text)
has_cmd__164_v0() {
    local cmd_245="${1}"
    local found_246=0
    command -v ${cmd_245} >/dev/null 2>&1
    __status=$?
    if [ "${__status}" = 0 ]; then
        found_246=1
    fi
    ret_has_cmd164_v0="${found_246}"
    return 0
}

# echo_error exits the process (default exit_code=1), so no fail needed.
# sudo_cmd(cmd: Text, envvar: [])
sudo_cmd__168_v0() {
    local cmd_243="${1}"
    local envvar_244=("${!2}")
    has_cmd__164_v0 "sudo"
    local ret_has_cmd164_v0__4_8="${ret_has_cmd164_v0}"
    if [ "${ret_has_cmd164_v0__4_8}" != 0 ]; then
        sudo ${envvar_244[@]} ${cmd_243}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd168_v0=''
            return "${__status}"
        fi
    else
        env ${envvar_244[@]} ${cmd_243}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd168_v0=''
            return "${__status}"
        fi
    fi
}

# sudo_cmd(cmd: Text, envvar: [Text])
sudo_cmd__168_v1() {
    local cmd_250="${1}"
    local envvar_251=("${!2}")
    has_cmd__164_v0 "sudo"
    local ret_has_cmd164_v0__4_8="${ret_has_cmd164_v0}"
    if [ "${ret_has_cmd164_v0__4_8}" != 0 ]; then
        sudo ${envvar_251[@]} ${cmd_250}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd168_v1=''
            return "${__status}"
        fi
    else
        env ${envvar_251[@]} ${cmd_250}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd168_v1=''
            return "${__status}"
        fi
    fi
}

was_updated_3=0
# update()
update__170_v0() {
    local array_13=()
    sudo_cmd__168_v0 "apt-get update" array_13[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_update170_v0=''
        return "${__status}"
    fi
}

# ensure_updated()
ensure_updated__171_v0() {
    if [ "$(( ! was_updated_3 ))" != 0 ]; then
        update__170_v0 
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_ensure_updated171_v0=''
            return "${__status}"
        fi
        was_updated_3=1
    fi
}

# apt_install(packages: [Text])
apt_install__172_v0() {
    local packages_242=("${!1}")
    ensure_updated__171_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_apt_install172_v0=''
        return "${__status}"
    fi
    join__7_v0 packages_242[@] " "
    local pkgs_249="${ret_join7_v0}"
    local array_14=("DEBIAN_FRONTEND=noninteractive")
    sudo_cmd__168_v1 "apt-get install -y --no-install-recommends ${pkgs_249}" array_14[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_apt_install172_v0=''
        return "${__status}"
    fi
}

# apt_install_or_die(packages: [Text])
apt_install_or_die__173_v0() {
    local packages_241=("${!1}")
    apt_install__172_v0 packages_241[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to apt install ${packages_241[@]}" 1
    fi
}

# home()
home__176_v0() {
    env_var_get__124_v0 "HOME"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_home176_v0=''
        return "${__status}"
    fi
    ret_home176_v0="${ret_env_var_get124_v0}"
    return 0
}

# copy_into_home(src: Text, rel_dest: Text)
copy_into_home__182_v0() {
    local src_260="${1}"
    local rel_dest_261="${2}"
    home__176_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_copy_into_home182_v0=''
        return "${__status}"
    fi
    local home_262="${ret_home176_v0}"
    local dest_263="${home_262}/${rel_dest_261}"
    dir_create__44_v0 "${dest_263}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_copy_into_home182_v0=''
        return "${__status}"
    fi
    local __cp_15=
    (( 1 )) && __cp_15="-f" || __cp_15=""
    cp -r ${__cp_15} "${src_260}" "${dest_263}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_copy_into_home182_v0=''
        return "${__status}"
    fi
    ret_copy_into_home182_v0="${dest_263}"
    return 0
}

# copy_into_home_or_die(src: Text, rel_dest: Text)
copy_into_home_or_die__183_v0() {
    local src_258="${1}"
    local rel_dest_259="${2}"
    copy_into_home__182_v0 "${src_258}" "${rel_dest_259}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "deploy of ${rel_dest_259} into home failed" 1
    fi
    local dest_265="${ret_copy_into_home182_v0}"
    ret_copy_into_home_or_die183_v0="${dest_265}"
    return 0
}

# dir_create_at_home(rel: Text)
dir_create_at_home__188_v0() {
    local rel_267="${1}"
    home__176_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_dir_create_at_home188_v0=''
        return "${__status}"
    fi
    local h_268="${ret_home176_v0}"
    dir_create__44_v0 "${h_268}/${rel_267}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_dir_create_at_home188_v0=''
        return "${__status}"
    fi
}

# dir_create_at_home_or_die(rel: Text)
dir_create_at_home_or_die__189_v0() {
    local rel_266="${1}"
    dir_create_at_home__188_v0 "${rel_266}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to create directory at home/${rel_266}" 1
    fi
}

# home()
home__193_v0() {
    env_var_get__124_v0 "HOME"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_home193_v0=''
        return "${__status}"
    fi
    ret_home193_v0="${ret_env_var_get124_v0}"
    return 0
}

__APPS_DIR_4=".local/share/applications"
# make_nnn_desktop(h: Text)
make_nnn_desktop__196_v0() {
    local h_269="${1}"
    local path_270="${h_269}/.local/bin/st-zsh"
    ret_make_nnn_desktop196_v0="[Desktop Entry]
Type=Application
Name=File Explorer (nnn)
Comment=Terminal file manager
Exec=${path_270} -e ${h_269}/.local/bin/nnn-launch
Terminal=false
Categories=Utility;FileManager;
Icon=nnn
"
    return 0
}

# make_btop_desktop(h: Text)
make_btop_desktop__197_v0() {
    local h_273="${1}"
    local path_274="${h_273}/.local/bin/st-zsh"
    ret_make_btop_desktop197_v0="[Desktop Entry]
Type=Application
Name=System Monitor (btop)
Comment=Resource monitor
Exec=${path_274} -e btop
Terminal=false
Categories=System;Monitor;
Icon=btop
"
    return 0
}

# make_ncdu_desktop(h: Text)
make_ncdu_desktop__198_v0() {
    local h_275="${1}"
    local path_276="${h_275}/.local/bin/st-zsh"
    ret_make_ncdu_desktop198_v0="[Desktop Entry]
Type=Application
Name=Disk Usage (ncdu)
Comment=Disk usage analyzer
Exec=${path_276} -e ncdu
Terminal=false
Categories=System;Utility;
Icon=ncdu
"
    return 0
}

# install_apt_essential_tools()
install_apt_essential_tools__199_v0() {
    local array_16=("rsync" "git" "tmux" "zsh" "sqlite3" "jq" "curl" "vim" "neovim" "ca-certificates" "ripgrep" "nnn" "fzf" "zenity" "btop" "ncdu")
    apt_install_or_die__173_v0 array_16[@]
    home__193_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to resolve HOME" 1
    fi
    local h_257="${ret_home193_v0}"
    copy_into_home_or_die__183_v0 "src/apt-essential-tools/.config/nnn" ".config/"
    copy_into_home_or_die__183_v0 "src/apt-essential-tools/.local/bin" ".local/"
    chmod +x ${h_257}/.config/nnn/plugins/dragdrop ${h_257}/.config/nnn/plugins/zmarks ${h_257}/.config/nnn/plugins/nvim-cd ${h_257}/.config/nnn/plugins/bm-create ${h_257}/.config/nnn/plugins/win-open ${h_257}/.config/nnn/profile ${h_257}/.local/bin/nnn-launch
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to chmod nnn files" 1
    fi
    dir_create_at_home_or_die__189_v0 "${__APPS_DIR_4}"
    make_nnn_desktop__196_v0 "${h_257}"
    local ret_make_nnn_desktop196_v0__39_46="${ret_make_nnn_desktop196_v0}"
    file_write__41_v0 "${h_257}/${__APPS_DIR_4}/nnn.desktop" "${ret_make_nnn_desktop196_v0__39_46}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to write nnn.desktop" 1
    fi
    make_btop_desktop__197_v0 "${h_257}"
    local ret_make_btop_desktop197_v0__42_47="${ret_make_btop_desktop197_v0}"
    file_write__41_v0 "${h_257}/${__APPS_DIR_4}/btop.desktop" "${ret_make_btop_desktop197_v0__42_47}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to write btop.desktop" 1
    fi
    make_ncdu_desktop__198_v0 "${h_257}"
    local ret_make_ncdu_desktop198_v0__45_47="${ret_make_ncdu_desktop198_v0}"
    file_write__41_v0 "${h_257}/${__APPS_DIR_4}/ncdu.desktop" "${ret_make_ncdu_desktop198_v0__45_47}"
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
install_apt_essential_ui__202_v0() {
    local array_17=("stterm" "i3" "suckless-tools" "dbus" "dbus-x11" "xss-lock" "x11-xserver-utils" "libgl1-mesa-dri" "libgl1" "libegl1" "libegl-mesa0")
    apt_install_or_die__173_v0 array_17[@]
    local array_18=("xfce4-settings")
    apt_install_or_die__173_v0 array_18[@]
    local array_19=("x11vnc" "xvfb")
    apt_install_or_die__173_v0 array_19[@]
}

# rsync(src: Text, target: Text, excludes: [], delete: Bool)
rsync__209_v0() {
    local src_342="${1}"
    local target_343="${2}"
    local excludes_344=("${!3}")
    local delete_345="${4}"
    dir_create__44_v0 "${target_343}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync209_v0=''
        return "${__status}"
    fi
    local excludes_arr_346=()
    for exclude_347 in "${excludes_344[@]}"; do
        local s_348="${exclude_347}"
        excludes_arr_346+=("--exclude" "${s_348}")
    done
    local delopt_349=""
    if [ "${delete_345}" != 0 ]; then
        delopt_349="--delete"
    fi
    rsync -a ${delopt_349} ${excludes_arr_346[@]} ${src_342} ${target_343}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync209_v0=''
        return "${__status}"
    fi
}

# rsync(src: Text, target: Text, excludes: [Text], delete: Bool)
rsync__209_v1() {
    local src_528="${1}"
    local target_529="${2}"
    local excludes_530=("${!3}")
    local delete_531="${4}"
    dir_create__44_v0 "${target_529}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync209_v1=''
        return "${__status}"
    fi
    local excludes_arr_532=()
    for exclude_533 in "${excludes_530[@]}"; do
        local s_534="${exclude_533}"
        excludes_arr_532+=("--exclude" "${s_534}")
    done
    local delopt_535=""
    if [ "${delete_531}" != 0 ]; then
        delopt_535="--delete"
    fi
    rsync -a ${delopt_535} ${excludes_arr_532[@]} ${src_528} ${target_529}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync209_v1=''
        return "${__status}"
    fi
}

# rsync_into_home(src: Text, rel_target: Text, delete: Bool)
rsync_into_home__211_v0() {
    local src_336="${1}"
    local rel_target_337="${2}"
    local delete_338="${3}"
    local excludes_339=()
    home__176_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync_into_home211_v0=''
        return "${__status}"
    fi
    local h_340="${ret_home176_v0}"
    local target_341="${h_340}/${rel_target_337}"
    dir_create__44_v0 "${target_341}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync_into_home211_v0=''
        return "${__status}"
    fi
    rsync__209_v0 "${src_336}" "${target_341}" excludes_339[@] "${delete_338}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_rsync_into_home211_v0=''
        return "${__status}"
    fi
}

# rsync_or_die_into_home(src: Text, rel_target: Text, delete: Bool)
rsync_or_die_into_home__212_v0() {
    local src_333="${1}"
    local rel_target_334="${2}"
    local delete_335="${3}"
    rsync_into_home__211_v0 "${src_333}" "${rel_target_334}" "${delete_335}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "rsync deploy of ${src_333} into ${rel_target_334} failed" 1
    fi
}

# rsync_or_die_opts(src: Text, target: Text, excludes: [Text], delete: Bool)
rsync_or_die_opts__213_v0() {
    local src_524="${1}"
    local target_525="${2}"
    local excludes_526=("${!3}")
    local delete_527="${4}"
    rsync__209_v1 "${src_524}" "${target_525}" excludes_526[@] "${delete_527}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "rsync deploy of ${src_524} into ${target_525} failed" 1
    fi
}

# rsync_or_die_opts_into_home(src: Text, rel_target: Text, excludes: [Text], delete: Bool)
rsync_or_die_opts_into_home__214_v0() {
    local src_519="${1}"
    local rel_target_520="${2}"
    local excludes_521=("${!3}")
    local delete_522="${4}"
    home__176_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "rsync_or_die_opts_into_home: failed to resolve home directory" 1
        exit 1
    fi
    local h_523="${ret_home176_v0}"
    rsync_or_die_opts__213_v0 "${src_519}" "${h_523}/${rel_target_520}" excludes_521[@] "${delete_522}"
}

# install_dotfiles_essential()
install_dotfiles_essential__216_v0() {
    rsync_or_die_into_home__212_v0 "src/dotfiles_essential/.config/" ".config" 0
}

# setup_global_gitignore()
setup_global_gitignore__221_v0() {
    home__176_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_setup_global_gitignore221_v0=''
        return "${__status}"
    fi
    local h_353="${ret_home176_v0}"
    file_exists__39_v0 "${h_353}/.gitignore_global"
    local ret_file_exists39_v0__7_12="${ret_file_exists39_v0}"
    if [ "$(( ! ret_file_exists39_v0__7_12 ))" != 0 ]; then
        ret_setup_global_gitignore221_v0=''
        return 1
    fi
    git config --global core.excludesFile ${h_353}/.gitignore_global
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_setup_global_gitignore221_v0=''
        return "${__status}"
    fi
}

# setup_global_gitignore_or_die()
setup_global_gitignore_or_die__222_v0() {
    setup_global_gitignore__221_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to setup global gitignore" 1
    fi
}

# install_dotfiles_personalization()
install_dotfiles_personalization__226_v0() {
    rsync_or_die_into_home__212_v0 "src/dotfiles_personalization/" "" 0
    setup_global_gitignore_or_die__222_v0 
    copy_into_home_or_die__183_v0 "src/dotfiles_personalization/.local/share/applications" ".local/share/applications"
}

# has_cmd(cmd: Text)
has_cmd__230_v0() {
    local cmd_406="${1}"
    local found_407=0
    command -v ${cmd_406} >/dev/null 2>&1
    __status=$?
    if [ "${__status}" = 0 ]; then
        found_407=1
    fi
    ret_has_cmd230_v0="${found_407}"
    return 0
}

# echo_error exits the process (default exit_code=1), so no fail needed.
# sudo_cmd(cmd: Text, envvar: [])
sudo_cmd__234_v0() {
    local cmd_404="${1}"
    local envvar_405=("${!2}")
    has_cmd__230_v0 "sudo"
    local ret_has_cmd230_v0__4_8="${ret_has_cmd230_v0}"
    if [ "${ret_has_cmd230_v0__4_8}" != 0 ]; then
        sudo ${envvar_405[@]} ${cmd_404}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd234_v0=''
            return "${__status}"
        fi
    else
        env ${envvar_405[@]} ${cmd_404}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_sudo_cmd234_v0=''
            return "${__status}"
        fi
    fi
}

# has_cmd(cmd: Text)
has_cmd__237_v0() {
    local cmd_398="${1}"
    local found_399=0
    command -v ${cmd_398} >/dev/null 2>&1
    __status=$?
    if [ "${__status}" = 0 ]; then
        found_399=1
    fi
    ret_has_cmd237_v0="${found_399}"
    return 0
}

# which_cmd(cmd: Text)
which_cmd__238_v0() {
    local cmd_400="${1}"
    local command_29
    command_29="$(command -v ${cmd_400} 2>/dev/null)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_which_cmd238_v0=''
        return "${__status}"
    fi
    ret_which_cmd238_v0="${command_29}"
    return 0
}

# echo_error exits the process (default exit_code=1), so no fail needed.
# set_terminal_alternative()
set_terminal_alternative__245_v0() {
    local command_30
    command_30="$(command -v st)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_set_terminal_alternative245_v0=''
        return "${__status}"
    fi
    local st_bin_396="${command_30}"
    local term_path_397="${st_bin_396}"
    has_cmd__237_v0 "zsh"
    local ret_has_cmd237_v0__11_8="${ret_has_cmd237_v0}"
    if [ "${ret_has_cmd237_v0__11_8}" != 0 ]; then
        which_cmd__238_v0 "zsh"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative245_v0=''
            return "${__status}"
        fi
        local zsh_bin_401="${ret_which_cmd238_v0}"
        home__193_v0 
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative245_v0=''
            return "${__status}"
        fi
        local h_402="${ret_home193_v0}"
        local wrapper_403="${h_402}/.local/bin/st-zsh"
        mkdir -p "${h_402}/.local/bin"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative245_v0=''
            return "${__status}"
        fi
        echo '#!/bin/sh' > "${wrapper_403}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative245_v0=''
            return "${__status}"
        fi
        echo '[ "$1" = "-e" ] && shift' >> "${wrapper_403}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative245_v0=''
            return "${__status}"
        fi
        echo 'if [ "$#" -eq 0 ]; then' >> "${wrapper_403}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative245_v0=''
            return "${__status}"
        fi
        echo "    exec ${st_bin_396} -f 'monospace:size=12' -e ${h_402}/.local/bin/st-init.sh ${zsh_bin_401}" >> "${wrapper_403}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative245_v0=''
            return "${__status}"
        fi
        echo 'else' >> "${wrapper_403}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative245_v0=''
            return "${__status}"
        fi
        echo "    exec ${st_bin_396} -f 'monospace:size=12' -e ${h_402}/.local/bin/st-init.sh" '"$@"' >> "${wrapper_403}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative245_v0=''
            return "${__status}"
        fi
        echo 'fi' >> "${wrapper_403}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative245_v0=''
            return "${__status}"
        fi
        chmod +x "${wrapper_403}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_set_terminal_alternative245_v0=''
            return "${__status}"
        fi
        term_path_397="${wrapper_403}"
    fi
    local array_31=()
    sudo_cmd__234_v0 "update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator ${term_path_397} 10" array_31[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_set_terminal_alternative245_v0=''
        return "${__status}"
    fi
    local array_32=()
    sudo_cmd__234_v0 "update-alternatives --set x-terminal-emulator ${term_path_397}" array_32[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_set_terminal_alternative245_v0=''
        return "${__status}"
    fi
}

# install_st()
install_st__246_v0() {
    set_terminal_alternative__245_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "st: failed to register x-terminal-emulator alternative" 1
    fi
    dir_create_at_home_or_die__189_v0 ".config/fontconfig"
    copy_into_home_or_die__183_v0 "src/st/.config/fontconfig/fonts.conf" ".config/fontconfig"
    home__193_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "st: cannot resolve HOME" 1
    fi
    local h_408="${ret_home193_v0}"
    mkdir -p "${h_408}/.local/bin"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "st: failed to create ~/.local/bin" 1
    fi
    cp "src/st/.local/bin/st-init.sh" "${h_408}/.local/bin/st-init.sh"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "st: failed to copy st-init.sh" 1
    fi
    chmod +x "${h_408}/.local/bin/st-init.sh"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "st: failed to chmod st-init.sh" 1
    fi
}

# symlink_create_dir(origin: Text, destination: Text)
symlink_create_dir__254_v0() {
    local origin_461="${1}"
    local destination_462="${2}"
    dir_exists__38_v0 "${origin_461}"
    local ret_dir_exists38_v0__4_12="${ret_dir_exists38_v0}"
    if [ "$(( ! ret_dir_exists38_v0__4_12 ))" != 0 ]; then
        echo "The directory ${origin_461} doesn't exist"
        ret_symlink_create_dir254_v0=''
        return 1
    fi
    ln -fsn ${origin_461} ${destination_462}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_create_dir254_v0=''
        return "${__status}"
    fi
}

# TODO test this
# _parent_dir(path: Text)
_parent_dir__256_v0() {
    local path_457="${1}"
    local command_33
    command_33="$(dirname ${path_457})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret__parent_dir256_v0=''
        return "${__status}"
    fi
    local parent_458="${command_33}"
    ret__parent_dir256_v0="${parent_458}"
    return 0
}

# symlink_into_home(src: Text, rel_dest: Text)
symlink_into_home__257_v0() {
    local src_453="${1}"
    local rel_dest_454="${2}"
    home__176_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home257_v0=''
        return "${__status}"
    fi
    local home_455="${ret_home176_v0}"
    local dest_456="${home_455}/${rel_dest_454}"
    _parent_dir__256_v0 "${dest_456}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home257_v0=''
        return "${__status}"
    fi
    local parent_459="${ret__parent_dir256_v0}"
    dir_create__44_v0 "${parent_459}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home257_v0=''
        return "${__status}"
    fi
    local command_34
    command_34="$(readlink -f ${src_453})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home257_v0=''
        return "${__status}"
    fi
    local abs_src_460="${command_34}"
    symlink_create_dir__254_v0 "${abs_src_460}" "${dest_456}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_into_home257_v0=''
        return "${__status}"
    fi
    ret_symlink_into_home257_v0="${dest_456}"
    return 0
}

# symlink_into_home_or_die(src: Text, rel_dest: Text)
symlink_into_home_or_die__258_v0() {
    local src_451="${1}"
    local rel_dest_452="${2}"
    symlink_into_home__257_v0 "${src_451}" "${rel_dest_452}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "deploy of ${src_451} symlink ${rel_dest_452}  into home failed" 1
    fi
    local dest_463="${ret_symlink_into_home257_v0}"
    ret_symlink_into_home_or_die258_v0="${dest_463}"
    return 0
}

# Symlink a home-relative path to another home-relative path (both resolved
# against home()). Works for files (e.g. bridging a data file from one config
# location to the path a plugin expects).
# symlink_at_home(src_rel: Text, dest_rel: Text)
symlink_at_home__259_v0() {
    local src_rel_1030="${1}"
    local dest_rel_1031="${2}"
    home__176_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_at_home259_v0=''
        return "${__status}"
    fi
    local h_1032="${ret_home176_v0}"
    local src_1033="${h_1032}/${src_rel_1030}"
    local dest_1034="${h_1032}/${dest_rel_1031}"
    file_exists__39_v0 "${src_1033}"
    local ret_file_exists39_v0__39_12="${ret_file_exists39_v0}"
    if [ "$(( ! ret_file_exists39_v0__39_12 ))" != 0 ]; then
        echo_error__142_v0 "symlink source ${src_1033} missing" 1
        ret_symlink_at_home259_v0=''
        return 1
    fi
    _parent_dir__256_v0 "${dest_1034}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_at_home259_v0=''
        return "${__status}"
    fi
    local parent_1035="${ret__parent_dir256_v0}"
    dir_create__44_v0 "${parent_1035}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_at_home259_v0=''
        return "${__status}"
    fi
    ln -fsn ${src_1033} ${dest_1034}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_symlink_at_home259_v0=''
        return "${__status}"
    fi
    ret_symlink_at_home259_v0="${dest_1034}"
    return 0
}

# symlink_at_home_or_die(src_rel: Text, dest_rel: Text)
symlink_at_home_or_die__260_v0() {
    local src_rel_1028="${1}"
    local dest_rel_1029="${2}"
    symlink_at_home__259_v0 "${src_rel_1028}" "${dest_rel_1029}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "symlink ${src_rel_1028} -> ${dest_rel_1029} in home failed" 1
    fi
    local dest_1036="${ret_symlink_at_home259_v0}"
    ret_symlink_at_home_or_die260_v0="${dest_1036}"
    return 0
}

# install_nerd_fonts()
install_nerd_fonts__262_v0() {
    local subpath_450=".local/share/fonts/NerdFonts"
    symlink_into_home_or_die__258_v0 "src/${subpath_450}" "${subpath_450}"
}

# install_rofi()
install_rofi__266_v0() {
    local array_35=("rofi")
    apt_install_or_die__173_v0 array_35[@]
    copy_into_home_or_die__183_v0 "src/rofi/.config/rofi" ".config/"
}

# set_only_user_write_or_die(path: Text)
set_only_user_write_or_die__271_v0() {
    local path_538="${1}"
    chmod -R g-w,o-w ${path_538}
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to set ${path_538} perms to user-only write" 1
    fi
}

# set_only_user_write_or_die_at_home(rel_path: Text)
set_only_user_write_or_die_at_home__272_v0() {
    local rel_path_536="${1}"
    home__176_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "cannot determine home directory for ${rel_path_536}" 1
    fi
    local h_537="${ret_home176_v0}"
    set_only_user_write_or_die__271_v0 "${h_537}/${rel_path_536}"
}

# make_executable(path: Text)
make_executable__273_v0() {
    local path_1124="${1}"
    chmod +x ${path_1124}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_make_executable273_v0=''
        return "${__status}"
    fi
}

# install_omz_config()
install_omz_config__275_v0() {
    local subpath_518=".oh-my-zsh"
    local array_36=("custom/plugins/")
    rsync_or_die_opts_into_home__214_v0 "src/${subpath_518}/" "${subpath_518}" array_36[@] 1
    set_only_user_write_or_die_at_home__272_v0 "${subpath_518}"
}

# execute(bin: Text, sh_path: Text)
execute__279_v0() {
    local bin_557="${1}"
    local sh_path_558="${2}"
    ${bin_557} ${sh_path_558}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute279_v0=''
        return "${__status}"
    fi
}

# execute_sh(sh_path: Text)
execute_sh__280_v0() {
    local sh_path_1146="${1}"
    execute__279_v0 "bash" "${sh_path_1146}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_sh280_v0=''
        return "${__status}"
    fi
}

# execute_zsh(sh_path: Text)
execute_zsh__281_v0() {
    local sh_path_556="${1}"
    execute__279_v0 "zsh" "${sh_path_556}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_zsh281_v0=''
        return "${__status}"
    fi
}

# execute_zsh_at_home(rel_sh_path: Text)
execute_zsh_at_home__284_v0() {
    local rel_sh_path_554="${1}"
    home__176_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_zsh_at_home284_v0=''
        return "${__status}"
    fi
    local h_555="${ret_home176_v0}"
    execute_zsh__281_v0 "${h_555}/${rel_sh_path_554}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_zsh_at_home284_v0=''
        return "${__status}"
    fi
}

# install_zshmarks()
install_zshmarks__287_v0() {
    mkdir -p ~/.oh-my-zsh/custom/plugins/zshmarks
    __status=$?
    cp src/zshmarks.plugin.zsh ~/.oh-my-zsh/custom/plugins/zshmarks/zshmarks.plugin.zsh
    __status=$?
    execute_zsh_at_home__284_v0 ".oh-my-zsh/custom/plugins/zshmarks/zshmarks.plugin.zsh"
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
temp_file_create__297_v0() {
    local suffix_709="${1}"
    token_20="$(( token_20 + 1 ))"
    local tmp_710="${__TMP_DIR_19}/${token_20}${suffix_709}"
    touch "${tmp_710}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_temp_file_create297_v0=''
        return "${__status}"
    fi
    ret_temp_file_create297_v0="${tmp_710}"
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
download_to__300_v0() {
    local url_712="${1}"
    local target_713="${2}"
    curl -fsSL ${url_712} -o ${target_713}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_to300_v0=''
        return "${__status}"
    fi
}

# download_tmp(url: Text)
download_tmp__301_v0() {
    local url_708="${1}"
    temp_file_create__297_v0 ""
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_tmp301_v0=''
        return "${__status}"
    fi
    local target_711="${ret_temp_file_create297_v0}"
    download_to__300_v0 "${url_708}" "${target_711}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_tmp301_v0=''
        return "${__status}"
    fi
    ret_download_tmp301_v0="${target_711}"
    return 0
}

# url_status(url: Text)
url_status__302_v0() {
    local url_967="${1}"
    local command_37
    command_37="$(curl -sIL ${url_967} | head -1 | tr -s ' ' | cut -d' ' -f2)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_url_status302_v0=''
        return "${__status}"
    fi
    ret_url_status302_v0="${command_37}"
    return 0
}

# download_verified_url_to(url: Text, target: Text, expected_hash: Text)
download_verified_url_to__303_v0() {
    local url_1119="${1}"
    local target_1120="${2}"
    local expected_hash_1121="${3}"
    download_to__300_v0 "${url_1119}" "${target_1120}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_url_to303_v0=''
        return 0
    fi
    local command_38
    command_38="$(sha256sum ${target_1120} | cut -d' ' -f1)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_url_to303_v0=''
        return "${__status}"
    fi
    local actual_1122="${command_38}"
    if [ "$([ "_${actual_1122}" == "_${expected_hash_1121}" ]; echo $?)" != 0 ]; then
        echo_error__142_v0 "sha256 mismatch for ${target_1120}: expected ${expected_hash_1121}, got ${actual_1122}" 1
        rm -f ${target_1120}
        __status=$?
        ret_download_verified_url_to303_v0=''
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
resolve_vendor_dir__315_v0() {
    dir_exists__38_v0 "${installed_vendor_23}"
    local ret_dir_exists38_v0__12_8="${ret_dir_exists38_v0}"
    file_exists__39_v0 "${installed_vendor_23}/jsonnet"
    local ret_file_exists39_v0__12_41="${ret_file_exists39_v0}"
    if [ "$(( ret_dir_exists38_v0__12_8 && ret_file_exists39_v0__12_41 ))" != 0 ]; then
        ret_resolve_vendor_dir315_v0="${installed_vendor_23}"
        return 0
    fi
    dir_exists__38_v0 "${project_vendor_22}"
    local ret_dir_exists38_v0__15_8="${ret_dir_exists38_v0}"
    file_exists__39_v0 "${project_vendor_22}/jsonnet"
    local ret_file_exists39_v0__15_39="${ret_file_exists39_v0}"
    if [ "$(( ret_dir_exists38_v0__15_8 && ret_file_exists39_v0__15_39 ))" != 0 ]; then
        ret_resolve_vendor_dir315_v0="${project_vendor_22}"
        return 0
    fi
    dir_exists__38_v0 "${installed_vendor_23}"
    local ret_dir_exists38_v0__18_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__18_8}" != 0 ]; then
        ret_resolve_vendor_dir315_v0="${installed_vendor_23}"
        return 0
    fi
    dir_exists__38_v0 "${project_vendor_22}"
    local ret_dir_exists38_v0__21_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__21_8}" != 0 ]; then
        ret_resolve_vendor_dir315_v0="${project_vendor_22}"
        return 0
    fi
    ret_resolve_vendor_dir315_v0=""
    return 0
}

resolve_vendor_dir__315_v0 
__VENDOR_DIR_34="${ret_resolve_vendor_dir315_v0}"
# jq_resolve()
jq_resolve__316_v0() {
    if [ "$([ "_${__VENDOR_DIR_34}" != "_" ]; echo $?)" != 0 ]; then
        ret_jq_resolve316_v0="jq"
        return 0
    fi
    ret_jq_resolve316_v0="${__VENDOR_DIR_34}/jq"
    return 0
}

# j2_resolve()
j2_resolve__317_v0() {
    if [ "$([ "_${__VENDOR_DIR_34}" != "_" ]; echo $?)" != 0 ]; then
        ret_j2_resolve317_v0="j2"
        return 0
    fi
    ret_j2_resolve317_v0="${__VENDOR_DIR_34}/j2"
    return 0
}

# jsonnet_resolve()
jsonnet_resolve__318_v0() {
    if [ "$([ "_${__VENDOR_DIR_34}" != "_" ]; echo $?)" != 0 ]; then
        ret_jsonnet_resolve318_v0="jsonnet"
        return 0
    fi
    ret_jsonnet_resolve318_v0="${__VENDOR_DIR_34}/jsonnet"
    return 0
}

# jsonschema_resolve()
jsonschema_resolve__319_v0() {
    if [ "$([ "_${__VENDOR_DIR_34}" != "_" ]; echo $?)" != 0 ]; then
        ret_jsonschema_resolve319_v0="jsonschema"
        return 0
    fi
    ret_jsonschema_resolve319_v0="${__VENDOR_DIR_34}/jsonschema"
    return 0
}

# lua_resolve()
lua_resolve__320_v0() {
    if [ "$([ "_${__VENDOR_DIR_34}" != "_" ]; echo $?)" != 0 ]; then
        ret_lua_resolve320_v0="lua"
        return 0
    fi
    ret_lua_resolve320_v0="${__VENDOR_DIR_34}/lua"
    return 0
}

jq_resolve__316_v0 
__JQ_35="${ret_jq_resolve316_v0}"
j2_resolve__317_v0 
jsonnet_resolve__318_v0 
jsonschema_resolve__319_v0 
lua_resolve__320_v0 
# tag_verified(repo: Text, tag: Text)
tag_verified__321_v0() {
    local repo_717="${1}"
    local tag_718="${2}"
    local ref_url_719="https://api.github.com/repos/${repo_717}/git/ref/tags/${tag_718}"
    download_tmp__301_v0 "${ref_url_719}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_tag_verified321_v0=''
        return "${__status}"
    fi
    local ref_data_720="${ret_download_tmp301_v0}"
    local command_40
    command_40="$(${__JQ_35} -r .object.type ${ref_data_720})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_tag_verified321_v0=''
        return "${__status}"
    fi
    local obj_type_721="${command_40}"
    if [ "$([ "_${obj_type_721}" == "_tag" ]; echo $?)" != 0 ]; then
        ret_tag_verified321_v0=1
        return 0
    fi
    local command_41
    command_41="$(${__JQ_35} -r .object.sha ${ref_data_720})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_tag_verified321_v0=''
        return "${__status}"
    fi
    local sha_722="${command_41}"
    local tag_url_723="https://api.github.com/repos/${repo_717}/git/tags/${sha_722}"
    local command_42
    command_42="$(curl -fsSL ${tag_url_723} | ${__JQ_35} -r .verification.verified)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_tag_verified321_v0=''
        return "${__status}"
    fi
    local verified_724="${command_42}"
    ret_tag_verified321_v0="$([ "_${verified_724}" != "_true" ]; echo $?)"
    return 0
}

# install_github_binary(repo: Text, asset_suffix: Text, binary_name: Text, install_dir: Text)
install_github_binary__324_v0() {
    local repo_703="${1}"
    local asset_suffix_704="${2}"
    local binary_name_705="${3}"
    local install_dir_706="${4}"
    local api_707="https://api.github.com/repos/${repo_703}/releases/latest"
    download_tmp__301_v0 "${api_707}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_github_binary324_v0=''
        return "${__status}"
    fi
    local rel_714="${ret_download_tmp301_v0}"
    local command_43
    command_43="$(${__JQ_35} -r '.assets[] | select(.name | endswith("'"${asset_suffix_704}"'")) | .browser_download_url' ${rel_714})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_github_binary324_v0=''
        return "${__status}"
    fi
    local url_715="${command_43}"
    local command_44
    command_44="$(${__JQ_35} -r .tag_name ${rel_714})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_github_binary324_v0=''
        return "${__status}"
    fi
    local tag_716="${command_44}"
    tag_verified__321_v0 "${repo_703}" "${tag_716}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_github_binary324_v0=''
        return "${__status}"
    fi
    local ret_tag_verified321_v0__44_12="${ret_tag_verified321_v0}"
    if [ "$(( ! ret_tag_verified321_v0__44_12 ))" != 0 ]; then
        ret_install_github_binary324_v0=''
        return 1
    fi
    download_tmp__301_v0 "${url_715}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_github_binary324_v0=''
        return "${__status}"
    fi
    local tarball_725="${ret_download_tmp301_v0}"
    temp_dir_create__46_v0 "gh-bin-XXXXXX" 0 0
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_github_binary324_v0=''
        return "${__status}"
    fi
    local tmp_726="${ret_temp_dir_create46_v0}"
    tar -xzf ${tarball_725} -C ${tmp_726}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_github_binary324_v0=''
        return "${__status}"
    fi
    install -m755 ${tmp_726}/${binary_name_705} ${install_dir_706}
    __status=$?
    if [ "${__status}" != 0 ]; then
        install -m755 ${tmp_726}/*/${binary_name_705} ${install_dir_706}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_install_github_binary324_v0=''
            return "${__status}"
        fi
    fi
}

# install_github_binary_or_die(repo: Text, asset_suffix: Text, binary_name: Text, install_dir: Text)
install_github_binary_or_die__325_v0() {
    local repo_699="${1}"
    local asset_suffix_700="${2}"
    local binary_name_701="${3}"
    local install_dir_702="${4}"
    install_github_binary__324_v0 "${repo_699}" "${asset_suffix_700}" "${binary_name_701}" "${install_dir_702}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to install ${binary_name_701} from ${repo_699}" 1
    fi
}

# install_system_tools()
install_system_tools__327_v0() {
    local array_45=("ncdu")
    apt_install_or_die__173_v0 array_45[@]
    has_cmd__237_v0 "jj"
    local ret_has_cmd237_v0__12_12="${ret_has_cmd237_v0}"
    if [ "$(( ! ret_has_cmd237_v0__12_12 ))" != 0 ]; then
        install_github_binary_or_die__325_v0 "jj-vcs/jj" "x86_64-unknown-linux-musl.tar.gz" "jj" "/usr/local/bin"
    fi
}

# install_deb(deb_path: Text)
install_deb__335_v0() {
    local deb_path_953="${1}"
    local array_46=()
    sudo_cmd__168_v0 "dpkg -i ${deb_path_953}" array_46[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        # dpkg may fail due to missing deps; fix them below
        :
    fi
    local array_47=()
    sudo_cmd__168_v0 "apt-get install -f -y" array_47[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_deb335_v0=''
        return "${__status}"
    fi
}

# install_deb_url(url: Text)
install_deb_url__337_v0() {
    local url_952="${1}"
    download_tmp__301_v0 "${url_952}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_deb_url337_v0=''
        return "${__status}"
    fi
    local ret_download_tmp301_v0__19_17="${ret_download_tmp301_v0}"
    install_deb__335_v0 "${ret_download_tmp301_v0__19_17}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_deb_url337_v0=''
        return "${__status}"
    fi
}

# install_deb_url_or_die(url: Text)
install_deb_url_or_die__338_v0() {
    local url_951="${1}"
    install_deb_url__337_v0 "${url_951}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to install .deb from ${url_951}" 1
    fi
}

# extract_extension_id(url: Text)
extract_extension_id__343_v0() {
    local url_956="${1}"
    replace_regex__3_v0 "${url_956}" "^https?://[^/]+/.+/([^/]+)\$" "" 1
    local ret_replace_regex3_v0__6_8="${ret_replace_regex3_v0}"
    if [ "$([ "_${ret_replace_regex3_v0__6_8}" != "_${url_956}" ]; echo $?)" != 0 ]; then
        echo_error__142_v0 "malformed extension url: ${url_956}" 1
    fi
    replace_regex__3_v0 "${url_956}" "^.*/([^/]+)\$" "\\1" 1
    ret_extract_extension_id343_v0="${ret_replace_regex3_v0}"
    return 0
}

# install_chrome_extension(url: Text)
install_chrome_extension__344_v0() {
    local url_955="${1}"
    extract_extension_id__343_v0 "${url_955}"
    local id_966="${ret_extract_extension_id343_v0}"
    url_status__302_v0 "${url_955}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_chrome_extension344_v0=''
        return "${__status}"
    fi
    local http_code_968="${ret_url_status302_v0}"
    if [ "$([ "_${http_code_968}" == "_200" ]; echo $?)" != 0 ]; then
        echo_error__142_v0 "extension url returned HTTP ${http_code_968} (expected 200): ${url_955}" 1
    fi
    local dir_969="/etc/opt/chrome/policies/managed"
    mkdir -p ${dir_969}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_chrome_extension344_v0=''
        return "${__status}"
    fi
    chmod 755 /etc/opt/chrome
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_chrome_extension344_v0=''
        return "${__status}"
    fi
    printf '{"ExtensionInstallForcelist":["%s;https://clients2.google.com/service/update2/crx"]}
' ${id_966} > ${dir_969}/vimium.json
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_chrome_extension344_v0=''
        return "${__status}"
    fi
}

# install_chrome_extension_or_die(url: Text)
install_chrome_extension_or_die__345_v0() {
    local url_954="${1}"
    install_chrome_extension__344_v0 "${url_954}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to install chrome extension ${url_954}" 1
    fi
}

__VIMIUM_URL_41="https://chromewebstore.google.com/detail/vimium/dbepggeogbaibhgnhhndojpepiihcmeb"
# install_browsers()
install_browsers__347_v0() {
    has_cmd__237_v0 "google-chrome-stable"
    local ret_has_cmd237_v0__14_12="${ret_has_cmd237_v0}"
    if [ "$(( ! ret_has_cmd237_v0__14_12 ))" != 0 ]; then
        install_deb_url_or_die__338_v0 "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    fi
    install_chrome_extension_or_die__345_v0 "${__VIMIUM_URL_41}"
}

# has_cmd(cmd: Text)
has_cmd__357_v0() {
    local cmd_996="${1}"
    local found_997=0
    command -v ${cmd_996} >/dev/null 2>&1
    __status=$?
    if [ "${__status}" = 0 ]; then
        found_997=1
    fi
    ret_has_cmd357_v0="${found_997}"
    return 0
}

# echo_error exits the process (default exit_code=1), so no fail needed.
# TODO cleanup this file... too bashish
# Source brew's shellenv so `brew` is on PATH after a same-session install.
# On container overlay filesystems brew lock filenames can exceed NAME_MAX;
# symlink the locks dir to /tmp to keep them short.
# install_via_curl(url: Text)
install_via_curl__372_v0() {
    local url_993="${1}"
    NONINTERACTIVE=1 curl -fsSL ${url_993} | bash
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_via_curl372_v0=''
        return "${__status}"
    fi
}

was_updated_42=0
# update()
update__380_v0() {
    local array_48=()
    sudo_cmd__168_v0 "apt-get update" array_48[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_update380_v0=''
        return "${__status}"
    fi
}

# ensure_updated()
ensure_updated__381_v0() {
    if [ "$(( ! was_updated_42 ))" != 0 ]; then
        update__380_v0 
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_ensure_updated381_v0=''
            return "${__status}"
        fi
        was_updated_42=1
    fi
}

# apt_install(packages: [Text])
apt_install__382_v0() {
    local packages_998=("${!1}")
    ensure_updated__381_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_apt_install382_v0=''
        return "${__status}"
    fi
    join__7_v0 packages_998[@] " "
    local pkgs_999="${ret_join7_v0}"
    local array_49=("DEBIAN_FRONTEND=noninteractive")
    sudo_cmd__168_v1 "apt-get install -y --no-install-recommends ${pkgs_999}" array_49[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_apt_install382_v0=''
        return "${__status}"
    fi
}

# install_via_npm(packages: [Text])
install_via_npm__386_v0() {
    local packages_995=("${!1}")
    has_cmd__357_v0 "npm"
    local ret_has_cmd357_v0__7_12="${ret_has_cmd357_v0}"
    if [ "$(( ! ret_has_cmd357_v0__7_12 ))" != 0 ]; then
        local array_50=("npm")
        apt_install__382_v0 array_50[@]
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_install_via_npm386_v0=''
            return "${__status}"
        fi
    fi
    local array_51=()
    sudo_cmd__168_v0 "npm install -g ${packages_995[@]}" array_51[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_via_npm386_v0=''
        return "${__status}"
    fi
}

# install_via_npm_or_die(packages: [Text])
install_via_npm_or_die__387_v0() {
    local packages_994=("${!1}")
    install_via_npm__386_v0 packages_994[@]
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to npm install ${packages_994[@]}" 1
    fi
}

# install_ai_tools()
install_ai_tools__389_v0() {
    install_via_curl__372_v0 "https://antigravity.google/cli/install.sh"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "skipping agy" 1
    fi
    local array_52=("@kilocode/cli")
    install_via_npm_or_die__387_v0 array_52[@]
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
install_quicksheet__391_v0() {
    :
}

# install_nvim()
install_nvim__396_v0() {
    local array_53=("fd-find" "clang" "g++")
    apt_install_or_die__173_v0 array_53[@]
    local subpath_1026=".config/nvim"
    symlink_into_home_or_die__258_v0 "src/${subpath_1026}" "${subpath_1026}"
    local lazy_dir_1027="${subpath_1026}/lazy"
    symlink_into_home_or_die__258_v0 "src/${lazy_dir_1027}" ".local/share/nvim/lazy"
    # quicksheet reads ~/.config/quicksheet.txt; the data ships from the nvim
    # repo as ~/.config/nvim/quicksheet.txt. Symlink it so quicksheet finds it.
    symlink_at_home_or_die__260_v0 ".config/nvim/quicksheet.txt" ".config/quicksheet.txt"
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
download_verified_url_to_home__415_v0() {
    local url_1113="${1}"
    local rel_path_1114="${2}"
    local expected_hash_1115="${3}"
    home__176_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_url_to_home415_v0=''
        return "${__status}"
    fi
    local h_1116="${ret_home176_v0}"
    local full_1117="${h_1116}/${rel_path_1114}"
    local command_54
    command_54="$(dirname ${full_1117})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_url_to_home415_v0=''
        return "${__status}"
    fi
    local parent_1118="${command_54}"
    dir_create__44_v0 "${parent_1118}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_url_to_home415_v0=''
        return "${__status}"
    fi
    download_verified_url_to__303_v0 "${url_1113}" "${full_1117}" "${expected_hash_1115}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_url_to_home415_v0=''
        return "${__status}"
    fi
}

# download_verified_executable_to_home(url: Text, rel_path: Text, expected_hash: Text)
download_verified_executable_to_home__417_v0() {
    local url_1110="${1}"
    local rel_path_1111="${2}"
    local expected_hash_1112="${3}"
    download_verified_url_to_home__415_v0 "${url_1110}" "${rel_path_1111}" "${expected_hash_1112}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_executable_to_home417_v0=''
        return "${__status}"
    fi
    home__176_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_executable_to_home417_v0=''
        return "${__status}"
    fi
    local h_1123="${ret_home176_v0}"
    make_executable__273_v0 "${h_1123}/${rel_path_1111}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_executable_to_home417_v0=''
        return "${__status}"
    fi
}

# download_verified_executable_to_home_or_die(url: Text, rel_path: Text, expected_hash: Text)
download_verified_executable_to_home_or_die__418_v0() {
    local url_1107="${1}"
    local rel_path_1108="${2}"
    local expected_hash_1109="${3}"
    download_verified_executable_to_home__417_v0 "${url_1107}" "${rel_path_1108}" "${expected_hash_1109}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to download, verify, or make executable ${url_1107} to ~/${rel_path_1108}" 1
    fi
}

# install_tmux_warm_daemon()
install_tmux_warm_daemon__420_v0() {
    copy_into_home_or_die__183_v0 "src/.tmux_warm_daemon/attach_warm.sh" ".local/bin/"
    copy_into_home_or_die__183_v0 "src/.tmux_warm_daemon/restart_daemon.sh" ".local/bin/"
    copy_into_home_or_die__183_v0 "src/.tmux_warm_daemon/agent-warm.sh" ".local/bin/"
    copy_into_home_or_die__183_v0 "src/.tmux_warm_daemon/bootstrap-warm-daemon.sh" ".local/bin/"
    # Pool config: defines the `agent` pool so the daemon pre-warms agent
    # sessions (agent-N / agent@<hash>) instead of only `warm-*`. The agent
    # command is agent-warm.sh, which execs whatever `kv agentclitool` points
    # at — so no tool is hardcoded (see ~/.local/bin/agent-warm.sh).
    copy_into_home_or_die__183_v0 "src/.tmux_warm_daemon/config.yaml" ".config/tmux_warm_daemon/"
    rsync_or_die_into_home__212_v0 "src/.tmux_warm_daemon/" ".tmux_warm_daemon/" 1
    # Only fetch Rust binary when the bash backend was stripped during generation
    # (i.e. user chose impl: 'rust' or didn't set impl). When bash is present,
    # the backend-agnostic launcher will fall through to it.
    local command_55
    command_55="$(test -f ~/.tmux_warm_daemon/bash/tmux_warm_daemon && echo "yes" || echo "")"
    __status=$?
    local bash_present_1105="${command_55}"
    if [ "$([ "_${bash_present_1105}" != "_" ]; echo $?)" != 0 ]; then
        local rel_bin_1106=".tmux_warm_daemon/rust/target/release/tmux_warm_daemon"
        download_verified_executable_to_home_or_die__418_v0 "https://github.com/jesusmb1995/tmux-warm-daemon/releases/download/v0.1.0-prealpha/tmux_warm_daemon" "${rel_bin_1106}" "95a6727f495b4e3970084e20efe12e93427bb90b7dc7e8dac3605c7a5e48b902"
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
install_cmd_bookmarks__423_v0() {
    symlink_into_home_or_die__258_v0 "src/cmd_bookmarks" ".local/share/cmd_bookmarks"
}

# execute_sh_at_home(rel_sh_path: Text)
execute_sh_at_home__429_v0() {
    local rel_sh_path_1144="${1}"
    home__176_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_sh_at_home429_v0=''
        return "${__status}"
    fi
    local h_1145="${ret_home176_v0}"
    execute_sh__280_v0 "${h_1145}/${rel_sh_path_1144}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_execute_sh_at_home429_v0=''
        return "${__status}"
    fi
}

# execute_sh_at_home_or_die(rel_sh_path: Text)
execute_sh_at_home_or_die__430_v0() {
    local rel_sh_path_1143="${1}"
    execute_sh_at_home__429_v0 "${rel_sh_path_1143}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to run ${rel_sh_path_1143}" 1
    fi
}

# install_agent_global_config()
install_agent_global_config__435_v0() {
    rsync_or_die_into_home__212_v0 "src/.agent/" ".agent" 1
    home__193_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "install_agent_global_config: home unresolved" 1
        exit 1
    fi
    local h_1140="${ret_home193_v0}"
    local scripts_1141=("sync-permissions-from-cli.sh" "sync-permissions.sh" "sync-antigravity-permissions.sh" "sync-kilocode-permissions.sh")
    for script_1142 in "${scripts_1141[@]}"; do
        file_exists__39_v0 "${h_1140}/.agent/${script_1142}"
        local ret_file_exists39_v0__20_12="${ret_file_exists39_v0}"
        if [ "${ret_file_exists39_v0__20_12}" != 0 ]; then
            execute_sh_at_home_or_die__430_v0 ".agent/${script_1142}"
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
resolve_vendor_dir__443_v0() {
    dir_exists__38_v0 "${installed_vendor_45}"
    local ret_dir_exists38_v0__12_8="${ret_dir_exists38_v0}"
    file_exists__39_v0 "${installed_vendor_45}/jsonnet"
    local ret_file_exists39_v0__12_41="${ret_file_exists39_v0}"
    if [ "$(( ret_dir_exists38_v0__12_8 && ret_file_exists39_v0__12_41 ))" != 0 ]; then
        ret_resolve_vendor_dir443_v0="${installed_vendor_45}"
        return 0
    fi
    dir_exists__38_v0 "${project_vendor_44}"
    local ret_dir_exists38_v0__15_8="${ret_dir_exists38_v0}"
    file_exists__39_v0 "${project_vendor_44}/jsonnet"
    local ret_file_exists39_v0__15_39="${ret_file_exists39_v0}"
    if [ "$(( ret_dir_exists38_v0__15_8 && ret_file_exists39_v0__15_39 ))" != 0 ]; then
        ret_resolve_vendor_dir443_v0="${project_vendor_44}"
        return 0
    fi
    dir_exists__38_v0 "${installed_vendor_45}"
    local ret_dir_exists38_v0__18_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__18_8}" != 0 ]; then
        ret_resolve_vendor_dir443_v0="${installed_vendor_45}"
        return 0
    fi
    dir_exists__38_v0 "${project_vendor_44}"
    local ret_dir_exists38_v0__21_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__21_8}" != 0 ]; then
        ret_resolve_vendor_dir443_v0="${project_vendor_44}"
        return 0
    fi
    ret_resolve_vendor_dir443_v0=""
    return 0
}

resolve_vendor_dir__443_v0 
__VENDOR_DIR_46="${ret_resolve_vendor_dir443_v0}"
# jq_resolve()
jq_resolve__444_v0() {
    if [ "$([ "_${__VENDOR_DIR_46}" != "_" ]; echo $?)" != 0 ]; then
        ret_jq_resolve444_v0="jq"
        return 0
    fi
    ret_jq_resolve444_v0="${__VENDOR_DIR_46}/jq"
    return 0
}

# j2_resolve()
j2_resolve__445_v0() {
    if [ "$([ "_${__VENDOR_DIR_46}" != "_" ]; echo $?)" != 0 ]; then
        ret_j2_resolve445_v0="j2"
        return 0
    fi
    ret_j2_resolve445_v0="${__VENDOR_DIR_46}/j2"
    return 0
}

# jsonnet_resolve()
jsonnet_resolve__446_v0() {
    if [ "$([ "_${__VENDOR_DIR_46}" != "_" ]; echo $?)" != 0 ]; then
        ret_jsonnet_resolve446_v0="jsonnet"
        return 0
    fi
    ret_jsonnet_resolve446_v0="${__VENDOR_DIR_46}/jsonnet"
    return 0
}

# jsonschema_resolve()
jsonschema_resolve__447_v0() {
    if [ "$([ "_${__VENDOR_DIR_46}" != "_" ]; echo $?)" != 0 ]; then
        ret_jsonschema_resolve447_v0="jsonschema"
        return 0
    fi
    ret_jsonschema_resolve447_v0="${__VENDOR_DIR_46}/jsonschema"
    return 0
}

# lua_resolve()
lua_resolve__448_v0() {
    if [ "$([ "_${__VENDOR_DIR_46}" != "_" ]; echo $?)" != 0 ]; then
        ret_lua_resolve448_v0="lua"
        return 0
    fi
    ret_lua_resolve448_v0="${__VENDOR_DIR_46}/lua"
    return 0
}

jq_resolve__444_v0 
j2_resolve__445_v0 
jsonnet_resolve__446_v0 
jsonschema_resolve__447_v0 
lua_resolve__448_v0 
# link_store(link: Text, canon: Text)
link_store__467_v0() {
    local link_1177="${1}"
    local canon_1178="${2}"
    local target_1179="../.agents/skills"
    local command_60
    command_60="$(dirname ${link_1177})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_link_store467_v0=''
        return "${__status}"
    fi
    local dir_1180="${command_60}"
    dir_create__44_v0 "${dir_1180}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_link_store467_v0=''
        return "${__status}"
    fi
    local is_real_dir_1181=0
    [ ! -L ${link_1177} ] && [ -d ${link_1177} ]
    __status=$?
    if [ "${__status}" = 0 ]; then
        is_real_dir_1181=1
    fi
    if [ "${is_real_dir_1181}" != 0 ]; then
        local __cp_61=
        (( 1 )) && __cp_61="-f" || __cp_61=""
        cp -r ${__cp_61} "${link_1177}" "${canon_1178}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_link_store467_v0=''
            return "${__status}"
        fi
        local __rm_62=
        (( 1 )) && __rm_62="-r" || __rm_62=""
        local __rm_63=
        rm ${__rm_63} ${__rm_62} "${link_1177}"
        ln -sfn ${target_1179} ${link_1177}
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_link_store467_v0=''
            return "${__status}"
        fi
    else
        local exists_plain_1182=0
        [ -e ${link_1177} ] && [ ! -L ${link_1177} ]
        __status=$?
        if [ "${__status}" = 0 ]; then
            exists_plain_1182=1
        fi
        if [ "$(( ! exists_plain_1182 ))" != 0 ]; then
            ln -sfn ${target_1179} ${link_1177}
            __status=$?
            if [ "${__status}" != 0 ]; then
                ret_link_store467_v0=''
                return "${__status}"
            fi
        fi
    fi
}

# install_agent_skills_impl()
install_agent_skills_impl__469_v0() {
    home__193_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_install_agent_skills_impl469_v0=''
        return "${__status}"
    fi
    local h_1173="${ret_home193_v0}"
    local canon_1174="${h_1173}/.agents/skills"
    local skills_src_1175="src/agent-skills/.agents/skills"
    rsync_or_die_into_home__212_v0 "${skills_src_1175}/" ".agents/skills" 0
    dir_exists__38_v0 "${canon_1174}"
    local ret_dir_exists38_v0__49_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__49_8}" != 0 ]; then
        local legacy_dir_1176="${h_1173}/.cursor/skills-cursor"
        dir_exists__38_v0 "${legacy_dir_1176}"
        local ret_dir_exists38_v0__51_12="${ret_dir_exists38_v0}"
        if [ "${ret_dir_exists38_v0__51_12}" != 0 ]; then
            local __rm_64=
            (( 1 )) && __rm_64="-r" || __rm_64=""
            local __rm_65=
            rm ${__rm_65} ${__rm_64} "${legacy_dir_1176}"
        fi
        # 2. Wire the store into each ENABLED tool. Antigravity reads ~/.agents/skills natively, so it needs no link.
        link_store__467_v0 "${h_1173}/.kilo/skills" "${canon_1174}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_install_agent_skills_impl469_v0=''
            return "${__status}"
        fi
    fi
}

# install_agent_skills()
install_agent_skills__470_v0() {
    install_agent_skills_impl__469_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        echo_error__142_v0 "failed to install agent skills" 1
    fi
}

# install_skill_caveman()
install_skill_caveman__473_v0() {
    symlink_into_home_or_die__258_v0 "src/.agents/skills/caveman" ".agents/skills/caveman"
}

# install_skill_humanizer()
install_skill_humanizer__476_v0() {
    symlink_into_home_or_die__258_v0 "src/.agents/skills/humanizer" ".agents/skills/humanizer"
}

# install_skill_ponytail()
install_skill_ponytail__479_v0() {
    symlink_into_home_or_die__258_v0 "src/.agents/skills/ponytail" ".agents/skills/ponytail"
}

temp_dir_create__46_v0 "amber-XXXXXX" 1 1
__status=$?
if [ "${__status}" != 0 ]; then
    :
fi
__TMP_DIR_53="${ret_temp_dir_create46_v0}"
token_54=1
# temp_file_create(suffix: Text)
temp_file_create__486_v0() {
    local suffix_1202="${1}"
    token_54="$(( token_54 + 1 ))"
    local tmp_1203="${__TMP_DIR_53}/${token_54}${suffix_1202}"
    touch "${tmp_1203}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_temp_file_create486_v0=''
        return "${__status}"
    fi
    ret_temp_file_create486_v0="${tmp_1203}"
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
download_to__489_v0() {
    local url_1208="${1}"
    local target_1209="${2}"
    curl -fsSL ${url_1208} -o ${target_1209}
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_to489_v0=''
        return "${__status}"
    fi
}

# download_verified_url_to(url: Text, target: Text, expected_hash: Text)
download_verified_url_to__492_v0() {
    local url_1205="${1}"
    local target_1206="${2}"
    local expected_hash_1207="${3}"
    download_to__489_v0 "${url_1205}" "${target_1206}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_url_to492_v0=''
        return 0
    fi
    local command_66
    command_66="$(sha256sum ${target_1206} | cut -d' ' -f1)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_download_verified_url_to492_v0=''
        return "${__status}"
    fi
    local actual_1210="${command_66}"
    if [ "$([ "_${actual_1210}" == "_${expected_hash_1207}" ]; echo $?)" != 0 ]; then
        echo_error__142_v0 "sha256 mismatch for ${target_1206}: expected ${expected_hash_1207}, got ${actual_1210}" 1
        rm -f ${target_1206}
        __status=$?
        ret_download_verified_url_to492_v0=''
        return 0
    fi
}

__BAZELISK_URL_55="https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64"
__BAZELISK_HASH_56="5a408715e932c0250d28bd84555f12edbf70117de42f9181691c736eacc4a992"
# install_bazelisk()
install_bazelisk__497_v0() {
    has_cmd__237_v0 "bazelisk"
    local ret_has_cmd237_v0__11_12="${ret_has_cmd237_v0}"
    if [ "$(( ! ret_has_cmd237_v0__11_12 ))" != 0 ]; then
        temp_file_create__486_v0 ""
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "bazelisk: failed to create temp file" 1
        fi
        local tmp_1204="${ret_temp_file_create486_v0}"
        download_verified_url_to__492_v0 "${__BAZELISK_URL_55}" "${tmp_1204}" "${__BAZELISK_HASH_56}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            echo_error__142_v0 "bazelisk: sha256 mismatch, expected ${__BAZELISK_HASH_56}" 1
        fi
        local array_67=()
        sudo_cmd__234_v0 "install -m755 ${tmp_1204} /usr/local/bin/bazelisk" array_67[@]
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
print_help__499_v0() {
    echo "Usage: ./install.sh [step ...]"
    printf '%s\n' ""
    echo "Install all steps by default. Pass one or more step names to run"
    echo "only those steps. Use 'help' to print this message."
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
run_step__500_v0() {
    local step_1293="${1}"
    local matched_1294=0
    if [ "$([ "_${step_1293}" != "_help" ]; echo $?)" != 0 ]; then
        print_help__499_v0 
        matched_1294=1
    fi
    if [ "$([ "_${step_1293}" != "_apt_essential_tools" ]; echo $?)" != 0 ]; then
        install_apt_essential_tools__199_v0 
        matched_1294=1
    fi
    if [ "$([ "_${step_1293}" != "_apt_essential_ui" ]; echo $?)" != 0 ]; then
        install_apt_essential_ui__202_v0 
        matched_1294=1
    fi
    if [ "$([ "_${step_1293}" != "_dotfiles_essential" ]; echo $?)" != 0 ]; then
        install_dotfiles_essential__216_v0 
        matched_1294=1
    fi
    if [ "$([ "_${step_1293}" != "_dotfiles_personalization" ]; echo $?)" != 0 ]; then
        install_dotfiles_personalization__226_v0 
        matched_1294=1
    fi
    if [ "$([ "_${step_1293}" != "_st" ]; echo $?)" != 0 ]; then
        install_st__246_v0 
        matched_1294=1
    fi
    if [ "$([ "_${step_1293}" != "_nerd_fonts" ]; echo $?)" != 0 ]; then
        install_nerd_fonts__262_v0 
        matched_1294=1
    fi
    if [ "$([ "_${step_1293}" != "_rofi" ]; echo $?)" != 0 ]; then
        install_rofi__266_v0 
        matched_1294=1
    fi
    if [ "$([ "_${step_1293}" != "_omz_config" ]; echo $?)" != 0 ]; then
        install_omz_config__275_v0 
        matched_1294=1
    fi
    if [ "$([ "_${step_1293}" != "_zshmarks" ]; echo $?)" != 0 ]; then
        install_zshmarks__287_v0 
        matched_1294=1
    fi
    if [ "$([ "_${step_1293}" != "_system_tools" ]; echo $?)" != 0 ]; then
        install_system_tools__327_v0 
        matched_1294=1
    fi
    if [ "$([ "_${step_1293}" != "_browsers" ]; echo $?)" != 0 ]; then
        install_browsers__347_v0 
        matched_1294=1
    fi
    if [ "$([ "_${step_1293}" != "_ai_tools" ]; echo $?)" != 0 ]; then
        install_ai_tools__389_v0 
        matched_1294=1
    fi
    if [ "$([ "_${step_1293}" != "_quicksheet" ]; echo $?)" != 0 ]; then
        install_quicksheet__391_v0 
        matched_1294=1
    fi
    if [ "$([ "_${step_1293}" != "_nvim" ]; echo $?)" != 0 ]; then
        install_nvim__396_v0 
        matched_1294=1
    fi
    if [ "$([ "_${step_1293}" != "_tmux_warm_daemon" ]; echo $?)" != 0 ]; then
        install_tmux_warm_daemon__420_v0 
        matched_1294=1
    fi
    if [ "$([ "_${step_1293}" != "_cmd_bookmarks" ]; echo $?)" != 0 ]; then
        install_cmd_bookmarks__423_v0 
        matched_1294=1
    fi
    if [ "$([ "_${step_1293}" != "_agent_global_config" ]; echo $?)" != 0 ]; then
        install_agent_global_config__435_v0 
        matched_1294=1
    fi
    if [ "$([ "_${step_1293}" != "_agent_skills" ]; echo $?)" != 0 ]; then
        install_agent_skills__470_v0 
        matched_1294=1
    fi
    if [ "$([ "_${step_1293}" != "_skill_caveman" ]; echo $?)" != 0 ]; then
        install_skill_caveman__473_v0 
        matched_1294=1
    fi
    if [ "$([ "_${step_1293}" != "_skill_humanizer" ]; echo $?)" != 0 ]; then
        install_skill_humanizer__476_v0 
        matched_1294=1
    fi
    if [ "$([ "_${step_1293}" != "_skill_ponytail" ]; echo $?)" != 0 ]; then
        install_skill_ponytail__479_v0 
        matched_1294=1
    fi
    if [ "$([ "_${step_1293}" != "_bazelisk" ]; echo $?)" != 0 ]; then
        install_bazelisk__497_v0 
        matched_1294=1
    fi
    if [ "$(( ! matched_1294 ))" != 0 ]; then
        echo "Unknown step: '${step_1293}'"
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
cmd_update__501_v0() {
    local command_69
    command_69="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_cmd_update501_v0=''
        return "${__status}"
    fi
    local script_dir_1264="${command_69}"
    local meta_path_1265="${script_dir_1264}/meta.json"
    local state_path_1266="${script_dir_1264}/.last_installed.json"
    local command_70
    command_70="$(jq -r '.repo_hashes | to_entries[] | "\(.key)	\(.value)"' "${meta_path_1265}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_cmd_update501_v0=''
        return "${__status}"
    fi
    local new_lines_1267="${command_70}"
    local old_lines_1268=""
    file_exists__39_v0 "${state_path_1266}"
    local ret_file_exists39_v0__469_8="${ret_file_exists39_v0}"
    if [ "${ret_file_exists39_v0__469_8}" != 0 ]; then
        local command_71
        command_71="$(jq -r '.repo_hashes | to_entries[] | "\(.key)	\(.value)"' "${state_path_1266}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_cmd_update501_v0=''
            return "${__status}"
        fi
        old_lines_1268="${command_71}"
    fi
    local old_keys_1269=()
    local old_vals_1270=()
    if [ "$([ "_${old_lines_1268}" == "_" ]; echo $?)" != 0 ]; then
        split_lines__5_v0 "${old_lines_1268}"
        local rows_1275=("${ret_split_lines5_v0[@]}")
        for row_1276 in "${rows_1275[@]}"; do
            if [ "$([ "_${row_1276}" != "_" ]; echo $?)" != 0 ]; then
                continue
            fi
            split__4_v0 "	" "${row_1276}"
            local parts_1277=("${ret_split4_v0[@]}")
            local __length_76=("${parts_1277[@]}")
            if [ "$(( ${#__length_76[@]} >= 2 ))" != 0 ]; then
                old_keys_1269+=("${parts_1277[0]?"Index out of bounds (at /tmp/jbtd-install-build-cJB240/install.ab:481:36)"}")
                old_vals_1270+=("${parts_1277[1]?"Index out of bounds (at /tmp/jbtd-install-build-cJB240/install.ab:482:36)"}")
            fi
        done
    fi
    local changed_1278=()
    split_lines__5_v0 "${new_lines_1267}"
    local new_rows_1279=("${ret_split_lines5_v0[@]}")
    for row_1280 in "${new_rows_1279[@]}"; do
        if [ "$([ "_${row_1280}" != "_" ]; echo $?)" != 0 ]; then
            continue
        fi
        split__4_v0 "	" "${row_1280}"
        local parts_1281=("${ret_split4_v0[@]}")
        local __length_82=("${parts_1281[@]}")
        if [ "$(( ${#__length_82[@]} < 2 ))" != 0 ]; then
            continue
        fi
        local key_1282="${parts_1281[0]?"Index out of bounds (at /tmp/jbtd-install-build-cJB240/install.ab:493:27)"}"
        local val_1283="${parts_1281[1]?"Index out of bounds (at /tmp/jbtd-install-build-cJB240/install.ab:494:27)"}"
        local matched_1284=0
        local __range_start_1285=0
        local __length_83=("${old_keys_1269[@]}")
        local __range_end_1285="${#__length_83[@]}"
        local __dir_1285=$(( ${__range_start_1285} <= ${__range_end_1285} ? 1 : -1 ))
        for (( i_1285=${__range_start_1285}; i_1285 * ${__dir_1285} < ${__range_end_1285} * ${__dir_1285}; i_1285+=${__dir_1285} )); do
            if [ "$([ "_${old_keys_1269[${i_1285}]?"Index out of bounds (at /tmp/jbtd-install-build-cJB240/install.ab:497:25)"}" != "_${key_1282}" ]; echo $?)" != 0 ]; then
                if [ "$([ "_${old_vals_1270[${i_1285}]?"Index out of bounds (at /tmp/jbtd-install-build-cJB240/install.ab:498:29)"}" == "_${val_1283}" ]; echo $?)" != 0 ]; then
                    local array_84=("${key_1282}")
                    changed_1278+=("${array_84[@]}")
                fi
                matched_1284=1
                break
            fi
done
        if [ "$(( ! matched_1284 ))" != 0 ]; then
            changed_1278+=("${key_1282}")
        fi
    done
    for ok_1286 in "${old_keys_1269[@]}"; do
        local found_1287=0
        for row_1288 in "${new_rows_1279[@]}"; do
            if [ "$([ "_${row_1288}" != "_" ]; echo $?)" != 0 ]; then
                continue
            fi
            split__4_v0 "	" "${row_1288}"
            local parts_1289=("${ret_split4_v0[@]}")
            local __length_90=("${parts_1289[@]}")
            if [ "$(( $(( ${#__length_90[@]} >= 2 )) && $([ "_${parts_1289[0]?"Index out of bounds (at /tmp/jbtd-install-build-cJB240/install.ab:515:42)"}" != "_${ok_1286}" ]; echo $?) ))" != 0 ]; then
                found_1287=1
                break
            fi
        done
        if [ "$(( ! found_1287 ))" != 0 ]; then
            changed_1278+=("${ok_1286}")
        fi
    done
    local __length_92=("${changed_1278[@]}")
    if [ "$(( ${#__length_92[@]} == 0 ))" != 0 ]; then
        echo "update: all repos up to date"
        ret_cmd_update501_v0=''
        return 0
    fi
    local __length_93=("${changed_1278[@]}")
    echo "update: ${#__length_93[@]} repo(s) changed:"
    for c_1290 in "${changed_1278[@]}"; do
        echo "  - ${c_1290}"
    done
    echo "Apply updates? [Y/n]"
    local command_96
    command_96="$(dd bs=1 count=100 status=none < /dev/tty 2>/dev/null | tr -d '
')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_cmd_update501_v0=''
        return "${__status}"
    fi
    local ans_1291="${command_96}"
    if [ "$(( $(( $(( $([ "_${ans_1291}" != "_n" ]; echo $?) || $([ "_${ans_1291}" != "_N" ]; echo $?) )) || $([ "_${ans_1291}" != "_no" ]; echo $?) )) || $([ "_${ans_1291}" != "_NO" ]; echo $?) ))" != 0 ]; then
        echo "update: aborted"
        ret_cmd_update501_v0=''
        return 0
    fi
    for c_1292 in "${changed_1278[@]}"; do
        run_step__500_v0 "${c_1292}"
    done
    cp "${meta_path_1265}" "${state_path_1266}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_cmd_update501_v0=''
        return "${__status}"
    fi
    echo "update: done"
}

typeset -r raw_args_58=("$0" "$@")
__length_101=("${raw_args_58[@]}")
slice_upper_100="${#__length_101[@]}"
slice_offset_102=1
slice_offset_102=$((${slice_offset_102} > 0 ? ${slice_offset_102} : 0))
slice_length_103="$(( slice_upper_100 - slice_offset_102 ))"
slice_length_103=$((${slice_length_103} > 0 ? ${slice_length_103} : 0))
args_59=("${raw_args_58[@]:${slice_offset_102}:${slice_length_103}}")
__length_104=("${args_59[@]}")
if [ "$(( ${#__length_104[@]} == 0 ))" != 0 ]; then
    install_apt_essential_tools__199_v0 
    install_apt_essential_ui__202_v0 
    install_dotfiles_essential__216_v0 
    install_dotfiles_personalization__226_v0 
    install_st__246_v0 
    install_nerd_fonts__262_v0 
    install_rofi__266_v0 
    install_omz_config__275_v0 
    install_zshmarks__287_v0 
    install_system_tools__327_v0 
    install_browsers__347_v0 
    install_ai_tools__389_v0 
    install_quicksheet__391_v0 
    install_nvim__396_v0 
    install_tmux_warm_daemon__420_v0 
    install_cmd_bookmarks__423_v0 
    install_agent_global_config__435_v0 
    install_agent_skills__470_v0 
    install_skill_caveman__473_v0 
    install_skill_humanizer__476_v0 
    install_skill_ponytail__479_v0 
    install_bazelisk__497_v0 
fi
__length_105=("${args_59[@]}")
if [ "$(( $(( ${#__length_105[@]} == 1 )) && $([ "_${args_59[0]?"Index out of bounds (at /tmp/jbtd-install-build-cJB240/install.ab:642:34)"}" != "_update" ]; echo $?) ))" != 0 ]; then
    cmd_update__501_v0 
    __status=$?
    if [ "${__status}" != 0 ]; then
        exit "${__status}"
    fi
fi
__length_106=("${args_59[@]}")
if [ "$(( ${#__length_106[@]} > 1 ))" != 0 ]; then
    for step_1295 in "${args_59[@]}"; do
        run_step__500_v0 "${step_1295}"
    done
fi
