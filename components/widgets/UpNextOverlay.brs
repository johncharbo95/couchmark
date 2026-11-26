' ============================================================================
' UpNextOverlay.brs
' ============================================================================

sub init()
    m.countdownLabel = m.top.FindNode("countdownLabel")
end sub

sub onSecondsChange()
    m.countdownLabel.text = "Starting in " + m.top.seconds.ToStr() + " s"
end sub
