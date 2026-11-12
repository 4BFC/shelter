"""Build a self-contained `shelter` executable for the current OS.

Run from the repository root: uv run --group build python scripts/build_cli.py
"""

import os
import platform
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "dist" / "cli"
WORK_DIR = ROOT / "build" / "cli"

LITE_BUILDS = {
    "Darwin": (
        ["/bin/bash", str(ROOT / "installers" / "macos" / "build.sh"), "--output-dir"],
        "shelter-lite-macos.sh",
    ),
    "Windows": (
        [
            "powershell.exe",
            "-NoLogo",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ROOT / "installers" / "windows" / "build.ps1"),
            "-OutputDirectory",
        ],
        "shelter-lite-windows.ps1",
    ),
}


def build_lite(system: str, lite_dir: Path) -> Path:
    command, artifact = LITE_BUILDS[system]
    # Same reason as shelter.lite.child_environment: a PowerShell 7 parent breaks 5.1 cmdlets.
    env = {key: value for key, value in os.environ.items() if key.upper() != "PSMODULEPATH"}
    subprocess.run([*command, str(lite_dir)], check=True, env=env)
    return lite_dir / artifact


def build_executable(lite_installer: Path) -> Path:
    # Lite reads its own version from the embedded copy, but Shelter reads package
    # metadata, so the metadata must travel inside the bundle as well.
    subprocess.run(
        [
            sys.executable,
            "-m",
            "PyInstaller",
            "--noconfirm",
            "--clean",
            "--onefile",
            "--name",
            "shelter",
            "--paths",
            str(ROOT / "src"),
            "--copy-metadata",
            "shelter",
            "--add-data",
            f"{lite_installer}{os.pathsep}lite",
            "--distpath",
            str(OUTPUT_DIR),
            "--workpath",
            str(WORK_DIR),
            "--specpath",
            str(WORK_DIR),
            str(ROOT / "src" / "shelter" / "__main__.py"),
        ],
        check=True,
    )
    return OUTPUT_DIR / ("shelter.exe" if sys.platform == "win32" else "shelter")


def smoke_test(executable: Path) -> None:
    version = (ROOT / "VERSION").read_text().strip()
    # A minimal environment shows the executable does not rely on a Python or uv on PATH.
    env = {key: os.environ[key] for key in ("SystemRoot", "TEMP", "TMP") if key in os.environ}
    env["PATH"] = os.pathsep.join(
        [str(Path(os.environ.get("SystemRoot", r"C:\Windows")) / "System32")]
        if sys.platform == "win32"
        else ["/usr/bin", "/bin"]
    )
    checks = [
        (["--version"], f"shelter {version}"),
        (["lite", "--version", "--color", "never"], f"Shelter Lite {version}"),
    ]
    for args, expected in checks:
        result = subprocess.run(
            [str(executable), *args], env=env, capture_output=True, text=True, check=True
        )
        if result.stdout.strip() != expected:
            raise SystemExit(f"{args}: expected {expected!r}, got {result.stdout.strip()!r}")
        print(f"ok: shelter {' '.join(args)} -> {expected}")


def main() -> int:
    system = platform.system()
    if system not in LITE_BUILDS:
        print(f"build_cli: macOS and Windows only, not {system}", file=sys.stderr)
        return 1
    shutil.rmtree(WORK_DIR, ignore_errors=True)
    with tempfile.TemporaryDirectory() as lite_dir:
        lite_installer = build_lite(system, Path(lite_dir))
        executable = build_executable(lite_installer)
    smoke_test(executable)
    print(f"built: {executable}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
