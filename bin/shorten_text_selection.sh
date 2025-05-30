#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-05-19 01:44:50 +0300 (Mon, 19 May 2025)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Shortens the selected text in the prior window

- Copies the selected text to the clipboard
- Replaces \"and\" with \"&\"
- Removes multiple blank lines between paragraphs (which can result from the copy/paste pipeline otherwise)
- Pastes the clipboard text back over the selected text

I use this a lot for LinkedIn comments in browser due to the short 1250 character limit

Tested on macOS 14, and Debian 11 with Xfce and LDXE desktop environments

Does not work on Debian 12 Gnome due to wayland lack of virtual keyboard support and even on Debian 12 Gnome on Xorg
the keystrokes do not come out properly, not sure why yet, ping me if you have time to figure out why as that's not
my day-to-day system to justify spending more time testing on it right now
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

no_more_args "$@"

if is_mac; then
    exec "$srcdir/../applescript/shorten_text_selection.scpt"
fi

for bin in xdotool xclip; do
    if ! type -P "$bin" &>/dev/null; then
        timestamp "Command '$bin' not found in \$PATH, attempting to install..."
        "$srcdir/../packages/install_packages.sh" "$bin"
    fi
done

check_bin xdotool
check_bin xclip

timestamp "Switching back to previous application"
# for Debian 12 Gnome
if [ "${XDG_SESSION_TYPE:-}" = wayland ]; then
    #timestamp "Detected wayland rather than Xorg, attempting to use ydotool instead"
    #if ! type -P ydotool &>/dev/null; then
    #    timestamp "Command 'ydotool' not found in \$PATH, attempting to install..."
    #    "$srcdir/../packages/install_packages.sh" ydotool
    #fi
    ##sudo ydotool key 56:1 15:1 15:0 56:0
    #sudo ydotool key 56:1    # press Alt
    #sleep 0.05
    #sudo ydotool key 15:1    # press Tab
    #sleep 0.05
    #sudo ydotool key 15:0    # release Tab
    #sleep 0.05
    #sudo ydotool key 56:0    # release Alt

    #timestamp "Detected wayland rather than Xorg, attempting to use wtype instead"
    #if ! type -P wtype &>/dev/null; then
    #    timestamp "Command 'wtype' not found in \$PATH, attempting to install..."
    #    "$srcdir/../packages/install_packages.sh" wtype
    #fi
    #wtype -M alt -k tab -m alt
    #
    # Results in error:
    #
    #   Compositor does not support the virtual keyboard protocol
    #
    # This is because Gnome intentionally disables it for security - you must switch to an X11 session
    die "ERROR: wayland based UI is not supported at this time due to lack of virtual keyboard protocol support (intentional by the developers)"
else
    xdotool keydown alt
    #xdotool keydown Tab
    #xdotool keyup Tab
    xdotool key Tab
    xdotool keyup alt
fi
sleep 0.3
echo

timestamp "Copying selected content (Ctrl-C)"
xdotool key ctrl+c
sleep 0.1
echo

timestamp "Replacing selected clipboard content - 'and' with '&' and collapse multiple blank lines"
xclip -o -selection clipboard |
sed -E 's/\band\b/\&/g' |
cat -s |
xclip -selection clipboard
sleep 0.1
echo

timestamp "Pasting modified clipboard content back to app (Ctrl-v)"
xdotool key ctrl+v
