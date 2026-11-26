' ============================================================================
' ShowScreen.brs
'
' Three focus areas, moved between with the arrow keys (lib/ShowNav.brs):
'   "continue"  the Continue button        Down  → episodes
'   "seasons"   season list (left)         OK/Right → open the season under
'                                          the cursor, Up (top) → continue
'   "episodes"  episode list (right)       Left  → seasons, cursor on the
'                                          selected season; Up (top) → continue
' Two different markers (lib/ListRowStyle.brs):
'   cursor    white row, only in the focused list (one on screen at a time)
'   selected  accent bar + tint on the season whose episodes are shown. It
'             changes only when a season is opened (OK / Right), not while
'             the cursor moves.
' ✱ marks the highlighted episode / season under the cursor / Continue
' episode as watched or unwatched (ToggleEpisodesWatched in lib/Library.brs).
' Play/Pause plays the highlighted episode (resuming) or Continue.
' Everything is refreshed when the screen reappears after playback.
' ============================================================================

sub init()
    m.continueButton = m.top.FindNode("continueButton")
    m.seasons = m.top.FindNode("seasons")
    m.episodes = m.top.FindNode("episodes")
    m.infoLabel = m.top.FindNode("infoLabel")
    m.emptyLabel = m.top.FindNode("emptyLabel")
    m.heroArt = m.top.FindNode("heroArt")
    m.loading = m.top.FindNode("loading")
    m.toast = m.top.FindNode("toast")

    m.continueButton.ObserveField("itemSelected", "onContinueSelected")
    m.seasons.ObserveField("itemSelected", "onSeasonSelected")
    m.episodes.ObserveField("itemSelected", "onEpisodeSelected")
    m.top.ObserveField("focusedChild", "onFocusedChildChange")
    m.top.ObserveField("visible", "onVisibleChange")

    m.show = invalid        ' { items, seasons, art } once scanned
    m.target = invalid      ' ContinueTarget result
    m.seasonIndex = -1      ' the selected season (its episodes are shown)
    m.area = "continue"
    m.started = false
end sub

sub onFocusedChildChange()
    if not m.top.HasFocus() then return
    if not m.started
        m.started = true
        m.heroArt.uri = m.top.art
        startScan()
    end if
    focusArea(m.area)
end sub

sub onVisibleChange()
    if m.top.visible and m.show <> invalid then refresh()
end sub

sub startScan()
    m.loading.message = "Reading " + m.top.title + "…"
    m.loading.visible = true
    m.task = CreateObject("roSGNode", "ShowScanTask")
    m.task.paths = m.top.paths
    m.task.ObserveField("show", "onShowScanned")
    m.task.control = "run"
end sub

sub onShowScanned(event as Object)
    m.loading.visible = false
    m.show = event.GetData()
    if m.top.art = "" then m.heroArt.uri = m.show.art

    if m.show.items.Count() = 0
        m.emptyLabel.text = "No episodes found in this show." + Chr(10) + Chr(10) + "Put episodes in season folders, e.g.  Shows / " + m.top.title + " / Season 1 / S01E01.mp4"
        m.emptyLabel.visible = true
        return
    end if

    seasonCount = m.show.seasons.Count()
    info = seasonCount.ToStr() + " seasons"
    if seasonCount = 1 then info = "1 season"
    m.infoLabel.text = info + "  ·  " + m.show.items.Count().ToStr() + " episodes"

    refresh()

    ' Open on the season of the episode you'd continue with (the episode
    ' cursor lands on that episode, see SeasonEntryRow).
    startSeason = 0
    if m.target <> invalid then startSeason = SeasonOfItem(m.show.seasons, m.target.index)
    m.seasons.jumpToItem = startSeason
    openSeason(startSeason)
    if m.target <> invalid
        m.area = "continue"
    else
        m.area = "episodes"
    end if
    focusArea(m.area)
end sub

' ----------------------------------------------------------------------------
' Building the lists
' ----------------------------------------------------------------------------

' Re-reads progress and updates the button, season rows and episode rows.
sub refresh()
    m.record = ProgressGetShow(m.top.title)

    m.target = ContinueTarget(m.record, m.show.items)
    if m.target <> invalid
        content = CreateObject("roSGNode", "ContentNode")
        content.CreateChild("ContentNode").title = m.target.text
        m.continueButton.content = content
        m.continueButton.visible = true
    else
        m.continueButton.content = invalid
        m.continueButton.visible = false
        if m.area = "continue" then m.area = "episodes"
    end if

    rows = CreateObject("roSGNode", "ContentNode")
    for each season in m.show.seasons
        watched = 0
        started = false
        for e = season.first to season.first + season.count - 1
            id = m.show.items[e].id
            if m.record.watched.DoesExist(id) then watched = watched + 1
            if ProgressFindPartial(m.record, id) <> invalid then started = true
        end for

        badge = ""
        progress = 0.0
        if watched = season.count
            badge = "watched"
        else if watched > 0 or started
            badge = "partial"
            progress = watched / season.count
        end if

        row = rows.CreateChild("ContentNode")
        row.title = season.title
        row.AddFields({ badge: badge, progress: progress, rowWidth: 420, strongCursor: true, listFocused: false, selected: false })
    end for
    focusedSeason = m.seasons.itemFocused
    m.seasons.content = rows
    if focusedSeason > 0 then m.seasons.jumpToItem = focusedSeason

    if m.seasonIndex >= 0 then refreshEpisodeBadges()
    updateRowStates()
end sub

' OK on a season: open it and move the cursor into its episodes.
sub onSeasonSelected()
    if m.show = invalid or m.show.items.Count() = 0 then return
    openSeason(m.seasons.itemSelected)
    focusArea("episodes")
end sub

' Makes a season the selected one: fills the episode list (if it changed)
' and puts the episode cursor where it should land (SeasonEntryRow in
' lib/ShowNav.brs). Doesn't move focus.
sub openSeason(index as Integer)
    if index < 0 or index >= m.show.seasons.Count() then return
    season = m.show.seasons[index]

    currentRow = -1
    if index = m.seasonIndex then currentRow = m.episodes.itemFocused
    targetIndex = -1
    if m.target <> invalid then targetIndex = m.target.index
    watched = []
    for e = season.first to season.first + season.count - 1
        watched.Push(m.record.watched.DoesExist(m.show.items[e].id))
    end for
    entryRow = SeasonEntryRow(season, targetIndex, watched, currentRow)

    if index <> m.seasonIndex
        m.seasonIndex = index
        rows = CreateObject("roSGNode", "ContentNode")
        for e = season.first to season.first + season.count - 1
            row = rows.CreateChild("ContentNode")
            row.title = m.show.items[e].label
            row.AddFields({ badge: "", progress: 0.0, detail: "", rowWidth: 1268, strongCursor: true, listFocused: false, selected: false })
        end for
        m.episodes.content = rows
        refreshEpisodeBadges()
    end if
    m.episodes.jumpToItem = entryRow
    updateRowStates()
end sub

sub refreshEpisodeBadges()
    season = m.show.seasons[m.seasonIndex]
    rows = m.episodes.content.GetChildren(-1, 0)
    for r = 0 to rows.Count() - 1
        item = m.show.items[season.first + r]
        state = EpisodeBadge(m.record, item.id)
        rows[r].badge = state.badge
        rows[r].progress = state.progress
        detail = ""
        if state.badge = "partial"
            partial = ProgressFindPartial(m.record, item.id)
            if partial.dur > partial.pos then detail = FormatRemaining(partial.dur - partial.pos) + " left"
        end if
        rows[r].detail = detail
    end for
end sub

' Tells the rows which list has focus (only that list draws its cursor) and
' which season is selected. ListItem draws the looks (lib/ListRowStyle.brs).
sub updateRowStates()
    if m.seasons.content <> invalid
        seasonRows = m.seasons.content.GetChildren(-1, 0)
        for r = 0 to seasonRows.Count() - 1
            seasonRows[r].listFocused = (m.area = "seasons")
            seasonRows[r].selected = (r = m.seasonIndex)
        end for
    end if
    if m.episodes.content <> invalid
        for each row in m.episodes.content.GetChildren(-1, 0)
            row.listFocused = (m.area = "episodes")
        end for
    end if
end sub

' ----------------------------------------------------------------------------
' Focus & keys
' ----------------------------------------------------------------------------

sub focusArea(area as String)
    if m.show = invalid or m.show.items.Count() = 0 then return
    if area = "continue" and not m.continueButton.visible then area = "episodes"
    m.area = area
    updateRowStates()
    if area = "continue"
        m.continueButton.SetFocus(true)
    else if area = "seasons"
        m.seasons.SetFocus(true)
    else
        m.episodes.SetFocus(true)
    end if
end sub

' Keys the lists didn't use (e.g. Up on the first row) arrive here.
function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "options"
        toggleWatched()
        return true
    else if key = "play"
        playFocused()
        return true
    end if

    if m.show = invalid or m.show.items.Count() = 0 then return false
    nextArea = ShowNextArea(m.area, key, m.continueButton.visible)
    if nextArea = "" then return false

    if m.area = "seasons" and key = "right"
        ' Right opens the season under the cursor, like OK.
        openSeason(m.seasons.itemFocused)
    else if nextArea = "seasons"
        ' From the episodes, the cursor starts on the selected season.
        m.seasons.jumpToItem = m.seasonIndex
    end if
    focusArea(nextArea)
    return true
end function

' ----------------------------------------------------------------------------
' Mark as watched / unwatched (✱)
' ----------------------------------------------------------------------------

sub toggleWatched()
    if m.show = invalid or m.show.items.Count() = 0 then return
    allIds = EpisodeIds(m.show.items, 0, -1)
    record = ProgressGetShow(m.top.title)

    if m.area = "continue"
        ' "I've already seen this one": always marks watched.
        item = m.show.items[m.target.index]
        ToggleEpisodesWatched(record, [item.id], allIds, true)
        message = EpisodeShortLabel(item) + " marked as watched"
    else if m.area = "seasons"
        ' The season under the cursor, which may not be the selected one.
        season = m.show.seasons[m.seasons.itemFocused]
        watched = ToggleEpisodesWatched(record, EpisodeIds(m.show.items, season.first, season.count), allIds)
        message = season.title + markedText(watched)
    else
        item = m.show.items[m.show.seasons[m.seasonIndex].first + m.episodes.itemFocused]
        watched = ToggleEpisodesWatched(record, [item.id], allIds)
        message = EpisodeShortLabel(item) + markedText(watched)
    end if

    ProgressSaveShow(m.top.title, record)
    m.toast.message = message
    refresh()
    ' The Continue button may have disappeared (show finished).
    focusArea(m.area)
end sub

function markedText(watched as Boolean) as String
    if watched then return " marked as watched"
    return " marked as unwatched"
end function

' ----------------------------------------------------------------------------
' Playing
' ----------------------------------------------------------------------------

function playerFields(index as Integer, startPos as Integer) as Object
    return { kind: "show", title: m.top.title, items: m.show.items, startIndex: index, startPos: startPos }
end function

sub onContinueSelected()
    m.top.navigate = { screen: "PlayerScreen", fields: playerFields(m.target.index, m.target.pos) }
end sub

' Play/Pause: Continue plays like OK; an episode starts right away, from
' its resume point if it has one (no Resume / Start over dialog).
sub playFocused()
    if m.show = invalid or m.show.items.Count() = 0 then return
    if m.area = "continue"
        onContinueSelected()
    else if m.area = "episodes"
        index = m.show.seasons[m.seasonIndex].first + m.episodes.itemFocused
        startPos = 0
        partial = ProgressFindPartial(m.record, m.show.items[index].id)
        if partial <> invalid then startPos = partial.pos
        m.top.navigate = { screen: "PlayerScreen", fields: playerFields(index, startPos) }
    end if
end sub

sub onEpisodeSelected()
    index = m.show.seasons[m.seasonIndex].first + m.episodes.itemSelected
    item = m.show.items[index]

    partial = ProgressFindPartial(m.record, item.id)
    if partial <> invalid
        m.top.navigate = {
            screen: "ResumeDialog"
            fields: {
                title: item.label
                resumeText: "Resume from " + FormatTime(partial.pos)
                resumeIndex: index
                resumePos: partial.pos
                restartIndex: index
                playerFields: playerFields(index, 0)
            }
        }
    else
        m.top.navigate = { screen: "PlayerScreen", fields: playerFields(index, 0) }
    end if
end sub
