# Testing Guide

This document explains how to safely run tests for the Apple Calendar CLI Tools.

## Test Safety Overview

The test suite is designed to be **completely safe** for multi-developer environments and will never interfere with your personal calendars.

### Test Calendar Naming Convention

**Shared Persistent Calendar:**
Due to macOS security restrictions on calendar deletion, most tests now use a single shared calendar:
```
APPLE_CAL_CLI_TEST_SHARED_PERSISTENT_SAFE_TO_DELETE
```

**Legacy Per-Test Calendars (for specific test suites):**
```
APPLE_CAL_CLI_TEST_[PURPOSE]_[PID]_SAFE_TO_DELETE
```

**Examples:**
- `APPLE_CAL_CLI_TEST_SHARED_PERSISTENT_SAFE_TO_DELETE` (main test calendar)
- `APPLE_CAL_CLI_CREATE_TEST_12345_SAFE_TO_DELETE` (calendar creation tests)

### Why This is Safe

1. **Clear Identification**: Calendar names clearly indicate they are test calendars
2. **Persistent Design**: Tests use a shared persistent calendar and only clean up events, not calendars
3. **Multi-Developer Safe**: Shared calendar design prevents conflicts between concurrent test runs
4. **Event-Only Cleanup**: Tests clean up events after completion, calendars persist for reuse
5. **Safety Validation**: Scripts refuse to operate on calendars without required safety keywords
6. **Manual Calendar Cleanup**: Test calendars must be manually deleted through Calendar app due to macOS restrictions

## Running Tests

### Quick Test Run
```bash
# Run all tests
./tests/run-all-tests

# Run individual test modules
./tests/test-events           # Event operations
./tests/test-calendars        # Calendar operations  
./tests/test-formats          # Content formatting & edge cases
./tests/test-errors           # Error handling
./tests/test-calendar-creation # Calendar creation (separate)
```

### Test Configuration
The test system automatically:
- Uses a shared persistent calendar for most tests to avoid deletion issues
- Creates the shared calendar if it doesn't exist
- Cleans up only events after tests complete, preserving the calendar
- Validates that only test calendars are modified
- Requires manual calendar deletion through Calendar app due to macOS restrictions

### What Each Test Does

**Basic Operations (`test-basic-operations`):**
- Uses shared persistent calendar: `APPLE_CAL_CLI_TEST_SHARED_PERSISTENT_SAFE_TO_DELETE`
- Tests: list, add event, get event, delete event
- Cleans up events only

**JSON Format Validation (`test-json-formats`):**
- Uses shared persistent calendar: `APPLE_CAL_CLI_TEST_SHARED_PERSISTENT_SAFE_TO_DELETE`
- Tests various edge cases that could break JSON formatting
- Includes special characters, HTML content, long descriptions
- Cleans up events only

**Ground Truth Integration (`test-ground-truth-integration`):**
- Uses shared persistent calendar: `APPLE_CAL_CLI_TEST_SHARED_PERSISTENT_SAFE_TO_DELETE`
- Tests CLI output against actual Calendar app state
- Verifies event creation, deletion, and retrieval accuracy
- Cleans up events only

**Calendar Creation (`test-calendar-creation`):**
- Creates unique test calendars: `APPLE_CAL_CLI_CREATE_TEST_[PID]_SAFE_TO_DELETE`
- Tests calendar creation operations only (no deletion)
- Requires manual cleanup through Calendar app

## Safety Mechanisms

### 1. Name Validation
```bash
# ✅ Valid test calendar names (accepted)
APPLE_CAL_CLI_TEST_BASIC_12345_SAFE_TO_DELETE
APPLE_CAL_CLI_TEST_JSON_67890_SAFE_TO_DELETE

# ❌ Invalid names (rejected)
MyPersonalCalendar
Work
CLI_TEST  # Missing required keywords
```

### 2. Event-Only Cleanup
- **Normal completion**: Test events removed on successful completion, calendars persist
- **Interruption**: Test events cleaned up even if tests are interrupted (Ctrl+C)
- **Persistent calendars**: Test calendars remain for reuse in future test runs

### 3. Process Isolation
- Each test run uses a unique process ID
- Multiple developers can run tests simultaneously
- No conflicts between concurrent test runs

## Troubleshooting

### Test Calendars Accumulation
Due to macOS security restrictions, test calendars persist and accumulate over time. To clean them up:

```bash
# Manual cleanup through Calendar app (recommended)
1. Open Calendar.app
2. Right-click each test calendar in the sidebar
3. Select "Delete Calendar"

# Look for calendars with names containing:
# - APPLE_CAL_CLI_TEST
# - SAFE_TO_DELETE
```

### Permission Issues
If you get calendar permission errors:
1. Go to System Preferences → Security & Privacy → Privacy → Automation
2. Allow Terminal (or your shell) to control Calendar
3. Run any CLI tool and approve the permission prompt

### Test Failures
If tests fail:
1. Check Calendar app is running and accessible
2. Verify you have automation permissions
3. Run individual test suites to isolate issues
4. Check the test output for specific error messages

## Test Components

### 1. Test Calendar Management (`cal-test-setup`)

Creates and manages temporary test calendars with unique, safe naming conventions.

**Usage:**
```bash
./cal-test-setup create                    # Create random test calendar
./cal-test-setup create "CALENDAR_NAME"    # Create specific test calendar
./cal-test-setup delete "CALENDAR_NAME"    # Delete specific test calendar
```

**Safety Features:**
- **Persistent shared calendar**: `APPLE_CAL_CLI_TEST_SHARED_PERSISTENT_SAFE_TO_DELETE`
- **Safety validation**: Only operates on calendars with required safety keywords
- **Event-only operations**: Tests modify events, not calendar structure
- **JSON status messages**: Returns structured feedback

### 2. JSON Validation (`validate-json`)

Validates JSON output from CLI tools and provides detailed error reporting.

**Usage:**
```bash
./cal-get "Calendar" $(date +%Y-%m-%d) $(date +%Y-%m-%d) | ./validate-json
```

**Features:**
- Validates JSON syntax
- Checks calendar-specific data structures
- Pretty-prints parsed JSON for verification
- Returns appropriate exit codes

### 3. Test Suites

**Event Operations Test (`test-events`):**
- Event creation (basic, with/without descriptions)
- Event retrieval and JSON structure validation
- Event deletion and verification
- Event count verification
- Multiple event operations
- Content matching verification

**Calendar Operations Test (`test-calendars`):**
- Calendar listing and JSON validation
- Calendar existence verification
- CLI vs Calendar app consistency checks
- Calendar details verification
- Performance testing

**Content Formatting & Edge Cases Test (`test-formats`):**
- Special characters (quotes, apostrophes, emojis, Unicode)
- HTML content and entities
- Very long content handling
- Control characters and newlines
- Cal-format output testing
- JSON structure integrity with complex content

**Error Handling Test (`test-errors`):**
- Non-existent calendar operations
- Invalid date/time format handling
- Missing parameter validation
- Injection attempt protection
- Concurrent operation handling
- Boundary condition testing

**Calendar Creation (`test-calendar-creation`):**
Tests calendar creation operations (separate suite due to deletion limitations):
- Calendar creation with and without descriptions
- Duplicate handling with --ignore-exists
- Error handling for invalid calendar names
- Creates calendars with unique names to avoid collisions
- Requires manual cleanup through Calendar app

**Note**: Calendar deletion tests have been removed due to macOS security restrictions that prevent reliable programmatic calendar deletion.

### 4. Test Runner (`run-all-tests`)

Main test orchestrator that:
- Verifies test prerequisites
- Runs all test suites in sequence
- Provides comprehensive reporting
- Ensures proper cleanup
- Returns appropriate exit codes for CI/CD

## For Developers

### Adding New Tests
When creating new test scripts:

1. **Load shared utilities:**
   ```bash
   source "$SCRIPT_DIR/../lib/test-utils.sh"
   ```

2. **Import test configuration:**
   ```bash
   source "$SCRIPT_DIR/test-config.sh"
   TEST_CALENDAR="$TEST_CALENDAR_[PURPOSE]"
   ```

3. **Use safety validation:**
   ```bash
   if is_test_calendar "$TEST_CALENDAR"; then
       # Safe to operate on this calendar
   fi
   ```

4. **Note about cleanup:**
   ```bash
   # Calendar deletion removed due to macOS security restrictions
   # Tests now use persistent calendars and only clean up events
   # For new tests, use the shared persistent calendar:
   TEST_CALENDAR="$TEST_CALENDAR_SHARED"
   ```

5. **Use shared test functions:**
   ```bash
   print_test "Running my test"
   print_pass "Test succeeded"
   print_test_summary  # At end of script
   ```

### Test Calendar Requirements
All test calendar names MUST:
- Start with `APPLE_CAL_CLI_TEST_`
- End with `_SAFE_TO_DELETE`
- Include a unique identifier (PID, timestamp, etc.)

This ensures safety validation will accept them and they'll be cleaned up properly.

## Continuous Integration

The test suite is designed for CI/CD environments:

```yaml
# Example GitHub Actions
- name: Run Calendar CLI Tests
  run: |
    chmod +x cal-*
    ./tests/run-all-tests
```

**CI Safety Features:**
- Each CI run gets unique process ID
- Tests run in isolation
- Automatic cleanup prevents test calendar accumulation
- Parallel CI runs won't interfere with each other

## Summary

The test suite provides comprehensive safety through:
- ✅ **Unique naming** prevents conflicts
- ✅ **Safety validation** prevents accidental calendar modification  
- ✅ **Automatic cleanup** removes all test artifacts
- ✅ **Process isolation** enables concurrent testing
- ✅ **Multi-developer safe** for team environments

You can run tests confidently knowing they will never affect your personal calendars or interfere with other developers' test runs.