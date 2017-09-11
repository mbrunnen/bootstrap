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
timestamp=$(date +"%s")
log_dir="/tmp/boostrap_logs_$timestamp"
# absolute or relative to destination dir
backup_dir="/tmp/boostrap_backup_$timestamp"
log_prefix="$log_dir/$(basename $0)"
do_sync=true
do_gather=true
do_deploy=true
action=
# a = -rlptgoD, u = update via timestamp, hence -t is necessary
# -FF: --filter=': /.rsync-filter' --filter='- .rsync-filter'
base_cmd="rsync -Ca --no-D -FF"
get_cmd="$base_cmd -uk --existing"
put_cmd="$base_cmd -uKb --backup-dir=$backup_dir"
gather_cmd="$base_cmd -k --existing"
deploy_cmd="$base_cmd -Kb --backup-dir=$backup_dir"
add_cmd="$base_cmd -k --ignore-existing"
dest_dir=$HOME
options='-v'
pathspec=''

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

parse_args() {
    [ -z "$DOTFILES" ] && fail 'DOTFILES not set.'
    section 'User input'
    # Parse command
    for i in "$@"
    do
        case "$i" in
            u|update)
                action=update
                ;;
            g|gather)
                action=gather
                ;;
            d|deploy)
                action=deploy
                ;;
            a|add)
                action=add
                ;;
            s|status)
                action=status
                ;;
            -*)
                options+=" $i"
                ;;
            *)
                pathspec+=" $i"
                ;;
        esac
    done

    success "Doing action \"$action\" with options:\"$options\"."
}

do_action() {
    section "Action \"$action\""
    if [ -z $action ]; then
        fail 'No action.'
    fi

    eval $action

    section "Finish"
    success "Action \"$action\" successful."
    echo "See the logs in $log_dir."
    if [ -z "$(ls -A "$backup_dir")" ]; then
        success "No backups created in $backup_dir."
    else
        warning "Backups had to be created in $backup_dir. Please check:"
        local backup_files=($(find "$backup_dir" -type f))
        printf '%s\n' "${backup_files[@]}"
        # TODO: print a diff
    fi
}

update() {
    eval "$get_cmd $options $dest_dir/ $DOTFILES"
    eval "$put_cmd $options $DOTFILES/ $dest_dir"
    success "Synchronized $dest_dir and $DOTFILES."
}

gather() {
    eval "$gather_cmd $options $dest_dir/ $DOTFILES"
    success "Gathered $dest_dir to $DOTFILES."
}

deploy() {
    eval "$deploy_cmd $options $DOTFILES/ $dest_dir"
    success "Deployed $DOTFILES to $dest_dir"
}

add() {
    local src_files=($(realpath "$pathspec"))
    for src in "${src_files[@]}"; do
        dest=${src/$dest_dir/$DOTFILES}
        eval "$add_cmd $options $src $dest"
        success "Added $src to $dest"
    done
}

status() {
    git -C "$DOTFILES" status
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

parse_args "$@"
do_action
