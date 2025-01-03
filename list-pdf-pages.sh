#!/bin/bash
# from Claude.AI

# Exit on error
set -e

# Check for qpdf
if ! command -v qpdf &> /dev/null; then
    echo "Installing qpdf..."
    brew install qpdf
fi

# Function to get page count of a PDF
get_page_count() {
    local file="$1"
    if [[ -r "$file" ]]; then
        qpdf --show-npages "$file" 2>/dev/null || echo "error"
    else
        echo "unreadable"
    fi
}

# Function to format file size
format_size() {
    local size=$1
    if ((size > 1073741824)); then
        printf "%.1fG" $(echo "scale=1; $size/1073741824" | bc)
    elif ((size > 1048576)); then
        printf "%.1fM" $(echo "scale=1; $size/1048576" | bc)
    elif ((size > 1024)); then
        printf "%.1fK" $(echo "scale=1; $size/1024" | bc)
    else
        echo "${size}B"
    fi
}

# Print header
printf "%-6s %-8s %-50s %s\n" "PAGES" "SIZE" "FILENAME" "PATH"
printf "%s\n" "$(printf '%.0s-' {1..80})"

# Find all PDFs in current directory and subdirectories
find . -type f -iname "*.pdf" | sort | while read -r file; do
    pages=$(get_page_count "$file")
    size=$(format_size $(stat -f %z "$file"))
    filename=$(basename "$file")
    printf "%-6s %-8s %-50.50s %s\n" "$pages" "$size" "$filename" "$file"
done