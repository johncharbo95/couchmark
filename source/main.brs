' ============================================================================
' main.brs — app entry point
'
' Roku calls Main() when the app launches. In a SceneGraph app, Main() only:
'   1. creates the screen and our root component (MainScene), and
'   2. runs an event loop until the user exits.
' All UI logic lives in components/ (which run on the "render thread").
' ============================================================================

sub Main(args as Dynamic)
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    scene = screen.CreateScene("MainScene")
    screen.Show()

    ' roFileSystem can tell us when a USB drive is plugged in or removed.
    ' Those events are only delivered here (to the main thread), so we
    ' forward them to the scene, which rescans the drives.
    fs = CreateObject("roFileSystem")
    fs.SetMessagePort(port)

    while true
        msg = Wait(0, port)
        msgType = Type(msg)

        if msgType = "roSGScreenEvent"
            if msg.IsScreenClosed() then return
        else if msgType = "roFileSystemEvent"
            print "[main] USB change: "; msg.GetMessage()
            scene.volumesChanged = true
        end if
    end while
end sub
