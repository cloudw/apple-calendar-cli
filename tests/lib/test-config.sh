#!/bin/bash
# Test configuration for Apple Calendar CLI Tools
# This file defines safe test calendar names and shared test utilities

# Test calendar naming convention - unique and clearly identifiable
# Format: APPLE_CAL_CLI_TEST_[PURPOSE]_[PID]_SAFE_TO_DELETE
# Using process ID ensures uniqueness across concurrent test runs
TEST_BASE_NAME="APPLE_CAL_CLI_TEST"
TEST_SUFFIX="SAFE_TO_DELETE"
TEST_PID="$$"  # Current process ID

# Shared persistent calendar for all tests (reused to avoid deletion issues)
TEST_CALENDAR_SHARED="${TEST_BASE_NAME}_SHARED_PERSISTENT_${TEST_SUFFIX}"

# Legacy calendar names (kept for individual test suites that need unique calendars)
TEST_CALENDAR_BASIC="${TEST_BASE_NAME}_BASIC_${TEST_PID}_${TEST_SUFFIX}"
TEST_CALENDAR_MGMT="${TEST_BASE_NAME}_MGMT_${TEST_PID}_${TEST_SUFFIX}"
TEST_CALENDAR_JSON="${TEST_BASE_NAME}_JSON_${TEST_PID}_${TEST_SUFFIX}"

# Export for use in other test scripts
export TEST_CALENDAR_SHARED
export TEST_CALENDAR_BASIC
export TEST_CALENDAR_MGMT
export TEST_CALENDAR_JSON

# Safety function to verify calendar name is a test calendar
is_test_calendar() {
    local calendar_name="$1"
    if [[ "$calendar_name" == *"APPLE_CAL_CLI_TEST"* && "$calendar_name" == *"SAFE_TO_DELETE"* ]]; then
        return 0  # True - it's a test calendar
    else
        return 1  # False - not a test calendar
    fi
}

# Export the safety function
export -f is_test_calendar

# Print test configuration (for debugging)
print_test_config() {
    echo "=== Test Configuration ==="
    echo "Shared Persistent Calendar: $TEST_CALENDAR_SHARED"
    echo "Basic Operations Calendar: $TEST_CALENDAR_BASIC"
    echo "Management Test Calendar: $TEST_CALENDAR_MGMT"
    echo "JSON Format Test Calendar: $TEST_CALENDAR_JSON"
    echo "Process ID: $TEST_PID"
    echo "Note: Tests use persistent calendars due to macOS deletion limitations"
    echo "=========================="
}

# Note: Calendar deletion removed due to macOS security restrictions
# Tests now use persistent calendars and only clean up events
# Cleanup function commented out - calendars need manual deletion through Calendar app