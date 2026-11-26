' ============================================================================
' LoadingOverlay.brs
' ============================================================================

sub init()
    m.spinner = m.top.FindNode("spinner")
    ' BusySpinner rotates whatever image we give it (96x96).
    m.spinner.poster.uri = "pkg:/images/spinner.png"

    ' Only spin while visible, to save CPU.
    m.top.ObserveField("visible", "onVisibleChange")
    onVisibleChange()
end sub

sub onVisibleChange()
    if m.top.visible
        m.spinner.control = "start"
    else
        m.spinner.control = "stop"
    end if
end sub
