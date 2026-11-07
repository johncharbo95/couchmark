' ============================================================================
' ShowNav.brs — where focus goes on the show page (ShowScreen)
'
' The page has three focus areas: "continue" (the Continue button),
' "seasons" (left list) and "episodes" (right list). The cursor moves inside
' a list with Up/Down; the screen only sees keys the lists didn't use.
' A season is SELECTED (its episodes shown) with OK or Right, not just by
' moving the cursor over it. Pure functions, unit-tested in
' tests/ShowNav.test.brs.
' ============================================================================

' The area a key moves to, or "" when the key does nothing here.
' Right in the season list is handled as "select the season" by the screen,
' but it also lands in "episodes".
function ShowNextArea(area as String, key as String, continueVisible as Boolean) as String
    if area = "continue" and key = "down" then return "episodes"
    if area = "seasons" and key = "right" then return "episodes"
    if area = "episodes" and key = "left" then return "seasons"
    if (area = "seasons" or area = "episodes") and key = "up" and continueVisible then return "continue"
    return ""
end function

' Index of the season that holds episode itemIndex (0 if none does).
' seasons: [{ first, count }, ...] in show order.
function SeasonOfItem(seasons as Object, itemIndex as Integer) as Integer
    for s = 0 to seasons.Count() - 1
        season = seasons[s]
        if itemIndex >= season.first and itemIndex < season.first + season.count then return s
    end for
    return 0
end function

' Episode row the cursor lands on when a season is opened (OK / Right).
'   season      { first, count }
'   targetIndex the show's Continue episode (index in all items), or -1
'   watched     array of Booleans, one per episode of this season
'   currentRow  the cursor row if this season was already selected, else -1
' Re-opening the selected season keeps your place. Otherwise: the Continue
' episode if it is in this season, else the first unwatched episode, else
' the first episode.
function SeasonEntryRow(season as Object, targetIndex as Integer, watched as Object, currentRow as Integer) as Integer
    if season.count <= 0 then return 0
    if currentRow >= 0 and currentRow < season.count then return currentRow
    if targetIndex >= season.first and targetIndex < season.first + season.count then return targetIndex - season.first
    for r = 0 to season.count - 1
        if r < watched.Count() and not watched[r] then return r
    end for
    return 0
end function
