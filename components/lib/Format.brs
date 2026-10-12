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

function pad2(value as Integer) as String
    return Right("0" + value.ToStr(), 2)
end function
