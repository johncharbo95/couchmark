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

' 5 -> "05"
function pad2(value as Integer) as String
    if value < 10 then return "0" + value.ToStr()
    return value.ToStr()
end function
