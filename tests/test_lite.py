import signal
import subprocess
import sys
from pathlib import Path

import pytest

from shelter import cli, lite

needs_bash = pytest.mark.skipif(sys.platform == "win32", reason="runs a Bash script")


@pytest.fixture
def stub_installer(tmp_path, monkeypatch):
    stub = tmp_path / "install.sh"
    stub.write_text('printf "%s\\n" "$@"\nexit "${STUB_EXIT:-0}"\n')
    monkeypatch.setitem(lite.INSTALLERS, "Darwin", stub)
    monkeypatch.setattr(lite.platform, "system", lambda: "Darwin")
    return stub


@needs_bash
def test_arguments_are_forwarded_unchanged(stub_installer, capfd):
    assert cli.main(["lite", "--dry-run", "--color", "never", "--help"]) == 0
    assert capfd.readouterr().out.splitlines() == ["--dry-run", "--color", "never", "--help"]


@needs_bash
def test_installer_exit_code_is_returned(stub_installer, monkeypatch):
    monkeypatch.setenv("STUB_EXIT", "3")
    assert cli.main(["lite", "--check"]) == 3


def test_missing_installer_fails(tmp_path, monkeypatch, capsys):
    monkeypatch.setitem(lite.INSTALLERS, "Darwin", tmp_path / "missing.sh")
    assert lite.run([], system="Darwin") == 1
    assert "installer not found" in capsys.readouterr().err


def test_unsupported_os_fails(capsys):
    assert lite.run([], system="Linux") == 1
    assert "supports macOS and Windows" in capsys.readouterr().err


def test_interrupt_returns_130(stub_installer, monkeypatch):
    def interrupted(command):
        raise KeyboardInterrupt

    monkeypatch.setattr(lite.subprocess, "run", interrupted)
    assert lite.run([]) == 130


def test_signal_exit_is_reported_like_a_shell():
    assert lite.exit_code(-signal.SIGTERM) == 128 + signal.SIGTERM


def test_windows_command_matches_launcher(tmp_path, monkeypatch):
    monkeypatch.setenv("SystemRoot", str(tmp_path))
    installer = Path("install.ps1")
    command = lite.installer_command("Windows", installer, ["--dry-run"])
    assert command == [
        str(tmp_path / "System32" / "WindowsPowerShell" / "v1.0" / "powershell.exe"),
        "-NoLogo",
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        "install.ps1",
        "--dry-run",
    ]


def test_bundled_installers_are_preferred(tmp_path, monkeypatch):
    monkeypatch.setattr(lite, "BUNDLE_DIR", str(tmp_path))
    paths = lite._installer_paths()
    assert paths["Darwin"] == tmp_path / "lite" / "shelter-lite-macos.sh"
    assert paths["Windows"] == tmp_path / "lite" / "shelter-lite-windows.ps1"


def test_source_installers_exist():
    assert lite.INSTALLERS["Darwin"].is_file()
    assert lite.INSTALLERS["Windows"].is_file()


@needs_bash
def test_real_installer_version_matches_shelter():
    result = subprocess.run(
        ["/bin/bash", str(lite.INSTALLERS["Darwin"]), "--version", "--color", "never"],
        capture_output=True,
        text=True,
    )
    root_version = (Path(__file__).parents[1] / "VERSION").read_text().strip()
    assert result.returncode == 0
    assert root_version in result.stdout
