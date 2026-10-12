' ============================================================================
' FolderListScreen.brs — the A–Z lists ("All Movies", "All Shows") and the
' Other folder browser.
'
'   1. On first focus, scan the folder(s) for subfolders.
'   2. OK opens MovieScreen or ShowScreen. On a movie, ✱ marks it watched /
'      unwatched.
'   Other: the first row plays a slideshow of this folder's photos and
'   videos; the other rows open subfolders (another FolderListScreen).
'   Movie badges (✓ / progress bar) are refreshed whenever the screen
'   reappears, e.g. after returning from the player.
' ============================================================================

sub init()
    m.list = m.top.FindNode("list")
    m.countLabel = m.top.FindNode("countLabel")
    m.emptyLabel = m.top.FindNode("emptyLabel")
    m.loading = m.top.FindNode("loading")
    m.toast = m.top.FindNode("toast")

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
    if m.top.kind = "other" then m.listTask.mode = "browse"
    m.listTask.ObserveField("content", "onListScanned")
    m.listTask.control = "run"
end sub

sub onListScanned(event as Object)
    m.loading.visible = false
    content = event.GetData()

    if m.top.kind = "other" then addSlideshowRow(content)

    count = content.GetChildCount()
    if count = 0
        example = "Movies / The Matrix (1999) / The Matrix.mp4"
        if m.top.kind = "shows" then example = "Shows / The Office / Season 1 / S01E01.mp4"
        if m.top.kind = "other" then example = "Other / Summer 2025 / IMG_0001.jpg"
        m.emptyLabel.text = "No folders found in " + m.top.title + "." + Chr(10) + Chr(10) + "Each title should be in its own folder, e.g.  " + example
        m.emptyLabel.visible = true
        return
    end if

    noun = "titles"
    if m.top.kind = "shows" then noun = "shows"
    m.countLabel.text = count.ToStr() + " " + noun
    if m.top.kind = "other" then m.countLabel.text = ""

    for each item in content.GetChildren(-1, 0)
        ' Extra fields read by ListItem to draw the ✓ / progress bar.
        if not item.HasField("detail") then item.AddFields({ badge: "", progress: 0.0, detail: "" })
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

' Other: puts "Play slideshow · 24 photos · 3 videos" first when the folder
' itself holds any photos or videos.
sub addSlideshowRow(content as Object)
    photos = content.photoCount
    videos = content.videoCount
    if photos + videos = 0 then return

    counts = []
    if photos > 0 then counts.Push(plural(photos, "photo"))
    if videos > 0 then counts.Push(plural(videos, "video"))
    if content.unsupportedCount > 0 then counts.Push(content.unsupportedCount.ToStr() + " unsupported")

    row = CreateObject("roSGNode", "ContentNode")
    row.title = "Play slideshow"
    row.AddFields({ badge: "", progress: 0.0, detail: counts.Join("  ·  "), isSlideshow: true })
    content.InsertChild(row, 0)
end sub

function plural(count as Integer, word as String) as String
    if count = 1 then return "1 " + word
    return count.ToStr() + " " + word + "s"
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
    if press and key = "options" and m.list.content <> invalid
        if m.top.kind = "movies"
            toggleMovieWatched(m.list.content.GetChild(m.list.itemFocused))
        else if m.top.kind = "shows"
            m.toast.message = "Open the show to mark episodes as watched"
        end if
        return true
    end if
    return false
end function

sub toggleMovieWatched(item as Object)
    if item = invalid then return
    record = ProgressGetMovie(item.title)
    parts = 1
    if record <> invalid then parts = record.parts
    watch = (MovieToggleAction(record) = "watch")
    ProgressSetMovieWatched(item.title, parts, watch)
    if watch then m.toast.message = item.title + " marked as watched" else m.toast.message = item.title + " marked as unwatched"
    refreshBadges()
end sub

sub onItemSelected()
    item = m.list.content.GetChild(m.list.itemSelected)
    if m.top.kind = "other"
        if item.HasField("isSlideshow")
            m.top.navigate = { screen: "SlideshowScreen", fields: { title: m.top.title, paths: m.top.paths } }
        else
            m.top.navigate = { screen: "FolderListScreen", fields: { title: item.title, kind: "other", paths: item.paths } }
        end if
        return
    end if
    if m.top.kind = "shows"
        m.top.navigate = { screen: "ShowScreen", fields: { title: item.title, paths: item.paths, art: "" } }
    else
        m.top.navigate = { screen: "MovieScreen", fields: { title: item.title, path: item.url, art: "" } }
    end if
end sub
