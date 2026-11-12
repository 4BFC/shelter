from pathlib import Path

import pytest

from shelter.cli import main

ROOT_VERSION = (Path(__file__).parents[1] / "VERSION").read_text().strip()


def test_no_arguments_prints_help(capsys):
    assert main([]) == 0
    assert "usage: shelter" in capsys.readouterr().out


def test_version_matches_root_version_file(capsys):
    with pytest.raises(SystemExit) as exit_info:
        main(["--version"])
    assert exit_info.value.code == 0
    assert capsys.readouterr().out.strip() == f"shelter {ROOT_VERSION}"


def test_unknown_option_fails(capsys):
    with pytest.raises(SystemExit) as exit_info:
        main(["--unknown"])
    assert exit_info.value.code == 2
