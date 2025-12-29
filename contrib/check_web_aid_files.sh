#!/bin/bash
#
# Web AID Tool Files Checker
# Validates that all required HTML, CSS, JS, and image files are present
# for the Aurora Web AID Tool
#
# Usage:
#   check_web_aid_files.sh              # Interactive mode with progress
#   check_web_aid_files.sh --quiet      # Automated mode (exit code only)
#   check_web_aid_files.sh --check      # Check mode (prints PASS/FAIL)
#

set -e

# Default to interactive mode
QUIET=false
CHECK_MODE=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --quiet)
            QUIET=true
            ;;
        --check)
            CHECK_MODE=true
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Validates Web AID Tool files are present and complete."
            echo ""
            echo "OPTIONS:"
            echo "  --quiet      Quiet mode (exit code 0=pass, 1=fail)"
            echo "  --check      Check mode (print PASS/FAIL and exit)"
            echo "  -h, --help   Show this help message"
            echo ""
            echo "INTERACTIVE MODE (default):"
            echo "  Shows progress and detailed summary"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Color codes for interactive output
if [ "$QUIET" = false ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Print functions
print_header() {
    if [ "$QUIET" = false ]; then
        echo -e "\n${BLUE}===================================================================${NC}"
        echo -e "${BLUE}$1${NC}"
        echo -e "${BLUE}===================================================================${NC}\n"
    fi
}

print_success() {
    if [ "$QUIET" = false ]; then
        echo -e "${GREEN}✓ ${NC} $1"
    fi
}

print_error() {
    if [ "$QUIET" = false ]; then
        echo -e "${RED}✗ ${NC} $1"
    fi
}

print_warning() {
    if [ "$QUIET" = false ]; then
        echo -e "${YELLOW}⚠ ${NC} $1"
    fi
}

print_info() {
    if [ "$QUIET" = false ]; then
        echo -e "${BLUE}ℹ ${NC} $1"
    fi
}

# Base directory for web aid files
# Can be overridden with WEB_AID_DIR environment variable for testing
WEB_AID_DIR="${WEB_AID_DIR:-$HOME/waterfurnace_aurora/html}"

# Tracking arrays
declare -a MISSING_FILES
declare -a FOUND_FILES
declare -a PARSED_FILES

# Associative arrays to track already-checked files (deduplication)
declare -A CHECKED_FILES
declare -A HTML_QUEUE

# Check if a file exists
check_file() {
    local file="$1"
    local full_path="$WEB_AID_DIR/$file"

    # Skip if already checked (deduplication)
    if [ -n "${CHECKED_FILES[$file]}" ]; then
        return ${CHECKED_FILES[$file]}
    fi

    if [ -f "$full_path" ]; then
        FOUND_FILES+=("$file")
        CHECKED_FILES[$file]=0
        print_success "Found: $file"
        return 0
    else
        MISSING_FILES+=("$file")
        CHECKED_FILES[$file]=1
        print_error "Missing: $file"
        return 1
    fi
}

# Parse HTML file for references
parse_html_file() {
    local file="$1"
    local full_path="$WEB_AID_DIR/$file"

    if [ ! -f "$full_path" ]; then
        print_warning "Cannot parse $file - file not found"
        return 1
    fi

    # Skip if already parsed (deduplication)
    local parsed_check
    for parsed_check in "${PARSED_FILES[@]}"; do
        if [ "$parsed_check" = "$file" ]; then
            return 0
        fi
    done

    PARSED_FILES+=("$file")
    print_info "Parsing: $file"

    # Extract CSS references (link rel="stylesheet")
    local css_files
    css_files=$(grep -oP 'href=["'"'"']\K[^"'"'"']+\.css' "$full_path" 2>/dev/null || true)
    while IFS= read -r css_file; do
        [ -z "$css_file" ] && continue
        # Remove leading slash or ./
        css_file="${css_file#/}"
        css_file="${css_file#./}"
        check_file "$css_file"
    done <<< "$css_files"

    # Extract JavaScript references (script src)
    local js_files
    js_files=$(grep -oP 'src=["'"'"']\K[^"'"'"']+\.js' "$full_path" 2>/dev/null || true)
    while IFS= read -r js_file; do
        [ -z "$js_file" ] && continue
        js_file="${js_file#/}"
        js_file="${js_file#./}"
        check_file "$js_file"
    done <<< "$js_files"

    # Extract image references (img src, various image formats)
    local img_files
    img_files=$(grep -oP 'src=["'"'"']\K[^"'"'"']+\.(png|jpg|jpeg|gif|ico|svg)' "$full_path" 2>/dev/null || true)
    while IFS= read -r img_file; do
        [ -z "$img_file" ] && continue
        img_file="${img_file#/}"
        img_file="${img_file#./}"
        check_file "$img_file"
    done <<< "$img_files"

    # Extract favicon (link rel="icon" or "shortcut icon")
    local ico_files
    ico_files=$(grep -oP 'href=["'"'"']\K[^"'"'"']+\.ico' "$full_path" 2>/dev/null || true)
    while IFS= read -r ico_file; do
        [ -z "$ico_file" ] && continue
        ico_file="${ico_file#/}"
        ico_file="${ico_file#./}"
        check_file "$ico_file"
    done <<< "$ico_files"

    # Extract HTML references (a href, but only .htm or .html files)
    local html_files
    html_files=$(grep -oP 'href=["'"'"']\K[^"'"'"']+\.html?' "$full_path" 2>/dev/null || true)
    while IFS= read -r html_file; do
        [ -z "$html_file" ] && continue
        # Skip external URLs and anchors
        if [[ ! "$html_file" =~ ^http ]] && [[ ! "$html_file" =~ ^# ]]; then
            html_file="${html_file#/}"
            html_file="${html_file#./}"
            if check_file "$html_file"; then
                # Queue HTML file for parsing if it exists and hasn't been queued
                if [ -z "${HTML_QUEUE[$html_file]}" ]; then
                    HTML_QUEUE[$html_file]=1
                fi
            fi
        fi
    done <<< "$html_files"
}

# Main validation flow
main() {
    if [ "$QUIET" = false ]; then
        print_header "Web AID Tool Files Validation"
        echo "Checking directory: $WEB_AID_DIR"
        echo ""
    fi

    # Check if base directory exists
    if [ ! -d "$WEB_AID_DIR" ]; then
        print_error "Web AID directory not found: $WEB_AID_DIR"
        print_info "Run the following commands to download the files:"
        print_info "  mkdir -p ~/waterfurnace_aurora"
        print_info "  cd ~/waterfurnace_aurora"
        print_info "  bash contrib/grab_awl_assets.sh [AWL_IP_ADDRESS]"
        exit 1
    fi

    print_success "Found Web AID directory"
    echo ""

    # Step 1: Check for index.htm
    print_info "Checking for index.htm..."
    if ! check_file "index.htm"; then
        print_error "Critical file missing: index.htm"
        print_info "This is the main entry point for the Web AID Tool"
        exit 1
    fi
    echo ""

    # Step 2: Parse index.htm for references
    print_info "Parsing index.htm for referenced files..."
    parse_html_file "index.htm"
    echo ""

    # Step 2.5: Check for common HTML files that might not be linked from index.htm
    print_info "Checking for additional common files..."
    for common_file in "config.htm" "indexat.htm"; do
        if check_file "$common_file"; then
            # Queue for parsing if not already queued or parsed
            local already_parsed=false
            for parsed in "${PARSED_FILES[@]}"; do
                if [ "$parsed" = "$common_file" ]; then
                    already_parsed=true
                    break
                fi
            done
            if [ "$already_parsed" = false ] && [ -z "${HTML_QUEUE[$common_file]}" ]; then
                HTML_QUEUE[$common_file]=1
            fi
        fi
    done
    echo ""

    # Step 3: Parse all discovered HTML files recursively
    print_info "Parsing discovered HTML files..."
    while [ ${#HTML_QUEUE[@]} -gt 0 ]; do
        # Get first item from queue
        local next_html=""
        for html_file in "${!HTML_QUEUE[@]}"; do
            next_html="$html_file"
            break
        done

        if [ -n "$next_html" ]; then
            unset HTML_QUEUE["$next_html"]
            echo ""
            print_info "Parsing $next_html for additional references..."
            parse_html_file "$next_html"
        fi
    done

    echo ""

    # Summary
    print_header "Validation Summary"

    local total_found=${#FOUND_FILES[@]}
    local total_missing=${#MISSING_FILES[@]}
    local total_files=$((total_found + total_missing))

    echo "Files checked: $total_files"
    echo -e "${GREEN}Files found: $total_found${NC}"

    if [ $total_missing -gt 0 ]; then
        echo -e "${RED}Files missing: $total_missing${NC}"
        echo ""
        print_warning "Missing files:"
        # Files are already deduplicated via CHECKED_FILES, just sort
        for file in "${MISSING_FILES[@]}"; do
            echo "  - $file"
        done | sort
        echo ""
        print_error "VALIDATION FAILED"
        echo ""
        print_info "To download the missing files, run:"
        print_info "  cd ~/waterfurnace_aurora"
        print_info "  bash contrib/grab_awl_assets.sh [AWL_IP_ADDRESS]"
        echo ""

        if [ "$CHECK_MODE" = true ]; then
            echo "FAIL"
        fi
        exit 1
    else
        echo ""
        print_success "VALIDATION PASSED"
        echo ""
        print_info "All required Web AID Tool files are present!"
        print_info "The web interface should work correctly."
        echo ""

        if [ "$CHECK_MODE" = true ]; then
            echo "PASS"
        fi
        exit 0
    fi
}

# Run main function
main "$@"
