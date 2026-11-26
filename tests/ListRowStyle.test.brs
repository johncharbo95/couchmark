' @include components/lib/ListRowStyle.brs

sub Main()
    ' Classic look (FolderListScreen, Settings): unchanged.
    s = ListRowStyle(0.0, true, false, false)
    assertEqual(s.state, "normal", "classic: unfocused row")
    assertEqual(s.background, "0x1E252DFF", "classic: dark background")
    assertNear(s.barOpacity, 0.0, 0.001, "classic: no bar")
    s = ListRowStyle(1.0, true, false, false)
    assertEqual(s.state, "cursor", "classic: focused row")
    assertEqual(s.background, "0x2A3440FF", "classic: lighter background")
    assertNear(s.barOpacity, 1.0, 0.001, "classic: bar shown")
    assertEqual(s.bold, false, "classic: never bold")
    s = ListRowStyle(0.4, true, false, false)
    assertNear(s.barOpacity, 0.4, 0.001, "classic: bar fades with the focus")
    assertEqual(s.background, "0x1E252DFF", "classic: background switches past half")

    ' Strong look (show page).
    normal = ListRowStyle(0.0, true, false, true)
    assertEqual(normal.state, "normal", "strong: plain row")
    assertNear(normal.barOpacity, 0.0, 0.001, "strong: plain row has no bar")

    cursor = ListRowStyle(1.0, true, false, true)
    assertEqual(cursor.state, "cursor", "strong: focused row in focused list is the cursor")
    assertTrue(cursor.background <> normal.background, "strong: cursor stands out")
    assertNear(cursor.barOpacity, 0.0, 0.001, "strong: cursor alone has no accent bar")

    ' A list without focus never shows a cursor.
    s = ListRowStyle(1.0, false, false, true)
    assertEqual(s.state, "normal", "strong: unfocused list shows no cursor")
    assertEqual(s.background, normal.background, "strong: unfocused list looks plain")

    selected = ListRowStyle(0.0, true, true, true)
    assertEqual(selected.state, "selected", "strong: selected season")
    assertNear(selected.barOpacity, 1.0, 0.001, "strong: selected has the accent bar")
    assertEqual(selected.bold, true, "strong: selected is bold")
    assertTrue(selected.background <> cursor.background, "strong: selected differs from cursor")
    assertTrue(selected.background <> normal.background, "strong: selected differs from plain")

    ' Selected stays visible while the cursor is in the other list.
    s = ListRowStyle(1.0, false, true, true)
    assertEqual(s.state, "selected", "strong: selected season while episodes have focus")
    assertEqual(s.background, selected.background, "strong: same selected look")

    both = ListRowStyle(1.0, true, true, true)
    assertEqual(both.state, "cursorSelected", "strong: cursor on the selected season")
    assertEqual(both.background, cursor.background, "strong: looks like the cursor")
    assertNear(both.barOpacity, 1.0, 0.001, "strong: and keeps the accent bar")

    s = ListRowStyle(0.3, true, false, true)
    assertEqual(s.state, "normal", "strong: row the cursor is leaving")

    finishTests()
end sub
