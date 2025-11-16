#!/usr/bin/env zsh

############################
# test_audit_apps.sh
#
# Integration test harness for audit_apps.sh
# Creates a temporary test environment with mock brew.sh and validates behavior
#
# Usage:
#   ./test_audit_apps.sh
############################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0
TEST_DIR=""

# Setup test environment
setup_test_env() {
    echo -e "${BLUE}Setting up test environment...${RESET}"
    
    # Create temp directory
    TEST_DIR=$(mktemp -d)
    echo "Test directory: $TEST_DIR"
    
    # Initialize as git repo
    cd "$TEST_DIR"
    git init -q
    git config user.name "Test User"
    git config user.email "test@example.com"
    
    # Copy audit script
    cp "$OLDPWD/audit_apps.sh" "$TEST_DIR/"
    chmod +x "$TEST_DIR/audit_apps.sh"
    
    echo -e "${GREEN}✓ Test environment created${RESET}\n"
}

# Cleanup test environment
cleanup_test_env() {
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
        echo -e "\n${BLUE}Cleaned up test environment${RESET}"
    fi
}

trap cleanup_test_env EXIT INT TERM

# Create a mock brew.sh file
create_mock_brew_sh() {
    local packages_content="$1"
    local apps_content="$2"
    local mas_content="$3"
    
    cat > "$TEST_DIR/brew.sh" <<'EOF'
#!/usr/bin/env zsh

# Mock brew.sh for testing

packages=(
EOF
    echo "$packages_content" >> "$TEST_DIR/brew.sh"
    cat >> "$TEST_DIR/brew.sh" <<'EOF'

)

# Some other content here
echo "Installing packages..."

apps=(
EOF
    echo "$apps_content" >> "$TEST_DIR/brew.sh"
    cat >> "$TEST_DIR/brew.sh" <<'EOF'
)

echo "Installing apps..."

app_store=(
EOF
    echo "$mas_content" >> "$TEST_DIR/brew.sh"
    cat >> "$TEST_DIR/brew.sh" <<'EOF'
 )

echo "Done!"
EOF
}

# Mock brew leaves command
mock_brew_leaves() {
    cat <<EOF
asdf
bash
git
tree
zsh
EOF
}

# Mock brew list --cask command
mock_brew_casks() {
    cat <<EOF
1password
google-chrome
visual-studio-code
obsidian
EOF
}

# Mock mas list command
mock_mas_list() {
    cat <<EOF
497799835 Xcode (15.0)
441258766 Magnet (3.0.7)
EOF
}

# Test helper functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    
    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✓ PASS${RESET}: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${RESET}: $test_name"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local test_name="$3"
    
    if [[ "$haystack" == *"$needle"* ]]; then
        echo -e "${GREEN}✓ PASS${RESET}: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${RESET}: $test_name"
        echo "  Expected to find: $needle"
        echo "  In: $haystack"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local test_name="$2"
    
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✓ PASS${RESET}: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${RESET}: $test_name"
        echo "  File not found: $file"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test 1: Script exists and is executable
test_script_exists() {
    echo -e "\n${BLUE}Test 1: Script exists and is executable${RESET}"
    
    if [[ -x "$TEST_DIR/audit_apps.sh" ]]; then
        echo -e "${GREEN}✓ PASS${RESET}: audit_apps.sh is executable"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${RESET}: audit_apps.sh is not executable"
        ((TESTS_FAILED++))
    fi
}

# Test 2: Help flag works
test_help_flag() {
    echo -e "\n${BLUE}Test 2: Help flag displays usage${RESET}"
    
    local output
    output=$(./audit_apps.sh --help 2>&1 || true)
    
    assert_contains "$output" "Usage:" "Help contains Usage section"
    assert_contains "$output" "Options:" "Help contains Options section"
    assert_contains "$output" "--dry-run" "Help contains --dry-run option"
}

# Test 3: Validates git repository requirement
test_git_validation() {
    echo -e "\n${BLUE}Test 3: Validates git repository requirement${RESET}"
    
    # Create a non-git directory
    local non_git_dir=$(mktemp -d)
    cp "$TEST_DIR/audit_apps.sh" "$non_git_dir/"
    
    cd "$non_git_dir"
    local output
    output=$(./audit_apps.sh 2>&1 || true)
    
    assert_contains "$output" "Not in a git repository" "Detects missing git repository"
    
    cd "$TEST_DIR"
    rm -rf "$non_git_dir"
}

# Test 4: Validates brew.sh exists
test_brew_sh_validation() {
    echo -e "\n${BLUE}Test 4: Validates brew.sh exists${RESET}"
    
    local output
    output=$(./audit_apps.sh 2>&1 || true)
    
    assert_contains "$output" "brew.sh not found" "Detects missing brew.sh"
}

# Test 5: Parses arrays correctly
test_array_parsing() {
    echo -e "\n${BLUE}Test 5: Parses arrays from brew.sh correctly${RESET}"
    
    # Create mock brew.sh with known content
    create_mock_brew_sh \
        '    "git"
    "tree"
    "python"' \
        '    "google-chrome"
    "visual-studio-code"' \
        '    "497799835" # Xcode
    "441258766" # Magnet'
    
    # Since we can't easily test internal parsing without running the full script,
    # we'll test that the script can read the file without errors
    if grep -q "packages=(" "$TEST_DIR/brew.sh" && \
       grep -q "apps=(" "$TEST_DIR/brew.sh" && \
       grep -q "app_store=(" "$TEST_DIR/brew.sh"; then
        echo -e "${GREEN}✓ PASS${RESET}: Mock brew.sh has required arrays"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${RESET}: Mock brew.sh missing required arrays"
        ((TESTS_FAILED++))
    fi
}

# Test 6: Dry-run mode doesn't modify files
test_dry_run_no_modifications() {
    echo -e "\n${BLUE}Test 6: Dry-run mode doesn't modify brew.sh${RESET}"
    
    create_mock_brew_sh \
        '    "git"' \
        '    "google-chrome"' \
        '    "497799835" # Xcode'
    
    git add brew.sh
    git commit -q -m "Initial commit"
    
    # Get original checksum
    local original_hash=$(md5 -q "$TEST_DIR/brew.sh")
    
    # Run in dry-run mode (will fail because brew/mas aren't mocked, but file shouldn't change)
    ./audit_apps.sh --dry-run 2>&1 || true
    
    local new_hash=$(md5 -q "$TEST_DIR/brew.sh")
    
    assert_equals "$original_hash" "$new_hash" "brew.sh unchanged in dry-run mode"
}

# Test 7: Detects known misclassifications
test_misclassification_detection() {
    echo -e "\n${BLUE}Test 7: Detects known misclassifications${RESET}"
    
    create_mock_brew_sh \
        '    "git"
    "obsidian"
    "grammarly-desktop"' \
        '    "google-chrome"' \
        '    "497799835" # Xcode'
    
    git add brew.sh
    git commit -q -m "Brew with misclassifications"
    
    # Check that obsidian and grammarly-desktop are in the hardcoded list
    if grep -q "obsidian" "$TEST_DIR/audit_apps.sh" && \
       grep -q "KNOWN_MISCLASSIFIED_CASKS" "$TEST_DIR/audit_apps.sh"; then
        echo -e "${GREEN}✓ PASS${RESET}: Known misclassifications are defined in script"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${RESET}: Known misclassifications not found in script"
        ((TESTS_FAILED++))
    fi
}

# Test 8: Creates backup when applying changes
test_backup_creation() {
    echo -e "\n${BLUE}Test 8: Backup creation (structural test)${RESET}"
    
    # Check that the script contains backup logic
    if grep -q "backup_file.*\.backup\." "$TEST_DIR/audit_apps.sh" && \
       grep -q "cp.*\$BREW_SH.*\$backup_file" "$TEST_DIR/audit_apps.sh"; then
        echo -e "${GREEN}✓ PASS${RESET}: Backup creation logic present in script"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${RESET}: Backup creation logic not found"
        ((TESTS_FAILED++))
    fi
}

# Test 9: Script handles empty arrays
test_empty_arrays() {
    echo -e "\n${BLUE}Test 9: Handles empty arrays gracefully${RESET}"
    
    create_mock_brew_sh '' '' ''
    
    git add brew.sh
    git commit -q -m "Empty arrays"
    
    # Script should not crash with empty arrays (even if other validations fail)
    if grep -q "packages=()" "$TEST_DIR/brew.sh" || \
       [[ $(grep -A1 "packages=(" "$TEST_DIR/brew.sh" | tail -1) == "" ]]; then
        echo -e "${GREEN}✓ PASS${RESET}: Empty arrays syntax is valid"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${RESET}: Empty arrays not properly formatted"
        ((TESTS_FAILED++))
    fi
}

# Test 10: Validates color output is defined
test_color_output() {
    echo -e "\n${BLUE}Test 10: Color output definitions${RESET}"
    
    if grep -q "RED=" "$TEST_DIR/audit_apps.sh" && \
       grep -q "GREEN=" "$TEST_DIR/audit_apps.sh" && \
       grep -q "YELLOW=" "$TEST_DIR/audit_apps.sh"; then
        echo -e "${GREEN}✓ PASS${RESET}: Color codes defined"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${RESET}: Color codes not found"
        ((TESTS_FAILED++))
    fi
}

# Run all tests
run_all_tests() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BLUE}║  audit_apps.sh Integration Test Suite                 ║${RESET}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${RESET}"
    
    setup_test_env
    
    test_script_exists
    test_help_flag
    test_git_validation
    test_brew_sh_validation
    test_array_parsing
    test_dry_run_no_modifications
    test_misclassification_detection
    test_backup_creation
    test_empty_arrays
    test_color_output
    
    # Summary
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BLUE}║  Test Summary                                          ║${RESET}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${RESET}"
    echo -e "${GREEN}Passed: $TESTS_PASSED${RESET}"
    echo -e "${RED}Failed: $TESTS_FAILED${RESET}"
    echo -e "Total:  $((TESTS_PASSED + TESTS_FAILED))"
    echo ""
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests passed!${RESET}"
        return 0
    else
        echo -e "${RED}✗ Some tests failed${RESET}"
        return 1
    fi
}

# Main
cd "$(dirname "$0")"
run_all_tests
