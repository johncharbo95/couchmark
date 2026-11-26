' @include components/lib/Settings.brs
' @include components/lib/Transitions.brs
' @double tests/doubles/Registry.brs

sub Main()
    resetRegistry()
    assertEqual(SettingsGet(), { photoSeconds: 5, transition: "fade", speed: "normal", saveLogs: "on" }, "defaults")

    SettingsSave({ photoSeconds: 10, transition: "wipe", speed: "fast" })
    ' (Compare fields one by one: keys set with dot notation are stored in
    '  lower case, so the JSON text of the whole object would differ.)
    saved = SettingsGet()
    assertEqual(saved.photoSeconds, 10, "saved duration comes back")
    assertEqual(saved.transition, "wipe", "saved transition comes back")
    assertEqual(saved.speed, "fast", "saved speed comes back")

    ' Damaged registry values fall back to defaults.
    section = settingsSection()
    section.Write("dur", "7")
    section.Write("tr", "spin")
    assertEqual(SettingsGet().photoSeconds, 5, "unknown duration: default")
    assertEqual(SettingsGet().transition, "fade", "unknown transition: default")

    ' Debug log on/off (on by default; saving without the key keeps it).
    assertEqual(SettingsGet().saveLogs, "on", "logs on by default")
    settings = SettingsGet()
    settings.saveLogs = NextSettingValue("saveLogs", settings.saveLogs, 1)
    SettingsSave(settings)
    assertEqual(SettingsGet().saveLogs, "off", "logs switched off")
    assertEqual(NextSettingValue("saveLogs", "off", 1), "on", "and back on")
    SettingsSave({ photoSeconds: 5, transition: "fade", speed: "normal" })
    assertEqual(SettingsGet().saveLogs, "off", "older callers don't reset it")
    section.Write("log", "maybe")
    assertEqual(SettingsGet().saveLogs, "on", "damaged value: default")
    assertEqual(SettingLabel("saveLogs", "off"), "Off", "on/off label")

    assertEqual(NextSettingValue("photoSeconds", 5, 1), 8, "next duration")
    assertEqual(NextSettingValue("photoSeconds", 30, 1), 3, "wraps at the end")
    assertEqual(NextSettingValue("photoSeconds", 3, -1), 30, "wraps at the start")
    assertEqual(NextSettingValue("speed", "normal", -1), "slow", "previous speed")
    assertEqual(NextSettingValue("transition", "zoom", 1), "random", "next transition")

    assertEqual(SettingLabel("photoSeconds", 8), "8 seconds", "duration label")
    assertEqual(SettingLabel("transition", "random"), "Random", "capitalised label")

    ' Settings and the slideshow agree on the transition names.
    assertEqual(SettingOptions("transition"), TransitionNames(), "same transition list")
    finishTests()
end sub
