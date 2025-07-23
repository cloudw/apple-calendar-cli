#!/bin/bash
# Shared test utilities for Calendar CLI tests
# This library consolidates common test functions to eliminate code duplication

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test result tracking variables
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test suite tracking (for run-all-tests)
SUITES_RUN=0
SUITES_PASSED=0
SUITES_FAILED=0

# Test output functions
print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
    TESTS_RUN=$((TESTS_RUN + 1))
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_suite_pass() {
    echo -e "${GREEN}[SUITE PASS]${NC} $1"
    SUITES_PASSED=$((SUITES_PASSED + 1))
}

print_suite_fail() {
    echo -e "${RED}[SUITE FAIL]${NC} $1"
    SUITES_FAILED=$((SUITES_FAILED + 1))
}

# Test summary functions
print_test_summary() {
    echo ""
    echo "=== Test Summary ==="
    echo "Tests Run: $TESTS_RUN"
    echo "Tests Passed: $TESTS_PASSED"
    echo "Tests Failed: $TESTS_FAILED"

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        return 1
    fi
}

print_suite_summary() {
    echo ""
    print_header "Final Test Results"
    echo "Test Suites Run: $SUITES_RUN"
    echo "Test Suites Passed: $SUITES_PASSED"
    echo "Test Suites Failed: $SUITES_FAILED"

    if [ $SUITES_FAILED -eq 0 ]; then
        echo ""
        echo -e "${GREEN}🎉 ALL TEST SUITES PASSED! 🎉${NC}"
        echo -e "${GREEN}The Calendar CLI tools are working correctly.${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}❌ SOME TEST SUITES FAILED ❌${NC}"
        echo -e "${RED}Please review the failed tests above.${NC}"
        return 1
    fi
}

# Path resolution utilities
get_script_dir() {
    echo "$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
}

get_cli_dir() {
    local script_dir="$1"
    echo "$(dirname "$script_dir")"
}

# Robust cleanup function that uses AppleScript to delete all events from a calendar
cleanup_calendar_events() {
    local calendar_name="$1"
    local start_date="$2"  # YYYY-MM-DD format
    local end_date="$3"    # YYYY-MM-DD format
    
    # Parse dates for AppleScript
    local start_year=$(echo "$start_date" | cut -d'-' -f1)
    local start_month=$(echo "$start_date" | cut -d'-' -f2)
    local start_day=$(echo "$start_date" | cut -d'-' -f3)
    
    local end_year=$(echo "$end_date" | cut -d'-' -f1)
    local end_month=$(echo "$end_date" | cut -d'-' -f2)
    local end_day=$(echo "$end_date" | cut -d'-' -f3)
    
    # Remove leading zeros for AppleScript
    start_month=$(echo "$start_month" | sed 's/^0*//')
    start_day=$(echo "$start_day" | sed 's/^0*//')
    end_month=$(echo "$end_month" | sed 's/^0*//')
    end_day=$(echo "$end_day" | sed 's/^0*//')
    
    local result=$(osascript << EOF
tell application "Calendar"
    try
        set targetCal to calendar "$calendar_name"
        
        -- Create start of range
        set startOfRange to current date
        set year of startOfRange to $start_year
        set month of startOfRange to $start_month
        set day of startOfRange to $start_day
        set hours of startOfRange to 0
        set minutes of startOfRange to 0
        set seconds of startOfRange to 0
        
        -- Create end of range
        set endOfRange to current date 
        set year of endOfRange to $end_year
        set month of endOfRange to $end_month
        set day of endOfRange to $end_day
        set hours of endOfRange to 23
        set minutes of endOfRange to 59
        set seconds of endOfRange to 59
        
        -- Get all events in the range
        set eventList to every event of targetCal whose start date ≥ startOfRange and start date ≤ endOfRange
        set eventCount to count of eventList
        
        -- Delete each event
        repeat with currentEvent in eventList
            delete currentEvent
        end repeat
        
        return "Deleted " & eventCount & " events"
    on error errMsg
        return "Error: " & errMsg
    end try
end tell
EOF
)
    
    echo "$result"
}

# Test runner utility for run-all-tests
run_test_suite() {
    local test_script="$1"
    local test_name="$2"
    local script_dir="$3"
    
    SUITES_RUN=$((SUITES_RUN + 1))
    
    if [ -x "$script_dir/$test_script" ]; then
        print_header "Running $test_name"
        if "$script_dir/$test_script"; then
            print_suite_pass "$test_name"
            return 0
        else
            print_suite_fail "$test_name"
            return 1
        fi
    else
        echo -e "${RED}[ERROR]${NC} Test script $test_script not found or not executable"
        print_suite_fail "$test_name (missing)"
        return 1
    fi
}

# Date utilities for cross-platform compatibility
get_tomorrow_date() {
    date -d '+1 day' '+%Y-%m-%d' 2>/dev/null || date -v+1d '+%Y-%m-%d'
}

get_date_range_for_tests() {
    local tomorrow=$(get_tomorrow_date)
    echo "${tomorrow}-00-00 ${tomorrow}-23-59"
}

# Test validation utilities
validate_json_response() {
    local result="$1"
    local script_dir="$2"
    
    if echo "$result" | "$script_dir/tools/validate-json" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Clean up utilities
setup_cleanup_trap() {
    local cleanup_function="$1"
    trap "$cleanup_function" EXIT
}