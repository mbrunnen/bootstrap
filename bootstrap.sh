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
# magenta="\E[95m"
cyan="\E[96m"
reset="\E[0m"
# bold="\E[1m"
timestamp=$(date +"%s")
log_dir="/tmp/boostrap_logs_$timestamp"
# absolute or relative to destination dir
backup_dir="/tmp/boostrap_backup_$timestamp"
log_prefix="$log_dir/$(basename "$0")"
action=
# a = -rlptgoD, u = update via timestamp, hence -t is necessary
# -FF: --filter=': /.rsync-filter' --filter='- .rsync-filter'
# Filter in $DOTFILES only applies for this script and .rsync-filter in source
# directories apply for possibly all rsyncs
base_cmd='rsync -Ca --no-D'
if [ -f "$DOTFILES/.bootstrap-filter" ]; then
    base_cmd+=" -FF -f'. $DOTFILES/.bootstrap-filter' -f'- .bootstrap-filter'"
fi
gather_cmd="$base_cmd -k --existing"
deploy_cmd="$base_cmd -Kb --backup-dir=$backup_dir"
add_cmd="$base_cmd -k --ignore-existing"
dest_dir=$HOME
# TODO: make options, pathspec to array
options=''
pathspec=''

mkdir -p "$log_dir" "$backup_dir"
#=================================== Logging ===================================

# Backup stdout(&1) and stderr(&2) to fd 3 and fd 4
exec 3>&1 4>&2
# Restore stdout and stderr
trap 'exec 2>&4 1>&3' 0 1 2 3
# Use tee to redirect fd 1 to logfile.out and to stdout
exec 1> >(tee "${log_prefix}.out.log" >&3)
# Use tee to redirect fd 2 to logfile.err and to stderr
exec 2> >(tee "${log_prefix}.err.log" >&4)

parse_args() {
    [ -z "$DOTFILES" ] && fail 'DOTFILES not set.'
    info 'Parsing user input'
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
            -*)
                options+=" $i"
                ;;
            *)
                pathspec+=" $i"
                ;;
        esac
    done

}

do_action() {
    info "Doing action \"$action\" with options:\"$options\" ..."
    if [ -z $action ]; then
        fail 'No action.'
    fi
    eval "$action"

    info "See the logs in $log_dir."

    if [ -z "$(ls -A "$backup_dir")" ]; then
        success "No backups created in $backup_dir."
    else
        # TODO: improve the output and show changes, filter not existing files
        warning "Backups were created in $backup_dir. Please check:"
        if type colordiff >/dev/null 2>&1; then
            colordiff -rw --exclude .git "$backup_dir" "$DOTFILES"
        else
            diff -rw --exclude .git "$backup_dir" "$DOTFILES"
        fi
    fi
}

# Synchronize two directories by taking the newest file in case of conflict.
update() {
    eval "$gather_cmd -u $options $dest_dir/ $DOTFILES"
    eval "$deploy_cmd -u $options $DOTFILES/ $dest_dir"
    success "Synchronized $dest_dir and $DOTFILES."
}

# Collect all relevant files to the backup directory and overwrite it with the
# content from the working directory.
gather() {
    eval "$gather_cmd $options $dest_dir/ $DOTFILES"
    success "Gathered $dest_dir to $DOTFILES."
}

# Put all backup files to the working directory and overwrite them. This is
# useful while installing.
deploy() {
    eval "$deploy_cmd $options $DOTFILES/ $dest_dir"
    success "Deployed $DOTFILES to $dest_dir"
}

add() {
    # TODO: make pathspec to array
    local src_files=($(realpath -s $pathspec))
    for src in "${src_files[@]}"; do
        dest=${src/$dest_dir/$DOTFILES}
        mkdir -p "$(dirname "$dest")"
        eval "$add_cmd $options $src $dest"
        success "Added $src to $dest"
        git -C "$DOTFILES" add "$dest"
    done
}


success () {
    printf "[%bOK%b] $1\n" "$green" "$reset"
}

info () {
    printf "[%bINFO%b] $1\n" "$blue" "$reset"
}

warning () {
    printf "[%bWARNING%b] $1\n" "$yellow" "$reset"
}

fail () {
    printf "[%bFAIL%b] $1\n" "$red" "$reset"
    exit
}

user () {
    printf "[%bINPUT%b] $1\n" "$cyan" "$reset"
}

parse_args "$@"
do_action
