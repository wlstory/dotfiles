#!/usr/bin/env bats

# Unit tests for audit_apps.sh using bats-core
# Run with: bats test/audit_apps.bats

# Setup runs before each test
setup() {
    # Create temporary test directory
    export TEST_DIR="$(mktemp -d)"
    export AUDIT_SCRIPT="${BATS_TEST_DIRNAME}/../audit_apps.sh"
    export TEST_MODE=1  # Enable test mode for mocked commands
    
    # Initialize git repo in test directory
    cd "$TEST_DIR"
    git init -q
    git config user.name "Test User"
    git config user.email "test@example.com"
    
    # Create a minimal mock brew.sh
    cat > "$TEST_DIR/brew.sh" <<'EOF'
#!/usr/bin/env zsh
packages=(
    "git"
    "tree"
)

apps=(
    "google-chrome"
    "visual-studio-code"
)

app_store=(
    "497799835" # Xcode
)
EOF
    
    git add brew.sh
    git commit -q -m "Initial brew.sh"
}

# Teardown runs after each test
teardown() {
    if [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

# Helper to create mock commands
create_mock_brew() {
    mkdir -p "$TEST_DIR/bin"
    cat > "$TEST_DIR/bin/brew" <<'EOF'
#!/usr/bin/env zsh
case "$1" in
    --version)
        echo "Homebrew 4.0.0"
        ;;
    leaves)
        echo "git"
        echo "tree"
        echo "node"
        ;;
    list)
        if [[ "$2" == "--cask" ]]; then
            echo "google-chrome"
            echo "visual-studio-code"
            echo "obsidian"
        else
            echo "git"
            echo "tree"
        fi
        ;;
    info)
        if [[ "$2" == "--formula" && "$3" == "obsidian" ]]; then
            exit 1
        elif [[ "$2" == "--cask" && "$3" == "obsidian" ]]; then
            echo "obsidian: 1.0.0"
            exit 0
        elif [[ "$2" == "--formula" && "$3" == "git" ]]; then
            echo "git: stable 2.43.0"
            exit 0
        elif [[ "$2" == "--cask" && "$3" == "google-chrome" ]]; then
            echo "google-chrome: latest"
            exit 0
        else
            exit 1
        fi
        ;;
esac
EOF
    chmod +x "$TEST_DIR/bin/brew"
    export PATH="$TEST_DIR/bin:$PATH"
}

create_mock_mas() {
    mkdir -p "$TEST_DIR/bin"
    cat > "$TEST_DIR/bin/mas" <<'EOF'
#!/usr/bin/env zsh
case "$1" in
    version)
        echo "1.8.6"
        ;;
    list)
        echo "497799835 Xcode (15.0)"
        echo "441258766 Magnet (3.0.7)"
        ;;
esac
EOF
    chmod +x "$TEST_DIR/bin/mas"
    export PATH="$TEST_DIR/bin:$PATH"
}

# ================================================================================
# Test Suite 1: Command-line Argument Parsing
# ================================================================================

@test "Script exits with status 0 on --help flag" {
    run "$AUDIT_SCRIPT" --help
    [ "$status" -eq 0 ]
}

@test "Help output contains usage information" {
    run "$AUDIT_SCRIPT" --help
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "--dry-run" ]]
    [[ "$output" =~ "--apply" ]]
}

@test "Script accepts --dry-run flag without error" {
    create_mock_brew
    create_mock_mas
    run "$AUDIT_SCRIPT" --dry-run
    # Script may fail on other validations but should accept the flag
    [[ ! "$output" =~ "Unknown option: --dry-run" ]]
}

@test "Script accepts --apply flag without error" {
    create_mock_brew
    create_mock_mas
    run "$AUDIT_SCRIPT" --apply
    [[ ! "$output" =~ "Unknown option: --apply" ]]
}

@test "Script accepts --verbose flag without error" {
    create_mock_brew
    create_mock_mas
    run "$AUDIT_SCRIPT" --verbose --dry-run
    [[ ! "$output" =~ "Unknown option: --verbose" ]]
}

@test "Script rejects unknown flags" {
    run "$AUDIT_SCRIPT" --unknown-flag
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Unknown option" ]]
}

@test "Script accepts multiple flags" {
    create_mock_brew
    create_mock_mas
    run "$AUDIT_SCRIPT" --dry-run --verbose
    [[ ! "$output" =~ "Unknown option" ]]
}

# ================================================================================
# Test Suite 2: Environment Validation
# ================================================================================

@test "Script detects when not in a git repository" {
    # Create non-git directory
    local non_git_dir="$(mktemp -d)"
    cd "$non_git_dir"
    
    run "$AUDIT_SCRIPT"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Not in a git repository" ]]
    
    rm -rf "$non_git_dir"
}

@test "Script detects git repository correctly" {
    create_mock_brew
    create_mock_mas
    
    run "$AUDIT_SCRIPT" --dry-run
    [[ "$output" =~ "Git repository detected" ]]
}

@test "Script fails when brew.sh is missing" {
    rm "$TEST_DIR/brew.sh"
    
    run "$AUDIT_SCRIPT"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "brew.sh not found" ]]
}

@test "Script detects brew.sh successfully" {
    create_mock_brew
    create_mock_mas
    
    run "$AUDIT_SCRIPT" --dry-run
    [[ "$output" =~ "brew.sh found and readable" ]]
}

@test "Script warns when mas is not installed" {
    create_mock_brew
    # Don't create mock mas
    
    run "$AUDIT_SCRIPT" --dry-run
    [[ "$output" =~ "mas" ]] && [[ "$output" =~ "not found" ]]
}

# ================================================================================
# Test Suite 3: Array Parsing from brew.sh
# ================================================================================

@test "Script parses packages array correctly" {
    create_mock_brew
    create_mock_mas
    
    run "$AUDIT_SCRIPT" --dry-run --verbose
    [[ "$output" =~ "Found 2 items in packages array" ]]
}

@test "Script parses apps array correctly" {
    create_mock_brew
    create_mock_mas
    
    run "$AUDIT_SCRIPT" --dry-run --verbose
    [[ "$output" =~ "Found 2 items in apps array" ]]
}

@test "Script parses app_store array correctly" {
    create_mock_brew
    create_mock_mas
    
    run "$AUDIT_SCRIPT" --dry-run --verbose
    [[ "$output" =~ "Found 1 items in app_store array" ]]
}

@test "Script handles empty packages array" {
    cat > "$TEST_DIR/brew.sh" <<'EOF'
#!/usr/bin/env zsh
packages=(
)

apps=(
    "google-chrome"
)

app_store=(
)
EOF
    git add brew.sh
    git commit -q -m "Empty packages"
    
    create_mock_brew
    create_mock_mas
    
    run "$AUDIT_SCRIPT" --dry-run --verbose
    [[ "$output" =~ "Found 0 items in packages array" ]]
}

@test "Script handles comments in arrays" {
    cat > "$TEST_DIR/brew.sh" <<'EOF'
#!/usr/bin/env zsh
packages=(
    "git"      # Version control
    "tree"     # Directory listing
)

apps=(
    "google-chrome"
)

app_store=(
    "497799835" # Xcode
)
EOF
    git add brew.sh
    git commit -q -m "Arrays with comments"
    
    create_mock_brew
    create_mock_mas
    
    run "$AUDIT_SCRIPT" --dry-run --verbose
    # Should parse items, ignoring comments
    [[ "$output" =~ "Found 2 items in packages array" ]]
}

# ================================================================================
# Test Suite 4: Misclassification Detection
# ================================================================================

@test "Script detects obsidian as misclassified cask in packages" {
    cat > "$TEST_DIR/brew.sh" <<'EOF'
#!/usr/bin/env zsh
packages=(
    "git"
    "obsidian"
)

apps=(
    "google-chrome"
)

app_store=(
)
EOF
    git add brew.sh
    git commit -q -m "Misclassified obsidian"
    
    create_mock_brew
    create_mock_mas
    
    run "$AUDIT_SCRIPT" --dry-run
    [[ "$output" =~ "obsidian" ]] && [[ "$output" =~ "misclassifi" ]]
}

@test "Script detects grammarly-desktop as misclassified" {
    cat > "$TEST_DIR/brew.sh" <<'EOF'
#!/usr/bin/env zsh
packages=(
    "git"
    "grammarly-desktop"
)

apps=(
)

app_store=(
)
EOF
    git add brew.sh
    git commit -q -m "Misclassified grammarly"
    
    create_mock_brew
    create_mock_mas
    
    run "$AUDIT_SCRIPT" --dry-run
    [[ "$output" =~ "grammarly-desktop" ]] && [[ "$output" =~ "cask" ]]
}

@test "Script has KNOWN_MISCLASSIFIED_CASKS array defined" {
    run grep -q "KNOWN_MISCLASSIFIED_CASKS" "$AUDIT_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "KNOWN_MISCLASSIFIED_CASKS contains obsidian" {
    run grep "KNOWN_MISCLASSIFIED_CASKS" "$AUDIT_SCRIPT"
    [[ "$output" =~ "obsidian" ]]
}

@test "KNOWN_MISCLASSIFIED_CASKS contains bruno" {
    run grep "KNOWN_MISCLASSIFIED_CASKS" "$AUDIT_SCRIPT"
    [[ "$output" =~ "bruno" ]]
}

@test "KNOWN_MISCLASSIFIED_CASKS contains little-snitch" {
    run grep "KNOWN_MISCLASSIFIED_CASKS" "$AUDIT_SCRIPT"
    [[ "$output" =~ "little-snitch" ]]
}

# ================================================================================
# Test Suite 5: Gap Analysis
# ================================================================================

@test "Script detects installed formulae missing from brew.sh" {
    # Mock brew shows node installed, but brew.sh doesn't have it
    create_mock_brew
    create_mock_mas
    
    run "$AUDIT_SCRIPT" --dry-run
    [[ "$output" =~ "installed formulae missing from brew.sh" ]]
}

@test "Script detects installed casks missing from brew.sh" {
    # Mock brew shows obsidian installed, but brew.sh doesn't have it
    create_mock_brew
    create_mock_mas
    
    run "$AUDIT_SCRIPT" --dry-run
    [[ "$output" =~ "installed casks missing from brew.sh" ]]
}

@test "Script detects MAS apps missing from brew.sh" {
    # Mock mas shows Magnet installed, but brew.sh doesn't have it
    create_mock_brew
    create_mock_mas
    
    run "$AUDIT_SCRIPT" --dry-run
    [[ "$output" =~ "MAS apps installed but missing from brew.sh" ]]
}

# ================================================================================
# Test Suite 6: Dry-run Safety
# ================================================================================

@test "Dry-run mode does not modify brew.sh" {
    create_mock_brew
    create_mock_mas
    
    # Get checksum before
    local checksum_before=$(md5 -q "$TEST_DIR/brew.sh")
    
    run "$AUDIT_SCRIPT" --dry-run
    
    # Get checksum after
    local checksum_after=$(md5 -q "$TEST_DIR/brew.sh")
    
    [ "$checksum_before" = "$checksum_after" ]
}

@test "Dry-run mode displays no changes will be made message" {
    create_mock_brew
    create_mock_mas
    
    run "$AUDIT_SCRIPT" --dry-run
    [[ "$output" =~ "DRY RUN" ]] || [[ "$output" =~ "dry-run" ]]
}

@test "Dry-run does not create backup files" {
    create_mock_brew
    create_mock_mas
    
    run "$AUDIT_SCRIPT" --dry-run
    
    # No backup files should exist
    run find "$TEST_DIR" -name "brew.sh.backup.*"
    [ -z "$output" ]
}

# ================================================================================
# Test Suite 7: Backup Creation
# ================================================================================

@test "Script contains backup creation logic" {
    run grep -q "backup_file.*\.backup\." "$AUDIT_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "Backup uses timestamp format" {
    run grep "backup_file.*date.*%Y%m%d_%H%M%S" "$AUDIT_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "Script copies brew.sh to backup before modification" {
    run grep -q 'cp.*BREW_SH.*backup' "$AUDIT_SCRIPT"
    [ "$status" -eq 0 ]
}

# ================================================================================
# Test Suite 8: Output and Logging
# ================================================================================

@test "Script has color codes defined" {
    run grep -q "RED=" "$AUDIT_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "Script has logging functions" {
    run grep -q "log_info()" "$AUDIT_SCRIPT"
    [ "$status" -eq 0 ]
    
    run grep -q "log_success()" "$AUDIT_SCRIPT"
    [ "$status" -eq 0 ]
    
    run grep -q "log_warning()" "$AUDIT_SCRIPT"
    [ "$status" -eq 0 ]
    
    run grep -q "log_error()" "$AUDIT_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "Script has verbose logging function" {
    run grep -q "log_verbose()" "$AUDIT_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "Verbose logging respects VERBOSE flag" {
    run grep -A2 "log_verbose()" "$AUDIT_SCRIPT"
    [[ "$output" =~ "VERBOSE" ]]
}

# ================================================================================
# Test Suite 9: Error Handling
# ================================================================================

@test "Script uses set -euo pipefail for error handling" {
    run head -50 "$AUDIT_SCRIPT"
    [[ "$output" =~ "set -euo pipefail" ]]
}

@test "Script has cleanup trap defined" {
    run grep -q "trap cleanup" "$AUDIT_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "Cleanup function removes temporary files" {
    run grep -A5 "cleanup()" "$AUDIT_SCRIPT"
    [[ "$output" =~ "TEMP_FILES" ]] && [[ "$output" =~ "rm" ]]
}

# ================================================================================
# Test Suite 10: Script Structure
# ================================================================================

@test "Script has proper shebang" {
    run head -1 "$AUDIT_SCRIPT"
    [[ "$output" =~ "#!/usr/bin/env zsh" ]]
}

@test "Script has main() function" {
    run grep -q "^main()" "$AUDIT_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "Script calls main at the end" {
    run tail -5 "$AUDIT_SCRIPT"
    [[ "$output" =~ 'main "$@"' ]] || [[ "$output" =~ "main \"\$@\"" ]]
}

@test "Script has validate_environment function" {
    run grep -q "validate_environment()" "$AUDIT_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "Script has collect_installed_state function" {
    run grep -q "collect_installed_state()" "$AUDIT_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "Script has parse_brew_sh function" {
    run grep -q "parse_brew_sh()" "$AUDIT_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "Script has classify_items function" {
    run grep -q "classify_items()" "$AUDIT_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "Script has perform_gap_analysis function" {
    run grep -q "perform_gap_analysis()" "$AUDIT_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "Script has interactive_review function" {
    run grep -q "interactive_review()" "$AUDIT_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "Script has apply_changes function" {
    run grep -q "apply_changes()" "$AUDIT_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "Script has show_summary function" {
    run grep -q "show_summary()" "$AUDIT_SCRIPT"
    [ "$status" -eq 0 ]
}

# ================================================================================
# Test Suite 11: Array Sorting Logic
# ================================================================================

@test "Script sorts packages array" {
    run grep -q "sort.*packages" "$AUDIT_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "Script sorts apps array" {
    run grep -q "sort.*apps" "$AUDIT_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "Script uses LC_ALL=C for consistent sorting" {
    run grep "sort" "$AUDIT_SCRIPT"
    [[ "$output" =~ "LC_ALL=C" ]]
}

# ================================================================================
# Test Suite 12: Interactive Prompts
# ================================================================================

@test "Interactive review has accept all option" {
    run grep -A20 "interactive_review()" "$AUDIT_SCRIPT"
    [[ "$output" =~ "accept" ]] || [[ "$output" =~ "[a]" ]]
}

@test "Interactive review has skip option" {
    run grep -A20 "interactive_review()" "$AUDIT_SCRIPT"
    [[ "$output" =~ "skip" ]] || [[ "$output" =~ "[s]" ]] || [[ "$output" =~ "[n]" ]]
}

@test "Interactive review has quit option" {
    run grep -A20 "interactive_review()" "$AUDIT_SCRIPT"
    [[ "$output" =~ "quit" ]] || [[ "$output" =~ "[q]" ]]
}

@test "Script has final confirmation before applying" {
    run grep -B5 -A5 "apply_changes" "$AUDIT_SCRIPT"
    [[ "$output" =~ "confirm" ]] || [[ "$output" =~ "Apply" ]]
}
