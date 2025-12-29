#!/bin/bash
#
# WaterFurnace Aurora Installation Test Script
# Tests all gem dependencies to identify compatibility issues
#
# Usage:
#   ./test_installation.sh
#
# This script will:
#   1. Display system information (Ruby version, platform, etc.)
#   2. Verify the waterfurnace_aurora gem is installed
#   3. Build a complete dependency tree (runtime dependencies only)
#   4. Test each gem individually to identify compatibility issues
#   5. Display a summary of results
#
# Note: set -e is not used because we need to handle signal-based errors
# (like illegal instruction) gracefully without exiting the script

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Arrays to track results
declare -a PASSED_GEMS
declare -a FAILED_GEMS
declare -a ALL_GEMS

# Print functions
print_header() {
    echo -e "\n${BLUE}===================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ ${NC} $1"
}

print_error() {
    echo -e "${RED}✗ ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠ ${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ ${NC} $1"
}

# Test if a gem can be loaded
# Arguments:
#   $1 - gem_name: The name of the gem to test
#   $2 - test_name: Optional display name (defaults to gem_name)
# Returns:
#   0 if gem loads successfully, 1 if it fails
test_gem() {
    local gem_name="$1"
    local test_name="${2:-$gem_name}"
    local require_name="${gem_name}"

    # Special handling for sinatra - require 'sinatra/base' instead of 'sinatra'
    if [ "${gem_name}" = "sinatra" ]; then
        require_name="sinatra/base"
    fi

    # Special handling for digest-crc - require 'digest/crc' instead of 'digest-crc'
    if [ "${gem_name}" = "digest-crc" ]; then
        require_name="digest/crc"
    fi

    # Special handling for rack-session - require 'rack/session' instead of 'rack-session'
    if [ "${gem_name}" = "rack-session" ]; then
        require_name="rack/session"
    fi

    # Run Ruby in a subprocess to isolate crashes (prevents script exit on SIGILL)
    # The & backgrounds the process, and wait captures its exit code
    ruby -e "begin; require '${require_name}'; rescue LoadError; exit 1; end" >/dev/null 2>&1 &
    local pid=$!
    # Redirect stderr on wait to suppress bash's "Illegal instruction" message
    wait $pid 2>/dev/null
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        print_success "${test_name}"
        PASSED_GEMS+=("${test_name}")
        return 0
    else
        print_error "${test_name}"
        FAILED_GEMS+=("${test_name}")
        return 1
    fi
}

# Get gem dependencies recursively
# Arguments:
#   $1 - gem_name: The name of the gem to analyze
#   $2 - indent: Optional indentation string for tree display (default: empty)
# Side effects:
#   Adds dependencies to ALL_GEMS array and prints dependency tree
get_gem_dependencies() {
    local gem_name="$1"
    local indent="${2:-}"

    # Get direct runtime dependencies from 'gem dependency' output
    # - Lines starting with two spaces are dependencies
    # - Exclude development dependencies (lines containing "development")
    local deps=$(gem dependency "$gem_name" 2>/dev/null | grep "^  " | grep -v "development" | sed 's/^  //' | awk '{print $1}')

    for dep in $deps; do
        # Skip if already in list
        if [[ ! " ${ALL_GEMS[@]} " =~ " ${dep} " ]]; then
            ALL_GEMS+=("$dep")
            echo "${indent}${dep}"
            # Recursively get dependencies (with indentation)
            get_gem_dependencies "$dep" "${indent}  "
        fi
    done
}

# Display system information
show_system_info() {
    print_header "System Information"

    echo "Ruby Version:"
    ruby -v
    echo

    echo "RubyGems Version:"
    gem --version
    echo

    echo "Platform:"
    ruby -e "puts RUBY_PLATFORM"
    echo

    if [ -f /proc/device-tree/model ]; then
        echo "Device Model:"
        cat /proc/device-tree/model
        echo
    fi
}

# Check if the waterfurnace_aurora gem is installed
# Returns:
#   0 if installed, 1 if not installed
check_gem_installed() {
    print_header "Checking Gem Installation"

    if gem list -i "^waterfurnace_aurora$" >/dev/null 2>&1; then
        local version=$(gem list waterfurnace_aurora | grep waterfurnace_aurora | sed 's/waterfurnace_aurora (//' | sed 's/)//')
        print_success "WaterFurnace Aurora gem is installed (version: $version)"
        return 0
    else
        print_error "WaterFurnace Aurora gem is NOT installed"
        echo
        print_info "Please run the installation script first:"
        echo "  ./install.sh"
        return 1
    fi
}

# Build and display the complete dependency tree
# Side effects:
#   Populates ALL_GEMS array and displays the tree structure
build_dependency_tree() {
    print_header "Building Dependency Tree"

    print_info "Analyzing waterfurnace_aurora dependencies..."
    echo

    # Initialize with the main gem
    ALL_GEMS=("waterfurnace_aurora")

    # Recursively build dependency tree
    echo "waterfurnace_aurora"
    get_gem_dependencies "waterfurnace_aurora" "  "

    echo
    print_info "Found ${#ALL_GEMS[@]} gems to test (including waterfurnace_aurora)"
}

# Test all gems in the dependency tree
# Side effects:
#   Populates PASSED_GEMS and FAILED_GEMS arrays
test_all_gems() {
    print_header "Testing Gem Loading"

    print_info "Testing each gem individually..."
    echo

    for gem_name in "${ALL_GEMS[@]}"; do
        test_gem "$gem_name"
    done
}

# Display summary of test results
show_results() {
    print_header "Test Results Summary"

    echo "Total gems tested: ${#ALL_GEMS[@]}"
    echo -e "Passed: ${GREEN}${#PASSED_GEMS[@]}${NC}"
    echo -e "Failed: ${RED}${#FAILED_GEMS[@]}${NC}"
    echo

    if [ ${#FAILED_GEMS[@]} -eq 0 ]; then
        print_success "All gems loaded successfully!"
        echo
        print_info "Your installation appears to be working correctly."
    else
        print_error "Some gems failed to load:"
        echo
        for gem in "${FAILED_GEMS[@]}"; do
            echo "  - $gem"
        done
    fi
}

# Main test flow - orchestrates all test steps
main() {
    print_header "WaterFurnace Aurora Installation Test"

    echo "This script will test your WaterFurnace Aurora installation"
    echo "and identify any compatibility issues with gem dependencies."
    echo

    # Step 1: Show system info
    show_system_info

    # Step 2: Verify gem is installed
    if ! check_gem_installed; then
        exit 1
    fi

    # Step 3: Build dependency tree
    build_dependency_tree

    # Step 4: Test all gems
    test_all_gems

    # Step 5: Show results
    show_results

    echo
    print_info "Test complete!"
}

# Run main function
main "$@"
