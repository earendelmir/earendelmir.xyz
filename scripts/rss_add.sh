#!/bin/bash

# File:   rss_add.sh
# Author: earendelmir
# Date:   19 Oct 2023
# Brief:  Add post to RSS feed file.

set -eo pipefail


_print_ok() {
    printf "\e[1;32m✓ \e[0m%b\n" "$1"
}
_print_err() {
    printf "\e[1;31m✗ \e[0m%b\n" "$1"
}
# Print RSS item description by highlighting HTML elements in it.
_print_descr() {
    print_html_bold=$(cat <<EOF
import re
string = "${1//\"/\\\"}"
output = ""
start = 0
for match in re.finditer(r'<([^>]*)>', string):
  output += string[start:match.start()] + "\033[1;33m<" + match.group(1) + ">\033[0m"
  start = match.end()
output += string[start:]
print(output)
EOF
    )
    printf "%s\n" "$(python3 -c "$print_html_bold")"
}
_exit() {
    popd &>/dev/null || true
    exit $1
}
# trap function for EXIT.
# Revert any change made to the repository before exiting the script. This gets
# called both if script dies for "set -e", for "_die", or when it ends.
# Look at this function last, this makes sense after having read the rest of the
# code.
_trap_exit() {
    # Nothing has actually been done yet, exit the script freely.
    [[ -z $__ok_start ]] && _exit $1
    # Everything has been done correctly, exit the script freely.
    [[ -n $__ok_all ]] && _exit $1
    # Something went wrong, revert any change already made. You can stop
    # checking at the first change that has failed.
    if [[ -z $__ok_title ]]; then
        _print_err "Can't get title." ; _exit $1
    fi
    if [[ -z $__ok_description ]]; then
        _print_err "Can't get description." ; _exit $1
    fi
    if [[ -n $__ok_add ]]; then
        line_nr_begin=$(grep -n "$fname</guid>" "$_FILE_RSS_FEED" | cut -d':' -f1)
        line_nr_end=$((line_nr_begin+5))
        line_nr_begin=$((line_nr_begin-2))
        sed -i "${line_nr_begin},${line_nr_end}d" "$_FILE_RSS_FEED"
    else
        _print_err "Add item to feed." ; _exit $1
    fi
    if [[ -z $__ok_delete ]]; then
        _print_err "Delete last item from feed" ; _exit $1
    fi
    _exit $1
}

# Exit with error.
_die() {
    [[ -n $1 ]] && echo "$1" >&2
    exit 1
}

_help() {
    printf "Usage: %s [FILE]
Add new post to the RSS feed file. By default it adds the latest one.

-h, --help      Show this guide and exit
-n, --note      Add latest note instead of post\n" "$(basename "$0")"
}

_get_note_title() {
    echo ""
}
_get_post_title() {
    grep -m 1 post-title "$file" | cut -d'>' -f2 | cut -d'<' -f1
}
_get_note_descr() {
    start_linenr="$(grep -m 1 -n e-content "$file")"
    start_linenr="${start_linenr%:*}"
    start_linenr=$((start_linenr + 1))
    end_linenr="$(grep -m 1 -n '</article>' "$file")"
    end_linenr="${end_linenr%:*}"
    end_linenr=$((end_linenr - 3))
    # Get note body.
    sed -n "${start_linenr},${end_linenr}p" "$file"
}
_get_post_descr() {
    start_linenr="$(grep -m 1 -n e-content "$file")"
    start_linenr="${start_linenr%:*}"
    start_linenr=$((start_linenr + 1))
    end_linenr="$(grep -m 1 -n '</article>' "$file")"
    end_linenr="${end_linenr%:*}"
    end_linenr=$((end_linenr - 2))
    # Get post body.
    sed -n "${start_linenr},${end_linenr}p" "$file"
}


trap _trap_exit EXIT

# Move into website's root folder.
pushd "${0%/*}/../docs" &>/dev/null

LANG=en_us_8859_1
readonly _FILE_RSS_FEED="feed.xml"
readonly _MAX_RSS_ENTRIES=20

[[ ! -f "$_FILE_RSS_FEED" ]] && _die "Feed file $_FILE_RSS_FEED does not exist."

# Parse command-line arguments.
case "$1" in
    '') ;;
    -h | --help) _help ; exit ;;
    -n | --note) add_note=1 ;;
esac

# Get most recent note/post.
if [[ -n $add_note ]]; then
    file="$(find notes/permalink/ -type f | sort -r | head -1 \
                | xargs -rI {} find {} -type f | sort -Vr | head -1)"
    filename=${file%.html}
    fname="${file#*permalink/}" ; fname="${fname%.html}"
else
    file="$(find archive/ -mindepth 1 -maxdepth 1 -type d ! -path "*tags*" \
                | sort -r | xargs -rI {} find {} -type f | sort -Vr | head -1)"
    filename=${file%.html}
    fname="${file#*archive/}" ; fname="${fname%.html}" ; fname="${fname/\//-}"
fi

# Check for validity.
[[ ! -f "$file" ]] && _die "File $file not found."
grep -q "$fname</guid>" "$_FILE_RSS_FEED" && _die "Post ${fname} already in the feed."
__ok_start=1
_print_ok "Found file $file"

# Get note/post title.
if [[ -n $add_note ]]; then
    title="$(_get_note_title)"
else
    title="$(_get_post_title)"
fi
__ok_title=1
_print_ok "Title: $title"

# Publication date is current timestamp.
pubDate="$(date -R)"

# Get note/post description (content body).
if [[ -n $add_note ]]; then
    descr="$(_get_note_descr)"
else
    descr="$(_get_post_descr)"
fi
# Format string.
descr="${descr//          /}"
descr="${descr//         /}"
descr="${descr//        /}"
descr="${descr//       /}"
descr="${descr//      /}"
descr="${descr//     /}"
descr="${descr//    /}"
descr="${descr//   /}"
descr="${descr//  /}"
descr="${descr//$'\n'/ }"

# Truncate string at a maximum length of N characters and add custom footer.
N=300
if (( ${#descr} > N )); then
    descr="${descr::N} [...]</p>"
    descr+="<br><hr><p>Read the full article <a href=\"https://earendelmir.xyz/$filename\">here</a>, or toggle <i>full page view</i> on your reader.</p><p>Want to get in touch? Reach out via <a href=\"mailto:earendelmir@proton.me\">email</a>.</p>"
else
    descr+="<br><hr><p>Want to get in touch? Reach out via <a href=\"mailto:earendelmir@proton.me\">email</a>.</p>"
fi
__ok_description=1
_print_ok "Description:" ; _print_descr "$descr"

# Add new item to the feed.
line="\ \ \ \ <item>\n\ \ \ \ \ \ <link>https://earendelmir.xyz/$filename</link>\n\ \ \ \ \ \ <guid isPermaLink=\"false\">$fname</guid>\n\ \ \ \ \ \ <author>earendelmir@proton.me</author>\n\ \ \ \ \ \ <title>$title</title>\n\ \ \ \ \ \ <description><![CDATA[$descr]]></description>\n\ \ \ \ \ \ <pubDate>$pubDate</pubDate>\n\ \ \ \ </item>\n"
line_nr="$(grep -n -m 1 "<item>" "$_FILE_RSS_FEED" | cut -d':' -f1)"
sed -i "${line_nr}i\\${line}" "$_FILE_RSS_FEED"
__ok_add=1
_print_ok "Add new item to feed"

# Remove oldest item to keep max _MAX_RSS_ENTRIES in the feed.
count="$(grep -c '<item>' "$_FILE_RSS_FEED")"
if (( count > _MAX_RSS_ENTRIES )); then
    last="$(grep -n '<item>' "$_FILE_RSS_FEED" | tail -1 | cut -d' ' -f1)"
    last="${last::-1}"
    final=$(( last + 8 ))
    sed -i "${last},${final}d" "$_FILE_RSS_FEED"
    __ok_delete=1
    _print_ok "Delete last item from feed"
else
    __ok_delete=1
fi


__ok_all=1
popd &>/dev/null
