#!/bin/bash

# File:   note.sh
# Date:   15 Feb 2024
# Brief:  Add a new note.

set -eo pipefail


_die() {
    [[ -n $1 ]] && echo "$1" >&2
    popd &>/dev/null || true
    exit 1
}

_help() {
    printf "Usage: %s [OPTION]
Add a new note. If no input file is given, the editor will open to let you write
the note.

-h, --help          Show this guide and exit
-l, --lang LANG     Language in which the note is written; either it or en\n" \
"$(basename "$0")"
}

_ask_lang() {
    while [[ -z $lang ]]; do
        read -rp "Lang: " lang
    done
    case "${lang,,}" in
        it | ita*) lang_def=" lang=\"it\"" ;;
        en | eng*) lang_def="" ;;
        *) echo "Language $lang not valid. Either IT or EN." ; unset lang ;;
    esac
    if [[ -z $lang ]]; then _ask_lang ; fi
}

# Add new note on top of page.
# Args:
#   - note: filepath containing HTML code
#   - file: HTML file to add note to
_add_note_on_top() {
    note="$1" file="$2"
    line_nr="$(grep -n "u-email" "$file" | head -1 | cut -d':' -f1)"
    line_nr=$((line_nr+2))
    sed -i "$line_nr"'r '"$note" "$file"
}

# Count number of notes in page
# Args:
#   - file: HTML file to count notes in
# Output:
#   Integer
_count_notes_in_file() {
    file="$1"
    grep -c "e-content" "$file"
}

# Delete last note of page
# Args:
#   - file: HTML file to delete note from
# Output:
#   - note: HTML code stored in _FILE_LASTNOTE
_cut_last_note() {
    file="$1"
    begin_line_nr="$(grep -n "e-content" "$file" | tail -1 | cut -d':' -f1)"
    begin_line_nr=$((begin_line_nr-2))
    end_line_nr="$(grep -n "dt-published" "$file" | tail -1 | cut -d':' -f1)"
    end_line_nr=$((end_line_nr+1))
    sed -n "$begin_line_nr"','"$end_line_nr"'p' "$file" > "$_FILE_LASTNOTE"
    sed -i "$begin_line_nr"','"$end_line_nr"'d' "$file" &>/dev/null
}


# Move into website's root folder.
pushd "${0%/*}/../docs" &>/dev/null

readonly _FILE_NOTES="notes/index.html"
readonly _FILE_NEWNOTE="/tmp/newnote.html"
readonly _FILE_LASTNOTE="/tmp/lastnote.html"
readonly _EDITOR="code -w"
readonly _MAX_NUM=20  # Maximum number of notes in every page.

# Parse command-line arguments.
while [[ -n $1 ]]; do
    case "$1" in
        -h | --help)
            _help ; exit ;;
        -l | --lang)
            [[ -z $2 ]] && _die "No language given."
            lang="$2"
            shift ;;
        *)
            _die "Argument '$1' not recognized." ;;
    esac
    shift
done

_ask_lang

# Get current date.
# Use English language to get first 3 letters of current month (%b).
LANG=en_us_8859_1
curr_datetime=$(date +%Y-%m-%d)
curr_date=$(date +%d' '%b' '%Y)
curr_date=($curr_date)
curr_date=$(echo ${curr_date[@]^})

# Write note in new file.
echo $"        <div class=\"h-entry\">
          <p class=\"e-content\"$lang_def></p>
          <time class=\"dt-published\" datetime=\"$curr_datetime\">$curr_date</time>
        </div>" > "$_FILE_NEWNOTE"
$_EDITOR "$_FILE_NEWNOTE"

[[ ! -f "$_FILE_NEWNOTE" ]] && _die "Note file not found."
[[ ! -s "$_FILE_NEWNOTE" ]] && _die "Note file empty."
if grep -q "e-content\"$lang_def></p>" "$_FILE_NEWNOTE"; then
    _die "Note not written. Abort."
fi

# Add new note on top of main notes page.
page="$_FILE_NOTES"
page_num=1
_add_note_on_top "$_FILE_NEWNOTE" "$page"
echo "Added note."
# If current page contains more than _MAX_NUM notes, move last one to top of
# next page. Iterate until all pages have correct number.
while [[ $(_count_notes_in_file "$page") -gt $_MAX_NUM ]]; do
    _cut_last_note "$page"
    # Select next page.
    page_num=$((page_num+1))
    page="notes/page/$page_num.html"
    # Create next page if it doesn't exist.
    if [[ ! -f "$page" ]]; then
        cp skeleton_notes.html "$page"
        sed "s/NUM-2/$((page_num-2))/g" -i "$page"
        sed "s/NUM-1/$((page_num-1))/g" -i "$page"
        sed "s/NUM/$page_num/g" -i "$page"
        echo -e "Created $page. \033[1mUpdate the links at the bottom.\033[0m"
    fi
    _add_note_on_top "$_FILE_LASTNOTE" "$page"
    echo "Moved last to $page."
done

# TODO: update page links at bottom when new pages get created.

popd &>/dev/null
