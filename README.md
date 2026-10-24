# dev-workspace-setup

A simple urility to setup a development workspace on a new Mac.

## Quickstart

By default, script runs in auto mode.

Run following commands in the terminal:
```bash
# clone the repository
git clone https://github.com/anurag-khadatkar/dev-workspace-setup.git

# switch to the repository directory
cd dev-workspace-setup

# run the setup script
./setup-mac.sh
```

### Wizard Mode

For wizard mode, run the script with `-w` or `--wizard` option:
```bash
./setup-mac.sh -w
```

This is similar to auto mode, except it will ask for confirmation before executing each step. You can choose to skip any step by entering `n` or `N` when prompted.

### Manual Mode

For manual mode, run the script with `-m` or `--manual` option:
```bash
./setup-mac.sh -m
```

It will display a menu with options to setup different components of the development workspace. You can select the desired option to run the corresponding setup function.
