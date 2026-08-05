#!/usr/bin/env python3
# Patches libcosmic's vendored iced_winit fork (a cargo git dependency,
# not part of cosmic-panel's own source tree) to fix a hard panic on
# Wayland-connection loss. See srcpkgs/cosmic-panel/template pre_build()
# for how this is invoked and why it has to work this way instead of a
# normal srcpkgs patches/ entry.
#
# Root cause: platform_specific/wayland/event_loop/mod.rs runs the SCTK
# event loop in a `loop { ... state.event_loop.dispatch(...) ... }` with
# no exit condition other than a panic. When the compositor tears down
# the Wayland socket (e.g. on logout), dispatch() starts failing with a
# fatal IO error (broken pipe) on every call; the loop just logs
# "SCTK dispatch error: ..." and immediately re-enters, spinning until an
# unrelated unwrap() elsewhere in the same call stack finally panics.
# Fix: exit the loop cleanly the first time dispatch fails with a fatal
# IoError, instead of retrying forever.
import re
import sys

MARKER = "COSMIC_VOID_FATAL_IOERROR_EXIT"

PATTERN = re.compile(
    r'(if let Err\(err\) =\s*\n\s*state\.event_loop\.dispatch\(None, &mut state\.state\)\s*\n(?P<indent>[ \t]*)\{\s*\n[ \t]*log::error!\("SCTK dispatch error: \{err\}"\);\s*\n)([ \t]*)\}'
)


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: patch-vendored-iced-sctk-panic.py <path to event_loop/mod.rs>", file=sys.stderr)
        return 1

    path = sys.argv[1]
    with open(path, encoding="utf-8") as f:
        src = f.read()

    if MARKER in src:
        print(f"{path}: already patched, skipping")
        return 0

    def repl(m: re.Match) -> str:
        indent = m.group("indent")
        inner = indent + "    "
        return (
            m.group(1)
            + f"{inner}// {MARKER}: the compositor tore down the wayland\n"
            + f"{inner}// connection (e.g. on logout); exit the loop cleanly\n"
            + f"{inner}// instead of spinning until an unrelated unwrap panics.\n"
            + f"{inner}if matches!(err, calloop::Error::IoError(_)) {{\n"
            + f"{inner}    log::warn!(\"Wayland connection lost, exiting SCTK event loop.\");\n"
            + f"{inner}    return Ok(());\n"
            + f"{inner}}}\n"
            + indent
            + "}"
        )

    new_src, count = PATTERN.subn(repl, src, count=1)
    if count == 0:
        print(f"{path}: dispatch-error pattern not found -- refusing to patch blindly "
              "(upstream source layout may have changed)", file=sys.stderr)
        return 1

    with open(path, "w", encoding="utf-8") as f:
        f.write(new_src)
    print(f"{path}: patched ({count} site)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
