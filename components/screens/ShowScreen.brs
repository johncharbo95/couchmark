' ============================================================================
' ShowScreen.brs
'
' Three focus areas, moved between with the arrow keys:
'   "continue"  the Continue button        Down  → episodes
'   "seasons"   season list (left)         Right → episodes, Up (top) → continue
'   "episodes"  episode list (right)       Left  → seasons,  Up (top) → continue
' Highlighting a season fills the episode list with its episodes.
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

    m.continueButton.ObserveField("itemSelected", "onContinueSelected")
    m.seasons.ObserveField("itemFocused", "onSeasonFocused")
    m.episodes.ObserveField("itemSelected", "onEpisodeSelected")
    m.top.ObserveField("focusedChild", "onFocusedChildChange")
    m.top.ObserveField("visible", "onVisibleChange")

    m.show = invalid        ' { items, seasons, art } once scanned
    m.target = invalid      ' ContinueTarget result
    m.seasonIndex = -1
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

    ' Open on the season of the episode you'd continue with.
    startSeason = 0
    if m.target <> invalid then startSeason = seasonOf(m.target.index)
    m.seasons.jumpToItem = startSeason
    showSeason(startSeason)
    if m.target <> invalid
        m.episodes.jumpToItem = m.target.index - m.show.seasons[startSeason].first
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
        row.AddFields({ badge: badge, progress: progress, rowWidth: 420 })
    end for
    focusedSeason = m.seasons.itemFocused
    m.seasons.content = rows
    if focusedSeason > 0 then m.seasons.jumpToItem = focusedSeason

    if m.seasonIndex >= 0 then refreshEpisodeBadges()
end sub

sub onSeasonFocused()
    if m.show <> invalid and m.seasons.itemFocused <> m.seasonIndex
        showSeason(m.seasons.itemFocused)
    end if
end sub

sub showSeason(index as Integer)
    if index < 0 or index >= m.show.seasons.Count() then return
    m.seasonIndex = index
    season = m.show.seasons[index]

    rows = CreateObject("roSGNode", "ContentNode")
    for e = season.first to season.first + season.count - 1
        row = rows.CreateChild("ContentNode")
        row.title = m.show.items[e].label
        row.AddFields({ badge: "", progress: 0.0, detail: "", rowWidth: 1268 })
    end for
    m.episodes.content = rows
    refreshEpisodeBadges()
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

function seasonOf(itemIndex as Integer) as Integer
    for s = 0 to m.show.seasons.Count() - 1
        season = m.show.seasons[s]
        if itemIndex >= season.first and itemIndex < season.first + season.count then return s
    end for
    return 0
end function

' ----------------------------------------------------------------------------
' Focus & keys
' ----------------------------------------------------------------------------

sub focusArea(area as String)
    if m.show = invalid or m.show.items.Count() = 0 then return
    if area = "continue" and not m.continueButton.visible then area = "episodes"
    m.area = area
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

    if m.area = "continue" and key = "down"
        focusArea("episodes")
        return true
    else if m.area = "seasons" and key = "right"
        focusArea("episodes")
        return true
    else if m.area = "episodes" and key = "left"
        focusArea("seasons")
        return true
    else if (m.area = "seasons" or m.area = "episodes") and key = "up" and m.continueButton.visible
        focusArea("continue")
        return true
    end if
    return false
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
