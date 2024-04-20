#!/bin/bash

# File:   marktohtml.sh
# Author: earendelmir
# Date:   30 Nov 2023
# Brief:  Convert Markdown draft into HTML post.

set -eo pipefail

_die() {
    [[ -n $1 ]] && echo "$1" >&2
    popd &>/dev/null || true
    exit 1
}

_help() {
    printf "Usage: %s [OPTION]...
Convert Markdown draft into HMTL body for latest post.

-h, --help      Show this guide and exit
-f FILE         Markdown file to convert (default to /drafts/draft.md)
-y, --yes       Apply draft to latest post without asking for confirmation
-q, --quiet     Like -y but doesn't even print the info\n" "$(basename "$0")"
}

_confirm() {
    unset ans
    while [[ -z $ans ]]; do
        read -rp "Confirm? " ans
        case "${ans,,}" in
            y|ye*|si) return 0 ;;
            n|no*)    return 1 ;;
            *)        unset ans ;;
        esac
    done
}


readonly FILE_MARKDOWN="/tmp/draft.md"
readonly FILE_HTML="/tmp/draft.html"

readonly TRANSLATE_CODE="""
try:
    from markdown import markdown
    with open(\"$FILE_MARKDOWN\", \"r\") as f:
        content = f.read()
    html = markdown(content)

    html = html.replace(\"<br />\", \"<br>\")
    html = html.replace(\"<hr />\", \"<hr>\")
    html = html.replace(\"em>\",    \"i>\")
    html = html.replace(\"strong>\",   \"b>\")
    html = html.replace(\"<li>\",   \"  <li>\")
    html = html.replace(\"<h2>\",   \"\n<h2>\")
    html = html.replace(\"<h3>\",   \"\n<h3>\")
    html = html.replace(\"\n<p>\",  \"\n\n<p>\")
    html = html.replace(\"\n\",     \"\n        \")
    html = \"        \" + html

    with open(\"$FILE_HTML\", \"w\") as f:
        f.write(html)
except Exception as e:
    print(e)
"""


# Move into this script's folder.
pushd "${0%/*}"/../docs/ &>/dev/null

# Parse command-line arguments.
while [[ -n $1 ]]; do
    case "$1" in
        -h | --help)
            _help ; exit ;;
        -f)
            [[ -z $2 ]] && _die "File not given"
            file="$2"
            shift ;;
        -y | --yes)
            confirmed=1 ;;
        -q | --quiet)
            quiet=1 ;;
        *)
            _die "Argument '$1' not recognized." ;;
    esac
    shift
done


# Default value for input file.
file="${file:="../drafts/draft.md"}"
[[ "$file" == "drafts/"* ]] && file=../"$file"
[[ ! -f "$file" ]] && _die "File '$file' not found."

# Copy content to fixed file location.
cp "$file" "$FILE_MARKDOWN"

# Get most recent file = post to modify.
post_filename="$(find archive/ -mindepth 1 -maxdepth 1 -type d ! -path "*tags*" \
                | sort -r | xargs -rI {} find {} -type f | sort -Vr | head -1)"
post_title="$(grep post-title "$post_filename")"
post_title="${post_title:29:-5}"

# Translate markdown to html.
python3 -c "$TRANSLATE_CODE"
post_body="$(cat $FILE_HTML)"

# Get line numbers where post body starts and where it ends.
line_nr_start="$(grep -n e-content "$post_filename" | cut -d':' -f1)"
(( line_nr_start+=1 ))
line_nr_end="$(grep -n /article "$post_filename" | cut -d':' -f1)"
(( line_nr_end-=2 ))

# Show before action, and ask for confirmation.
if [[ -z $quiet ]]; then
    printf "POST:  %s (%s)\n" "$post_title" "${post_filename:8}"
    printf "START: %s\n" "$line_nr_start"
    printf "END:   %s\n" "$line_nr_end"
    printf "BODY:\n%s\n" "$post_body"
    [[ -z $confirmed ]] && { _confirm || exit ;}
fi

# Remove previous post body.
if (( line_nr_end >= line_nr_start )); then
    sed -i "${line_nr_start},${line_nr_end}d" "$post_filename"
fi

# Add new post body.
readonly tmp_file="/tmp/post.html"
awk -v n="$line_nr_start" -v s="$post_body" \
    "NR==n {print s} 1" "$post_filename" > "$tmp_file"
mv "$tmp_file" "$post_filename"


popd &>/dev/null
