' ============================================================================
' ListItem.brs
' ============================================================================

sub init()
    m.background = m.top.FindNode("background")
    m.focusBar = m.top.FindNode("focusBar")
    m.title = m.top.FindNode("title")
    m.detail = m.top.FindNode("detail")
    m.check = m.top.FindNode("check")
    m.progressBar = m.top.FindNode("progressBar")
    m.progressTrack = m.top.FindNode("progressTrack")
    m.progressFill = m.top.FindNode("progressFill")
    m.barWidth = 180
end sub

sub onContentSet()
    item = m.top.itemContent
    if item = invalid then return

    layout(fieldOr(item, "rowWidth", 1610))
    m.title.text = item.title
    update()

    ' The screen changes badge/progress/detail after returning from the
    ' player, so watch those fields on the node we're drawing. Lists reuse
    ' row components while scrolling, so stop watching the previous node.
    if m.watched <> invalid
        for each name in ["badge", "progress", "detail"]
            m.watched.UnobserveFieldScoped(name)
        end for
    end if
    for each name in ["badge", "progress", "detail"]
        if item.HasField(name) then item.ObserveFieldScoped(name, "update")
    end for
    m.watched = item
end sub

' Positions everything for a row of the given width.
sub layout(width as Integer)
    m.background.width = width
    m.check.translation = [width - 70, 20]

    if width < 900
        ' Compact: title fills the row, thin progress bar along the bottom.
        m.compact = true
        m.title.width = width - 36 - 80
        m.detail.visible = false
        m.barWidth = width - 72
        m.progressBar.translation = [36, 70]
    else
        m.compact = false
        m.title.width = width - 36 - 560
        m.detail.visible = true
        m.detail.translation = [width - 540, 0]
        m.barWidth = 180
        m.progressBar.translation = [width - 210, 38]
    end if
    m.progressTrack.width = m.barWidth
end sub

sub update()
    item = m.top.itemContent
    badge = fieldOr(item, "badge", "")
    m.detail.text = fieldOr(item, "detail", "")

    m.check.visible = (badge = "watched")
    m.progressBar.visible = (badge = "partial")
    if badge = "partial"
        ' Always show at least a sliver so "started" is visible.
        fraction = fieldOr(item, "progress", 0.0)
        if fraction < 0.03 then fraction = 0.03
        if fraction > 1 then fraction = 1
        m.progressFill.width = m.barWidth * fraction
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

function fieldOr(node as Object, name as String, fallback as Dynamic) as Dynamic
    if node.HasField(name) then return node.GetField(name)
    return fallback
end function
