# Quick Oh My Zsh Setup

This script provides an automated way to install **Oh My Zsh** and essential plugins, while intelligently selecting the best installation source based on internet connectivity. It supports both **GitHub** and **Gitee (China mirror)** for better accessibility.

## Features
- Automatically detects the operating system (Ubuntu/Debian or CentOS)
- Installs **Zsh**, **Oh My Zsh**, and essential plugins
- Checks Google connectivity to decide whether to use GitHub or a domestic mirror (Gitee)
- Installs useful plugins like:
  - `zsh-syntax-highlighting`
  - `zsh-autosuggestions`
- Sets Zsh as the default shell

## Prerequisites
Make sure you have `git` and `curl` installed. If not, the script will install them for you.

## Installation

### Clone the Repository
```bash
git clone git@github.com:NiceAsiv/quick-ohmyzsh-setup.git
cd quick-ohmyzsh-setup
```

### Run the Script
```bash
chmod +x run.sh
./run.sh
```

The script will:
1. Check for system dependencies and install `zsh`
2. Test internet connectivity to Google to determine the best installation source
3. Install **Oh My Zsh** using either **GitHub** or **Gitee**
4. Install recommended plugins
5. Set Zsh as the default shell

## Switching to Tsinghua University Mirror
If you are in China and want to switch an existing `Oh My Zsh` installation to the **Tsinghua mirror**, use:
```bash
git -C $ZSH remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/ohmyzsh.git
git -C $ZSH pull
```

## Notes
- After installation, restart your terminal or run `zsh` to start using **Oh My Zsh**.
- You may need to manually enable installed plugins by editing `~/.zshrc`.

## License
This project is open-source and distributed under the **MIT License**.

## Contributions
Feel free to fork the repository and submit a pull request!

Enjoy your new **Oh My Zsh** setup! 🎉


## reference

https://zhuanlan.zhihu.com/p/35283688

https://github.com/dunwu/linux-tutorial/blob/master/docs/linux/ops/zsh.md