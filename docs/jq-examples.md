# Calendar CLI Tools - jq Examples

This document provides examples of using `jq` to format and process JSON output from the calendar CLI tools.

## Timezone Information
All datetime values in the JSON output include timezone information in ISO 8601 format (e.g., `2024-12-15T14:00:00-08:00`). The timezone corresponds to your system's timezone setting.

## Basic Usage

### Pretty Print JSON Output
```bash
./cal-list | jq .
./cal-get "Calendar Name" $(date +%Y-%m-%d) $(date -d '+1 day' +%Y-%m-%d) | jq .
```

### Extract Specific Fields

#### Get just event titles
```bash
./cal-get "Calendar Name" $(date +%Y-%m-%d) $(date -d '+1 day' +%Y-%m-%d) | jq '.events[].title'
```

#### Get titles and start times
```bash
./cal-get "Calendar Name" $(date +%Y-%m-%d) $(date -d '+1 day' +%Y-%m-%d) | jq '.events[] | {title, startDate}'
```

#### Get calendar names only
```bash
./cal-list | jq '.calendars[]'
```

### Filtering Events

#### Events containing specific text in title
```bash
./cal-get "Calendar Name" $(date +%Y-%m-%d) $(date -d '+1 day' +%Y-%m-%d) | jq '.events[] | select(.title | contains("meeting"))'
```

#### Events starting after a specific time
```bash
./cal-get "Calendar Name" $(date +%Y-%m-%d) $(date -d '+1 day' +%Y-%m-%d) | jq '.events[] | select(.startDate > "'$(date +%Y-%m-%d)'T12:00:00")'
```

#### Events with descriptions
```bash
./cal-get "Calendar Name" $(date +%Y-%m-%d) $(date -d '+1 day' +%Y-%m-%d) | jq '.events[] | select(.description != "")'
```

### Custom Formatting

#### Simple event list with time
```bash
# Today's events with time
./cal-get "Calendar Name" $(date +%Y-%m-%d) $(date +%Y-%m-%d) | jq -r '.events[] | "\(.startDate | split("T")[1] | split(":")[0,1] | join(":")): \(.title)"'
```

#### Event summary with duration
```bash
# Today and tomorrow's events with full details
./cal-get "Calendar Name" $(date +%Y-%m-%d) $(date -d '+1 day' +%Y-%m-%d) | jq -r '.events[] | "\(.title) (\(.startDate | split("T")[0])) \(.startDate | split("T")[1] | split(":")[0,1] | join(":")) - \(.endDate | split("T")[1] | split(":")[0,1] | join(":"))"'
```

#### Count events by date
```bash
# This week's events grouped by date
./cal-get "Calendar Name" $(date +%Y-%m-%d) $(date -d '+7 days' +%Y-%m-%d) | jq '.events | group_by(.startDate | split("T")[0]) | map({date: .[0].startDate | split("T")[0], count: length})'
```

### Advanced Queries

#### Events sorted by start time
```bash
./cal-get "Calendar Name" $(date +%Y-%m-%d) $(date -d '+1 day' +%Y-%m-%d) | jq '.events | sort_by(.startDate)'
```

#### Today's events only
```bash
./cal-get "Calendar Name" $(date +%Y-%m-%d) $(date -d '+1 day' +%Y-%m-%d) | jq '.events[] | select(.startDate | startswith("'$(date +%Y-%m-%d)'"))'
```

#### Extract unique event titles
```bash
# This month's unique event titles
./cal-get "Calendar Name" $(date -d 'first day of this month' +%Y-%m-%d) $(date -d 'last day of this month' +%Y-%m-%d) | jq '[.events[].title] | unique'
```

### Processing Operation Results

#### Check if event creation was successful
```bash
# Create test event (adjust date as needed)
./cal-add "Calendar" "Test Event" 2024-12-15-14-00 2024-12-15-15-00 | jq -r 'if .status == "created" then "✅ Event created: \(.event.title)" else "❌ Failed to create event" end'
```

#### Format deletion results
```bash
# Delete test event (adjust date as needed)
./cal-delete "Calendar" "Test Event" 2024-12-15 2024-12-15 | jq -r 'if .eventsDeleted > 0 then "🗑️ Deleted \(.eventsDeleted) event(s): \(.eventTitle)" else "ℹ️ No events found matching: \(.eventTitle)" end'
```

### Combining with Shell Commands

#### Save events to CSV
```bash
# Export today's events to CSV
./cal-get "Calendar Name" $(date +%Y-%m-%d) $(date +%Y-%m-%d) | jq -r '.events[] | [.title, .startDate, .endDate, .description] | @csv' > events.csv
```

#### Count total events
```bash
# Count events in current month
./cal-get "Calendar Name" $(date -d 'first day of this month' +%Y-%m-%d) $(date -d 'last day of this month' +%Y-%m-%d) | jq '.events | length'
```

#### Find calendar with most events (when checking multiple calendars)
```bash
# Compare event counts across calendars for current month
for cal in $(./cal-list | jq -r '.calendars[]'); do
  start_date=$(date -d 'first day of this month' +%Y-%m-%d)
  end_date=$(date -d 'last day of this month' +%Y-%m-%d)
  count=$(./cal-get "$cal" "$start_date" "$end_date" | jq '.events | length')
  echo "$cal: $count events"
done | sort -k2 -nr | head -1
```

### Error Handling

#### Check for errors in output
```bash
./cal-get "NonExistent" $(date +%Y-%m-%d) $(date +%Y-%m-%d) | jq -r 'if .error then "Error: \(.error)" else "Success: \(.events | length) events found" end'
```

#### Extract error messages
```bash
./cal-get "NonExistent" $(date +%Y-%m-%d) $(date +%Y-%m-%d) | jq -r 'select(.error) | .error'
```

## Useful jq Filters for Calendar Data

### Date/Time Manipulation
```bash
# Extract just the date part
jq '.events[] | .startDate | split("T")[0]'

# Extract just the time part
jq '.events[] | .startDate | split("T")[1]'

# Convert to different format
jq '.events[] | .startDate | strptime("%Y-%m-%dT%H:%M:%S") | strftime("%B %d, %Y at %I:%M %p")'
```

### Creating Custom Reports
```bash
# Daily agenda format for today's events
./cal-get "Calendar" $(date +%Y-%m-%d) $(date +%Y-%m-%d) | jq -r '
  .events 
  | group_by(.startDate | split("T")[0])
  | .[]
  | "Date: \(.[0].startDate | split("T")[0])\n" + 
    (map("  \(.startDate | split("T")[1] | split(":")[0,1] | join(":")): \(.title)") | join("\n"))
'
```

These examples should help you process and format the JSON output from the calendar CLI tools using `jq`.