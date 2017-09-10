#!/bin/bash
#===============================================================================
#        AUTHOR: Manoel Brunnen, manoel.brunnen@gmail.com
#       CREATED: 13.08.2017
#       LICENSE: MIT
#          FILE: bootstrap.sh
#         USAGE: ./bootstrap.sh
#
#   DESCRIPTION: boostrap the dotfiles.
#
#       No warranty! For nothing. Use it at your own risk.
#===============================================================================
set -e
set -u

#================================== Variables ==================================
red="\E[91m"
green="\E[92m"
yellow="\E[93m"
blue="\E[94m"
magenta="\E[95m"
cyan="\E[96m"
reset="\E[0m"
bold="\E[1m"
dot_root="$(cd $(dirname $0) && pwd)"
log_dir="$dot_root/logs"
timestamp=$(date +"%s")
# absolute or relative to destination dir
backup_dir="/tmp/boostrap_backup_$timestamp"
log_prefix="$log_dir/$(basename $0)"
do_sync=true
do_gather=true
do_deploy=true
action=
# a = -rlptgoD, u = update via timestamp, hence -t is necessary
put_cmd="rsync -Cauv --no-D -b --backup-dir=$backup_dir"
get_cmd='rsync -Cauv --no-D'
gather_cmd='rsync -Cav'
deploy_cmd="rsync -Cabv --backup-dir=$backup_dir"
dest_dir=$HOME

mkdir -p $log_dir $backup_dir
#=================================== Logging ===================================

# Backup stdout(&1) and stderr(&2) to fd 3 and fd 4
exec 3>&1 4>&2
# Restore stdout and stderr
trap 'exec 2>&4 1>&3' 0 1 2 3
# Use tee to redirect fd 1 to logfile.out and to stdout
exec 1> >(tee ${log_prefix}.out.log >&3)
# Use tee to redirect fd 2 to logfile.err and to stderr
exec 2> >(tee ${log_prefix}.err.log >&4)

parse_action() {
    section 'User input'
    for i in "$@"
    do
        case "$i" in
            s|-s|--sync)
                action=sync
                ;;
            g|-g|--gather)
                action=gather
                ;;
            d|-d|--deploy)
                action=deploy
                ;;
            n|-n|--dryrun)
                action=dryrun
                ;;
            *)
                # unknown option
                ;;
        esac
    done
    if [ -z "$action" ]; then
        user "What do you want to do: [s]ynchronize, [g]ather, [d]eploy or [Q]uit?"
        read -n 1 input
        echo
        case "$input" in
            s )
                action=sync
                ;;
            g )
                action=gather
                ;;
            d )
                action=deploy
                ;;
            n )
                action=dryrun
                ;;
            * )
                fail 'Quitting.'
                ;;
        esac
    fi
    success "Doing action \"$action\"."
}

do_action() {
    section 'Searching dotfiles'
    local src_dir="$dot_root/homedir"
    local src_files=($(realpath $(git ls-tree -r HEAD --name-only -- $src_dir)))
    declare -a dest_files=()
    for sfile in ${src_files[@]}; do
        declare dest_files+=(${sfile/$src_dir/$dest_dir})
    done

    [ ${#src_files[@]} -eq ${#dest_files[@]} ] \
        || fail 'Unequal source and destination files.'

    section "Action \"$action\""
    if [ -z $action ]; then
        fail 'No action.'
    fi

    for (( i = 0; i < ${#src_files[@]}; i++ )); do
        case "$action" in
            sync)
                sync "${src_files[i]}" "${dest_files[i]}"
                ;;
            gather)
                gather "${src_files[i]}" "${dest_files[i]}"
                ;;
            deploy)
                deploy "${src_files[i]}" "${dest_files[i]}"
                ;;
            dryrun)
                dryrun "${src_files[i]}" "${dest_files[i]}"
                ;;
        esac
    done

    section "Finish"
    success "Action \"$action\" successful."
    echo "See the logs in $log_dir."
    if [ -z "$(ls -A $backup_dir)" ]; then
        success "No backups created in $backup_dir."
    else
        warning "Backups had to be created in $backup_dir. Please check:"
        local backup_files=($(find $backup_dir -type f))
        for bfile in ${backup_files[@]}; do
            echo "$bfile"
        done
    fi
}

sync() {
    local loc=$1 # here
    local rem=$2 # there
    local rem_dir="$(dirname $rem)"
    [ ! -d $rem_dir ] && mkdir -p $rem_dir &&
        success "Created directory $rem_dir."
    eval "$put_cmd $loc $rem"
    eval "$get_cmd $rem $loc"
    success "Synchronized $loc and $rem."
}

gather() {
    local loc=$1 # here
    local rem=$2 # there
    [ -e $rem ] && eval "$gather_cmd $rem $loc"
    success "Gathered $rem to $loc."
}

deploy() {
    local loc=$1 # here
    local rem=$2 # there
    local rem_bak="$backup_dir/$(basename $rem)"
    local rem_dir="$(dirname $rem)"
    [ ! -d $rem_dir ] && mkdir -p $rem_dir &&
        success "Created directory $rem_dir"
    eval "$deploy_cmd $loc $rem"
    success "Deployed $loc to $rem"
}

dryrun() {
    local loc=$1 # here
    local rem=$2 # there
    if [ -e $loc ]; then
        success "$loc found"
    else
        fail "$loc not found."
    fi
    echo -e "\tmove\t$loc\n\tto\t$rem\n"
}

success () {
    printf "[%bOK%b] $1\n" $green $reset
}

warning () {
    printf "[%bWARNING%b] $1\n" $yellow $reset
}

fail () {
    printf "[%bFAIL%b] $1\n" $red $reset
    exit
}

user () {
    printf "[%bINPUT%b] $1\n" $cyan $reset
}

section () {
    printf "\n\t\t=====   %b$1%b   =====\n" $bold $reset
}

parse_action "$@"
do_action
