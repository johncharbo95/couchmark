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
    m.regularFont = m.title.font
    m.boldFont = CreateObject("roSGNode", "Font")
    m.boldFont.uri = "font:BoldSystemFontFile"
    m.boldFont.size = 36
    m.bold = false
end sub

sub onContentSet()
    item = m.top.itemContent
    if item = invalid then return

    layout(fieldOr(item, "rowWidth", 1610))
    m.title.text = item.title
    update()

    ' The screen changes badge/progress/detail after returning from the
    ' player, and listFocused/selected when focus or the season changes, so
    ' watch those fields on the node we're drawing. Lists reuse row
    ' components while scrolling, so stop watching the previous node.
    names = ["badge", "progress", "detail", "listFocused", "selected"]
    if m.watched <> invalid
        for each name in names
            m.watched.UnobserveFieldScoped(name)
        end for
    end if
    for each name in names
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
    applyStyle()
end sub

sub onFocusPercentChange()
    applyStyle()
end sub

' Colours for the current focus/selection state (lib/ListRowStyle.brs).
sub applyStyle()
    item = m.top.itemContent
    if item = invalid then return
    style = ListRowStyle(m.top.focusPercent, fieldOr(item, "listFocused", true), fieldOr(item, "selected", false), fieldOr(item, "strongCursor", false))
    m.background.color = style.background
    m.title.color = style.titleColor
    m.detail.color = style.detailColor
    m.focusBar.color = style.barColor
    m.focusBar.opacity = style.barOpacity
    if style.bold <> m.bold
        m.bold = style.bold
        if m.bold then m.title.font = m.boldFont else m.title.font = m.regularFont
    end if
end sub

function fieldOr(node as Object, name as String, fallback as Dynamic) as Dynamic
    if node.HasField(name) then return node.GetField(name)
    return fallback
end function
