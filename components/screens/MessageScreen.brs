' ============================================================================
' MessageScreen.brs
' ============================================================================

sub init()
    m.hintLabel = m.top.FindNode("hintLabel")
    updateHint()
end sub

sub updateHint()
    if m.top.allowRescan
        m.hintLabel.text = "Press OK to look for drives again"
    else
        m.hintLabel.text = "Press Back to return"
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if press and key = "OK" and m.top.allowRescan
        m.top.navigate = { action: "rescan" }
        return true
    end if
    return false
end function
