#!/bin/bash

# File:   newpost.sh
# Author: earendelmir
# Date:   21 Feb 2023
# Brief:  Create a new post with a given title and language.

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
    if [[ -n $__ok_file_created ]]; then
        rm "$post_file"
    else
        _print_err "Create file." ; _exit $1
    fi
    if [[ -n $__ok_add_homepage ]]; then
        sed -i "/${post_filename//\//\\/}/d" "$_FILE_HOMEPAGE"
    else
        _print_err "Add post to $_FILE_HOMEPAGE." ; _exit $1
    fi
    if [[ -n $__ok_remove_homepage ]]; then
        line_nr=$(grep -n "h-entry" "$_FILE_HOMEPAGE" | tail -1 | cut -d':' -f1)
        sed -i "${line_nr}a\\${oldest_line}" "$_FILE_HOMEPAGE"
    else
        _print_err "Remove oldest entry from $_FILE_HOMEPAGE." ; _exit $1
    fi
    if [[ -n $__ok_add_archive ]]; then
        sed -i "/${post_filename//\//\\/}/d" "$_FILE_ARCHIVE"
    else
        _print_err "Add post to $_FILE_ARCHIVE." ; _exit $1
    fi
    if [[ -n $__ok_add_archive_tags ]]; then
        sed -i "/${post_filename//\//\\/}/d" "$_FILE_ARCHIVE_TAGS"
    else
        _print_err "Add post to $_FILE_ARCHIVE_TAGS." ; _exit $1
    fi
    if [[ -n $__ok_update_tag ]]; then
        sed -i "$line_nr_tag""s/$new_tag_num/$curr_tag_num/" "$_FILE_ARCHIVE_TAGS"
    else
        _print_err "Update tag post count." ; _exit $1
    fi
    if [[ -n $__ok_link_prev ]]; then
        true
    else
        _print_err "Link prev post." ; _exit $1
    fi
    if [[ -n $__ok_link_next ]]; then
        next_linenr="$(grep -n "prevnext-next" "archive/$year/$latest_post" | cut -d: -f1)"
        next_line="      <div class=\"prevnext-next\"></div>"
        sed -i "${next_linenr}s|.*|${next_line}|" "archive/$year/$latest_post"
    else
        _print_err "Link next post." ; _exit $1
    fi
    if [[ -n $__ok_add_sitemap_xml ]]; then
        num_lines="$(wc -l < $_FILE_SITEMAP_XML)"
        begin_line_nr=$((num_lines-5))
        end_line_nr=$((num_lines-1))
        sed -i "$begin_line_nr"','"$end_line_nr"'d' "$_FILE_SITEMAP_XML"
    else
        _print_err "Add page to XML sitemap." ; _exit $1
    fi
    if [[ -n $__ok_add_sitemap_txt ]]; then
        sed -i "/${post_filename//\//\\/}/d" "$_FILE_SITEMAP_TXT"
    else
        _print_err "Add page to TXT sitemap." ; _exit $1
    fi
    if [[ -n $__ok_write_body ]]; then
        true
    else
        _print_err "Write body from MD file." ; _exit $1
    fi
    _exit $1
}

# Exit with error.
_die() {
    [[ -n $1 ]] && echo "$1" >&2
    exit 1
}

_help() {
    printf "Usage: %s [OPTION]...
Create new post file.

-h, --help          Show this guide and exit
--tags              List all existing tags and exit
--title TITLE       Post title
--lang LANG         Language in which the post is written; either it or en
--tag TAG           Post tag
-f, --file FILE     Markdown file containing the post body.\n" "$(basename "$0")"
}

_list_tags() {
    grep "<li id=" archive/tags/index.html | cut -c 19- | cut -d'"' -f1
}

_is_valid_tag() {
    tags="$(_list_tags)"
    for t in ${tags[@]}; do
        if [[ "$tag" == "$t" ]]; then
            return 0
        fi
    done
    return 1
}

_ask_tag() {
    while [[ -z $tag ]]; do
        read -rp "Tag: " tag
    done
    tag=${tag,,}
    if ! _is_valid_tag ; then unset tag ; fi
    if [[ -z $tag ]]; then _ask_tag ; fi
}

_ask_title() {
    while [[ -z $title ]]; do
        read -rp "Title: " title
    done
    title=${title^}
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


trap _trap_exit EXIT

# Move into website's root folder.
pushd "${0%/*}/../docs" &>/dev/null

readonly _FILE_HOMEPAGE="index.html"
readonly _FILE_ARCHIVE="archive/index.html"
readonly _FILE_ARCHIVE_TAGS="archive/tags/index.html"
readonly _FILE_SITEMAP_XML="sitemap-xml.xml"
readonly _FILE_SITEMAP_TXT="sitemap.txt"

# Parse command line arguments.
while [[ -n $1 ]]; do
    case "$1" in
        -h | --help)
            _help ; exit ;;
        --tags)
            _list_tags ; exit ;;
        --title | --name)
            [[ -z $2 ]] && _die "No title given."
            title="$2"
            shift ;;
        --lang)
            [[ -z $2 ]] && _die "No language given."
            lang="$2"
            shift ;;
        --tag)
            [[ -z $2 ]] && _die "No tag given."
            tag="$2"
            shift ;;
        -f | --file)
            [[ -z $2 ]] && _die "No markdown file given."
            mdfile="$2"
            shift ;;
        *)
            _die "Argument '$1' not recognized." ;;
    esac
    shift
done

_ask_title
_ask_lang
_ask_tag

# Get current date.
# Use English language to get first 3 letters of current month (%b).
LANG=en_us_8859_1
year=$(date +%Y)
curr_datetime=$(date +%Y-%m-%d)
curr_date=$(date +%d' '%b' '%Y)
curr_date=($curr_date)
curr_date=$(echo ${curr_date[@]^})

# Create directory to store posts for this year.
[[ ! -d "archive/$year" ]] && mkdir -p "archive/$year"

# Determine post number by adding 1 to the latest post number. I can't count the
# number of files in the directory in case I delete some of them.
# This also works if the post is the first of a new year (if the folder is
# empty).
latest_post="$(ls archive/$year/ | sort -gr | head -1)"
latest_num="${latest_post#archive/$year/}"
latest_num="${latest_num%.html}"
num="$((latest_num+1))"
post_file="archive/$year/$num.html"
post_filename="archive/$year/$num"
if [[ $latest_num -eq 0 || -z $latest_num ]]; then
    latest_year=$((year-1))
else
    latest_year=$year
fi


################################################################################
###  CREATE FILE
################################################################################

[[ -f $post_file ]] && _die "Post '$post_file' already exists."
__ok_start=1

# Create file from skeleton.
cp skeleton.html "$post_file"
# Set title.
sed "s/TITLE/$title/g" -i "$post_file"
# Set post url.
sed "s|POSTFILENAME|$post_filename|g" -i "$post_file"
# Set language.
sed "s|POSTLANG|$lang|g" -i "$post_file"
# Set publication date.
sed "s/DD MMMM YYYY/$curr_date/g" -i "$post_file"
sed "s/YYYY-MM-DD/$curr_datetime/g" -i "$post_file"
# Set tag.
sed "s/TAG/$tag/g" -i "$post_file"
# Set email subject.
_MAX_MAILSUBJECT_LEN=35
if [ ${#title} -gt $_MAX_MAILSUBJECT_LEN ]; then
    mail_title=$(echo "${title:0:$_MAX_MAILSUBJECT_LEN}" | sed 's/^\(.\{0,'"$_MAX_MAILSUBJECT_LEN"'\}\)[[:space:]].*/\1/')
    mail_title+="..."
fi
mail_title="${mail_title// /%20}"
mail_title="${mail_title//\"/\'}"
query="?subject=Re:%20$mail_title"
sed "s/MAIL-SUBJECT/$query/g" -i "$post_file"

__ok_file_created=1
_print_ok "Create file $post_file."


################################################################################
###  ADD TO /index.html
################################################################################

line="\ \ \ \ \ \ \ \ <li class=\"h-entry\"><time class=\"dt-published\" datetime=\"$curr_datetime\">${curr_date:3:3} ${curr_date::2}</time><a class=\"u-url\" href=\"/$post_filename\"><span class=\"p-name\" lang=\"$lang\">$title</span></a></li>"
line_nr="$(grep -n -m 1 "h-entry" "$_FILE_HOMEPAGE" | cut -d':' -f1)"
sed -i "${line_nr}i\\${line}" "$_FILE_HOMEPAGE"
__ok_add_homepage=1
_print_ok "Add post to $_FILE_HOMEPAGE."

oldest_line="$(grep "h-entry" "$_FILE_HOMEPAGE" | tail -1)"
sed -i "/$(echo $oldest_line | awk -F 'span' '{print $2}' | cut -d'/' -f1)/d" "$_FILE_HOMEPAGE"
__ok_remove_homepage=1
_print_ok "Remove oldest entry from $_FILE_HOMEPAGE."


################################################################################
###  ADD TO /archive/
################################################################################

line="\ \ \ \ \ \ \ \ <li class=\"h-entry $lang\"><time class=\"dt-published\" datetime=\"$curr_datetime\">${curr_date:3:3} ${curr_date::2}</time><a class=\"u-url\" href=\"/$post_filename\"><span class=\"p-name\" lang=\"$lang\">$title</span></a></li>"

# Check if a list of posts for the current year already exists.
if ! grep -n -m 1 "h2>$year" "$_FILE_ARCHIVE" &>/dev/null 2>&1 ; then
    # Insert new list section for current year.
    new_section_string=$"      <section>
      <h2>$year</h2>
      <ul class=\"list posts-list\">
      </ul>
      </section>
"
    # Get line number where to insert this new line: above first <section>
    line_nr="$(grep -n -m 1 "<section>" "$_FILE_ARCHIVE" | cut -d':' -f1)"
    line_nr=$((line_nr-1))
    # To insert multiple lines with sed I need a tmp file.
    tmpfile=$(mktemp)
    printf '%s\n' "$new_section_string" > "$tmpfile"
    sed -i "${line_nr}r $tmpfile" "$_FILE_ARCHIVE"
    rm "$tmpfile"
    # Get line number where to insert new post line: under first <ul> section.
    line_nr="$(grep -n -m 1 " posts-list" "$_FILE_ARCHIVE" | cut -d':' -f1)"
    line_nr=$((line_nr+1))
else
    # Get line number where to insert new post line: 1 line above the first
    # h-entry of current year.
    line_nr="$(grep -n -m 1 "h-entry" "$_FILE_ARCHIVE" | cut -d':' -f1)"
fi
sed -i "${line_nr}i\\${line}" "$_FILE_ARCHIVE"
__ok_add_archive=1
_print_ok "Add post to $_FILE_ARCHIVE."


################################################################################
###  ADD TO /archive/tags/
################################################################################

line="\ \ \ \ \ \ \ \ <li class=\"h-entry $lang\"><a class=\"u-url\" href=\"/$post_filename\"><span class=\"p-name\" lang=\"$lang\">$title</span></a></li>"

# Get line number where to insert this new line: 2 lines below the h2 tag title.
line_nr=$(grep -n "h2 id=\"$tag\"" "$_FILE_ARCHIVE_TAGS" | cut -d':' -f1)
line_nr=$((line_nr+2))
sed -i "$line_nr i ""${line}" "$_FILE_ARCHIVE_TAGS"
__ok_add_archive_tags=1
_print_ok "Add post to $_FILE_ARCHIVE_TAGS."


################################################################################
###  INCREASE TAG COUNT IN /archive/tags/
################################################################################

line_nr_tag="$(grep -n "href=\"#$tag\"" "$_FILE_ARCHIVE_TAGS" | cut -d':' -f1)"
curr_tag_num="$(grep "href=\"#$tag\"" "$_FILE_ARCHIVE_TAGS" | grep -oP "(?<=<sup>)[^<]+")"
new_tag_num=$((curr_tag_num+1))
sed -i "$line_nr_tag""s/$curr_tag_num/$new_tag_num/" "$_FILE_ARCHIVE_TAGS"
__ok_update_tag=1
_print_ok "Update tag count in tags list."


################################################################################
###  ADD prev LINK IN THIS NEW POST
################################################################################

prev_linenr="$(grep -n "Previously</p></div>" "$post_file" | cut -d: -f1)"
prev_line="      <div><p>Previously</p><a href=\"/archive/$latest_year/$latest_num\">$(grep -m 1 post-title "archive/$year/$latest_post" | cut -d'>' -f2 | cut -d'<' -f1)</a></div>"
sed -i "${prev_linenr}s|.*|${prev_line}|" "$post_file"
__ok_link_prev=1
_print_ok "Link to prev post."


################################################################################
###  ADD next LINK IN LAST POST
################################################################################

next_linenr="$(grep -n "prevnext-next" "archive/$latest_year/$latest_post" | cut -d: -f1)"
next_line="      <div class=\"prevnext-next\"><p>Up next</p><a href=\"/archive/$year/$num\">$title</a></div>"
sed -i "${next_linenr}s|.*|${next_line}|" "archive/$latest_year/$latest_post"
__ok_link_next=1
_print_ok "Link to next post."


################################################################################
###  ADD TO SITEMAPS
################################################################################

# Add new post to sitemap(s).
sed -i "/<\/urlset>/d" "$_FILE_SITEMAP_XML"
echo "  <url>" >> "$_FILE_SITEMAP_XML"
echo "    <loc>https://earendelmir.xyz/$post_filename</loc>" >> "$_FILE_SITEMAP_XML"
echo "    <lastmod>$(date -u +"%Y-%m-%d")</lastmod>" >> "$_FILE_SITEMAP_XML"
echo "    <priority>0.80</priority>" >> "$_FILE_SITEMAP_XML"
echo "  </url>" >> "$_FILE_SITEMAP_XML"
echo "</urlset>" >> "$_FILE_SITEMAP_XML"
__ok_add_sitemap_xml=1
_print_ok "Add page to XML sitemap."

echo "https://earendelmir.xyz/$post_filename" >> "$_FILE_SITEMAP_TXT"
__ok_add_sitemap_txt=1
_print_ok "Add page to TXT sitemap."


################################################################################
###  WRITE BODY FROM MARKDOWN FILE
################################################################################

if [[ -n "$mdfile" ]]; then
    ../scripts/marktohtml.sh -f "$mdfile" -q
    __ok_write_body=1
    _print_ok "Write body from MD file."
fi


__ok_all=1
popd &>/dev/null
