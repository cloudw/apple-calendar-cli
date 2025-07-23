# Apple Calendar CLI Tools

A collection of command-line tools for managing Apple Calendar events with JSON output and human-readable formatting options.

## Why

Apple Calendar doesn't provide a public API for programmatic access, making calendar integration challenging for automation and AI assistants. These CLI tools bridge that gap by using AppleScript to interact with the native Calendar app, providing a standardized JSON interface.

**Key Use Cases:**
- **AI Assistant Integration**: Enable Claude, ChatGPT, or other AI tools to manage calendar events through simple CLI commands
- **Project Automation**: Programmatically schedule and track project-related events and deadlines  
- **Cross-Platform Workflows**: Integrate Apple Calendar with shell scripts, Python applications, and other automation tools
- **Data Export/Analysis**: Extract calendar data in structured JSON format for reporting and analysis

This approach works around Apple's API limitations while maintaining full compatibility with the native Calendar app and all its features (sync, notifications, etc.).

## Tools Overview

### Core CLI Tools (AppleScript-based)

**Calendar Management:**
- **`cal-list`** - List available calendars
- **`cal-create-cal`** - Create a new calendar
- **`cal-delete-cal`** - ⚠️ Delete a calendar (limited by macOS security)

**Event Management:**
- **`cal-get`** - Get events from a calendar within a date range
- **`cal-add`** - Add a new event to a calendar
- **`cal-delete`** - Delete events by title from a calendar

### Formatting Tools

- **`cal-format`** - Python tool to convert JSON output to human-readable formats
- **`jq-examples.md`** - Examples of using `jq` for advanced JSON processing

## Usage

### List Calendars
```bash
./cal-list
./cal-list | ./cal-format
```

### Create Calendars
```bash
# Create calendar with name only
./cal-create-cal "My New Calendar"

# Create calendar with description
./cal-create-cal "Project Calendar" "Calendar for project tasks"

# Ignore error if calendar already exists
./cal-create-cal "My Calendar" --ignore-exists
./cal-create-cal "My Calendar" "Description" --ignore-exists

# With human-readable confirmation
./cal-create-cal "My Calendar" | ./cal-format
```

### Delete Calendars

**⚠️ macOS Security Limitation**

Due to macOS security restrictions, **calendar deletion is not reliable through AppleScript** on modern macOS versions. The `cal-delete-cal` tool exists but will typically fail with "AppleEvent handler failed" errors.

**Recommended Approach**: Delete calendars manually through the Calendar app:
1. Open Calendar.app
2. Right-click on the calendar in the sidebar  
3. Select "Delete Calendar"

```bash
# These commands may fail on modern macOS due to security restrictions:
./cal-delete-cal "Calendar Name"          # Often fails
./cal-delete-cal "Calendar Name" --force  # Often fails
```

This limitation exists to prevent malicious scripts from deleting user calendar data.

### Get Events
```bash
# Get events for a date range (example dates)
./cal-get "Calendar Name" 2024-12-15 2024-12-16

# With human-readable formatting
./cal-get "Calendar Name" $(date +%Y-%m-%d) $(date -d '+1 day' +%Y-%m-%d) | ./cal-format --format agenda
./cal-get "Calendar Name" $(date +%Y-%m-%d) $(date -d '+1 day' +%Y-%m-%d) | ./cal-format --format table
./cal-get "Calendar Name" $(date +%Y-%m-%d) $(date -d '+1 day' +%Y-%m-%d) | ./cal-format --format summary
```

### Add Events
```bash
# Add event with title, start/end times (example date)
./cal-add "Calendar Name" "Meeting Title" 2024-12-15-14-00 2024-12-15-15-00

# Add event with description
./cal-add "Calendar Name" "Meeting Title" 2024-12-15-14-00 2024-12-15-15-00 "Meeting description"

# With human-readable confirmation
./cal-add "Calendar Name" "Meeting Title" 2024-12-15-14-00 2024-12-15-15-00 | ./cal-format
```

### Delete Events
```bash
# Delete events by title within date range (example date)
./cal-delete "Calendar Name" "Meeting Title" 2024-12-15 2024-12-15

# With human-readable confirmation
./cal-delete "Calendar Name" "Meeting Title" 2024-12-15 2024-12-15 | ./cal-format
```

## Date Formats

### For `cal-get` and `cal-delete`
- `YYYY-MM-DD` (time defaults to 00:00)
- `YYYY-MM-DD-HH-MM` (24-hour format)

### For `cal-add`
- `YYYY-MM-DD-HH-MM` (24-hour format, required for both start and end)

## Timezone Handling

### Default Behavior
- **All dates and times use the system timezone** by default
- Events are created and displayed in your macOS system timezone
- JSON output includes timezone offset (e.g., `-08:00`, `+05:30`)

### How It Works
1. **Input dates** (like `2024-12-15-14-00`) are interpreted as local time in your system timezone
2. **Output dates** include the timezone offset for clarity (ISO 8601 format)
3. **Calendar app integration** respects your system timezone settings

### Examples
```bash
# System timezone: PST (-08:00)
./cal-add "Work" "Meeting" 2024-12-15-14-00 2024-12-15-15-00
# Creates event: 2:00 PM - 3:00 PM PST
# JSON output: "startDate": "2024-12-15T14:00:00-08:00"

# System timezone: EST (-05:00) 
# Same command creates: 2:00 PM - 3:00 PM EST
# JSON output: "startDate": "2024-12-15T14:00:00-05:00"
```

### Timezone Support in Calendar App
- If you have **"Time Zone Support"** enabled in Calendar preferences, events maintain their timezone
- If disabled, events are displayed relative to your current system timezone
- The CLI tools work with both settings - they always use your system timezone as the reference

## JSON Output Format

All tools output JSON with consistent structure:

### Events List (`cal-get`)
```json
{
  "events": [
    {
      "title": "Event Title",
      "description": "Event description",
      "startDate": "2024-12-15T14:00:00-08:00",
      "endDate": "2024-12-15T15:00:00-08:00"
    }
  ]
}
```

### Calendar List (`cal-list`)
```json
{
  "calendars": ["Calendar 1", "Calendar 2"]
}
```

### Event Operation Results (`cal-add`, `cal-delete`)
```json
{
  "status": "created",
  "event": {
    "title": "Event Title",
    "description": "Event description",
    "startDate": "2024-12-15T14:00:00-08:00",
    "endDate": "2024-12-15T15:00:00-08:00"
  }
}
```

### Calendar Operation Results (`cal-create-cal`, `cal-delete-cal`)
```json
{
  "status": "created",
  "calendar": {
    "name": "Calendar Name",
    "description": "Calendar description"
  },
  "message": "Calendar created successfully"
}
```

### Error Format
```json
{
  "error": "Error message"
}
```

## Formatting Options

The `cal-format` tool supports three output formats:

- **`agenda`** (default) - Timeline view grouped by date with emojis
- **`table`** - Clean table format showing title, start, and end times
- **`summary`** - Overview with statistics and event list

## Advanced Usage with jq

See `docs/jq-examples.md` for comprehensive examples of processing JSON output with `jq` for:
- Filtering events
- Custom formatting
- Date/time manipulation
- Creating reports
- Error handling

## AI Assistant Integration

See `docs/ai-integration.md` for guidance on integrating these tools with AI assistants like Claude, ChatGPT, and others. The guide includes:
- Command patterns optimized for LLM understanding
- Common workflows and automation examples
- Error handling and best practices
- Platform-specific integration strategies

## Examples

```bash
# Create project calendar
./bin/cal-create-cal "Project Alpha" "Tasks and meetings for Project Alpha" | ./bin/cal-format

# Today's agenda
./bin/cal-get "Work" $(date +%Y-%m-%d) $(date +%Y-%m-%d) | ./bin/cal-format

# This week's events in table format
./bin/cal-get "Personal" $(date +%Y-%m-%d) $(date -d '+7 days' +%Y-%m-%d) | ./bin/cal-format --format table

# Quick event creation (example date)
./bin/cal-add "Work" "Team Meeting" 2024-12-15-10-00 2024-12-15-11-00 "Weekly standup"

# Find meetings containing "review"
./bin/cal-get "Work" $(date -d 'first day of this month' +%Y-%m-%d) $(date -d 'last day of this month' +%Y-%m-%d) | jq '.events[] | select(.title | contains("review"))'

# Count events per calendar (current month)
for cal in $(./bin/cal-list | jq -r '.calendars[]'); do
  start_date=$(date -d 'first day of this month' +%Y-%m-%d)
  end_date=$(date -d 'last day of this month' +%Y-%m-%d)
  count=$(./bin/cal-get "$cal" "$start_date" "$end_date" | jq '.events | length')
  echo "$cal: $count events"
done

# Note: Calendar deletion often fails due to macOS security restrictions
# Recommend manual deletion through Calendar app instead
```

## Error Handling

All tools return JSON with error information when operations fail:
- Invalid calendar names
- Date parsing errors
- Permission issues
- Calendar app connectivity problems

Use `./bin/cal-format` or `jq` to display errors in a user-friendly format.

## Project Structure

```
apple-calendar-cli-tools/
├── README.md                    # Main documentation
├── LICENSE                      # License  
├── bin/                         # CLI tools (production)
│   ├── cal-add                  # Add events
│   ├── cal-create-cal           # Create calendars
│   ├── cal-delete               # Delete events
│   ├── cal-delete-cal           # Delete calendars (limited by macOS)
│   ├── cal-format               # Format JSON output
│   ├── cal-get                  # Get events
│   └── cal-list                 # List calendars
├── lib/                         # Production utilities
│   ├── calendar-utils.applescript
│   └── calendar-utils.scpt
├── tests/                       # Test suite
│   ├── TESTING.md               # Test documentation
│   ├── run-all-tests            # Main test runner
│   ├── test-events              # Event operations tests
│   ├── test-calendars           # Calendar operations tests
│   ├── test-formats             # Formatting & edge cases tests
│   ├── test-errors              # Error handling tests
│   ├── test-calendar-creation   # Calendar creation tests
│   ├── lib/                     # Test utilities
│   └── tools/                   # Test-specific tools
└── docs/                        # Documentation
    ├── jq-examples.md           # Advanced jq usage examples
    └── ai-integration.md        # AI assistant integration guide
```

## Installation

### Prerequisites

- **macOS** with Calendar app
- **Terminal access** with Calendar permissions
- **Python 3** (for cal-format tool)
- **jq** (optional, for advanced JSON processing)

### Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/apple-calendar-cli-tools.git
   cd apple-calendar-cli-tools
   ```

2. **Make scripts executable:**
   ```bash
   chmod +x cal-*
   ```

3. **Grant Calendar permissions:**
   - Go to System Preferences → Security & Privacy → Privacy → Automation
   - Allow Terminal (or your shell) to control Calendar
   - Or run any CLI tool and approve the permission prompt

4. **Test the installation:**
   ```bash
   ./cal-list | ./cal-format
   ```

### Optional: Add to PATH

Add the directory to your PATH for global access:
```bash
echo 'export PATH="$PATH:/path/to/apple-calendar-cli-tools"' >> ~/.bashrc
# OR for zsh
echo 'export PATH="$PATH:/path/to/apple-calendar-cli-tools"' >> ~/.zshrc
```

## Testing

Run the comprehensive test suite:
```bash
./tests/run-all-tests
```

Individual test suites:
```bash
./tests/test-events           # Event operations (create, retrieve, delete)
./tests/test-calendars        # Calendar operations (list, existence verification)
./tests/test-formats          # Content formatting and special characters
./tests/test-errors           # Error handling and edge cases
./tests/test-calendar-creation # Calendar creation (separate due to deletion limitations)
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`./tests/run-all-tests`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built for the macOS Calendar app ecosystem
- Designed to work seamlessly with AI assistants like Claude
- Inspired by the need for programmatic calendar access on macOS