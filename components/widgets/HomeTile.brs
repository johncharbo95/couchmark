' ============================================================================
' HomeTile.brs
' ============================================================================

sub init()
    m.body = m.top.FindNode("body")
    m.card = m.top.FindNode("card")
    m.accent = m.top.FindNode("accent")
    m.title = m.top.FindNode("title")
    m.subtitle = m.top.FindNode("subtitle")
end sub

sub onContentSet()
    item = m.top.itemContent
    if item = invalid then return

    m.title.text = item.title
    m.subtitle.text = item.description

    ' Dim tiles whose folder is missing from the drive.
    if item.enabled then m.body.opacity = 1.0 else m.body.opacity = 0.4
end sub

sub onFocusPercentChange()
    p = m.top.focusPercent

    ' Grow slightly and show the accent bar as the tile gains focus.
    scale = 1.0 + 0.06 * p
    m.body.scale = [scale, scale]
    m.accent.opacity = p

    if p > 0.5
        m.card.color = "0x2A3440FF"
    else
        m.card.color = "0x1E252DFF"
    end if
end sub
