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
FILE            Filepath of post to add to the feed\n" "$(basename "$0")"
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
    *) file="$1" ;;
esac

# Get most recent file from archive, if none has been given.
if [[ -z $file ]]; then
    file="$(find archive/ -name "20*" | sort -r | head -1 \
                | xargs -rI {} find {} -type f | sort -Vr | head -1)"
fi
filename=${file%.html}
fname="${file#*archive/}" ; fname="${fname%.html}" ; fname="${fname/\//-}"

# Check for validity.
[[ ! -f "$file" ]] && _die "File $file not found."
grep -q "$fname</guid>" "$_FILE_RSS_FEED" && _die "Post ${fname} already in the feed."
__ok_start=1
_print_ok "Found file $file"

# Get post title.
title="$(grep -m 1 post-title "$file")"
title="${title#*\">}"
title=${title::-5}
__ok_title=1
_print_ok "Title: $title"

# Publication date is current timestamp.
pubDate="$(date -R)"

# Description is first N characters of post body, find line numbers for start
# and end.
start_linenr="$(grep -m 1 -n e-content "$file")"
start_linenr="${start_linenr%:*}"
start_linenr=$((start_linenr + 1))
end_linenr="$(grep -m 1 -n '</article>' "$file")"
end_linenr="${end_linenr%:*}"
end_linenr=$((end_linenr - 2))
# Get post body.
sed -n "${start_linenr},${end_linenr}p" "$file" > /tmp/descr
# Format string.
descr="$(cat /tmp/descr)"
descr="${descr//\"/\\\"}"
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
# Truncate string at a maximum length of N characters.
N=300
length=${#descr}
if (( length > N )); then
    descr="${descr::N} [...]</p>"
fi
__ok_description=1
_print_ok "Descrition:\n$descr"
descr+="<br><hr><p>Read the full article <a href=\"https://earendelmir.xyz/$filename\">here</a>, or toggle <i>full page view</i> on your reader.</p><p>Want to get in touch? Reply via <a href=\"mailto:earendelmir@proton.me\">email</a>.</p>"

# Add new item.
line="\ \ \ \ <item>\n\ \ \ \ \ \ <link>https://earendelmir.xyz/$filename</link>\n\ \ \ \ \ \ <guid isPermaLink=\"false\">$fname</guid>\n\ \ \ \ \ \ <title>$title</title>\n\ \ \ \ \ \ <description><![CDATA[$descr]]></description>\n\ \ \ \ \ \ <pubDate>$pubDate</pubDate>\n\ \ \ \ </item>\n"
line_nr="$(grep -n -m 1 "<item>" "$_FILE_RSS_FEED" | cut -d':' -f1)"
sed -i "${line_nr}i\\${line}" "$_FILE_RSS_FEED"
__ok_add=1
_print_ok "Add new item to feed"

# Remove oldest item to keep max _MAX_RSS_ENTRIES in the feed.
count="$(grep -c '<item>' "$_FILE_RSS_FEED")"
if (( count > _MAX_RSS_ENTRIES )); then
    last="$(grep -n '<item>' "$_FILE_RSS_FEED" | tail -1 | cut -d' ' -f1)"
    last="${last::-1}"
    final=$(( last + 7 ))
    sed -i "${last},${final}d" "$_FILE_RSS_FEED"
    __ok_delete=1
    _print_ok "Delete last item from feed"
else
    __ok_delete=1
fi


__ok_all=1
popd &>/dev/null
