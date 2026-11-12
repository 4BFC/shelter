import os
import platform
import signal
import subprocess
import sys
from collections.abc import Sequence
from pathlib import Path

# PyInstaller sets _MEIPASS to the unpacked bundle; scripts/build_cli.py puts the
# generated standalone installers under lite/ there.
BUNDLE_DIR = getattr(sys, "_MEIPASS", None)


def _installer_paths() -> dict[str, Path]:
    if BUNDLE_DIR is not None:
        lite_dir = Path(BUNDLE_DIR) / "lite"
        return {
            "Darwin": lite_dir / "shelter-lite-macos.sh",
            "Windows": lite_dir / "shelter-lite-windows.ps1",
        }
    # The source installers read sibling files and the root VERSION by relative path,
    # so outside a bundle they only run from inside a checkout.
    source_root = Path(__file__).resolve().parents[2]
    return {
        "Darwin": source_root / "installers" / "macos" / "install.sh",
        "Windows": source_root / "installers" / "windows" / "install.ps1",
    }


INSTALLERS = _installer_paths()


class LiteUnavailable(Exception):
    pass


def windows_powershell() -> str:
    system_root = Path(os.environ.get("SystemRoot", r"C:\Windows"))
    relative = Path("WindowsPowerShell") / "v1.0" / "powershell.exe"
    # A 32-bit Python sees the 32-bit System32; Sysnative reaches the native PowerShell.
    native = system_root / "Sysnative" / relative
    if native.exists():
        return str(native)
    return str(system_root / "System32" / relative)


def installer_command(system: str, installer: Path, args: Sequence[str]) -> list[str]:
    if system == "Darwin":
        return ["/bin/bash", str(installer), *args]
    if system == "Windows":
        return [
            windows_powershell(),
            "-NoLogo",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(installer),
            *args,
        ]
    raise LiteUnavailable(f"Shelter Lite supports macOS and Windows, not {system}.")


def child_environment(system: str) -> dict[str, str]:
    if system != "Windows":
        return dict(os.environ)
    # PowerShell 7 exports its own module path; Windows PowerShell 5.1 inheriting it
    # loads incompatible core modules and loses cmdlets such as Get-FileHash.
    # Windows Python upper-cases environment keys, so compare without case.
    return {key: value for key, value in os.environ.items() if key.upper() != "PSMODULEPATH"}


def find_installer(system: str) -> Path:
    installer = INSTALLERS.get(system)
    if installer is None:
        raise LiteUnavailable(f"Shelter Lite supports macOS and Windows, not {system}.")
    if not installer.is_file():
        raise LiteUnavailable(f"Shelter Lite installer not found: {installer}")
    return installer


def exit_code(returncode: int) -> int:
    # POSIX children killed by a signal report a negative code; shells report 128 + signal.
    if returncode < 0:
        return 128 + -returncode
    return returncode


def run(args: Sequence[str], system: str | None = None) -> int:
    system = system or platform.system()
    try:
        command = installer_command(system, find_installer(system), args)
    except LiteUnavailable as error:
        print(f"shelter: {error}", file=sys.stderr)
        return 1
    try:
        return exit_code(subprocess.run(command, env=child_environment(system)).returncode)
    except KeyboardInterrupt:
        return 128 + signal.SIGINT
