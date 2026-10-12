' ============================================================================
' UpNextOverlay.brs
' ============================================================================

sub init()
    m.countdownLabel = m.top.FindNode("countdownLabel")
    m.timer = m.top.FindNode("timer")
    m.timer.ObserveField("fire", "onTick")
end sub

sub onStart()
    m.remaining = m.top.seconds
    updateCountdown()
    m.timer.control = "start"
end sub

sub onTick()
    m.remaining = m.remaining - 1
    if m.remaining <= 0
        finish("play")
    else
        updateCountdown()
    end if
end sub

sub updateCountdown()
    m.countdownLabel.text = "Starting in " + m.remaining.ToStr() + "s"
end sub

sub finish(choice as String)
    m.timer.control = "stop"
    m.top.choice = choice
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if key = "OK" or key = "play"
        finish("play")
        return true
    else if key = "back"
        finish("cancel")
        return true
    end if
    ' Swallow other keys so they don't reach the hidden player.
    return true
end function
