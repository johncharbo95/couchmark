' ============================================================================
' Settings.brs — user settings, stored in the registry section "settings"
'
'   key  meaning                         values (default first)
'   dur  seconds each photo is shown      5, 3, 8, 10, 15, 30
'   tr   slideshow transition             fade, none, slide, push, wipe, zoom, random
'   spd  transition speed                 normal, slow, fast
' ============================================================================

function SettingsDefaults() as Object
    return { photoSeconds: 5, transition: "fade", speed: "normal" }
end function

' Returns { photoSeconds, transition, speed }.
function SettingsGet() as Object
    settings = SettingsDefaults()
    section = CreateObject("roRegistrySection", "settings")
    if section.Exists("dur")
        seconds = section.Read("dur").ToInt()
        if seconds > 0 then settings.photoSeconds = seconds
    end if
    if section.Exists("tr") then settings.transition = section.Read("tr")
    if section.Exists("spd") then settings.speed = section.Read("spd")
    return settings
end function

sub SettingsSave(settings as Object)
    section = CreateObject("roRegistrySection", "settings")
    section.Write("dur", settings.photoSeconds.ToStr())
    section.Write("tr", settings.transition)
    section.Write("spd", settings.speed)
    section.Flush()
end sub
