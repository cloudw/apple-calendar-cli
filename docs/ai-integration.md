# AI Assistant Integration Guide

This document helps AI assistants (Claude, ChatGPT, GitHub Copilot, etc.) understand and effectively use the Apple Calendar CLI tools.

## Tool Overview

The Apple Calendar CLI tools provide programmatic access to macOS Calendar through AppleScript, returning structured JSON for easy parsing and automation.

### Core Commands

**Calendar Management:**
- `./bin/cal-list` - Returns JSON array of all available calendars
- `./bin/cal-create-cal <name> [description] [--ignore-exists]` - Creates new calendar

**Event Operations:**
- `./bin/cal-get <calendar> <start_date> <end_date>` - Retrieves events as JSON
- `./bin/cal-add <calendar> <title> <start_datetime> <end_datetime> [description]` - Creates event
- `./bin/cal-delete <calendar> <title> <start_date> <end_date>` - Deletes matching events

**Output Formatting:**
- `./bin/cal-format [--format agenda|table|summary]` - Converts JSON to human-readable format

### Date/Time Formats

- **Dates:** `YYYY-MM-DD` (e.g., `2024-12-15`)
- **Times:** `YYYY-MM-DD-HH-MM` (e.g., `2024-12-15-14-30` for 2:30 PM)
- **Ranges:** Use start and end times for precise event scheduling

## Common Patterns & Workflows

### 1. Calendar Discovery
```bash
# List all calendars to help user choose
./bin/cal-list | jq -r '.calendars[]'

# Get user's calendar preferences
./bin/cal-list | ./bin/cal-format
```

### 2. Event Scheduling Workflow
```bash
# Check availability for a date
./bin/cal-get "Work" "2024-12-15" "2024-12-15" | ./bin/cal-format

# Add new event
./bin/cal-add "Work" "Team Meeting" "2024-12-15-10-00" "2024-12-15-11-00" "Weekly standup"

# Confirm event was created
./bin/cal-get "Work" "2024-12-15-10-00" "2024-12-15-11-00" | ./bin/cal-format
```

### 3. Agenda Generation
```bash
# Today's schedule
./bin/cal-get "Work" $(date +%Y-%m-%d) $(date +%Y-%m-%d) | ./bin/cal-format --format agenda

# This week's overview
./bin/cal-get "Personal" $(date +%Y-%m-%d) $(date -d '+7 days' +%Y-%m-%d) | ./bin/cal-format --format table
```

### 4. Event Management
```bash
# Find specific events
./bin/cal-get "Work" "2024-12-01" "2024-12-31" | jq '.events[] | select(.title | contains("meeting"))'

# Delete events by title
./bin/cal-delete "Work" "Cancelled Meeting" "2024-12-15" "2024-12-15"
```

## AI Assistant Integration Strategies

### For Conversational AI (Claude, ChatGPT)

**Natural Language to Commands:**
- Parse user requests like "schedule a meeting tomorrow at 2pm" 
- Convert to: `./bin/cal-add "Work" "Meeting" "2024-12-16-14-00" "2024-12-16-15-00"`
- Always confirm details before executing

**Calendar Intelligence:**
- Check for conflicts before scheduling
- Suggest alternative times if busy
- Provide context-aware scheduling (work hours, existing patterns)

**Response Formatting:**
- Use `./bin/cal-format` for user-friendly output
- Parse JSON for programmatic logic
- Combine multiple operations in workflows

### For Code Generation AI (GitHub Copilot)

**Script Automation:**
```bash
#!/bin/bash
# AI-generated calendar automation example

# Get user's work calendar for today
today=$(date +%Y-%m-%d)
events=$(./bin/cal-get "Work" "$today" "$today")

# Check if busy
if echo "$events" | jq '.events | length' | grep -q "^0$"; then
    echo "Free day! Consider scheduling focused work."
else
    echo "Busy day:"
    echo "$events" | ./bin/cal-format --format agenda
fi
```

**Integration Patterns:**
- Wrap CLI calls in functions for reuse
- Add error handling for missing calendars
- Use JSON parsing for conditional logic

## Example Use Cases

### 1. Meeting Scheduler Assistant
```bash
# Check availability
availability=$(./bin/cal-get "Work" "2024-12-15" "2024-12-15")

# If free, schedule meeting
if [ $(echo "$availability" | jq '.events | length') -eq 0 ]; then
    ./bin/cal-add "Work" "Client Call" "2024-12-15-10-00" "2024-12-15-11-00" "Quarterly review"
    echo "Meeting scheduled successfully!"
fi
```

### 2. Daily Agenda Generator
```bash
# Generate morning briefing
today=$(date +%Y-%m-%d)
echo "Today's Schedule:"
./bin/cal-get "Work" "$today" "$today" | ./bin/cal-format --format agenda

echo -e "\nPersonal Events:"
./bin/cal-get "Personal" "$today" "$today" | ./bin/cal-format --format agenda
```

### 3. Calendar Analytics
```bash
# Count events per calendar this month
for calendar in $(./bin/cal-list | jq -r '.calendars[]'); do
    start_date=$(date -d 'first day of this month' +%Y-%m-%d)
    end_date=$(date -d 'last day of this month' +%Y-%m-%d)
    count=$(./bin/cal-get "$calendar" "$start_date" "$end_date" | jq '.events | length')
    echo "$calendar: $count events"
done
```

## Error Handling Guidelines

### Robust AI Integration
```bash
# Always check if calendar exists
if ./bin/cal-list | jq -r '.calendars[]' | grep -q "^Work$"; then
    ./bin/cal-add "Work" "Meeting" "2024-12-15-10-00" "2024-12-15-11-00"
else
    echo "Calendar 'Work' not found. Available calendars:"
    ./bin/cal-list | ./bin/cal-format
fi

# Validate dates before operations
if date -d "2024-12-15" >/dev/null 2>&1; then
    # Proceed with calendar operations
else
    echo "Invalid date format. Use YYYY-MM-DD"
fi
```

### JSON Error Detection
```bash
# Check for error responses
result=$(./bin/cal-get "NonExistent" "2024-12-15" "2024-12-15")
if echo "$result" | jq -e '.error' >/dev/null; then
    echo "Error: $(echo "$result" | jq -r '.error')"
else
    echo "$result" | ./bin/cal-format
fi
```

## Best Practices for AI Assistants

### 1. Always Confirm Before Acting
- Show user what command will be executed
- Confirm calendar names and times
- Display planned changes before applying

### 2. Provide Context
- Show current calendar state when relevant
- Explain why certain times might not work
- Offer alternatives when conflicts exist

### 3. Use Human-Friendly Output
- Prefer `./bin/cal-format` for user-facing results
- Use JSON parsing for decision logic
- Combine multiple views (agenda + table) when helpful

### 4. Handle Edge Cases
- Check for calendar existence before operations
- Validate date formats
- Handle timezone considerations (all times are local)
- Gracefully handle permission issues

## Integration Examples by AI Platform

### Claude Integration
```markdown
You have access to Apple Calendar CLI tools. When users request calendar operations:

1. First check available calendars: `./bin/cal-list`
2. For scheduling: `./bin/cal-add "Calendar" "Title" "YYYY-MM-DD-HH-MM" "YYYY-MM-DD-HH-MM" "Description"`
3. For viewing: `./bin/cal-get "Calendar" "start-date" "end-date" | ./bin/cal-format`
4. Always confirm details before executing commands
```

### ChatGPT Code Interpreter
```python
import subprocess
import json

def get_calendar_events(calendar_name, start_date, end_date):
    """Get events from Apple Calendar CLI"""
    cmd = f'./bin/cal-get "{calendar_name}" "{start_date}" "{end_date}"'
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return json.loads(result.stdout)

# Use with natural language processing to parse user requests
```

### GitHub Copilot Comments
```bash
# Get today's work schedule and format as agenda
# Check if meeting room is available at 2pm tomorrow
# Schedule recurring team standup for every Monday at 9am
# Export this month's events to analyze meeting frequency
```

## Limitations & Considerations

### macOS Specific
- Only works on macOS with Calendar app
- Requires proper permissions (System Preferences → Security & Privacy → Automation)
- Calendar deletion has limitations due to macOS security restrictions

### Timezone Handling
- All times are interpreted in system timezone
- Output includes timezone information in ISO 8601 format
- Consider user's timezone when parsing natural language time requests

### Performance
- AppleScript calls have some latency
- Batch operations when possible
- Cache calendar lists for repeated operations

This guide provides the foundation for building intelligent, user-friendly calendar automation with any AI assistant platform.