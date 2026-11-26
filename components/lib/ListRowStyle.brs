' ============================================================================
' ListRowStyle.brs — how a ListItem row looks, given its state
'
' Two looks:
'   classic (default)  every list except the show page: a blue bar on the
'                      left and a lighter background on the focused row.
'   strong             the show page (seasons | episodes), Netflix-style:
'                        cursor   white row, dark bold text. Only drawn while
'                                 the row's list has focus, so there is never
'                                 more than one cursor on screen.
'                        selected blue accent bar, blue-tinted background,
'                                 bold white text: "these are the episodes
'                                 you're looking at". Stays visible when the
'                                 cursor is elsewhere.
'                      A row can be both (cursor on the selected season): it
'                      is white AND keeps its accent bar.
' Pure function, unit-tested in tests/ListRowStyle.test.brs.
' ============================================================================

' focusPercent  0.0 – 1.0 from the MarkupList (1 = this is the focused row)
' listFocused   does the list itself have focus?
' selected      is this the selected row (e.g. the season being shown)?
' strong        use the show page look (see above)
'
' Returns { state, background, titleColor, detailColor, barColor,
'           barOpacity, bold }
' state is "normal", "cursor", "selected" or "cursorSelected".
function ListRowStyle(focusPercent as Float, listFocused as Boolean, selected as Boolean, strong as Boolean) as Object
    if not strong
        ' Classic look, unchanged: the bar fades in with the focus.
        style = { state: "normal", background: "0x1E252DFF", titleColor: "0xDDDDDDFF", detailColor: "0x8A96A3FF", barColor: "0x3D7EFFFF", barOpacity: focusPercent, bold: false }
        if focusPercent > 0.5
            style.state = "cursor"
            style.background = "0x2A3440FF"
        end if
        return style
    end if

    cursor = listFocused and focusPercent > 0.5
    style = { state: "normal", background: "0x1E252DFF", titleColor: "0xC8D0D8FF", detailColor: "0x8A96A3FF", barColor: "0x3D7EFFFF", barOpacity: 0.0, bold: false }

    if selected
        style.state = "selected"
        style.background = "0x23395EFF"
        style.titleColor = "0xFFFFFFFF"
        style.detailColor = "0xC8D0D8FF"
        style.barOpacity = 1.0
        style.bold = true
    end if

    if cursor
        if selected then style.state = "cursorSelected" else style.state = "cursor"
        style.background = "0xF2F4F7FF"
        style.titleColor = "0x101418FF"
        style.detailColor = "0x4A5560FF"
        style.bold = true
    end if
    return style
end function
