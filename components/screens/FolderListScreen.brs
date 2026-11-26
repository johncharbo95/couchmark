' ============================================================================
' FolderListScreen.brs — the A–Z lists ("All Movies", "All Shows"), the
' Other folder browser and the Files browser.
'
'   1. On first focus, scan the folder(s) for subfolders.
'   2. OK opens MovieScreen or ShowScreen. On a movie, ✱ marks it watched /
'      unwatched, and Play/Pause starts it (resuming).
'   Other: the first row plays a slideshow of this folder's photos and
'   videos; the other rows open subfolders (another FolderListScreen).
'   Files: everything in the folder as the drive has it. OK opens a folder,
'   plays a video (the folder's videos play in a row; Resume / Start over
'   when it has a resume point), or plays a slideshow from a photo.
'   Play/Pause on a video starts it right away (resuming).
'   Movie / episode badges (✓ / progress bar) are refreshed whenever the screen
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
    if m.top.kind = "files" then m.listTask.mode = "files"
    m.listTask.title = m.top.title
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
        if m.top.kind = "files"
            m.emptyLabel.text = "This folder is empty."
            m.emptyLabel.visible = true
            return
        end if
        m.emptyLabel.text = "No folders found in " + m.top.title + "." + Chr(10) + Chr(10) + "Each title should be in its own folder, e.g.  " + example
        m.emptyLabel.visible = true
        return
    end if

    noun = "titles"
    if m.top.kind = "shows" then noun = "shows"
    m.countLabel.text = count.ToStr() + " " + noun
    if m.top.kind = "other" then m.countLabel.text = ""
    if m.top.kind = "files" then m.countLabel.text = filesSummary(content)

    for each item in content.GetChildren(-1, 0)
        ' Extra fields read by ListItem to draw the ✓ / progress bar.
        if not item.HasField("detail") then item.AddFields({ badge: "", progress: 0.0, detail: "" })
        if m.top.kind = "files" then item.detail = fileDetail(item)
    end for
    m.list.content = content
    refreshBadges()
end sub

' Reads saved progress for every movie and updates its badge.
' (Show progress needs every episode scanned, so the show page shows it.)
sub refreshBadges()
    if m.top.kind = "files" then refreshFileBadges()
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
        else if m.top.kind = "shows" or (m.top.kind = "files" and m.list.content.playerKind = "show")
            m.toast.message = "Open the show to mark episodes as watched"
        end if
        return true
    else if press and key = "play" and m.list.content <> invalid and m.top.kind = "movies"
        item = m.list.content.GetChild(m.list.itemFocused)
        if item <> invalid then PlayMovie(item.title, item.url)
        return true
    else if press and key = "play" and m.list.content <> invalid and m.top.kind = "files"
        item = m.list.content.GetChild(m.list.itemFocused)
        if item <> invalid and item.kind = "video" then playFile(item.videoIndex, fileResumePos(item.videoIndex))
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
    if m.top.kind = "files"
        openFile(item)
        return
    end if
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

' ----------------------------------------------------------------------------
' Files browser
' ----------------------------------------------------------------------------

' "2 folders · 24 videos · 1 other file"
function filesSummary(content as Object) as String
    parts = []
    if content.folderCount > 0 then parts.Push(plural(content.folderCount, "folder"))
    if content.videoCount > 0 then parts.Push(plural(content.videoCount, "video"))
    if content.photoCount > 0 then parts.Push(plural(content.photoCount, "photo"))
    if content.otherCount > 0 then parts.Push(plural(content.otherCount, "other file"))
    return parts.Join("  ·  ")
end function

function fileDetail(item as Object) as String
    if item.kind = "folder" then return "Folder"
    if item.kind = "photo" then return "Photo"
    if item.kind = "" then return "Can't play"
    return ""
end function

' Videos in a show's folder get the same ✓ / progress bar as on the show page.
sub refreshFileBadges()
    content = m.list.content
    if content.playerKind <> "show" then return
    record = ProgressGetShow(content.playerTitle)
    for each item in content.GetChildren(-1, 0)
        if item.kind = "video"
            state = EpisodeBadge(record, content.playerItems[item.videoIndex].id)
            item.badge = state.badge
            item.progress = state.progress
        end if
    end for
end sub

sub openFile(item as Object)
    if item.kind = "folder"
        m.top.navigate = { screen: "FolderListScreen", fields: { title: item.title, kind: "files", paths: item.paths } }
    else if item.kind = "photo"
        m.top.navigate = { screen: "SlideshowScreen", fields: { title: m.top.title, paths: m.top.paths } }
    else if item.kind = "video"
        index = item.videoIndex
        startPos = fileResumePos(index)
        if startPos > 0
            content = m.list.content
            m.top.navigate = {
                screen: "ResumeDialog"
                fields: {
                    title: content.playerItems[index].label
                    resumeText: "Resume from " + FormatTime(startPos)
                    resumeIndex: index
                    resumePos: startPos
                    restartIndex: index
                    playerFields: filePlayerFields(index, 0)
                }
            }
        else
            playFile(index, 0)
        end if
    else
        m.toast.message = "Couchmark can't play ." + FileExtension(item.title) + " files"
    end if
end sub

' Saved resume position (seconds) of the folder's video at index, or 0.
' Only videos in a show or movie folder have saved progress.
function fileResumePos(index as Integer) as Integer
    content = m.list.content
    if content.playerKind = "show"
        partial = ProgressFindPartial(ProgressGetShow(content.playerTitle), content.playerItems[index].id)
        if partial <> invalid then return partial.pos
    else if content.playerKind = "movie"
        record = ProgressGetMovie(content.playerTitle)
        if MovieInProgress(record) and record.part = index and record.parts = content.playerItems.Count() then return record.pos
    end if
    return 0
end function

function filePlayerFields(index as Integer, startPos as Integer) as Object
    content = m.list.content
    return { kind: content.playerKind, title: content.playerTitle, items: content.playerItems, startIndex: index, startPos: startPos }
end function

sub playFile(index as Integer, startPos as Integer)
    m.top.navigate = { screen: "PlayerScreen", fields: filePlayerFields(index, startPos) }
end sub
