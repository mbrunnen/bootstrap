#!/bin/bash
#===============================================================================
#        AUTHOR: Manoel Brunnen, manoel.brunnen@gmail.com
#       CREATED: 13.08.2017
#       LICENSE: MIT
#          FILE: bootstrap.sh
#         USAGE: ./bootstrap.sh
#
#   DESCRIPTION: bootrap the dotfiles.
#
#       No warranty! For nothing. Use it at your own risk.
#===============================================================================
set -e
set -u

#================================== Variables ==================================
red="\E[91m"
green="\E[92m"
yellow="\E[93m"
reset="\E[0m"
bold="\E[1m"
dot_root="$(cd $(dirname $0) && pwd)"
log_dir="$dot_root/logs"
backup_dir="$dot_root/backups"
log_prefix="$log_dir/$(basename $0)"
bs_file=".bs_file.sh"
do_sync=true
do_gather=true
do_deploy=true
action=

declare -A dests

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
            * )
                fail 'Quitting'
                ;;
        esac
    fi
    success "Doing action \"$action\""
}

do_action() {
    section 'Searching BS files'
    local bs_files=$(realpath $(find -H . "$dot_root" -maxdepth 2\
        -name "$bs_file" -not -path '.git') | sort -u)
    for bs in ${bs_files[@]}; do
        success "Found BS file in: $(dirname $bs)"
        cd $(dirname $bs)
        source $bs
    done

    section "Action \"$action\""
    if [ -z $action ]; then
        fail 'No Action'
    fi

    for src in "${!dests[@]}"; do
        case "$action" in
            sync)
                sync "$src" "${dests[$src]}"
                ;;
            gather)
                gather "$src" "${dests[$src]}"
                ;;
            deploy)
                deploy "$src" "${dests[$src]}"
                ;;
        esac
    done

    section "Finish"
    success "Action \"$action\" successful"
    echo "See the logs in $log_dir"
    echo "See the backups in $backup_dir"
}

sync() {
    local loc=$1 # here
    local rem=$2 # there
    # a = -rlptgoD, u = update via timestamp, hence -t is necessary
    rsync -auv --no-D $loc $rem
    rsync -auv --no-D $rem $loc
    success "Synchronized $loc and $rem"
}

gather() {
    local loc=$1 # here
    local rem=$2 # there
    rsync -av $rem $loc
    success "Gathered $rem to $loc"
}

deploy() {
    local loc=$1 # here
    local rem=$2 # there
    local rem_bak="$backup_dir/$(basename $rem)"
    local rem_dir="$(dirname $rem)"
    [ -f $rem ] && mv $rem $rem_bak &&
        success "Created a backup for $rem in $rem_bak"
    [ ! -d $rem_dir ] && mkdir -p $rem_dir &&
        success "Created directory $rem_dir"
    rsync -abv --backup-dir=$backup_dir $loc $rem
    # rsync -av $loc $rem
    success "Deployed $loc to $rem"
}

success () {
    printf "[%bOK%b] $1\n" $green $reset
}

fail () {
    printf "[%bFAIL%b] $1\n" $red $reset
    exit
}

user () {
    printf "[%bINPUT%b] $1\n" $yellow $reset
}

section () {
    printf "\n\t\t=====   %b$1%b   =====\n" $bold $reset
}

parse_action "$@"
do_action
