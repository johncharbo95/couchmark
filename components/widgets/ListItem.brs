' ============================================================================
' ListItem.brs
' ============================================================================

sub init()
    m.background = m.top.FindNode("background")
    m.focusBar = m.top.FindNode("focusBar")
    m.title = m.top.FindNode("title")
    m.check = m.top.FindNode("check")
    m.progressBar = m.top.FindNode("progressBar")
    m.progressFill = m.top.FindNode("progressFill")
end sub

sub onContentSet()
    item = m.top.itemContent
    if item = invalid then return

    m.title.text = item.title
    updateBadge()

    ' The screen changes "badge"/"progress" after returning from the player,
    ' so watch those fields on the node we're drawing. Lists reuse row
    ' components while scrolling, so stop watching the previous node first.
    if m.watched <> invalid
        m.watched.UnobserveFieldScoped("badge")
        m.watched.UnobserveFieldScoped("progress")
    end if
    item.ObserveFieldScoped("badge", "updateBadge")
    item.ObserveFieldScoped("progress", "updateBadge")
    m.watched = item
end sub

sub updateBadge()
    item = m.top.itemContent
    badge = ""
    if item.HasField("badge") then badge = item.badge

    m.check.visible = (badge = "watched")
    m.progressBar.visible = (badge = "partial")
    if badge = "partial"
        ' Always show at least a sliver so "started" is visible.
        fraction = item.progress
        if fraction < 0.03 then fraction = 0.03
        if fraction > 1 then fraction = 1
        m.progressFill.width = 180 * fraction
    end if
end sub

sub onFocusPercentChange()
    p = m.top.focusPercent
    m.focusBar.opacity = p
    if p > 0.5
        m.background.color = "0x2A3440FF"
    else
        m.background.color = "0x1E252DFF"
    end if
end sub
