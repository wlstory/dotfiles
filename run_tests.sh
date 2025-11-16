#!/usr/bin/env zsh

############################
# run_tests.sh
#
# Comprehensive test runner for audit_apps.sh
# Installs test dependencies and runs both unit and integration tests
#
# Usage:
#   ./run_tests.sh [OPTIONS]
#
# Options:
#   --unit-only         Run only unit tests (bats)
#   --integration-only  Run only integration tests
#   --no-install        Skip installing test dependencies
#   --verbose           Show verbose output
#   --help              Show this help
############################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# Defaults
RUN_UNIT=1
RUN_INTEGRATION=1
INSTALL_DEPS=1
VERBOSE=0

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --unit-only)
                RUN_INTEGRATION=0
                shift
                ;;
            --integration-only)
                RUN_UNIT=0
                shift
                ;;
            --no-install)
                INSTALL_DEPS=0
                shift
                ;;
            --verbose)
                VERBOSE=1
                shift
                ;;
            --help|-h)
                sed -n '3,24p' "$0" | sed 's/^# //; s/^#//'
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1${RESET}"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Install test dependencies
install_dependencies() {
    if [[ $INSTALL_DEPS -eq 0 ]]; then
        echo -e "${BLUE}Skipping dependency installation${RESET}"
        return
    fi
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}Installing Test Dependencies${RESET}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    
    # Check if Homebrew is available
    if ! command -v brew &>/dev/null; then
        echo -e "${RED}✗ Homebrew not found${RESET}"
        echo "Please install Homebrew first: https://brew.sh"
        exit 1
    fi
    
    # Install bats-core if needed
    if ! command -v bats &>/dev/null; then
        echo -e "${YELLOW}Installing bats-core...${RESET}"
        brew install bats-core
        echo -e "${GREEN}✓ bats-core installed${RESET}"
    else
        echo -e "${GREEN}✓ bats-core already installed${RESET}"
    fi
    
    # Note: bats-support and bats-assert are optional helper libraries
    # They're not available via Homebrew on macOS and our tests don't require them
    echo -e "${GREEN}✓ Test dependencies installed${RESET}"
    
    echo ""
}

# Run unit tests with bats
run_unit_tests() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}Running Unit Tests (bats-core)${RESET}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    
    if [[ ! -f "test/audit_apps.bats" ]]; then
        echo -e "${RED}✗ Unit test file not found: test/audit_apps.bats${RESET}"
        return 1
    fi
    
    local bats_opts=""
    if [[ $VERBOSE -eq 1 ]]; then
        bats_opts="--verbose-run --print-output-on-failure"
    fi
    
    if bats $bats_opts test/audit_apps.bats; then
        echo ""
        echo -e "${GREEN}✓ All unit tests passed${RESET}"
        return 0
    else
        echo ""
        echo -e "${RED}✗ Some unit tests failed${RESET}"
        return 1
    fi
}

# Run integration tests
run_integration_tests() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}Running Integration Tests${RESET}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    
    if [[ ! -f "test_audit_apps.sh" ]]; then
        echo -e "${RED}✗ Integration test file not found: test_audit_apps.sh${RESET}"
        return 1
    fi
    
    if ./test_audit_apps.sh; then
        return 0
    else
        return 1
    fi
}

# Main execution
main() {
    parse_args "$@"
    
    cd "$(dirname "$0")"
    
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║      audit_apps.sh Comprehensive Test Suite               ║${RESET}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    install_dependencies
    
    local unit_status=0
    local integration_status=0
    
    # Run unit tests
    if [[ $RUN_UNIT -eq 1 ]]; then
        if ! run_unit_tests; then
            unit_status=1
        fi
        echo ""
    fi
    
    # Run integration tests
    if [[ $RUN_INTEGRATION -eq 1 ]]; then
        if ! run_integration_tests; then
            integration_status=1
        fi
        echo ""
    fi
    
    # Final summary
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}Final Test Summary${RESET}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    
    if [[ $RUN_UNIT -eq 1 ]]; then
        if [[ $unit_status -eq 0 ]]; then
            echo -e "${GREEN}✓ Unit Tests: PASSED${RESET}"
        else
            echo -e "${RED}✗ Unit Tests: FAILED${RESET}"
        fi
    fi
    
    if [[ $RUN_INTEGRATION -eq 1 ]]; then
        if [[ $integration_status -eq 0 ]]; then
            echo -e "${GREEN}✓ Integration Tests: PASSED${RESET}"
        else
            echo -e "${RED}✗ Integration Tests: FAILED${RESET}"
        fi
    fi
    
    echo ""
    
    if [[ $unit_status -eq 0 && $integration_status -eq 0 ]]; then
        echo -e "${BOLD}${GREEN}✓ All tests passed! audit_apps.sh is ready to use.${RESET}"
        return 0
    else
        echo -e "${BOLD}${RED}✗ Some tests failed. Please review the output above.${RESET}"
        return 1
    fi
}

main "$@"
