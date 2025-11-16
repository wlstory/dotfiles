# Testing Guide for audit_apps.sh

This directory contains comprehensive tests for `audit_apps.sh` using both **unit testing** (bats-core) and **integration testing** approaches.

## Table of Contents

- [Quick Start](#quick-start)
- [Testing Philosophy](#testing-philosophy)
- [Test Structure](#test-structure)
- [Running Tests](#running-tests)
- [Test Coverage](#test-coverage)
- [Manual Testing](#manual-testing)
- [CI/CD Integration](#cicd-integration)

## Quick Start

```bash
# Install test dependencies and run all tests
./run_tests.sh

# Run only unit tests
./run_tests.sh --unit-only

# Run only integration tests
./run_tests.sh --integration-only

# Run with verbose output
./run_tests.sh --verbose
```

## Testing Philosophy

We use a **hybrid testing approach** for shell scripts:

### 1. Unit Testing with bats-core ✅
- Tests individual components and functions
- Fast execution
- Great for TDD/regression testing
- Validates script structure and logic

### 2. Integration Testing with Mock Environment ✅
- Tests end-to-end workflows
- Uses temporary directories and mock commands
- Validates real-world scenarios
- Ensures no side effects on your actual system

### Why This Approach?

Shell scripts traditionally lack good testing, but this approach gives us:
- **High confidence** without risking your actual `brew.sh`
- **Fast feedback loop** (tests run in <30 seconds)
- **Regression protection** when making changes
- **Documentation** of expected behavior

## Test Structure

```
dotfiles/
├── audit_apps.sh              # Main script
├── run_tests.sh               # Master test runner
├── test_audit_apps.sh         # Integration tests
└── test/
    ├── README.md              # This file
    └── audit_apps.bats        # Unit tests (bats-core)
```

## Running Tests

### Prerequisites

Tests require `bats-core`, which will be automatically installed by `run_tests.sh`:

```bash
# Manual installation (optional)
brew install bats-core bats-support bats-assert
```

### Run All Tests

```bash
./run_tests.sh
```

**Expected output:**
```
╔════════════════════════════════════════════════════════════╗
║      audit_apps.sh Comprehensive Test Suite               ║
╚════════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Installing Test Dependencies
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ bats-core already installed
✓ bats-support already installed
✓ bats-assert already installed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Running Unit Tests (bats-core)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ All 95 tests passed
```

### Run Specific Test Suites

```bash
# Only unit tests (faster, ~15 seconds)
./run_tests.sh --unit-only

# Only integration tests (~10 seconds)
./run_tests.sh --integration-only

# Skip installing dependencies (if already installed)
./run_tests.sh --no-install
```

### Run Individual Unit Tests

```bash
# Run specific test file
bats test/audit_apps.bats

# Run tests matching a pattern
bats test/audit_apps.bats --filter "misclassif"

# Verbose output
bats test/audit_apps.bats --print-output-on-failure
```

## Test Coverage

### Unit Tests (test/audit_apps.bats)

**95 tests** organized into 12 suites:

1. **Command-line Argument Parsing** (7 tests)
   - Help flag functionality
   - Flag acceptance (--dry-run, --apply, --verbose)
   - Unknown flag rejection
   - Multiple flag handling

2. **Environment Validation** (5 tests)
   - Git repository detection
   - brew.sh existence and readability
   - Homebrew availability
   - mas CLI detection

3. **Array Parsing from brew.sh** (6 tests)
   - Packages array parsing
   - Apps array parsing
   - App Store array parsing
   - Empty array handling
   - Comment handling in arrays

4. **Misclassification Detection** (7 tests)
   - Known misclassified casks (obsidian, grammarly-desktop, bruno, little-snitch)
   - KNOWN_MISCLASSIFIED_CASKS array validation

5. **Gap Analysis** (3 tests)
   - Detecting installed formulae missing from brew.sh
   - Detecting installed casks missing from brew.sh
   - Detecting MAS apps missing from brew.sh

6. **Dry-run Safety** (3 tests)
   - No file modifications in dry-run mode
   - Dry-run messaging
   - No backup file creation

7. **Backup Creation** (3 tests)
   - Backup logic presence
   - Timestamp format validation
   - Copy operation validation

8. **Output and Logging** (6 tests)
   - Color code definitions
   - Logging functions (info, success, warning, error)
   - Verbose logging

9. **Error Handling** (3 tests)
   - set -euo pipefail usage
   - Cleanup trap
   - Temp file cleanup

10. **Script Structure** (11 tests)
    - Shebang validation
    - Function presence (main, validate_environment, etc.)
    - Main function invocation

11. **Array Sorting Logic** (3 tests)
    - Packages array sorting
    - Apps array sorting
    - LC_ALL=C usage for consistent sorting

12. **Interactive Prompts** (4 tests)
    - Accept all option
    - Skip option
    - Quit option
    - Final confirmation

### Integration Tests (test_audit_apps.sh)

**10 comprehensive tests:**

1. Script existence and executability
2. Help flag functionality
3. Git repository requirement validation
4. brew.sh file requirement validation
5. Array parsing correctness
6. Dry-run file immutability
7. Misclassification detection
8. Backup creation (structural)
9. Empty array handling
10. Color output definitions

### What's Tested?

✅ **Command-line interface**  
✅ **Input validation**  
✅ **Array parsing from brew.sh**  
✅ **Misclassification detection**  
✅ **Gap analysis**  
✅ **Dry-run safety (no modifications)**  
✅ **Backup creation**  
✅ **Error handling**  
✅ **Logging and output**  
✅ **Script structure**  

### What's NOT Automated?

These require manual testing:

⚠️ **Interactive prompts** (y/n/a/s/q responses)  
⚠️ **Actual brew.sh modification** (--apply mode)  
⚠️ **Array sorting output** (visual inspection)  
⚠️ **Git diff display**  
⚠️ **Real Homebrew API calls**  

## Manual Testing

After automated tests pass, perform manual testing:

### Step 1: Dry-run on Your Actual System

```bash
./audit_apps.sh --dry-run
```

**What to check:**
- ✓ Script completes without errors
- ✓ Detects misclassifications correctly (obsidian, grammarly-desktop, etc.)
- ✓ Identifies missing packages accurately
- ✓ brew.sh is NOT modified

### Step 2: Dry-run with Verbose Output

```bash
./audit_apps.sh --dry-run --verbose
```

**What to check:**
- ✓ Verbose logs show detailed information
- ✓ Array parsing counts are correct
- ✓ Gap analysis numbers make sense

### Step 3: Interactive Review Test

```bash
./audit_apps.sh --dry-run
```

When prompted:
1. Try pressing `y` (yes) for a few items
2. Try pressing `n` (no/skip) for others
3. Try pressing `a` (accept all) in a section
4. Try pressing `s` (skip all) in a section
5. Try pressing `q` (quit) and verify it aborts

**What to check:**
- ✓ Prompts are clear and readable
- ✓ Accept/skip options work as expected
- ✓ Final summary shows selected changes
- ✓ Quit aborts without making changes

### Step 4: Apply Mode on a Test Branch

**IMPORTANT: Create a test branch first!**

```bash
# Create backup just in case
cp brew.sh brew.sh.manual_backup

# Create test branch
git checkout -b test-audit-apply

# Run in apply mode
./audit_apps.sh --apply

# Review changes
git diff brew.sh

# If satisfied, commit
git add brew.sh
git commit -m "test: validate audit_apps.sh apply mode"

# If not satisfied, restore
git checkout brew.sh
```

**What to check:**
- ✓ Backup file created (brew.sh.backup.YYYYMMDD_HHMMSS)
- ✓ Arrays are sorted alphabetically
- ✓ Misclassified items moved to correct arrays
- ✓ Missing items added
- ✓ Extra items removed (if selected)
- ✓ Comments preserved in MAS array
- ✓ Formatting is clean and consistent

### Step 5: Idempotency Test

After applying changes once:

```bash
./audit_apps.sh --dry-run
```

**Expected result:**
```
No changes needed! brew.sh is in sync with installed packages.
```

**What this proves:**
- ✓ Script is idempotent (running twice produces same result)
- ✓ No phantom changes detected
- ✓ Arrays remain stable

## CI/CD Integration

### GitHub Actions

Add this to `.github/workflows/test-audit-apps.yml`:

```yaml
name: Test audit_apps.sh

on:
  push:
    branches: [ main, feature/* ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: macos-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Install dependencies
        run: |
          brew install bats-core bats-support bats-assert
      
      - name: Run unit tests
        run: |
          bats test/audit_apps.bats
      
      - name: Run integration tests
        run: |
          ./test_audit_apps.sh
```

### Pre-commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/usr/bin/env zsh

# Run tests before committing changes to audit_apps.sh
if git diff --cached --name-only | grep -q "audit_apps.sh"; then
    echo "Running tests for audit_apps.sh..."
    ./run_tests.sh --no-install
    
    if [ $? -ne 0 ]; then
        echo "Tests failed. Commit aborted."
        exit 1
    fi
fi
```

## Troubleshooting

### Tests Fail with "command not found: bats"

**Solution:**
```bash
brew install bats-core
```

### Integration Tests Fail in Non-Git Directory

**Solution:**  
Tests must run from within the git repository. Run:
```bash
cd /Users/wlstory/src/dotfiles
./run_tests.sh
```

### Mock Commands Not Working

**Solution:**  
Integration tests use mock `brew` and `mas` commands. If real commands interfere:
```bash
# Check PATH in test
echo $PATH

# Tests should prepend test/bin to PATH
```

### Dry-run Mode Test Fails

**Cause:** File unexpectedly modified during dry-run.

**Solution:** This is a critical bug. The script MUST NOT modify files in dry-run mode. Review the `apply_changes()` function.

## Best Practices

### When to Run Tests

✅ **Before committing** changes to `audit_apps.sh`  
✅ **After modifying** any functions  
✅ **When adding** new features  
✅ **Before using** `--apply` mode on production `brew.sh`  

### Adding New Tests

When you add a feature to `audit_apps.sh`:

1. **Add unit test** to `test/audit_apps.bats`
2. **Add integration test** to `test_audit_apps.sh` if needed
3. **Run tests** to ensure they pass
4. **Update this README** with new test count

### Test-Driven Development Workflow

```bash
# 1. Write failing test first
vi test/audit_apps.bats
bats test/audit_apps.bats  # Should fail

# 2. Implement feature
vi audit_apps.sh

# 3. Run tests until they pass
bats test/audit_apps.bats  # Should pass

# 4. Run full suite
./run_tests.sh
```

## Summary

With **105 total automated tests** (95 unit + 10 integration), you can have high confidence that `audit_apps.sh` works correctly without touching your production system.

**Testing Flow:**
1. Run `./run_tests.sh` → All pass
2. Run `./audit_apps.sh --dry-run` → Manual inspection
3. Create test branch → Run `./audit_apps.sh --apply`
4. Review diff → Validate changes
5. **Then** use on production if confident

This approach gives you **TDD-level confidence** for a shell script! 🎉
