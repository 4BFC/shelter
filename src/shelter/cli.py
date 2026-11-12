import argparse
import sys
from collections.abc import Sequence
from importlib.metadata import PackageNotFoundError, version

from shelter import lite


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
    commands = parser.add_subparsers(title="commands", metavar="COMMAND")
    commands.add_parser(
        "lite",
        help="Run the Shelter Lite installer; options are passed to it unchanged",
        add_help=False,
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    # Lite owns its options and help text, so they bypass Shelter's parser entirely.
    if args and args[0] == "lite":
        return lite.run(args[1:])
    parser = build_parser()
    parser.parse_args(args)
    parser.print_help()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
