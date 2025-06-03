#!/bin/bash

# File:   compressimg.sh
# Author: earendelmir
# Date:   25 Aug 2023
# Brief:  Convert image to webp and resize.


_die() {
    [[ -n $1 ]] && echo "$1" >&2
    exit 1
}

_help() {
    printf "Usage: $(basename $0) IMAGE [OPTION]
Convert image to webp and resize.

-h, --help          Show this guide and exit.
IMAGE               Path to image to compress.
--size WxH          Convert and resize.
--noresize          Do not resize image. (deafult)
"
}


# Parse command-line arguments.
while [[ -n $1 ]]; do
    case "$1" in
        -h | --help)
            _help ; exit ;;
        --size)
            [[ -z "$2" ]] && _die "No size specified."
            size="$2"
            shift ;;
        --noresize)
            noresize=1 ;;
        *)
            if [[ -z "$img" ]]; then
                img="$1"
            else
                _die "Argument '$1' not recognized."
            fi ;;
    esac
    shift
done

[[ -z "$img" ]] && _die "No image given."
[[ ! -f "$img" ]] && _die "Image '$img' does not exist."

img_webp="${img%.*}".webp
cwebp -quiet -preset photo -m 6 "$img" -o "$img_webp" || _die "Could not convert."

[[ -z "$size" || -n $noresize ]] && exit
magick "$img_webp" -resize "$size" "$img_webp" || _die "Could not resize."
