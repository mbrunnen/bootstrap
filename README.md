# bootstrap

`bootstrap.sh` is a tool to deploy your configuration files, i.e. dotfiles, via
`rsync` to your home directory and to track changes you made in your home
directory. Inspired by [github's dotfiles guide](https://dotfiles.github.io/).

## Usage

### Dotfiles directory

Define in a environment variable `DOTFILES` which holds the path to the
dotfiles source directory. I would recommend that this directory is a git
repository. This directory has to has the same hierarchy as the
destination directory, i.e. `~/`, e.g.:
```
.
├── .config
│   ├── fetcher.conf
│   └── i3
│       └── config
├── .gitconfig
├── .tmux.conf
├── .zshrc
└── bootstrap-filter
```
### Commands

With `./bootstrap.sh update` you synchronize the dotfiles and your home
directory by keeping the newer files. Only files which exists in your dotfiles
directory will be synchronized.

With `./bootstrap.sh gather` you overwrite the dotfiles state with the state of
your home directory.Only files which exists in your dotfiles
directory will be overwritten.

With `./bootstrap.sh deploy` you overwrite the home directory state with the
state of your dotfiles directory.

With `bootstrap add path/to/file` you add a new file to your dotfiles
directory, so it will be synchronized as well.

### Filter
bootstrap understands the default `.rsync-filter` files, but you can also
define an additional `$DOTFILES/.bootstrap-filter` file in the root of your
dotfiles directory, only used by bootstrap. Please refer to rsync for the
filter rules.

### Backups and Logs
Every time a home directory file is overwritten, a backup will be created and
stored in `/tmp/boostrap_backup_<timestamp>`.

A log file will be created in `/tmp/boostrap_logs_<timestamp>`.
