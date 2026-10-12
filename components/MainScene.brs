' ============================================================================
' MainScene.brs — screen stack + USB library scanning
' ============================================================================

sub init()
    m.screenLayer = m.top.FindNode("screenLayer")
    m.loading = m.top.FindNode("loading")
    m.rescanTimer = m.top.FindNode("rescanTimer")
    m.rescanTimer.ObserveField("fire", "startUsbScan")

    ' The stack of open screens. The last element is the visible one.
    m.stack = []

    ' m.global is a node every component can read. We keep the scanned
    ' library there so any screen can find the Movies/Shows/Other folders.
    '   library = {
    '       volumes: ["ext1:", ...],
    '       roots:   { movies: ["ext1:/Movies", ...], shows: [...], other: [...] }
    '   }
    m.global.AddFields({ library: {} })

    startUsbScan()
end sub

' ----------------------------------------------------------------------------
' USB scanning
' ----------------------------------------------------------------------------

sub startUsbScan()
    m.loading.message = "Looking for USB drives…"
    m.loading.visible = true

    ' Task nodes run their function on a background thread, so the UI never
    ' freezes while we read the drive. We get notified when "result" changes.
    m.scanTask = CreateObject("roSGNode", "UsbScanTask")
    m.scanTask.ObserveField("result", "onUsbScanDone")
    m.scanTask.control = "run"
end sub

sub onUsbScanDone(event as Object)
    ' Ignore results from an older scan if a newer one has been started.
    if not event.GetRoSGNode().IsSameNode(m.scanTask) then return

    library = event.GetData()
    m.global.library = library
    m.loading.visible = false

    ' Whatever was open is now stale (a drive may have vanished): start over.
    clearStack()

    roots = library.roots
    hasAnything = roots.movies.Count() + roots.shows.Count() + roots.other.Count() > 0

    if hasAnything
        pushScreen(CreateObject("roSGNode", "HomeScreen"))
    else
        msg = CreateObject("roSGNode", "MessageScreen")
        if library.volumes.Count() = 0
            msg.title = "No USB drive found"
            msg.message = "Plug a USB drive into your TV and Couchmark will find it automatically." + Chr(10) + Chr(10) + UsbLayoutHelp()
        else
            msg.title = "No Couchmark folders on your USB drive"
            msg.message = "Couchmark found a drive but none of the folders it looks for." + Chr(10) + Chr(10) + UsbLayoutHelp()
        end if
        msg.allowRescan = true
        pushScreen(msg)
    end if
end sub

sub onVolumesChanged()
    ' Restart the timer: several events in a row only trigger one rescan.
    m.rescanTimer.control = "stop"
    m.rescanTimer.control = "start"
end sub

' ----------------------------------------------------------------------------
' Screen stack
' ----------------------------------------------------------------------------

sub pushScreen(screen as Object)
    if m.stack.Count() > 0 then m.stack.Peek().visible = false

    screen.ObserveField("navigate", "onNavigate")
    m.screenLayer.AppendChild(screen)
    m.stack.Push(screen)
    screen.SetFocus(true)
end sub

sub popScreen()
    screen = m.stack.Pop()
    screen.UnobserveField("navigate")
    m.screenLayer.RemoveChild(screen)

    if m.stack.Count() > 0
        top = m.stack.Peek()
        top.visible = true
        top.SetFocus(true)
    end if
end sub

sub clearStack()
    while m.stack.Count() > 0
        popScreen()
    end while
end sub

' A screen set its "navigate" field. Supported requests:
'   { screen: "ComponentName", fields: { ...values for the new screen... } }
'   { screen: ..., fields: ..., replace: true }  close the current screen first
'   { action: "back" }    close the current screen
'   { action: "rescan" }  rescan USB drives
' (We use DoesExist because comparing a missing (invalid) value with a
'  string is a runtime error in BrightScript.)
sub onNavigate(event as Object)
    request = event.GetData()
    if request = invalid then return

    if request.DoesExist("action")
        if request.action = "rescan"
            startUsbScan()
        else if request.action = "back"
            if m.stack.Count() > 1 then popScreen()
        end if
        return
    end if

    if request.DoesExist("screen")
        if request.DoesExist("replace") then popScreen()
        screen = CreateObject("roSGNode", request.screen)
        if request.DoesExist("fields") then screen.SetFields(request.fields)
        pushScreen(screen)
    end if
end sub

' Keys that no screen handled "bubble up" to here.
function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "back" and m.stack.Count() > 1
        popScreen()
        return true
    end if

    ' Returning false on the first screen lets Roku exit the app.
    return false
end function
