#!/usr/bin/env python3

import os
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent
HOME = Path.home()


def run(cmd, env=None):
    print(f"+ {' '.join(cmd)}")
    subprocess.run(cmd, check=True, env=env)


def command_exists(cmd):
    return shutil.which(cmd) is not None


def brew_prefix():
    return subprocess.check_output(["brew", "--prefix"], text=True).strip()


def brew_install(pkg):
    result = subprocess.run(["brew", "list", pkg], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if result.returncode == 0:
        print(f"{pkg} already installed")
    else:
        run(["brew", "install", pkg])


def clone_if_missing(repo_url, target_dir):
    target = Path(target_dir).expanduser()
    git_dir = target / ".git"
    if git_dir.is_dir():
        print(f"repo already present at {target}")
        return
    if target.exists():
        print(f"cannot clone {repo_url} because {target} already exists and is not a git repo")
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    run(["git", "clone", repo_url, str(target)])


def link_file(source_path, target_path):
    source = Path(source_path).resolve()
    target = Path(target_path).expanduser()
    target.parent.mkdir(parents=True, exist_ok=True)

    if target.is_symlink():
        if target.resolve() == source:
            print(f"link already configured: {target}")
            return
        target.unlink()
    elif target.exists():
        backup = target.with_name(f"{target.name}.bak.{datetime.now().strftime('%Y%m%d%H%M%S')}")
        target.rename(backup)
        print(f"backed up existing file to {backup}")

    target.symlink_to(source)


def bootstrap_packer():
    packer_dir = HOME / ".local/share/nvim/site/pack/packer/start/packer.nvim"
    clone_if_missing("https://github.com/wbthomason/packer.nvim", packer_dir)


def install_homebrew():
    print("installing homebrew")
    if command_exists("brew"):
        print("homebrew already installed")
        return
    env = os.environ.copy()
    env["NONINTERACTIVE"] = "1"
    run(
        [
            "/bin/bash",
            "-c",
            "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)",
        ],
        env=env,
    )


def install_zsh_stack():
    print("installing zsh")
    brew_install("zsh")

    print("installing oh my zsh")
    oh_my_zsh_dir = HOME / ".oh-my-zsh"
    if oh_my_zsh_dir.is_dir():
        print("oh my zsh already installed")
    else:
        env = os.environ.copy()
        env["RUNZSH"] = "no"
        env["CHSH"] = "no"
        env["KEEP_ZSHRC"] = "yes"
        run(
            [
                "sh",
                "-c",
                "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)",
            ],
            env=env,
        )

    print("installing zsh plugins")
    brew_install("direnv")
    zsh_custom = os.environ.get("ZSH_CUSTOM", str(HOME / ".oh-my-zsh/custom"))
    clone_if_missing(
        "https://github.com/zsh-users/zsh-autosuggestions",
        Path(zsh_custom) / "plugins/zsh-autosuggestions",
    )

    brew_install("fzf")
    fzf_install = Path(brew_prefix()) / "opt/fzf/install"
    run([str(fzf_install), "--all", "--no-update-rc"])

    print("applying zsh config")
    link_file(REPO_ROOT / "zsh/.zshrc", HOME / ".zshrc")

    target_shell = Path(brew_prefix()) / "bin/zsh"
    current_shell = os.environ.get("SHELL", "")
    if target_shell.exists() and current_shell != str(target_shell):
        if os.environ.get("APPLY_LOGIN_SHELL", "0") == "1":
            run(["chsh", "-s", str(target_shell)])
        else:
            print(f"skipping chsh (set APPLY_LOGIN_SHELL=1 to apply {target_shell})")


def install_ghostty():
    print("applying ghostty config")
    link_file(REPO_ROOT / "ghostty/config", HOME / ".config/ghostty/config")


def install_tmux():
    print("installing tmux")
    brew_install("tmux")
    print("applying tmux config")
    link_file(REPO_ROOT / "tmux/.tmux.conf", HOME / ".tmux.conf")


def install_vscode():
    print("copying vscode configs")
    vscode_user_dir = HOME / "Library/Application Support/Code/User"
    link_file(REPO_ROOT / "vscode/settings.json", vscode_user_dir / "settings.json")
    link_file(REPO_ROOT / "vscode/keybindings.json", vscode_user_dir / "keybindings.json")


def install_scm_breeze():
    print("installing scm breeze (git plugin)")
    scm_dir = HOME / ".scm_breeze"
    clone_if_missing("https://github.com/scmbreeze/scm_breeze.git", scm_dir)
    installer = scm_dir / "install.sh"
    if installer.exists():
        run([str(installer)])
    else:
        print(f"skipping scm breeze installer (not found at {installer})")


def install_neovim():
    brew_install("neovim")
    brew_install("ripgrep")
    brew_install("fd")
    link_file(REPO_ROOT / "neovim/.config/nvim", HOME / ".config/nvim")
    bootstrap_packer()
    print("syncing neovim plugins")
    run(
        [
            "nvim",
            "--headless",
            "-c",
            "lua require('oldguo.packer')",
            "-c",
            "autocmd User PackerComplete quitall",
            "-c",
            "lua require('packer').sync()",
        ]
    )
    run(["nvim", "--headless", "-c", "TSUpdateSync", "-c", "quitall"])


def main():
    install_homebrew()
    install_zsh_stack()
    install_ghostty()
    install_tmux()
    install_vscode()
    install_scm_breeze()
    install_neovim()
    print("Done")


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as exc:
        print(f"command failed with exit code {exc.returncode}: {exc.cmd}", file=sys.stderr)
        sys.exit(exc.returncode)
