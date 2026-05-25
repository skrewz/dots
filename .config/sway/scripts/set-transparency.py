#!/usr/bin/python
#
# This script requires i3ipc-python package (install it from a system package manager

import i3ipc

if __name__ == "__main__":
    transparency_val = "0.80"

    parser = argparse.ArgumentParser(
    parser.add_argument(
        "--opacity",
        "-o",
        type=str,
        default=transparency_val,
        help="set opacity value in range 0...1",
    )
    args = parser.parse_args()

    ipc = i3ipc.Connection()
    prev_focused = None
    prev_workspace = ipc.get_tree().find_focused().workspace().num

    for window in ipc.get_tree():
        if window.focused:
            prev_focused = window
        else:
            window.command("opacity " + args.opacity)
