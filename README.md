# bootstrap

`bootstrap.sh` is a tool to deploy your configuration files, i.e. dotfiles, via
`rsync` to your home directory and to track changes you made in your home
directory.

## Usage

Define in a environment variable `DOTFILES` which holds the path to the
dotfiles source directory. This directory has to has the same hierarchy as the
destination directory:
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
