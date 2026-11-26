' ============================================================================
' Format.brs — small text formatting helpers
' ============================================================================

' 3734 -> "1:02:14", 845 -> "14:05"
function FormatTime(totalSeconds as Integer) as String
    hours = totalSeconds \ 3600
    minutes = (totalSeconds mod 3600) \ 60
    seconds = totalSeconds mod 60

    if hours > 0
        return hours.ToStr() + ":" + pad2(minutes) + ":" + pad2(seconds)
    end if
    return minutes.ToStr() + ":" + pad2(seconds)
end function

' Rough time left for tiles: 3900 -> "1 h 5 min", 1380 -> "23 min"
function FormatRemaining(totalSeconds as Integer) as String
    minutes = (totalSeconds + 59) \ 60
    if minutes < 60 then return minutes.ToStr() + " min"
    return (minutes \ 60).ToStr() + " h " + (minutes mod 60).ToStr() + " min"
end function

' Player time on the right of the scrubber: time left / total length.
'   (845, 2640) -> "-29:55 / 44:00"     "" while the length is unknown
function FormatRemainingOfTotal(position as Integer, duration as Integer) as String
    if duration <= 0 then return ""
    remaining = duration - position
    if remaining < 0 then remaining = 0
    return "-" + FormatTime(remaining) + " / " + FormatTime(duration)
end function

' 5 -> "05"
function pad2(value as Integer) as String
    if value < 10 then return "0" + value.ToStr()
    return value.ToStr()
end function

' Home screen clock, always 24-hour. `now` is { weekday (0 = Sunday),
' month (1-12), day, hour (0-23), minute }.
'   Wed 25 Nov 2026 19:05 -> "Wed, Nov 25  ·  19:05"
function FormatClock(now as Object) as String
    days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    dateText = days[now.weekday] + ", " + months[now.month - 1] + " " + now.day.ToStr()
    return dateText + "  ·  " + pad2(now.hour) + ":" + pad2(now.minute)
end function
