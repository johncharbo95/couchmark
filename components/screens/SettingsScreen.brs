' ============================================================================
' SettingsScreen.brs
'
' Rows (each ContentNode has a "key" field):
'   photoSeconds / transition / speed   values from SettingOptions()
'   saveLogs                            debug log on/off (tells LogTask)
'   clear                               clear watch history (OK twice)
'   about                               version, read-only
' ============================================================================

sub init()
    m.list = m.top.FindNode("list")
    m.hint = m.top.FindNode("hint")
    m.list.ObserveField("itemSelected", "onItemSelected")
    m.list.ObserveField("itemFocused", "onItemFocused")
    m.top.ObserveField("focusedChild", "onFocusedChildChange")

    m.settings = SettingsGet()
    m.confirmingClear = false
    buildRows()
end sub

sub onFocusedChildChange()
    if m.top.HasFocus() then m.list.SetFocus(true)
end sub

sub buildRows()
    rows = CreateObject("roSGNode", "ContentNode")
    addRow(rows, "photoSeconds", "Photo duration")
    addRow(rows, "transition", "Transition")
    addRow(rows, "speed", "Transition speed")
    addRow(rows, "saveLogs", "Save debug logs to USB")
    addRow(rows, "clear", "Clear watch history")
    addRow(rows, "about", "About Couchmark")
    m.list.content = rows
    for each row in rows.GetChildren(-1, 0)
        updateRow(row)
    end for
    onItemFocused()
end sub

sub addRow(rows as Object, key as String, title as String)
    row = rows.CreateChild("ContentNode")
    row.title = title
    row.AddFields({ key: key, detail: "", badge: "", progress: 0.0 })
end sub

' The value shown on the right of a row.
sub updateRow(row as Object)
    key = row.key
    if key = "clear"
        if m.confirmingClear then row.detail = "Press OK again to confirm" else row.detail = ""
    else if key = "about"
        row.detail = "Version " + CreateObject("roAppInfo").GetVersion()
    else
        row.detail = "<   " + SettingLabel(key, m.settings[key]) + "   >"
    end if
end sub

' The grey help line under the list describes the highlighted row.
sub onItemFocused()
    row = focusedRow()
    if row = invalid then return

    ' Moving away cancels a half-done "clear history".
    if m.confirmingClear and row.key <> "clear"
        m.confirmingClear = false
        updateRow(rowByKey("clear"))
    end if

    hints = {
        photoSeconds: "How long each photo stays on screen in a slideshow. Videos always play to the end."
        transition: "How one photo changes to the next. Random picks a different effect each time."
        speed: "How long the transition takes: slow 1.5 s, normal 0.8 s, fast 0.4 s."
        saveLogs: "Writes what Couchmark does to Couchmark/logs on your USB drive (one file per day, last 7 days kept), to help find problems. Nothing is sent anywhere."
        clear: "Forgets every resume point and watched mark for movies and shows. Your files are not touched."
        about: "Open source, MIT license. Plays media from USB drives; nothing leaves your TV."
    }
    m.hint.text = hints[row.key]
    if row.key = "saveLogs" then m.hint.text = m.hint.text + Chr(10) + logTargetText()
    ' Development builds: also show which commit is running.
    if row.key = "about"
        build = BuildInfoText(ReadBuildInfo())
        if build <> "" then m.hint.text = m.hint.text + Chr(10) + Chr(10) + build
    end if
end sub

function focusedRow() as Dynamic
    if m.list.content = invalid or m.list.itemFocused < 0 then return invalid
    return m.list.content.GetChild(m.list.itemFocused)
end function

function rowByKey(key as String) as Dynamic
    for each row in m.list.content.GetChildren(-1, 0)
        if row.key = key then return row
    end for
    return invalid
end function

' Where the log is being written right now (LogTask.target).
function logTargetText() as String
    if m.settings.saveLogs <> "on" then return "Off: nothing is written."
    logTask = m.global.logTask
    if logTask = invalid or logTask.target = "" then return "No folder could be written yet."
    if Left(logTask.target, 4) = "tmp:" then return "No writable USB drive: the log is kept on the TV until it restarts."
    return "Saving to " + logTask.target
end function

' The Log task follows the setting right away.
sub applyLogSetting()
    logTask = m.global.logTask
    if logTask <> invalid then logTask.enabled = (m.settings.saveLogs = "on")
    LogInfo("Settings", "save debug logs: " + m.settings.saveLogs)
end sub

' Left / Right change the value (the list itself only uses Up / Down).
function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if key = "left" then return changeFocused(-1)
    if key = "right" then return changeFocused(1)
    return false
end function

function changeFocused(delta as Integer) as Boolean
    row = focusedRow()
    if row = invalid or not m.settings.DoesExist(row.key) then return false
    m.settings[row.key] = NextSettingValue(row.key, m.settings[row.key], delta)
    SettingsSave(m.settings)
    updateRow(row)
    if row.key = "saveLogs"
        applyLogSetting()
        onItemFocused()   ' refresh the hint
    end if
    return true
end function

sub onItemSelected()
    row = m.list.content.GetChild(m.list.itemSelected)
    if row.key = "clear"
        if m.confirmingClear
            ProgressClearAll()
            m.confirmingClear = false
            row.detail = "Cleared"
        else
            m.confirmingClear = true
            updateRow(row)
        end if
    else
        changeFocused(1)
    end if
end sub
