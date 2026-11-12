import argparse
from collections.abc import Sequence
from importlib.metadata import PackageNotFoundError, version


def _installed_version() -> str:
    try:
        return version("shelter")
    except PackageNotFoundError:
        return "unknown"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="shelter",
        description="Inspect and set up a fixed developer tool environment.",
    )
    parser.add_argument(
        "-V",
        "--version",
        action="version",
        version=f"shelter {_installed_version()}",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    parser.parse_args(argv)
    parser.print_help()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
