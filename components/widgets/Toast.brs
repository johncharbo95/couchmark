' ============================================================================
' Toast.brs
' ============================================================================

sub init()
    m.box = m.top.FindNode("box")
    m.label = m.top.FindNode("label")
    m.timer = m.top.FindNode("timer")
    m.timer.ObserveField("fire", "onTimer")
end sub

sub onMessage()
    m.label.text = m.top.message
    m.box.visible = true
    m.timer.control = "stop"
    m.timer.control = "start"
end sub

sub onTimer()
    m.box.visible = false
end sub
