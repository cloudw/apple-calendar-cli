-- Shared utility functions for Calendar CLI tools
-- This library consolidates common AppleScript functions to eliminate code duplication

-- JSON String Escaping with HTML cleaning support
on escapeJSONString(inputString)
    if inputString is missing value then return ""
    if inputString is "" then return ""
    
    set cleanedString to inputString as string
    
    -- Limit length to prevent JSON corruption
    if length of cleanedString > 1000 then
        set cleanedString to (characters 1 thru 1000 of cleanedString as string) & "..."
    end if
    
    -- Escape JSON special characters
    set escapedString to cleanedString
    
    -- Replace backslashes first (must be first)
    set escapedString to my replaceText(escapedString, "\\", "\\\\")
    
    -- Replace quotes
    set escapedString to my replaceText(escapedString, "\"", "\\\"")
    
    -- Replace newlines and returns
    set escapedString to my replaceText(escapedString, return, "\\n")
    set escapedString to my replaceText(escapedString, linefeed, "\\n")
    
    -- Replace tabs
    set escapedString to my replaceText(escapedString, tab, "\\t")
    
    -- Replace other problematic characters
    set escapedString to my replaceText(escapedString, "\r", "\\r")
    
    return escapedString
end escapeJSONString

-- Enhanced JSON escaping with HTML tag removal (for event content)
on cleanAndEscapeJSON(inputString)
    if inputString is missing value then return ""
    if inputString is "" then return ""
    
    set cleanedString to inputString as string
    
    -- Remove HTML tags (basic cleanup)
    set cleanedString to my removeHTMLTags(cleanedString)
    
    -- Limit length to prevent JSON corruption
    if length of cleanedString > 1000 then
        set cleanedString to (characters 1 thru 1000 of cleanedString as string) & "..."
    end if
    
    -- Use standard JSON escaping
    return my escapeJSONString(cleanedString)
end cleanAndEscapeJSON

-- HTML tag removal utility
on removeHTMLTags(inputString)
    if inputString is missing value then return ""
    if inputString is "" then return ""
    
    set cleanedString to inputString
    
    -- Basic HTML tag removal (simple approach)
    -- Remove <tag> and </tag> patterns
    repeat
        set tagStart to 0
        set tagEnd to 0
        
        -- Find opening <
        repeat with i from 1 to length of cleanedString
            if character i of cleanedString is "<" then
                set tagStart to i
                exit repeat
            end if
        end repeat
        
        if tagStart is 0 then exit repeat
        
        -- Find closing >
        repeat with i from tagStart to length of cleanedString
            if character i of cleanedString is ">" then
                set tagEnd to i
                exit repeat
            end if
        end repeat
        
        if tagEnd is 0 then exit repeat
        
        -- Remove the tag
        if tagStart is 1 then
            if tagEnd is length of cleanedString then
                set cleanedString to ""
            else
                set cleanedString to (characters (tagEnd + 1) thru -1 of cleanedString) as string
            end if
        else if tagEnd is length of cleanedString then
            set cleanedString to (characters 1 thru (tagStart - 1) of cleanedString) as string
        else
            set cleanedString to (characters 1 thru (tagStart - 1) of cleanedString) as string & (characters (tagEnd + 1) thru -1 of cleanedString) as string
        end if
    end repeat
    
    -- Clean up HTML entities (basic ones)
    set cleanedString to my replaceText(cleanedString, "&nbsp;", " ")
    set cleanedString to my replaceText(cleanedString, "&amp;", "&")
    set cleanedString to my replaceText(cleanedString, "&lt;", "<")
    set cleanedString to my replaceText(cleanedString, "&gt;", ">")
    set cleanedString to my replaceText(cleanedString, "&quot;", "\"")
    set cleanedString to my replaceText(cleanedString, "&#39;", "'")
    set cleanedString to my replaceText(cleanedString, "<br>", " ")
    set cleanedString to my replaceText(cleanedString, "<br/>", " ")
    set cleanedString to my replaceText(cleanedString, "<br />", " ")
    
    -- Clean up multiple spaces and newlines
    repeat while cleanedString contains "  "
        set cleanedString to my replaceText(cleanedString, "  ", " ")
    end repeat
    
    return cleanedString
end removeHTMLTags

-- Text replacement utility using AppleScript's text item delimiters
on replaceText(inputString, searchString, replaceString)
    set AppleScript's text item delimiters to searchString
    set textItems to text items of inputString
    set AppleScript's text item delimiters to replaceString
    set outputString to textItems as string
    set AppleScript's text item delimiters to ""
    return outputString
end replaceText

-- String splitting utility
on splitString(inputString, delimiter)
    set AppleScript's text item delimiters to delimiter
    set stringItems to text items of inputString
    set AppleScript's text item delimiters to ""
    return stringItems
end splitString

-- Date parsing with flexible component count
on parse_date(dateStr, requiredComponents)
    set dateComponents to my splitString(dateStr, "-")
    
    if length of dateComponents < 3 then
        error "Invalid date format. Use YYYY-MM-DD or YYYY-MM-DD-HH-MM"
    end if
    
    -- Check if we have the required number of components
    if requiredComponents is not missing value and length of dateComponents < requiredComponents then
        if requiredComponents = 5 then
            error "Invalid date format. Use YYYY-MM-DD-HH-MM"
        else
            error "Invalid date format. Use YYYY-MM-DD or YYYY-MM-DD-HH-MM"
        end if
    end if
    
    set yearNum to (item 1 of dateComponents) as integer
    set monthNum to (item 2 of dateComponents) as integer
    set dayNum to (item 3 of dateComponents) as integer
    
    set hourNum to 0
    set minuteNum to 0
    
    if length of dateComponents ≥ 4 then
        set hourNum to (item 4 of dateComponents) as integer
    end if
    
    if length of dateComponents ≥ 5 then
        set minuteNum to (item 5 of dateComponents) as integer
    end if
    
    return my make_date(yearNum, monthNum, dayNum, hourNum, minuteNum)
end parse_date

-- Date creation utility
on make_date(yearNum, monthNum, dayNum, hourNum, minuteNum)
    set newDate to current date
    set year of newDate to yearNum
    set month of newDate to monthNum
    set day of newDate to dayNum
    set hours of newDate to hourNum
    set minutes of newDate to minuteNum
    set seconds of newDate to 0
    return newDate
end make_date

-- ISO 8601 date formatting with timezone
on formatDateISO(dateValue)
    set yearStr to year of dateValue as string
    set monthNum to month of dateValue as integer
    set dayNum to day of dateValue
    set hourNum to hours of dateValue
    set minNum to minutes of dateValue
    set secNum to seconds of dateValue
    
    if monthNum < 10 then set monthStr to "0" & monthNum
    if monthNum ≥ 10 then set monthStr to monthNum as string
    if dayNum < 10 then set dayStr to "0" & dayNum
    if dayNum ≥ 10 then set dayStr to dayNum as string
    if hourNum < 10 then set hourStr to "0" & hourNum
    if hourNum ≥ 10 then set hourStr to hourNum as string
    if minNum < 10 then set minStr to "0" & minNum
    if minNum ≥ 10 then set minStr to minNum as string
    if secNum < 10 then set secStr to "0" & secNum
    if secNum ≥ 10 then set secStr to secNum as string
    
    -- Add timezone offset (system timezone)
    set gmtOffset to time to GMT
    set offsetHours to gmtOffset div 3600
    set offsetMinutes to (gmtOffset mod 3600) div 60
    if offsetHours ≥ 0 then
        set offsetSign to "+"
    else
        set offsetSign to "-"
        set offsetHours to -offsetHours
    end if
    
    if offsetHours < 10 then set offsetHoursStr to "0" & offsetHours as string
    if offsetHours ≥ 10 then set offsetHoursStr to offsetHours as string
    if offsetMinutes < 10 then set offsetMinutesStr to "0" & offsetMinutes as string
    if offsetMinutes ≥ 10 then set offsetMinutesStr to offsetMinutes as string
    
    set timezoneOffset to offsetSign & offsetHoursStr & ":" & offsetMinutesStr
    
    return yearStr & "-" & monthStr & "-" & dayStr & "T" & hourStr & ":" & minStr & ":" & secStr & timezoneOffset
end formatDateISO

-- Calendar result formatting for create/delete operations
on formatCalendarResult(status, calendarName, calendarDescription, message)
    set calendarNameJSON to my escapeJSONString(calendarName)
    set calendarDescJSON to my escapeJSONString(calendarDescription)
    set messageJSON to my escapeJSONString(message)
    
    set jsonOutput to "{"
    set jsonOutput to jsonOutput & "\"status\": \"" & status & "\","
    set jsonOutput to jsonOutput & "\"calendar\": {"
    set jsonOutput to jsonOutput & "\"name\": \"" & calendarNameJSON & "\","
    set jsonOutput to jsonOutput & "\"description\": \"" & calendarDescJSON & "\""
    set jsonOutput to jsonOutput & "},"
    set jsonOutput to jsonOutput & "\"message\": \"" & messageJSON & "\""
    set jsonOutput to jsonOutput & "}"
    
    return jsonOutput
end formatCalendarResult

-- Delete result formatting
on formatDeleteResult(status, calendarName, message)
    set calendarNameJSON to my escapeJSONString(calendarName)
    set messageJSON to my escapeJSONString(message)
    
    set jsonOutput to "{"
    set jsonOutput to jsonOutput & "\"status\": \"" & status & "\","
    set jsonOutput to jsonOutput & "\"calendar\": \"" & calendarNameJSON & "\","
    set jsonOutput to jsonOutput & "\"message\": \"" & messageJSON & "\""
    set jsonOutput to jsonOutput & "}"
    
    return jsonOutput
end formatDeleteResult