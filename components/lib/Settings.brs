' ============================================================================
' Settings.brs — user settings, stored in the registry section "settings"
'
'   setting        registry key  values (default marked *)
'   photoSeconds   dur           3, 5*, 8, 10, 15, 30
'   transition     tr            none, fade*, slide, push, wipe, zoom, random
'   speed          spd           slow, normal*, fast
'
' SettingOptions / SettingLabel / NextSettingValue drive the Settings screen
' and are plain functions (unit-tested in tests/Settings.test.brs).
' Needs: Transitions.brs
' ============================================================================

function SettingsDefaults() as Object
    return { photoSeconds: 5, transition: "fade", speed: "normal" }
end function

' Returns { photoSeconds, transition, speed }. Unknown or damaged values
' fall back to the defaults.
function SettingsGet() as Object
    settings = SettingsDefaults()
    section = settingsSection()
    if section.Exists("dur")
        seconds = section.Read("dur").ToInt()
        if isOption("photoSeconds", seconds) then settings.photoSeconds = seconds
    end if
    if section.Exists("tr")
        value = section.Read("tr")
        if isOption("transition", value) then settings.transition = value
    end if
    if section.Exists("spd")
        value = section.Read("spd")
        if isOption("speed", value) then settings.speed = value
    end if
    return settings
end function

sub SettingsSave(settings as Object)
    section = settingsSection()
    section.Write("dur", settings.photoSeconds.ToStr())
    section.Write("tr", settings.transition)
    section.Write("spd", settings.speed)
    section.Flush()
end sub

' The choices for a setting, in display order.
function SettingOptions(key as String) as Object
    if key = "photoSeconds" then return [3, 5, 8, 10, 15, 30]
    if key = "transition" then return TransitionNames()   ' lib/Transitions.brs
    if key = "speed" then return ["slow", "normal", "fast"]
    return []
end function

' How a value is shown: 5 -> "5 seconds", "fade" -> "Fade".
function SettingLabel(key as String, value as Dynamic) as String
    if key = "photoSeconds" then return value.ToStr() + " seconds"
    return UCase(Left(value, 1)) + Mid(value, 2)
end function

' The value after (delta = 1) or before (delta = -1) the current one,
' wrapping around at either end.
function NextSettingValue(key as String, current as Dynamic, delta as Integer) as Dynamic
    options = SettingOptions(key)
    index = 0
    for i = 0 to options.Count() - 1
        if options[i] = current then index = i
    end for
    index = (index + delta + options.Count()) mod options.Count()
    return options[index]
end function

function isOption(key as String, value as Dynamic) as Boolean
    for each option in SettingOptions(key)
        if option = value then return true
    end for
    return false
end function

function settingsSection() as Object
    return CreateObject("roRegistrySection", "settings")
end function
