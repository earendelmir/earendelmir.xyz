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
        it | ita*) lang=it ;;
        en | eng*) lang=en ;;
        *) echo "Language $lang not valid. Either IT or EN." ; unset lang ;;
    esac
    if [[ -z $lang ]]; then _ask_lang ; fi
}

# Find available filename for a new note, based on current date and counter.
# Output:
#   filename: string
_find_note_filename() {
    local date_for_filename="$(date +%y%m%d)" i=1
    while [[ -f "notes/permalink/${date_for_filename}${i}.html" ]]; do
        i=$((i+1))
    done
    echo "notes/permalink/${date_for_filename}${i}"
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
    grep -c "h-entry" "$file"
}

# Delete last note of page
# Args:
#   - file: HTML file to delete note from
# Output:
#   - note: HTML code stored in _FILE_LASTNOTE
_cut_last_note() {
    file="$1"
    begin_line_nr="$(grep -n "h-entry" "$file" | tail -1 | cut -d':' -f1)"
    end_line_nr="$(grep -n "dt-published" "$file" | tail -1 | cut -d':' -f1)"
    end_line_nr=$((end_line_nr+1))
    sed -n "$begin_line_nr"','"$end_line_nr"'p' "$file" > "$_FILE_LASTNOTE"
    sed -i "$begin_line_nr"','"$end_line_nr"'d' "$file" &>/dev/null
}


# Move into website's root folder.
pushd "${0%/*}/../docs" &>/dev/null

# Get current date.
# Use English language to get first 3 letters of current month (%b).
LANG=en_us_8859_1
curr_datetime=$(date +%Y-%m-%d)
curr_date=$(date +%d' '%b' '%Y)
curr_date=($curr_date)
curr_date=$(echo ${curr_date[@]^})

readonly _FILE_NOTES="notes/index.html"
readonly _FILE_EDITOR="/tmp/newnote.txt"
readonly _FILENAME_NEWNOTE="$(_find_note_filename)"
readonly _FILE_NEWNOTE="$_FILENAME_NEWNOTE.html"
readonly _FILE_TMPNOTE_FOR_NOTES="/tmp/note_for_notes.html"
readonly _FILE_DESCRIPTION="/tmp/description.txt"
readonly _FILE_LASTNOTE="/tmp/lastnote.html"
readonly _EDITOR="code -w"
readonly _MAX_NUM=15  # Maximum number of notes in every page.

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

# Ask user to write note's content.
$_EDITOR "$_FILE_EDITOR"
[[ ! -f "$_FILE_EDITOR" ]] && _die "File not found."
[[ ! -s "$_FILE_EDITOR" ]] && _die "File empty."
# Replace newlines with spaces and remove last space.
content="$(< "$_FILE_EDITOR" tr '\n' ' ')"
content="${content%"${content##*[![:space:]]}"}"

# Let user edit string as meta description.
echo "${content:0:120}..." > "$_FILE_DESCRIPTION"
echo "Press ENTER to edit meta description"
read -rp "Keep it under 160 chars ... "
$_EDITOR "$_FILE_DESCRIPTION"
# Replace newlines with spaces and remove last space.
description="$(< "$_FILE_DESCRIPTION" tr '\n' ' ')"
description="${description%"${description##*[![:space:]]}"}"
printf "Your description — you can change it in the file:\n%s\n" "$description"

# Write note in new file.
cp skeleton_note.html "$_FILE_NEWNOTE"
# Set note url.
sed "s|NOTEFILENAME|$_FILENAME_NEWNOTE|g" -i "$_FILE_NEWNOTE"
# Set language.
sed "s|NOTELANG|$lang|g" -i "$_FILE_NEWNOTE"
# Set meta description.
sed "s|NOTEDESCRIPTION|$description|g" -i "$_FILE_NEWNOTE"
# Set publication date.
sed "s/YYYY-MM-DD/$curr_datetime/g" -i "$_FILE_NEWNOTE"
sed "s/DD MMMM YYYY/$curr_date/g" -i "$_FILE_NEWNOTE"
# Set content.
sed "s|NOTECONTENT|$(printf '%s' "$content" | sed 's/[\/&]/\\&/g')|g" -i "$_FILE_NEWNOTE"


echo $"        <div class=\"h-entry\">
          <p class=\"e-content\" lang=\"$lang\">$content</p>
          <div><a href=\"/$_FILENAME_NEWNOTE\" aria-label=\"Permalink to this note\" title=\"Permalink to this note\"><time class=\"dt-published\" datetime=\"$curr_datetime\">$curr_date</time></a></div>
        </div>" > "$_FILE_TMPNOTE_FOR_NOTES"

# Add new note on top of main notes page.
page="$_FILE_NOTES"
page_num=1
_add_note_on_top "$_FILE_TMPNOTE_FOR_NOTES" "$page"
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
