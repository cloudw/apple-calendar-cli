#!/bin/bash
# Ground truth verification utilities for Calendar CLI tests
# These functions verify actual Calendar app state, not just JSON responses

# Note: test-utils.sh should be loaded by the calling script

# Direct AppleScript queries to Calendar app for ground truth verification

# Verify if a calendar exists in Calendar app
verify_calendar_exists() {
    local calendar_name="$1"
    
    local result=$(osascript << EOF
tell application "Calendar"
    try
        set targetCal to calendar "$calendar_name"
        return "EXISTS"
    on error
        return "NOT_EXISTS"
    end try
end tell
EOF
)
    
    if [[ "$result" == "EXISTS" ]]; then
        return 0
    else
        return 1
    fi
}

# Get calendar details directly from Calendar app
get_calendar_details() {
    local calendar_name="$1"
    
    osascript << EOF
tell application "Calendar"
    try
        set targetCal to calendar "$calendar_name"
        set calName to name of targetCal
        set calDesc to description of targetCal
        
        return "{\"name\": \"" & calName & "\", \"description\": \"" & calDesc & "\", \"exists\": true}"
    on error errMsg
        return "{\"exists\": false, \"error\": \"" & errMsg & "\"}"
    end try
end tell
EOF
}

# Verify if an event exists in Calendar app
verify_event_exists() {
    local calendar_name="$1"
    local event_title="$2"
    local search_date="$3"  # YYYY-MM-DD format
    
    # Parse date for AppleScript
    local year=$(echo "$search_date" | cut -d'-' -f1)
    local month=$(echo "$search_date" | cut -d'-' -f2)
    local day=$(echo "$search_date" | cut -d'-' -f3)
    
    # Remove leading zeros for AppleScript
    month=$(echo "$month" | sed 's/^0*//')
    day=$(echo "$day" | sed 's/^0*//')
    
    local result=$(osascript << EOF
tell application "Calendar"
    try
        set targetCal to calendar "$calendar_name"
        
        -- Create start of day using proper AppleScript date construction
        set startOfDay to current date
        set year of startOfDay to $year
        set month of startOfDay to $month
        set day of startOfDay to $day
        set hours of startOfDay to 0
        set minutes of startOfDay to 0
        set seconds of startOfDay to 0
        
        -- Create end of day
        set endOfDay to current date
        set year of endOfDay to $year
        set month of endOfDay to $month
        set day of endOfDay to $day
        set hours of endOfDay to 23
        set minutes of endOfDay to 59
        set seconds of endOfDay to 59
        
        set eventList to every event of targetCal whose start date ≥ startOfDay and start date ≤ endOfDay
        
        repeat with currentEvent in eventList
            if summary of currentEvent is "$event_title" then
                return "EXISTS"
            end if
        end repeat
        
        return "NOT_EXISTS"
    on error errMsg
        return "ERROR: " & errMsg
    end try
end tell
EOF
)
    
    if [[ "$result" == "EXISTS" ]]; then
        return 0
    else
        return 1
    fi
}

# Get event count for a specific date from Calendar app
get_event_count() {
    local calendar_name="$1"
    local search_date="$2"  # YYYY-MM-DD format
    
    # Parse date for AppleScript
    local year=$(echo "$search_date" | cut -d'-' -f1)
    local month=$(echo "$search_date" | cut -d'-' -f2)
    local day=$(echo "$search_date" | cut -d'-' -f3)
    
    # Remove leading zeros for AppleScript
    month=$(echo "$month" | sed 's/^0*//')
    day=$(echo "$day" | sed 's/^0*//')
    
    osascript << EOF
tell application "Calendar"
    try
        set targetCal to calendar "$calendar_name"
        
        -- Create date range
        set startOfDay to current date
        set year of startOfDay to $year
        set month of startOfDay to $month
        set day of startOfDay to $day
        set hours of startOfDay to 0
        set minutes of startOfDay to 0
        set seconds of startOfDay to 0
        
        set endOfDay to current date
        set year of endOfDay to $year
        set month of endOfDay to $month
        set day of endOfDay to $day
        set hours of endOfDay to 23
        set minutes of endOfDay to 59
        set seconds of endOfDay to 59
        
        set eventList to every event of targetCal whose start date ≥ startOfDay and start date ≤ endOfDay
        return count of eventList
    on error errMsg
        return -1
    end try
end tell
EOF
}

# Get all events for a specific date from Calendar app
get_events_ground_truth() {
    local calendar_name="$1"
    local search_date="$2"  # YYYY-MM-DD format
    
    # Parse date for AppleScript
    local year=$(echo "$search_date" | cut -d'-' -f1)
    local month=$(echo "$search_date" | cut -d'-' -f2)
    local day=$(echo "$search_date" | cut -d'-' -f3)
    
    # Remove leading zeros for AppleScript
    month=$(echo "$month" | sed 's/^0*//')
    day=$(echo "$day" | sed 's/^0*//')
    
    osascript << EOF
tell application "Calendar"
    try
        set targetCal to calendar "$calendar_name"
        
        -- Create date range
        set startOfDay to current date
        set year of startOfDay to $year
        set month of startOfDay to $month
        set day of startOfDay to $day
        set hours of startOfDay to 0
        set minutes of startOfDay to 0
        set seconds of startOfDay to 0
        
        set endOfDay to current date
        set year of endOfDay to $year
        set month of endOfDay to $month
        set day of endOfDay to $day
        set hours of endOfDay to 23
        set minutes of endOfDay to 59
        set seconds of endOfDay to 59
        
        set eventList to every event of targetCal whose start date ≥ startOfDay and start date ≤ endOfDay
        set eventTitles to {}
        
        repeat with currentEvent in eventList
            set eventTitles to eventTitles & {summary of currentEvent}
        end repeat
        
        set AppleScript's text item delimiters to ","
        set titleString to eventTitles as string
        set AppleScript's text item delimiters to ""
        
        return titleString
    on error errMsg
        return "ERROR: " & errMsg
    end try
end tell
EOF
}

# List all calendars directly from Calendar app
list_calendars_ground_truth() {
    osascript << EOF
tell application "Calendar"
    set calendarNames to {}
    repeat with cal in calendars
        set calendarNames to calendarNames & {name of cal}
    end repeat
    
    set AppleScript's text item delimiters to "
"
    set nameString to calendarNames as string
    set AppleScript's text item delimiters to ""
    
    return nameString
end tell
EOF
}

# Ground truth verification test functions

# Test: Verify CLI output matches Calendar app reality
test_calendar_existence() {
    local calendar_name="$1"
    local expected_exists="$2"  # true or false
    
    print_test "Ground truth: Verifying calendar '$calendar_name' exists=$expected_exists"
    
    # Check CLI output
    local cli_result=$(./cal-list 2>/dev/null)
    local cli_has_calendar=false
    if echo "$cli_result" | jq -r '.calendars[]' | grep -q "^$calendar_name$"; then
        cli_has_calendar=true
    fi
    
    # Check ground truth
    if verify_calendar_exists "$calendar_name"; then
        local ground_truth_exists=true
    else
        local ground_truth_exists=false
    fi
    
    # Compare results
    if [[ "$cli_has_calendar" == "$ground_truth_exists" && "$ground_truth_exists" == "$expected_exists" ]]; then
        print_pass "CLI and ground truth match: calendar exists=$ground_truth_exists"
        return 0
    else
        print_fail "Mismatch - CLI: $cli_has_calendar, Ground truth: $ground_truth_exists, Expected: $expected_exists"
        return 1
    fi
}

# Test: Verify event existence matches between CLI and Calendar app
test_event_existence() {
    local calendar_name="$1"
    local event_title="$2"
    local search_date="$3"
    local expected_exists="$4"  # true or false
    
    print_test "Ground truth: Verifying event '$event_title' in '$calendar_name' on $search_date exists=$expected_exists"
    
    # Check CLI output
    local search_start="${search_date}-00-00"
    local search_end="${search_date}-23-59"
    local cli_result=$(./cal-get "$calendar_name" "$search_start" "$search_end" 2>/dev/null)
    local cli_has_event=false
    if echo "$cli_result" | jq -r '.events[]?.title' | grep -q "^$event_title$"; then
        cli_has_event=true
    fi
    
    # Check ground truth
    if verify_event_exists "$calendar_name" "$event_title" "$search_date"; then
        local ground_truth_exists=true
    else
        local ground_truth_exists=false
    fi
    
    # Compare results
    if [[ "$cli_has_event" == "$ground_truth_exists" && "$ground_truth_exists" == "$expected_exists" ]]; then
        print_pass "CLI and ground truth match: event exists=$ground_truth_exists"
        return 0
    else
        print_fail "Mismatch - CLI: $cli_has_event, Ground truth: $ground_truth_exists, Expected: $expected_exists"
        return 1
    fi
}

# Test: Verify event count matches between CLI and Calendar app
test_event_count() {
    local calendar_name="$1"
    local search_date="$2"
    local expected_count="$3"
    
    print_test "Ground truth: Verifying event count in '$calendar_name' on $search_date = $expected_count"
    
    # Check CLI output
    local search_start="${search_date}-00-00"
    local search_end="${search_date}-23-59"
    local cli_result=$(./cal-get "$calendar_name" "$search_start" "$search_end" 2>/dev/null)
    local cli_count=$(echo "$cli_result" | jq '.events | length' 2>/dev/null || echo "0")
    
    # Check ground truth
    local ground_truth_count=$(get_event_count "$calendar_name" "$search_date")
    
    # Compare results
    if [[ "$cli_count" == "$ground_truth_count" && "$ground_truth_count" == "$expected_count" ]]; then
        print_pass "CLI and ground truth match: event count=$ground_truth_count"
        return 0
    else
        print_fail "Mismatch - CLI: $cli_count, Ground truth: $ground_truth_count, Expected: $expected_count"
        return 1
    fi
}