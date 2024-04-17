#!/bin/bash

# File:   update.sh
# Author: earendelmir
# Date:   18 Sep 2023
# Brief:  Check that everything is okay before committing.

set -eo pipefail


_print_ok() {
    printf "\e[1;32m✓ \e[0m%s\n" "$1"
}
_print_err() {
    printf "\e[1;31m✗ \e[0m%s\n" "$1"
}

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
Check that everything is okay before committing.\n" "$(basename "$0")"
}


trap _exit EXIT

# Move into website's root folder.
pushd "${0%/*}/../docs" &>/dev/null

readonly _FILE_ARCHIVE="archive/index.html"
readonly _FILE_SITEMAP_XML="sitemap-xml.xml"
readonly _FILE_SITEMAP_TXT="sitemap.txt"
readonly _FILE_RSS="feed.xml"
readonly _NUM_RSS_ENTRIES=20

# Parse command-line argument.
case "$1" in
    '') ;;
    -h | --help) _help ; exit ;;
    *) _die "Argument '$1' not recognized." ;;
esac


################################################################################
###  CHECKS FOR INDIVIDUAL POST FILES
################################################################################

for file in $(find archive/ -name "20*" | sort -r \
                | xargs -rI {} find {} -type f | sort -Vr); do
    fname="${file#*archive/}" ; fname="${fname%.html}"
    # Check for reading time inside post.
    if grep -q "NUM min" "$file" ; then
        _print_err "No reading time for $fname"
    fi
    # Check for meta title inside post.
    if grep -q "TITLE" "$file" ; then
        _print_err "No title for $fname"
    fi
    # Check for meta description inside post.
    if grep -q "POST DESCRIPTION" "$file" ; then
        _print_err "No description for $fname"
    fi
    # Check for TAG inside post.
    if grep -q "TAG" "$file" ; then
        _print_err "No tag for $fname"
    fi
    # Check post is in /archive page.
    if ! grep -q "$fname" "$_FILE_ARCHIVE" ; then
        _print_err "Post $fname not in /archive"
    fi
    # Check post is in sitemap XML.
    if ! grep -q "$fname" "$_FILE_SITEMAP_XML" ; then
        _print_err "Post $fname not in sitemap XML"
    fi
    # Check post is in sitemap TXT.
    if ! grep -q "$fname" "$_FILE_SITEMAP_TXT" ; then
        _print_err "Post $fname not in sitemap TXT"
    fi
done


################################################################################
###  CHECKS FOR RSS FEED
################################################################################

# Check that all files mentioned in feed actually exist.
lines=$(grep "<link" "$_FILE_RSS")
while IFS= read -r line; do
    file=.$(echo "$line" | cut -d'z' -f2 | cut -d'<' -f1)
    [[ "$file" == . ]] && continue
    if [[ ! -f "$file.html" ]]; then
        _print_err "Post ${file} from RSS feed doesn't exist."
    fi
done <<< "$lines"

# Check that latest N posts are included in the RSS feed.
for file in $(find archive/ -type d -name "20*" | sort -r | head -1 \
            | xargs -rI {} find {} -type f | sort -Vr | head -$_NUM_RSS_ENTRIES)
do
    fname="${file#*archive/}" ; fname="${fname%.html}"
    if ! grep -q "$fname</link>" "$_FILE_RSS" ; then
        _print_err "Post ${fname} not in RSS feed."
    fi
done


################################################################################
###  CHECKS FOR SITEMAPS
################################################################################

# Check that all files mentioned in the sitemaps actually exist.
while IFS= read -r line; do
    file="${line#*earendelmir.xyz/}"
    [[ "$file" == "" ]] && file="index"
    [[ "$file" == *"/" ]] && file="${file}index"
    if [[ ! -f "$file.html" ]]; then
        _print_err "File $file from sitemap TXT doesn't exist."
    fi
done < "$_FILE_SITEMAP_TXT"

while IFS= read -r line; do
    file="${line#*earendelmir.xyz/}"
    file="$(echo "$file" | cut -d '<' -f1)"
    [[ "$file" == "" ]] && file="index"
    [[ "$file" == *"/" ]] && file="${file}index"
    if [[ ! -f "$file.html" ]]; then
        _print_err "File $file from sitemap XML doesn't exist."
    fi
done <<< "$(grep loc "$_FILE_SITEMAP_XML")"


popd &>/dev/null
