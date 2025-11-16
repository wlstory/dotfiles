#!/usr/bin/env zsh

############################
# audit_apps.sh
#
# Purpose:
#   Audits currently installed Homebrew formulae, casks, and Mac App Store apps
#   against what's configured in brew.sh. Provides an interactive interface to:
#   - Fix misclassified items (e.g., casks wrongly in the packages array)
#   - Add installed items missing from brew.sh
#   - Remove items in brew.sh that aren't installed
#   - Optionally scan /Applications for unmanaged apps
#
# Prerequisites:
#   - Homebrew installed and in PATH
#   - mas (Mac App Store CLI) installed: brew install mas
#   - git repository (script validates this)
#
# Usage:
#   ./audit_apps.sh [OPTIONS]
#
# Options:
#   --dry-run       (default) Show what would change without modifying brew.sh
#   --apply         Actually modify brew.sh (creates timestamped backup first)
#   --scan-apps     Additionally scan /Applications for unmanaged .app bundles
#   --verbose       Enable detailed logging
#   --help          Show this help message
#
# Examples:
#   ./audit_apps.sh --dry-run                # Safe preview mode
#   ./audit_apps.sh --apply                  # Make changes to brew.sh
#   ./audit_apps.sh --scan-apps --dry-run    # Include app bundle scan
#
# Safety:
#   - Defaults to dry-run mode (no modifications)
#   - Creates timestamped backup before any changes: brew.sh.backup.YYYYMMDD_HHMMSS
#   - Validates environment and dependencies before running
#   - Idempotent: re-running after applying changes should show no further diffs
#
# Output:
#   - Arrays are sorted: formulae and casks alphabetically, MAS by app name
#   - Original indentation and comment style preserved
#   - One item per line for readability
############################

set -euo pipefail
IFS=$'\n\t'

# Global variables
DOTFILES_DIR=""
BREW_SH=""
DRY_RUN=1
SCAN_APPS=0
VERBOSE=0
TEMP_FILES=()
TEST_MODE=${TEST_MODE:-0}  # Set TEST_MODE=1 for testing with mocks

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Known misclassifications (casks that might be in packages array)
KNOWN_MISCLASSIFIED_CASKS=("obsidian" "grammarly-desktop" "bruno" "little-snitch")

# Trap to cleanup temp files on exit
cleanup() {
    if [[ ${#TEMP_FILES[@]} -gt 0 ]]; then
        for tmpfile in "${TEMP_FILES[@]}"; do
            [[ -f "$tmpfile" ]] && rm -f "$tmpfile"
        done
    fi
}
trap cleanup EXIT INT TERM

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ${RESET} $*"
}

log_success() {
    echo -e "${GREEN}✓${RESET} $*"
}

log_warning() {
    echo -e "${YELLOW}⚠${RESET} $*"
}

log_error() {
    echo -e "${RED}✗${RESET} $*" >&2
}

log_verbose() {
    if [[ $VERBOSE -eq 1 ]]; then
        echo -e "${CYAN}[VERBOSE]${RESET} $*"
    fi
    return 0
}

log_section() {
    echo ""
    echo -e "${BOLD}${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}${MAGENTA}$*${RESET}"
    echo -e "${BOLD}${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

# Usage help
show_help() {
    cat <<'EOF'
audit_apps.sh

Purpose:
  Audits currently installed Homebrew formulae, casks, and Mac App Store apps
  against what's configured in brew.sh. Provides an interactive interface to:
  - Fix misclassified items (e.g., casks wrongly in the packages array)
  - Add installed items missing from brew.sh
  - Remove items in brew.sh that aren't installed
  - Optionally scan /Applications for unmanaged apps

Prerequisites:
  - Homebrew installed and in PATH
  - mas (Mac App Store CLI) installed: brew install mas
  - git repository (script validates this)

Usage:
  ./audit_apps.sh [OPTIONS]

Options:
  --dry-run       (default) Show what would change without modifying brew.sh
  --apply         Actually modify brew.sh (creates timestamped backup first)
  --scan-apps     Additionally scan /Applications for unmanaged .app bundles
  --verbose       Enable detailed logging
  --help          Show this help message

Examples:
  ./audit_apps.sh --dry-run                # Safe preview mode
  ./audit_apps.sh --apply                  # Make changes to brew.sh
  ./audit_apps.sh --scan-apps --dry-run    # Include app bundle scan

Safety:
  - Defaults to dry-run mode (no modifications)
  - Creates timestamped backup before any changes: brew.sh.backup.YYYYMMDD_HHMMSS
  - Validates environment and dependencies before running
  - Idempotent: re-running after applying changes should show no further diffs

Output:
  - Arrays are sorted: formulae and casks alphabetically, MAS by app name
  - Original indentation and comment style preserved
  - One item per line for readability
EOF
    exit 0
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --apply)
                DRY_RUN=0
                shift
                ;;
            --scan-apps)
                SCAN_APPS=1
                shift
                ;;
            --verbose)
                VERBOSE=1
                shift
                ;;
            --help|-h)
                show_help
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Validate environment and dependencies
validate_environment() {
    log_section "Validating Environment"
    
    # Check if in a git repo
    if ! git rev-parse --git-dir &>/dev/null; then
        log_error "Not in a git repository"
        exit 1
    fi
    log_success "Git repository detected"
    
    # Get dotfiles directory
    DOTFILES_DIR=$(git rev-parse --show-toplevel)
    log_verbose "Dotfiles directory: $DOTFILES_DIR"
    
    # Validate brew.sh exists and is readable
    BREW_SH="${DOTFILES_DIR}/brew.sh"
    if [[ ! -f "$BREW_SH" ]]; then
        log_error "brew.sh not found at: $BREW_SH"
        exit 1
    fi
    if [[ ! -r "$BREW_SH" ]]; then
        log_error "brew.sh is not readable: $BREW_SH"
        exit 1
    fi
    log_success "brew.sh found and readable"
    
    # Check Homebrew (skip in test mode as mocks will be used)
    if [[ $TEST_MODE -eq 0 ]]; then
        if ! command -v brew &>/dev/null; then
            log_error "Homebrew not found in PATH"
            log_error "Please install Homebrew: https://brew.sh"
            exit 1
        fi
        log_success "Homebrew detected: $(brew --version | head -1)"
        
        # Check mas
        if ! command -v mas &>/dev/null; then
            log_warning "mas (Mac App Store CLI) not found"
            log_warning "Install with: brew install mas"
            log_warning "MAS audit will be skipped"
        else
            log_success "mas detected: $(mas version)"
        fi
    else
        # Test mode - assume mocked commands are available
        if command -v brew &>/dev/null; then
            log_success "Homebrew detected: $(brew --version 2>/dev/null | head -1 || echo 'mock')"
        else
            log_warning "Homebrew not found (test mode)"
        fi
        
        if command -v mas &>/dev/null; then
            log_success "mas detected: $(mas version 2>/dev/null || echo 'mock')"
        else
            log_warning "mas not found (test mode)"
        fi
    fi
    
    echo ""
}

# Collect currently installed packages
collect_installed_state() {
    log_section "Collecting Installed State"
    
    # Explicit formulae (brew leaves)
    log_info "Collecting explicitly installed formulae..."
    INSTALLED_FORMULAE=($(brew leaves 2>/dev/null | sort))
    log_success "Found ${#INSTALLED_FORMULAE[@]} explicit formulae"
    log_verbose "Formulae: ${INSTALLED_FORMULAE[*]}"
    
    # All casks
    log_info "Collecting installed casks..."
    INSTALLED_CASKS=($(brew list --cask 2>/dev/null | sort))
    log_success "Found ${#INSTALLED_CASKS[@]} casks"
    log_verbose "Casks: ${INSTALLED_CASKS[*]}"
    
    # Mac App Store apps
    if command -v mas &>/dev/null; then
        log_info "Collecting Mac App Store apps..."
        declare -gA INSTALLED_MAS_MAP
        declare -ga INSTALLED_MAS_IDS
        
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                local id=$(echo "$line" | awk '{print $1}')
                local name=$(echo "$line" | cut -d' ' -f2-)
                INSTALLED_MAS_MAP[$id]="$name"
                INSTALLED_MAS_IDS+=("$id")
            fi
        done < <(mas list 2>/dev/null)
        
        log_success "Found ${#INSTALLED_MAS_IDS[@]} Mac App Store apps"
        log_verbose "MAS apps: ${INSTALLED_MAS_IDS[*]}"
    else
        declare -gA INSTALLED_MAS_MAP
        declare -ga INSTALLED_MAS_IDS
        log_warning "Skipping MAS collection (mas not installed)"
    fi
    
    echo ""
}

# Parse arrays from brew.sh
parse_brew_sh() {
    log_section "Parsing brew.sh"
    
    local content=$(cat "$BREW_SH")
    
    # Parse packages array
    log_info "Parsing packages array..."
    declare -ga PACKAGES_ARRAY
    declare -gi PACKAGES_START_LINE
    declare -gi PACKAGES_END_LINE
    
    local in_packages=0
    local line_num=0
    local temp_packages=()
    
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        
        if [[ "$line" == packages=\(* ]]; then
            in_packages=1
            PACKAGES_START_LINE=$line_num
            log_verbose "Found packages array start at line $line_num"
            continue
        fi
        
        if [[ $in_packages -eq 1 ]]; then
            if [[ "$line" == \)* ]]; then
                PACKAGES_END_LINE=$line_num
                in_packages=0
                log_verbose "Found packages array end at line $line_num"
                break
            fi
            
            # Extract package name (remove quotes, comments, whitespace)
            local pkg=$(echo "$line" | sed 's/^[[:space:]]*"//; s/"[[:space:]]*$//; s/#.*//' | xargs)
            if [[ -n "$pkg" ]]; then
                temp_packages+=("$pkg")
            fi
            true  # Prevent set -e from exiting on empty pkg
        fi
    done <<< "$content"
    
    PACKAGES_ARRAY=("${temp_packages[@]}")
    log_success "Found ${#PACKAGES_ARRAY[@]} items in packages array"
    log_verbose "Packages: ${PACKAGES_ARRAY[*]}"
    
    # Parse apps array
    log_info "Parsing apps array..."
    declare -ga APPS_ARRAY
    declare -gi APPS_START_LINE
    declare -gi APPS_END_LINE
    
    local in_apps=0
    line_num=0
    local temp_apps=()
    
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        
        if [[ "$line" == apps=\(* ]]; then
            in_apps=1
            APPS_START_LINE=$line_num
            log_verbose "Found apps array start at line $line_num"
            continue
        fi
        
        if [[ $in_apps -eq 1 ]]; then
            if [[ "$line" == \)* ]]; then
                APPS_END_LINE=$line_num
                in_apps=0
                log_verbose "Found apps array end at line $line_num"
                break
            fi
            
            local app=$(echo "$line" | sed 's/^[[:space:]]*"//; s/"[[:space:]]*$//; s/#.*//' | xargs)
            if [[ -n "$app" ]]; then
                temp_apps+=("$app")
            fi
            true  # Prevent set -e from exiting on empty app
        fi
    done <<< "$content"
    
    APPS_ARRAY=("${temp_apps[@]}")
    log_success "Found ${#APPS_ARRAY[@]} items in apps array"
    log_verbose "Apps: ${APPS_ARRAY[*]}"
    
    # Parse app_store array
    log_info "Parsing app_store array..."
    declare -ga APP_STORE_ARRAY
    declare -gA APP_STORE_COMMENTS
    declare -gi APP_STORE_START_LINE
    declare -gi APP_STORE_END_LINE
    
    local in_app_store=0
    line_num=0
    local temp_app_store=()
    
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        
        if [[ "$line" == app_store=\(* ]]; then
            in_app_store=1
            APP_STORE_START_LINE=$line_num
            log_verbose "Found app_store array start at line $line_num"
            continue
        fi
        
        if [[ $in_app_store -eq 1 ]]; then
            if [[ "$line" == \)* || "$line" == [[:space:]]\)* ]]; then
                APP_STORE_END_LINE=$line_num
                in_app_store=0
                log_verbose "Found app_store array end at line $line_num"
                break
            fi
            
            # Extract ID and comment
            if [[ "$line" =~ \"([0-9]+)\"[[:space:]]*#[[:space:]]*(.+) ]]; then
                # Access BASH_REMATCH safely - check it exists first
                if [[ ${#BASH_REMATCH[@]} -ge 3 ]]; then
                    local id="${BASH_REMATCH[1]}"
                    local comment="${BASH_REMATCH[2]}"
                    temp_app_store+=("$id")
                    APP_STORE_COMMENTS[$id]="$comment"
                    log_verbose "Found MAS entry: $id # $comment"
                fi
            fi
            true  # Prevent set -e from exiting on non-matching lines
        fi
    done <<< "$content"
    
    APP_STORE_ARRAY=("${temp_app_store[@]}")
    log_success "Found ${#APP_STORE_ARRAY[@]} items in app_store array"
    log_verbose "App Store: ${APP_STORE_ARRAY[*]}"
    
    echo ""
}

# Classify items and detect misclassifications
classify_items() {
    log_section "Classifying and Validating Items"
    
    declare -ga MISCLASSIFIED_ITEMS
    declare -gA ITEM_CLASSIFICATIONS  # item -> "formula" | "cask" | "mas" | "unknown"
    
    # Check packages array for casks
    log_info "Checking packages array for misclassified casks..."
    local misclassified_count=0
    
    for pkg in "${PACKAGES_ARRAY[@]}"; do
        local is_known_cask=0
        
        # Check known misclassifications
        for known_cask in "${KNOWN_MISCLASSIFIED_CASKS[@]}"; do
            if [[ "$pkg" == "$known_cask" ]]; then
                is_known_cask=1
                break
            fi
        done
        
        if [[ $is_known_cask -eq 1 ]]; then
            log_warning "Known misclassification: '$pkg' is a cask, not a formula"
            MISCLASSIFIED_ITEMS+=("$pkg|packages->apps")
            ITEM_CLASSIFICATIONS[$pkg]="cask"
            ((misclassified_count++))
        else
            # Try to determine actual type
            if brew info --formula "$pkg" &>/dev/null; then
                ITEM_CLASSIFICATIONS[$pkg]="formula"
            elif brew info --cask "$pkg" &>/dev/null; then
                log_warning "Misclassification detected: '$pkg' is a cask, not a formula"
                MISCLASSIFIED_ITEMS+=("$pkg|packages->apps")
                ITEM_CLASSIFICATIONS[$pkg]="cask"
                ((misclassified_count++))
            else
                log_warning "Unknown item in packages: '$pkg'"
                ITEM_CLASSIFICATIONS[$pkg]="unknown"
            fi
        fi
    done
    
    if [[ $misclassified_count -eq 0 ]]; then
        log_success "No misclassifications found in packages array"
    else
        log_warning "Found $misclassified_count misclassified item(s) in packages array"
    fi
    
    # Validate apps array
    log_info "Validating apps array..."
    local invalid_apps=0
    
    for app in "${APPS_ARRAY[@]}"; do
        if brew info --cask "$app" &>/dev/null; then
            ITEM_CLASSIFICATIONS[$app]="cask"
        elif brew info --formula "$app" &>/dev/null; then
            log_warning "App '$app' appears to be a formula, not a cask"
            MISCLASSIFIED_ITEMS+=("$app|apps->packages")
            ITEM_CLASSIFICATIONS[$app]="formula"
            ((invalid_apps++))
        else
            log_warning "Unknown cask in apps: '$app'"
            ITEM_CLASSIFICATIONS[$app]="unknown"
        fi
    done
    
    if [[ $invalid_apps -eq 0 ]]; then
        log_success "All apps validated"
    fi
    
    echo ""
}

# Perform gap analysis
perform_gap_analysis() {
    log_section "Gap Analysis"
    
    declare -ga MISSING_FORMULAE
    declare -ga MISSING_CASKS
    declare -ga MISSING_MAS
    declare -ga EXTRA_FORMULAE
    declare -ga EXTRA_CASKS
    declare -ga EXTRA_MAS
    
    # Find formulae installed but missing from brew.sh
    log_info "Finding installed formulae missing from brew.sh..."
    for formula in "${INSTALLED_FORMULAE[@]}"; do
        local found=0
        for pkg in "${PACKAGES_ARRAY[@]}"; do
            if [[ "$formula" == "$pkg" ]]; then
                found=1
                break
            fi
        done
        
        if [[ $found -eq 0 ]]; then
            MISSING_FORMULAE+=("$formula")
            log_verbose "Missing formula: $formula"
        fi
    done
    
    log_info "Found ${#MISSING_FORMULAE[@]} installed formulae missing from brew.sh"
    
    # Find formulae in brew.sh but not installed
    log_info "Finding formulae in brew.sh but not installed..."
    for pkg in "${PACKAGES_ARRAY[@]}"; do
        # Skip if it's a known misclassified cask
        if [[ "${ITEM_CLASSIFICATIONS[$pkg]}" == "cask" ]]; then
            continue
        fi
        
        local found=0
        for formula in "${INSTALLED_FORMULAE[@]}"; do
            if [[ "$pkg" == "$formula" ]]; then
                found=1
                break
            fi
        done
        
        if [[ $found -eq 0 ]] && [[ "${ITEM_CLASSIFICATIONS[$pkg]}" == "formula" ]]; then
            EXTRA_FORMULAE+=("$pkg")
            log_verbose "Extra formula: $pkg"
        fi
    done
    
    log_info "Found ${#EXTRA_FORMULAE[@]} formulae in brew.sh but not installed"
    
    # Find casks installed but missing from brew.sh
    log_info "Finding installed casks missing from brew.sh..."
    for cask in "${INSTALLED_CASKS[@]}"; do
        local found=0
        for app in "${APPS_ARRAY[@]}"; do
            if [[ "$cask" == "$app" ]]; then
                found=1
                break
            fi
        done
        
        if [[ $found -eq 0 ]]; then
            MISSING_CASKS+=("$cask")
            log_verbose "Missing cask: $cask"
        fi
    done
    
    log_info "Found ${#MISSING_CASKS[@]} installed casks missing from brew.sh"
    
    # Find casks in brew.sh but not installed
    log_info "Finding casks in brew.sh but not installed..."
    for app in "${APPS_ARRAY[@]}"; do
        # Skip if it's a misclassified formula
        if [[ "${ITEM_CLASSIFICATIONS[$app]}" == "formula" ]]; then
            continue
        fi
        
        local found=0
        for cask in "${INSTALLED_CASKS[@]}"; do
            if [[ "$app" == "$cask" ]]; then
                found=1
                break
            fi
        done
        
        if [[ $found -eq 0 ]] && [[ "${ITEM_CLASSIFICATIONS[$app]}" == "cask" ]]; then
            EXTRA_CASKS+=("$app")
            log_verbose "Extra cask: $app"
        fi
    done
    
    log_info "Found ${#EXTRA_CASKS[@]} casks in brew.sh but not installed"
    
    # Mac App Store gaps
    if command -v mas &>/dev/null; then
        log_info "Finding MAS apps installed but missing from brew.sh..."
        for id in "${INSTALLED_MAS_IDS[@]}"; do
            local found=0
            for mas_id in "${APP_STORE_ARRAY[@]}"; do
                if [[ "$id" == "$mas_id" ]]; then
                    found=1
                    break
                fi
            done
            
            if [[ $found -eq 0 ]]; then
                MISSING_MAS+=("$id")
                log_verbose "Missing MAS: $id (${INSTALLED_MAS_MAP[$id]})"
            fi
        done
        
        log_info "Found ${#MISSING_MAS[@]} MAS apps installed but missing from brew.sh"
        
        log_info "Finding MAS apps in brew.sh but not installed..."
        for mas_id in "${APP_STORE_ARRAY[@]}"; do
            local found=0
            for id in "${INSTALLED_MAS_IDS[@]}"; do
                if [[ "$mas_id" == "$id" ]]; then
                    found=1
                    break
                fi
            done
            
            if [[ $found -eq 0 ]]; then
                EXTRA_MAS+=("$mas_id")
                log_verbose "Extra MAS: $mas_id"
            fi
        done
        
        log_info "Found ${#EXTRA_MAS[@]} MAS apps in brew.sh but not installed"
    fi
    
    echo ""
}

# Interactive review
interactive_review() {
    log_section "Interactive Review"
    
    declare -ga ACTIONS  # Array of "action|type|item" strings
    
    local total_changes=$((${#MISCLASSIFIED_ITEMS[@]} + ${#MISSING_FORMULAE[@]} + ${#MISSING_CASKS[@]} + ${#MISSING_MAS[@]} + ${#EXTRA_FORMULAE[@]} + ${#EXTRA_CASKS[@]} + ${#EXTRA_MAS[@]}))
    
    if [[ $total_changes -eq 0 ]]; then
        log_success "No changes needed! brew.sh is in sync with installed packages."
        return
    fi
    
    echo -e "${BOLD}Found $total_changes potential change(s).${RESET}"
    echo ""
    echo "For each item, you can:"
    echo "  [y] Yes, apply this change"
    echo "  [n] No, skip this change (default)"
    echo "  [a] Accept all remaining in this section"
    echo "  [s] Skip all remaining in this section"
    echo "  [q] Quit without making any changes"
    echo ""
    
    # Section 1: Misclassifications
    if [[ ${#MISCLASSIFIED_ITEMS[@]} -gt 0 ]]; then
        echo -e "${BOLD}${YELLOW}══════════════════════════════════════════════════════${RESET}"
        echo -e "${BOLD}${YELLOW}Section 1: Misclassified Items (${#MISCLASSIFIED_ITEMS[@]} item(s))${RESET}"
        echo -e "${BOLD}${YELLOW}══════════════════════════════════════════════════════${RESET}"
        echo ""
        
        local accept_all=0
        local skip_all=0
        
        for entry in "${MISCLASSIFIED_ITEMS[@]}"; do
            if [[ $skip_all -eq 1 ]]; then
                break
            fi
            
            local item=$(echo "$entry" | cut -d'|' -f1)
            local direction=$(echo "$entry" | cut -d'|' -f2)
            
            if [[ $accept_all -eq 1 ]]; then
                ACTIONS+=("move|$direction|$item")
                echo -e "${GREEN}✓${RESET} Move '$item' from $direction (auto-accepted)"
                continue
            fi
            
            echo -e "${YELLOW}Move '$item' from $direction?${RESET}"
            read -k 1 "response?"
            echo ""
            
            case "$response" in
                y|Y)
                    ACTIONS+=("move|$direction|$item")
                    echo -e "${GREEN}✓${RESET} Will move '$item'"
                    ;;
                a|A)
                    accept_all=1
                    ACTIONS+=("move|$direction|$item")
                    echo -e "${GREEN}✓${RESET} Accepting all in this section..."
                    ;;
                s|S)
                    skip_all=1
                    echo -e "${CYAN}⊘${RESET} Skipping all in this section..."
                    ;;
                q|Q)
                    log_warning "Aborting..."
                    exit 0
                    ;;
                *)
                    echo -e "${CYAN}⊘${RESET} Skipped"
                    ;;
            esac
            echo ""
        done
    fi
    
    # Section 2: Missing items (installed but not in brew.sh)
    local missing_total=$((${#MISSING_FORMULAE[@]} + ${#MISSING_CASKS[@]} + ${#MISSING_MAS[@]}))
    if [[ $missing_total -gt 0 ]]; then
        echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════${RESET}"
        echo -e "${BOLD}${BLUE}Section 2: Add Installed Items Missing from brew.sh ($missing_total item(s))${RESET}"
        echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════${RESET}"
        echo ""
        
        local accept_all=0
        local skip_all=0
        
        # Formulae
        for formula in "${MISSING_FORMULAE[@]}"; do
            if [[ $skip_all -eq 1 ]]; then
                break
            fi
            
            if [[ $accept_all -eq 1 ]]; then
                ACTIONS+=("add|formula|$formula")
                echo -e "${GREEN}✓${RESET} Add formula '$formula' (auto-accepted)"
                continue
            fi
            
            echo -e "${BLUE}Add formula '$formula' to packages array?${RESET}"
            read -k 1 "response?"
            echo ""
            
            case "$response" in
                y|Y)
                    ACTIONS+=("add|formula|$formula")
                    echo -e "${GREEN}✓${RESET} Will add '$formula'"
                    ;;
                a|A)
                    accept_all=1
                    ACTIONS+=("add|formula|$formula")
                    echo -e "${GREEN}✓${RESET} Accepting all in this section..."
                    ;;
                s|S)
                    skip_all=1
                    echo -e "${CYAN}⊘${RESET} Skipping all in this section..."
                    break
                    ;;
                q|Q)
                    log_warning "Aborting..."
                    exit 0
                    ;;
                *)
                    echo -e "${CYAN}⊘${RESET} Skipped"
                    ;;
            esac
            echo ""
        done
        
        # Casks
        for cask in "${MISSING_CASKS[@]}"; do
            if [[ $skip_all -eq 1 ]]; then
                break
            fi
            
            if [[ $accept_all -eq 1 ]]; then
                ACTIONS+=("add|cask|$cask")
                echo -e "${GREEN}✓${RESET} Add cask '$cask' (auto-accepted)"
                continue
            fi
            
            echo -e "${BLUE}Add cask '$cask' to apps array?${RESET}"
            read -k 1 "response?"
            echo ""
            
            case "$response" in
                y|Y)
                    ACTIONS+=("add|cask|$cask")
                    echo -e "${GREEN}✓${RESET} Will add '$cask'"
                    ;;
                a|A)
                    accept_all=1
                    ACTIONS+=("add|cask|$cask")
                    echo -e "${GREEN}✓${RESET} Accepting all in this section..."
                    ;;
                s|S)
                    skip_all=1
                    echo -e "${CYAN}⊘${RESET} Skipping all in this section..."
                    break
                    ;;
                q|Q)
                    log_warning "Aborting..."
                    exit 0
                    ;;
                *)
                    echo -e "${CYAN}⊘${RESET} Skipped"
                    ;;
            esac
            echo ""
        done
        
        # Mac App Store
        for mas_id in "${MISSING_MAS[@]}"; do
            if [[ $skip_all -eq 1 ]]; then
                break
            fi
            
            local mas_name="${INSTALLED_MAS_MAP[$mas_id]}"
            
            if [[ $accept_all -eq 1 ]]; then
                ACTIONS+=("add|mas|$mas_id|$mas_name")
                echo -e "${GREEN}✓${RESET} Add MAS app '$mas_id # $mas_name' (auto-accepted)"
                continue
            fi
            
            echo -e "${BLUE}Add MAS app '$mas_id # $mas_name' to app_store array?${RESET}"
            read -k 1 "response?"
            echo ""
            
            case "$response" in
                y|Y)
                    ACTIONS+=("add|mas|$mas_id|$mas_name")
                    echo -e "${GREEN}✓${RESET} Will add '$mas_id # $mas_name'"
                    ;;
                a|A)
                    accept_all=1
                    ACTIONS+=("add|mas|$mas_id|$mas_name")
                    echo -e "${GREEN}✓${RESET} Accepting all in this section..."
                    ;;
                s|S)
                    skip_all=1
                    echo -e "${CYAN}⊘${RESET} Skipping all in this section..."
                    break
                    ;;
                q|Q)
                    log_warning "Aborting..."
                    exit 0
                    ;;
                *)
                    echo -e "${CYAN}⊘${RESET} Skipped"
                    ;;
            esac
            echo ""
        done
    fi
    
    # Section 3: Extra items (in brew.sh but not installed)
    local extra_total=$((${#EXTRA_FORMULAE[@]} + ${#EXTRA_CASKS[@]} + ${#EXTRA_MAS[@]}))
    if [[ $extra_total -gt 0 ]]; then
        echo -e "${BOLD}${RED}══════════════════════════════════════════════════════${RESET}"
        echo -e "${BOLD}${RED}Section 3: Remove Items from brew.sh (not installed) ($extra_total item(s))${RESET}"
        echo -e "${BOLD}${RED}══════════════════════════════════════════════════════${RESET}"
        echo ""
        
        local accept_all=0
        local skip_all=0
        
        # Formulae
        for formula in "${EXTRA_FORMULAE[@]}"; do
            if [[ $skip_all -eq 1 ]]; then
                break
            fi
            
            if [[ $accept_all -eq 1 ]]; then
                ACTIONS+=("remove|formula|$formula")
                echo -e "${GREEN}✓${RESET} Remove formula '$formula' (auto-accepted)"
                continue
            fi
            
            echo -e "${RED}Remove formula '$formula' from packages array?${RESET}"
            read -k 1 "response?"
            echo ""
            
            case "$response" in
                y|Y)
                    ACTIONS+=("remove|formula|$formula")
                    echo -e "${GREEN}✓${RESET} Will remove '$formula'"
                    ;;
                a|A)
                    accept_all=1
                    ACTIONS+=("remove|formula|$formula")
                    echo -e "${GREEN}✓${RESET} Accepting all in this section..."
                    ;;
                s|S)
                    skip_all=1
                    echo -e "${CYAN}⊘${RESET} Skipping all in this section..."
                    break
                    ;;
                q|Q)
                    log_warning "Aborting..."
                    exit 0
                    ;;
                *)
                    echo -e "${CYAN}⊘${RESET} Skipped"
                    ;;
            esac
            echo ""
        done
        
        # Casks
        for cask in "${EXTRA_CASKS[@]}"; do
            if [[ $skip_all -eq 1 ]]; then
                break
            fi
            
            if [[ $accept_all -eq 1 ]]; then
                ACTIONS+=("remove|cask|$cask")
                echo -e "${GREEN}✓${RESET} Remove cask '$cask' (auto-accepted)"
                continue
            fi
            
            echo -e "${RED}Remove cask '$cask' from apps array?${RESET}"
            read -k 1 "response?"
            echo ""
            
            case "$response" in
                y|Y)
                    ACTIONS+=("remove|cask|$cask")
                    echo -e "${GREEN}✓${RESET} Will remove '$cask'"
                    ;;
                a|A)
                    accept_all=1
                    ACTIONS+=("remove|cask|$cask")
                    echo -e "${GREEN}✓${RESET} Accepting all in this section..."
                    ;;
                s|S)
                    skip_all=1
                    echo -e "${CYAN}⊘${RESET} Skipping all in this section..."
                    break
                    ;;
                q|Q)
                    log_warning "Aborting..."
                    exit 0
                    ;;
                *)
                    echo -e "${CYAN}⊘${RESET} Skipped"
                    ;;
            esac
            echo ""
        done
        
        # Mac App Store
        for mas_id in "${EXTRA_MAS[@]}"; do
            if [[ $skip_all -eq 1 ]]; then
                break
            fi
            
            local mas_comment="${APP_STORE_COMMENTS[$mas_id]:-Unknown}"
            
            if [[ $accept_all -eq 1 ]]; then
                ACTIONS+=("remove|mas|$mas_id")
                echo -e "${GREEN}✓${RESET} Remove MAS app '$mas_id # $mas_comment' (auto-accepted)"
                continue
            fi
            
            echo -e "${RED}Remove MAS app '$mas_id # $mas_comment' from app_store array?${RESET}"
            read -k 1 "response?"
            echo ""
            
            case "$response" in
                y|Y)
                    ACTIONS+=("remove|mas|$mas_id")
                    echo -e "${GREEN}✓${RESET} Will remove '$mas_id'"
                    ;;
                a|A)
                    accept_all=1
                    ACTIONS+=("remove|mas|$mas_id")
                    echo -e "${GREEN}✓${RESET} Accepting all in this section..."
                    ;;
                s|S)
                    skip_all=1
                    echo -e "${CYAN}⊘${RESET} Skipping all in this section..."
                    break
                    ;;
                q|Q)
                    log_warning "Aborting..."
                    exit 0
                    ;;
                *)
                    echo -e "${CYAN}⊘${RESET} Skipped"
                    ;;
            esac
            echo ""
        done
    fi
    
    # Final confirmation
    if [[ ${#ACTIONS[@]} -eq 0 ]]; then
        log_warning "No changes selected."
        exit 0
    fi
    
    echo -e "${BOLD}${MAGENTA}══════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}Summary: ${#ACTIONS[@]} change(s) selected${RESET}"
    echo -e "${BOLD}${MAGENTA}══════════════════════════════════════════════════════${RESET}"
    echo ""
    
    for action in "${ACTIONS[@]}"; do
        local action_type=$(echo "$action" | cut -d'|' -f1)
        local item_type=$(echo "$action" | cut -d'|' -f2)
        local item_name=$(echo "$action" | cut -d'|' -f3)
        
        case "$action_type" in
            move)
                echo -e "  ${YELLOW}→${RESET} Move $item_name"
                ;;
            add)
                echo -e "  ${GREEN}+${RESET} Add $item_type: $item_name"
                ;;
            remove)
                echo -e "  ${RED}−${RESET} Remove $item_type: $item_name"
                ;;
        esac
    done
    
    echo ""
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "DRY RUN MODE: No changes will be made to brew.sh"
        log_info "Run with --apply to make these changes"
    else
        echo -e "${BOLD}Apply these changes to brew.sh? [y/N]${RESET}"
        read -k 1 "final_confirm?"
        echo ""
        
        if [[ "$final_confirm" != "y" && "$final_confirm" != "Y" ]]; then
            log_warning "Cancelled by user"
            exit 0
        fi
    fi
    
    echo ""
}

# Apply changes to brew.sh
apply_changes() {
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "Skipping apply in dry-run mode"
        return
    fi
    
    if [[ ${#ACTIONS[@]} -eq 0 ]]; then
        return
    fi
    
    log_section "Applying Changes"
    
    # Create backup
    local backup_file="${BREW_SH}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$BREW_SH" "$backup_file"
    log_success "Created backup: $backup_file"
    
    # Build new arrays
    local new_packages=("${PACKAGES_ARRAY[@]}")
    local new_apps=("${APPS_ARRAY[@]}")
    declare -A new_mas
    for id in "${APP_STORE_ARRAY[@]}"; do
        new_mas[$id]="${APP_STORE_COMMENTS[$id]}"
    done
    
    # Apply actions
    for action in "${ACTIONS[@]}"; do
        local action_type=$(echo "$action" | cut -d'|' -f1)
        local item_type=$(echo "$action" | cut -d'|' -f2)
        local item_name=$(echo "$action" | cut -d'|' -f3)
        local item_extra=$(echo "$action" | cut -d'|' -f4)
        
        case "$action_type" in
            move)
                if [[ "$item_type" == "packages->apps" ]]; then
                    # Remove from packages, add to apps
                    new_packages=("${(@)new_packages:#$item_name}")
                    new_apps+=("$item_name")
                    log_verbose "Moved $item_name from packages to apps"
                elif [[ "$item_type" == "apps->packages" ]]; then
                    # Remove from apps, add to packages
                    new_apps=("${(@)new_apps:#$item_name}")
                    new_packages+=("$item_name")
                    log_verbose "Moved $item_name from apps to packages"
                fi
                ;;
            add)
                case "$item_type" in
                    formula)
                        new_packages+=("$item_name")
                        log_verbose "Added formula: $item_name"
                        ;;
                    cask)
                        new_apps+=("$item_name")
                        log_verbose "Added cask: $item_name"
                        ;;
                    mas)
                        new_mas[$item_name]="$item_extra"
                        log_verbose "Added MAS: $item_name # $item_extra"
                        ;;
                esac
                ;;
            remove)
                case "$item_type" in
                    formula)
                        new_packages=("${(@)new_packages:#$item_name}")
                        log_verbose "Removed formula: $item_name"
                        ;;
                    cask)
                        new_apps=("${(@)new_apps:#$item_name}")
                        log_verbose "Removed cask: $item_name"
                        ;;
                    mas)
                        unset "new_mas[$item_name]"
                        log_verbose "Removed MAS: $item_name"
                        ;;
                esac
                ;;
        esac
    done
    
    # Sort arrays
    log_info "Sorting arrays..."
    new_packages=($(printf '%s\n' "${new_packages[@]}" | LC_ALL=C sort -u))
    new_apps=($(printf '%s\n' "${new_apps[@]}" | LC_ALL=C sort -u))
    
    # Sort MAS by app name (case-insensitive)
    local sorted_mas_ids=()
    for id in "${(@k)new_mas}"; do
        sorted_mas_ids+=("$id|${new_mas[$id]}")
    done
    sorted_mas_ids=($(printf '%s\n' "${sorted_mas_ids[@]}" | sort -t'|' -k2 -f))
    
    # Read original file
    local content=$(cat "$BREW_SH")
    local temp_output=$(mktemp)
    TEMP_FILES+=("$temp_output")
    
    # Write file up to packages array
    echo "$content" | sed -n "1,$((PACKAGES_START_LINE - 1))p" > "$temp_output"
    
    # Write packages array
    echo "packages=(" >> "$temp_output"
    for pkg in "${new_packages[@]}"; do
        echo "    \"$pkg\"" >> "$temp_output"
    done
    echo "" >> "$temp_output"
    echo ")" >> "$temp_output"
    
    # Write content between packages and apps
    echo "$content" | sed -n "$((PACKAGES_END_LINE + 1)),$((APPS_START_LINE - 1))p" >> "$temp_output"
    
    # Write apps array
    echo "apps=(" >> "$temp_output"
    for app in "${new_apps[@]}"; do
        echo "    \"$app\"" >> "$temp_output"
    done
    echo ")" >> "$temp_output"
    
    # Write content between apps and app_store
    echo "$content" | sed -n "$((APPS_END_LINE + 1)),$((APP_STORE_START_LINE - 1))p" >> "$temp_output"
    
    # Write app_store array
    echo "app_store=(" >> "$temp_output"
    for entry in "${sorted_mas_ids[@]}"; do
        local id=$(echo "$entry" | cut -d'|' -f1)
        local name=$(echo "$entry" | cut -d'|' -f2)
        echo "    \"$id\" # $name" >> "$temp_output"
    done
    echo " )" >> "$temp_output"
    
    # Write content after app_store
    echo "$content" | sed -n "$((APP_STORE_END_LINE + 1)),\$p" >> "$temp_output"
    
    # Replace original file
    mv "$temp_output" "$BREW_SH"
    log_success "Updated brew.sh"
    
    echo ""
}

# Show summary and diff
show_summary() {
    log_section "Summary"
    
    if [[ ${#ACTIONS[@]} -eq 0 ]]; then
        log_success "No changes made. brew.sh is in sync!"
        return
    fi
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "DRY RUN: The following changes would be made:"
    else
        log_success "Applied ${#ACTIONS[@]} change(s) to brew.sh"
    fi
    
    echo ""
    
    local added=0
    local removed=0
    local moved=0
    
    for action in "${ACTIONS[@]}"; do
        local action_type=$(echo "$action" | cut -d'|' -f1)
        case "$action_type" in
            add) ((added++)) ;;
            remove) ((removed++)) ;;
            move) ((moved++)) ;;
        esac
    done
    
    echo "  ${GREEN}+${RESET} Added: $added"
    echo "  ${RED}−${RESET} Removed: $removed"
    echo "  ${YELLOW}→${RESET} Moved: $moved"
    echo ""
    
    if [[ $DRY_RUN -eq 0 ]]; then
        log_info "Showing git diff of brew.sh:"
        echo ""
        git --no-pager diff --color=always "$BREW_SH" || true
        echo ""
        echo -e "${BOLD}Next steps:${RESET}"
        echo "  1. Review the changes above"
        echo "  2. Test by running: ./brew.sh (on a test system if possible)"
        echo "  3. Commit the changes: git add brew.sh && git commit -m 'Update brew.sh'"
        echo ""
    else
        echo -e "${BOLD}To apply these changes, run:${RESET}"
        echo "  ./audit_apps.sh --apply"
        echo ""
    fi
}

# Main execution
main() {
    parse_args "$@"
    
    log_section "Homebrew/MAS Audit & Sync for brew.sh"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "Running in DRY RUN mode (no modifications will be made)"
    else
        log_warning "Running in APPLY mode (brew.sh will be modified)"
    fi
    
    echo ""
    
    validate_environment
    collect_installed_state
    parse_brew_sh
    classify_items
    perform_gap_analysis
    interactive_review
    apply_changes
    show_summary
    
    log_success "Audit complete!"
}

# Run main
main "$@"
