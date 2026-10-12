' ============================================================================
' FolderListScreen.brs — the A–Z lists ("All Movies", "All Shows")
'
'   1. On first focus, scan the folder(s) for movie / show folders.
'   2. OK opens MovieScreen or ShowScreen.
'   Movie badges (✓ / progress bar) are refreshed whenever the screen
'   reappears, e.g. after returning from the player.
' ============================================================================

sub init()
    m.list = m.top.FindNode("list")
    m.countLabel = m.top.FindNode("countLabel")
    m.emptyLabel = m.top.FindNode("emptyLabel")
    m.loading = m.top.FindNode("loading")

    m.list.ObserveField("itemSelected", "onItemSelected")
    m.top.ObserveField("focusedChild", "onFocusedChildChange")
    m.top.ObserveField("visible", "onVisibleChange")

    m.loaded = false
end sub

sub onFocusedChildChange()
    if not m.top.HasFocus() then return

    ' Fields such as "paths" are set after init(), so the first scan starts
    ' the first time the screen is focused.
    if not m.loaded
        m.loaded = true
        startListScan()
    end if
    m.list.SetFocus(true)
end sub

sub onVisibleChange()
    if m.top.visible and m.list.content <> invalid then refreshBadges()
end sub

sub startListScan()
    m.loading.message = "Reading " + m.top.title + "…"
    m.loading.visible = true

    m.listTask = CreateObject("roSGNode", "FolderScanTask")
    m.listTask.paths = m.top.paths
    m.listTask.mode = "folders"
    m.listTask.ObserveField("content", "onListScanned")
    m.listTask.control = "run"
end sub

sub onListScanned(event as Object)
    m.loading.visible = false
    content = event.GetData()

    count = content.GetChildCount()
    if count = 0
        example = "Movies / The Matrix (1999) / The Matrix.mp4"
        if m.top.kind = "shows" then example = "Shows / The Office / Season 1 / S01E01.mp4"
        m.emptyLabel.text = "No folders found in " + m.top.title + "." + Chr(10) + Chr(10) + "Each title should be in its own folder, e.g.  " + example
        m.emptyLabel.visible = true
        return
    end if

    noun = "titles"
    if m.top.kind = "shows" then noun = "shows"
    m.countLabel.text = count.ToStr() + " " + noun

    for each item in content.GetChildren(-1, 0)
        ' Extra fields read by ListItem to draw the ✓ / progress bar.
        item.AddFields({ badge: "", progress: 0.0, detail: "" })
    end for
    m.list.content = content
    refreshBadges()
end sub

' Reads saved progress for every movie and updates its badge.
' (Show progress needs every episode scanned, so the show page shows it.)
sub refreshBadges()
    if m.top.kind <> "movies" then return

    for each item in m.list.content.GetChildren(-1, 0)
        record = ProgressGetMovie(item.title)
        state = MovieBadge(record)
        item.badge = state.badge
        item.progress = state.progress
        detail = ""
        if state.badge = "partial" then detail = MovieResumeText(record)
        item.detail = detail
    end for
end sub

sub onItemSelected()
    item = m.list.content.GetChild(m.list.itemSelected)
    if m.top.kind = "shows"
        m.top.navigate = { screen: "ShowScreen", fields: { title: item.title, paths: item.paths, art: "" } }
    else
        m.top.navigate = { screen: "MovieScreen", fields: { title: item.title, path: item.url, art: "" } }
    end if
end sub
