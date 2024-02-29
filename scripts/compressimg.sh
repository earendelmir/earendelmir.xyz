#!/bin/bash

# File:   compressimg.sh
# Author: earendelmir
# Date:   25 Aug 2023
# Brief:  Resize image and convet it to webp format.


_die() {
    [[ -n $1 ]] && echo "$1" >&2
    exit 1
}

_help() {
    printf "Usage: $(basename $0) IMAGE [OPTION]...
Resize image and convet it to webp format.

-h, --help          Show this guide and exit.
IMAGE               Path to image to compress.
--size WxH          New size. Default is 300x300.
--noresize          Do not resize image. Only convert to webp.
"
}


# Parse command-line arguments.
while [[ -n $1 ]]; do
    case "$1" in
        -h | --help)
            _help ; exit ;;
        --size)
            if [[ -z "$2" ]]; then
                _die "No size specified."
            fi
            size="$2"
            shift ; shift ;;
        --noresize)
            noresize=1
            shift ;;
        *)
            if [[ -z "$img" ]]; then
                img="$1"
                shift
            else
                _die "Argument '$1' not recognized."
            fi ;;
    esac
done

[[ -z "$img" ]] && _die "No image given."
[[ ! -f "$img" ]] && _die "Image '$img' does not exist."

[[ -z "$size" ]] && size="300x300"


# Resize.
if [[ -z $noresize ]]; then
    if ! convert "$img" -resize "$size" "$img" ; then
        _die "Could not resize img."
    fi
fi

# Convert to WEBP.
cwebp -quiet -preset photo -m 6 "$img" -o "${img%.*}".webp
