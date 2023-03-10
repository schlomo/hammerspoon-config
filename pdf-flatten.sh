#!/usr/bin/env bash
# found at https://superuser.com/a/1588781 and slightly modified

set -e -u -o pipefail

function die() {
    echo 1>&2 "ERROR: $*"
    exit 1
}

function file_size() {
    result=($(du -h "$1"))
    echo "$result" # return first word
}

LF=$'\n'
(($# == 1)) || test -s "${1:-}" || die "Usage: $0 <PDF File>$LF Replace PDF with rasterized to 300dpi file"

pdf_file="$1"
shift
tmp_file=$(mktemp)
trap 'rm -f "$tmp_file"' EXIT

old_size=$(file_size "$pdf_file")

echo "Creating raster version... (in $tmp_file)"
convert -render -density 300 "$pdf_file" "$tmp_file"
echo "Optimizing to shrink pdf file..."
gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$pdf_file" "$tmp_file"
echo "Rasterized $pdf_file ($old_size -> $(file_size "$pdf_file"))"
