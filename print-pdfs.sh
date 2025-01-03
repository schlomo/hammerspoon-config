#!/bin/bash
# from Claude.AI

set -e  # Exit on error

# Error handling function
error_exit() {
    echo "Error: ${1:-"Unknown Error"}" >&2
    exit 1
}

# Help message
show_help() {
    echo "Usage: $0 [--dry-run] <pdf-file1> [pdf-file2> ...]"
    echo "Options:"
    echo "  --dry-run    Create PDFs with headers but don't print"
    exit 1
}

# Check for required tools
for cmd in qpdf gs; do
    if ! command -v $cmd &> /dev/null; then
        echo "Installing $cmd..."
        brew install $cmd || error_exit "Failed to install $cmd"
    fi
done

# Parse arguments
DRY_RUN=0
PDF_FILES=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *.pdf)
            PDF_FILES+=("$1")
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            show_help
            ;;
    esac
done

# Check if any PDF files were provided
if [ ${#PDF_FILES[@]} -eq 0 ]; then
    show_help
fi

process_pdf() {
    local input_file="$1"
    local filename=$(basename "$input_file")
    local output_dir
    local temp_dir
    
    # Create temp directory for work files
    temp_dir=$(mktemp -d) || error_exit "Failed to create temporary directory"
    trap 'rm -rf -- "$temp_dir"' EXIT
    
    if [ $DRY_RUN -eq 1 ]; then
        output_dir="."
    else
        output_dir="$temp_dir"
    fi
    
    local output_file="${output_dir}/${filename%.pdf}_with_footer.pdf"
    local overlay_ps="${temp_dir}/overlay.ps"
    local overlay_pdf="${temp_dir}/overlay.pdf"
    
    echo "Processing: $filename"
    
    # Verify input file exists and is readable
    [[ -r "$input_file" ]] || error_exit "Cannot read input file: $input_file"
    
    # Get page count
    local pages
    pages=$(qpdf --show-npages "$input_file") || error_exit "Failed to get page count"
    
    # Escape filename for PostScript string
    # Replace parentheses and backslashes with escaped versions
    local ps_filename=${filename//\\/\\\\}
    ps_filename=${ps_filename//\(/\\(}
    ps_filename=${ps_filename//\)/\\)}
    
    # Create PostScript file for footer overlay
    cat > "$overlay_ps" << EOF
%!PS-Adobe-3.0

% Define standard page size if not specified (A4)
/pagewidth 595 def
/pageheight 842 def
/margin 12 def  % 12pt margin from bottom

% Set up initial font and color
/Helvetica findfont 12 scalefont setfont

% Define the text string builder
/maketext {    % page_number => text_string
    20 string cvs
    ($ps_filename - Page ) exch concatstrings
} def

% Function to draw footer
/drawPageFooter {    % pagenum
    % Save state
    gsave
    
    % Set gray color for text
    0.4 setgray
    
    % Create the full text string
    dup maketext
    
    % Get string width for centering
    dup stringwidth pop
    
    % Calculate position
    pagewidth 2 div
    exch 2 div sub
    margin moveto
    
    % Draw the text
    show
    
    grestore
} def

% Process each page
1 1 $pages {
    % Set up the page
    << /PageSize [pagewidth pageheight] >> setpagedevice
    
    % Draw the footer
    dup drawPageFooter
    
    % Output the page
    showpage
} for
EOF


    # Convert PostScript to PDF with better error handling
    if ! gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite \
           -dPDFSETTINGS=/prepress \
           -dCompatibilityLevel=1.4 \
           -sOutputFile="$overlay_pdf" "$overlay_ps"; then
        error_exit "Failed to create overlay PDF. Check PostScript syntax."
    fi
    
    # Verify the overlay PDF was created and is valid
    if [ ! -f "$overlay_pdf" ] || ! qpdf --check "$overlay_pdf" >/dev/null 2>&1; then
        error_exit "Generated overlay PDF is invalid"
    fi
    
    # Combine original PDF with overlay
    qpdf "$input_file" --overlay "$overlay_pdf" -- "$output_file" \
        || error_exit "Failed to apply overlay"
    
    if [ $DRY_RUN -eq 1 ]; then
        echo "✓ Created: $output_file"
    else
        # Print the file double-sided
        if ! lpr -o sides=two-sided-long-edge "$output_file"; then
            error_exit "Failed to send to printer"
        fi
        echo "✓ Printed: $filename"
    fi
}

# Process each PDF file
for pdf in "${PDF_FILES[@]}"; do
    process_pdf "$pdf" || error_exit "Failed to process $pdf"
done

if [ $DRY_RUN -eq 1 ]; then
    echo "All files processed - PDFs created in current directory"
else
    echo "All files processed and sent to printer!"
fi