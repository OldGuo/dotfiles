#!/usr/bin/env python3

import os
import shlex
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent
HOME = Path.home()
LINUX_APT_UPDATED = False

LINUX_PACKAGE_OVERRIDES = {
    "fd": {
        "apt": "fd-find",
        "dnf": "fd-find",
        "pacman": "fd",
        "zypper": "fd",
    }
}

PACKAGE_BINARIES = {
    "neovim": ("nvim",),
    "ripgrep": ("rg",),
    "fd": ("fd", "fdfind"),
    "zsh": ("zsh",),
    "tmux": ("tmux",),
    "direnv": ("direnv",),
    "fzf": ("fzf",),
}


def run(cmd, env=None):
    print(f"+ {' '.join(cmd)}")
    subprocess.run(cmd, check=True, env=env)


def command_exists(cmd):
    return shutil.which(cmd) is not None


def linux_package_manager():
    if not sys.platform.startswith("linux"):
        return None
    for manager, binary in (
        ("apt", "apt-get"),
        ("dnf", "dnf"),
        ("pacman", "pacman"),
        ("zypper", "zypper"),
    ):
        if command_exists(binary):
            return manager
    return None


def with_privilege(cmd):
    if hasattr(os, "geteuid") and os.geteuid() == 0:
        return cmd
    if command_exists("sudo"):
        return ["sudo", *cmd]
    return None


def linux_package_name(pkg, manager):
    return LINUX_PACKAGE_OVERRIDES.get(pkg, {}).get(manager, pkg)


def pkg_installed(pkg):
    binaries = PACKAGE_BINARIES.get(pkg, (pkg,))
    return any(command_exists(binary) for binary in binaries)


def ensure_fd_compat_shim():
    if command_exists("fd"):
        return
    fdfind = shutil.which("fdfind")
    if not fdfind:
        return

    local_bin = HOME / ".local/bin"
    local_bin.mkdir(parents=True, exist_ok=True)
    shim = local_bin / "fd"

    if shim.exists():
        return

    shim.write_text(f"#!/usr/bin/env sh\nexec {shlex.quote(fdfind)} \"$@\"\n", encoding="utf-8")
    shim.chmod(0o755)
    print(f"created fd compatibility shim at {shim} (ensure {local_bin} is in PATH)")


def linux_install(pkg):
    global LINUX_APT_UPDATED

    manager = linux_package_manager()
    if not manager:
        print(f"skipping {pkg}: no supported linux package manager found (apt/dnf/pacman/zypper)")
        return False

    if pkg_installed(pkg):
        print(f"{pkg} already installed")
        if pkg == "fd":
            ensure_fd_compat_shim()
        return True

    target_pkg = linux_package_name(pkg, manager)

    if manager == "apt":
        if not LINUX_APT_UPDATED:
            update_cmd = with_privilege(["apt-get", "update"])
            if not update_cmd:
                print("skipping apt install: sudo is required (or run as root)")
                return False
            run(update_cmd)
            LINUX_APT_UPDATED = True
        install_cmd = with_privilege(["apt-get", "install", "-y", target_pkg])
    elif manager == "dnf":
        install_cmd = with_privilege(["dnf", "install", "-y", target_pkg])
    elif manager == "pacman":
        install_cmd = with_privilege(["pacman", "-S", "--noconfirm", target_pkg])
    else:
        install_cmd = with_privilege(["zypper", "--non-interactive", "install", target_pkg])

    if not install_cmd:
        print(f"skipping {pkg}: sudo is required (or run as root)")
        return False

    run(install_cmd)

    if pkg == "fd":
        ensure_fd_compat_shim()

    return pkg_installed(pkg)


def brew_prefix():
    if not command_exists("brew"):
        return None
    return subprocess.check_output(["brew", "--prefix"], text=True).strip()


def install_package(pkg):
    if not command_exists("brew"):
        if sys.platform.startswith("linux"):
            return linux_install(pkg)
        print(f"skipping {pkg}: homebrew is not available")
        return False
    result = subprocess.run(["brew", "list", pkg], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if result.returncode == 0:
        print(f"{pkg} already installed")
        return True
    else:
        run(["brew", "install", pkg])
        return True


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


def install_homebrew():
    print("installing homebrew")
    if command_exists("brew"):
        print("homebrew already installed")
        return True
    if sys.platform.startswith("linux") and os.environ.get("INSTALL_HOMEBREW", "0") != "1":
        print("skipping homebrew bootstrap on linux (set INSTALL_HOMEBREW=1 to force install)")
        return False
    env = os.environ.copy()
    env["NONINTERACTIVE"] = "1"
    try:
        run(
            [
                "/bin/bash",
                "-c",
                "curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | /bin/bash",
            ],
            env=env,
        )
    except subprocess.CalledProcessError:
        print("warning: unable to install homebrew; continuing without brew-managed packages")
        return False
    return command_exists("brew")


def install_zsh_stack():
    print("installing zsh")
    install_package("zsh")
    if not command_exists("zsh"):
        print("skipping zsh setup: zsh is not installed")
        return

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
                "curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh",
            ],
            env=env,
        )

    print("installing zsh plugins")
    install_package("direnv")
    zsh_custom = os.environ.get("ZSH_CUSTOM", str(HOME / ".oh-my-zsh/custom"))
    clone_if_missing(
        "https://github.com/zsh-users/zsh-autosuggestions",
        Path(zsh_custom) / "plugins/zsh-autosuggestions",
    )

    if install_package("fzf"):
        prefix = brew_prefix()
        if prefix:
            fzf_install = Path(prefix) / "opt/fzf/install"
            if fzf_install.exists():
                run([str(fzf_install), "--all", "--no-update-rc"])
            else:
                print(f"skipping fzf installer (not found at {fzf_install})")

    print("applying zsh config")
    link_file(REPO_ROOT / "zsh/.zshrc", HOME / ".zshrc")

    zsh_path = shutil.which("zsh")
    target_shell = Path(zsh_path) if zsh_path else None
    current_shell = os.environ.get("SHELL", "")
    if target_shell and target_shell.exists() and current_shell != str(target_shell):
        if os.environ.get("APPLY_LOGIN_SHELL", "0") == "1":
            run(["chsh", "-s", str(target_shell)])
        else:
            print(f"skipping chsh (set APPLY_LOGIN_SHELL=1 to apply {target_shell})")


def install_ghostty():
    print("applying ghostty config")
    link_file(REPO_ROOT / "ghostty/config", HOME / ".config/ghostty/config")
    shader_dir = REPO_ROOT / "ghostty/shaders"
    if shader_dir.is_dir():
        for shader_file in sorted(shader_dir.glob("*.glsl")):
            link_file(shader_file, HOME / ".config/ghostty/shaders" / shader_file.name)


def install_tmux():
    print("installing tmux")
    install_package("tmux")
    print("applying tmux config")
    link_file(REPO_ROOT / "tmux/.tmux.conf", HOME / ".tmux.conf")


def install_vscode():
    print("copying vscode configs")
    if sys.platform == "darwin":
        vscode_user_dir = HOME / "Library/Application Support/Code/User"
    else:
        vscode_user_dir = HOME / ".config/Code/User"
    link_file(REPO_ROOT / "vscode/settings.json", vscode_user_dir / "settings.json")
    link_file(REPO_ROOT / "vscode/keybindings.json", vscode_user_dir / "keybindings.json")


def install_scm_breeze():
    print("installing scm breeze (git plugin)")
    scm_dir = HOME / ".scm_breeze"
    clone_if_missing("https://github.com/scmbreeze/scm_breeze.git", scm_dir)
    scm_lib = scm_dir / "lib/scm_breeze.sh"
    if not scm_lib.exists():
        print(f"skipping scm breeze config bootstrap (not found at {scm_lib})")
        return
    if not command_exists("bash"):
        print("skipping scm breeze config bootstrap: bash is not available")
        return
    print("ensuring scm breeze user config files")
    cmd = (
        f"scmbDir={shlex.quote(str(scm_dir))}; "
        f"source {shlex.quote(str(scm_lib))}; "
        "_create_or_patch_scmbrc"
    )
    run(["bash", "-lc", cmd])


def install_codex():
    print("applying codex config")
    link_file(REPO_ROOT / "codex/config.toml", HOME / ".codex/config.toml")


def install_neovim():
    install_package("neovim")
    install_package("ripgrep")
    install_package("fd")
    ensure_fd_compat_shim()
    if not command_exists("nvim"):
        print("skipping neovim config: nvim is not installed")
        return
    link_file(REPO_ROOT / "neovim/.config/nvim", HOME / ".config/nvim")
    print("syncing neovim plugins")
    run(["nvim", "--headless", "+lua require('lazy').sync({wait = true})", "+qa"])
    run(["nvim", "--headless", "-c", "TSUpdateSync", "-c", "quitall"])


def main():
    install_homebrew()
    install_zsh_stack()
    install_ghostty()
    install_tmux()
    install_vscode()
    install_codex()
    install_scm_breeze()
    install_neovim()
    print("Done")


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as exc:
        print(f"command failed with exit code {exc.returncode}: {exc.cmd}", file=sys.stderr)
        sys.exit(exc.returncode)
