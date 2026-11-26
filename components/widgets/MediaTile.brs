' ============================================================================
' MediaTile.brs
' ============================================================================

sub init()
    m.body = m.top.FindNode("body")
    m.border = m.top.FindNode("border")
    m.card = m.top.FindNode("card")
    m.cardTitle = m.top.FindNode("cardTitle")
    m.art = m.top.FindNode("art")
    m.progressTrack = m.top.FindNode("progressTrack")
    m.progressFill = m.top.FindNode("progressFill")
    m.check = m.top.FindNode("check")
    m.subtitle = m.top.FindNode("subtitle")
end sub

sub onContentSet()
    item = m.top.itemContent
    if item = invalid then return

    m.cardTitle.text = item.title
    m.subtitle.text = item.description
    m.art.uri = item.hdPosterUrl
    m.card.color = cardColor(item.title)

    badge = fieldOr(item, "badge", "")
    m.check.visible = (badge = "watched")
    m.progressTrack.visible = (badge = "partial")
    m.progressFill.visible = (badge = "partial")
    if badge = "partial"
        fraction = fieldOr(item, "progress", 0.0)
        if fraction < 0.03 then fraction = 0.03
        if fraction > 1 then fraction = 1
        m.progressFill.width = 400 * fraction
    end if

    if fieldOr(item, "enabled", true) then m.body.opacity = 1.0 else m.body.opacity = 0.4
end sub

' The tile is "focused" only when its row is the focused row and the
' RowList itself has focus; focusPercent alone is set in every row.
sub updateFocus()
    p = m.top.focusPercent * m.top.rowFocusPercent
    if not m.top.rowListHasFocus then p = 0

    scale = 1.0 + 0.07 * p
    m.body.scale = [scale, scale]
    m.border.opacity = p
end sub

' A stable, muted colour per title, so tiles without artwork differ.
function cardColor(title as String) as String
    palette = ["0x2E4057FF", "0x4A3B5CFF", "0x2F5148FF", "0x5A3A3AFF", "0x3B4A6BFF", "0x5B4B2EFF"]
    total = 0
    for i = 1 to Len(title)
        total = total + Asc(Mid(title, i, 1))
    end for
    return palette[total mod palette.Count()]
end function

function fieldOr(node as Object, name as String, fallback as Dynamic) as Dynamic
    if node.HasField(name) then return node.GetField(name)
    return fallback
end function
