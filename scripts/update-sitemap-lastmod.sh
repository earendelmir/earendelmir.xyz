#!/bin/bash

# File:   update-sitemap-lastmod.sh
# Author: Marco Plaitano
# Date:   13 Apr 2024
# Brief:  Update lastmod date for every entry in the XML sitemap.

set -eo pipefail

_exit() {
    popd &>/dev/null || true
    exit $1
}
_die() {
    [[ -n $1 ]] && echo "$1" >&2
    exit 1
}

_help() {
    printf "Usage: %s
Update lastmod date for every entry in the XML sitemap.\n" \
"$(basename "$0")"
}


trap _exit EXIT

# Move into website's root folder.
pushd "${0%/*}/../docs" &>/dev/null

# Parse command-line arguments.
while [[ -n $1 ]]; do
    case "$1" in
        -h | --help) _help ; exit ;;
        *) _die "Argument '$1' not recognized." ;;
    esac
done

LANG=en_us_8859_1
readonly _FILE_SITEMAP_XML="sitemap-xml.xml"

grep "<loc" "$_FILE_SITEMAP_XML" 2>/dev/null | while IFS= read -r line ; do
    filename="$(echo "$line" | cut -d'>' -f2 | cut -d'<' -f1)"
    # Get number of line to replace.
    line_nr="$(grep -n -m 1 "$filename" "$_FILE_SITEMAP_XML" | cut -d':' -f1)"
    line_nr=$((line_nr + 1))

    # Get actual file path, to check its last modification date.
    file="${filename#*xyz/}"
    if [[ "$file" =~ [0-9]$ ]]; then
        file+=".html"
    else
        file+="index.html"
    fi
    if [[ ! -f "$file" ]]; then
        echo "File $file from sitemap.xml not found" >&2
        continue
    fi
    new_line="    <lastmod>$(date -r "$file" +'%Y-%m-%d')</lastmod>"
    sed -i "${line_nr}s|.*|${new_line}|" "$_FILE_SITEMAP_XML"
done
