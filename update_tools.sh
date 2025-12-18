#!/usr/bin/env bash
# Written in [Amber](https://amber-lang.com/)
# version: 0.5.1-alpha
# All dates are internally stored as milliseconds since the Epoch (1970-01-01 00:00 UTC).
date_format_posix__0_v0() {
    local date=$1
    local format=$2
    local utc=$3
    utc_flag_7="$(if [ "${utc}" != 0 ]; then echo "-u"; else echo ""; fi)"
    command_1="$(date ${utc_flag_7} -d "@${date}" +"${format}" 2>/dev/null)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        command_0="$(date ${utc_flag_7} -j -r "${date}" +"${format}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_date_format_posix0_v0=''
            return "${__status}"
        fi
        ret_date_format_posix0_v0="${command_0}"
        return 0
    fi
    ret_date_format_posix0_v0="${command_1}"
    return 0
}

date_now__2_v0() {
    command_2="$(date +%s)"
    __status=$?
    ret_date_now2_v0="${command_2}"
    return 0
}

dir_exists__43_v0() {
    local path=$1
    [ -d "${path}" ]
    __status=$?
    ret_dir_exists43_v0="$(( ${__status} == 0 ))"
    return 0
}

file_exists__44_v0() {
    local path=$1
    [ -f "${path}" ]
    __status=$?
    ret_file_exists44_v0="$(( ${__status} == 0 ))"
    return 0
}

dir_create__49_v0() {
    local path=$1
    dir_exists__43_v0 "${path}"
    ret_dir_exists43_v0__87_12="${ret_dir_exists43_v0}"
    if [ "$(( ! ${ret_dir_exists43_v0__87_12} ))" != 0 ]; then
        mkdir -p "${path}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_dir_create49_v0=''
            return "${__status}"
        fi
    fi
}

env_var_get__109_v0() {
    local name=$1
    command_3="$(echo ${!name})"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_env_var_get109_v0=''
        return "${__status}"
    fi
    ret_env_var_get109_v0="${command_3}"
    return 0
}

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
__status=$?
env_var_get__109_v0 "HOME"
__status=$?
__HOME_3="${ret_env_var_get109_v0}"
log_timestamp__130_v0() {
    local message=$1
    date_now__2_v0 
    current_date_6="${ret_date_now2_v0}"
    date_format_posix__0_v0 "${current_date_6}" "%F %T" 0
    __status=$?
    timestamp_8="${ret_date_format_posix0_v0}"
    echo "===== ${timestamp_8} ${message} ====="
}

log_path_4="${__HOME_3}/Library/Logs/update-tools.log"
command_5="$(dirname "${log_path_4}")"
__status=$?
log_dir_5="${command_5}"
dir_exists__43_v0 "${log_dir_5}"
ret_dir_exists43_v0__22_12="${ret_dir_exists43_v0}"
if [ "$(( ! ${ret_dir_exists43_v0__22_12} ))" != 0 ]; then
    dir_create__49_v0 "${log_dir_5}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        exit "${__status}"
    fi
fi
exec >> "${log_path_4}" 2>&1
__status=$?
log_timestamp__130_v0 "starting updates"
brew update
__status=$?
if [ "${__status}" != 0 ]; then
    exit "${__status}"
fi
brew upgrade
__status=$?
if [ "${__status}" != 0 ]; then
    exit "${__status}"
fi
brew cleanup
__status=$?
if [ "${__status}" != 0 ]; then
    exit "${__status}"
fi
mas_bin_9="/opt/homebrew/bin/mas"
file_exists__44_v0 "${mas_bin_9}"
ret_file_exists44_v0__40_12="${ret_file_exists44_v0}"
if [ "$(( ! ${ret_file_exists44_v0__40_12} ))" != 0 ]; then
    echo "ERROR: mas binary not found"
    exit 1
fi
__sudo=$([ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1 && printf sudo)
${__sudo} ${mas_bin_9} upgrade
__status=$?
log_timestamp__130_v0 "finished updates"
