#!/bin/bash

# File:   update-sitemap-lastmod.sh
# Author: Marco Plaitano
# Date:   13 Apr 2024
# Brief:  Update lastmod date for every entry in the XML sitemap to current day.

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
Update lastmod date for every entry in the XML sitemap to current day.\n" \
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

new_line="    <lastmod>$(date +'%Y-%m-%d')</lastmod>"

sed -i "/^    <lastmod>/c\\$new_line" "$_FILE_SITEMAP_XML"
