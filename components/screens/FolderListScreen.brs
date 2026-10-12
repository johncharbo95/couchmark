' ============================================================================
' FolderListScreen.brs
'
' Flow for kind = "movies":
'   1. On first focus, scan the Movies folder(s) for movie folders.
'   2. OK on a movie: scan that folder for its video files ("parts").
'   3. If there is saved progress, open ResumeDialog; otherwise play.
' Badges (✓ / progress bar) are refreshed whenever the screen reappears,
' e.g. after returning from the player.
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

' ----------------------------------------------------------------------------
' Listing the folder
' ----------------------------------------------------------------------------

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
        m.emptyLabel.text = "No folders found in " + m.top.title + "." + Chr(10) + Chr(10) + "Each movie should be in its own folder, e.g.  Movies / The Matrix (1999) / The Matrix.mp4"
        m.emptyLabel.visible = true
        return
    end if

    if count = 1 then m.countLabel.text = "1 title" else m.countLabel.text = count.ToStr() + " titles"

    for each item in content.GetChildren(-1, 0)
        ' Extra fields read by ListItem to draw the ✓ / progress bar.
        item.AddFields({ badge: "", progress: 0.0 })
    end for
    m.list.content = content
    refreshBadges()
end sub

' Reads saved progress for every visible title and updates its badge.
sub refreshBadges()
    for each item in m.list.content.GetChildren(-1, 0)
        badge = ""
        progress = 0.0

        record = ProgressGetMovie(item.title)
        if record <> invalid
            if record.pos > 0 or record.part > 0
                badge = "partial"
                progress = movieFraction(record)
            else if record.watched
                badge = "watched"
            end if
        end if

        item.badge = badge
        item.progress = progress
    end for
end sub

' How far through the whole movie (0.0 – 1.0), counting finished parts.
function movieFraction(record as Object) as Float
    partFraction = 0.0
    if record.dur > 0 then partFraction = record.pos / record.dur
    parts = record.parts
    if parts < 1 then parts = 1
    return (record.part + partFraction) / parts
end function

' ----------------------------------------------------------------------------
' Selecting a movie
' ----------------------------------------------------------------------------

sub onItemSelected()
    m.selected = m.list.content.GetChild(m.list.itemSelected)

    m.loading.message = "Opening " + m.selected.title + "…"
    m.loading.visible = true

    m.partsTask = CreateObject("roSGNode", "FolderScanTask")
    m.partsTask.paths = [m.selected.url]
    m.partsTask.mode = "videos"
    m.partsTask.ObserveField("content", "onPartsScanned")
    m.partsTask.control = "run"
end sub

sub onPartsScanned(event as Object)
    m.loading.visible = false
    movie = m.selected

    parts = []
    for each child in event.GetData().GetChildren(-1, 0)
        parts.Push(child.url)
    end for

    if parts.Count() = 0
        m.top.navigate = {
            screen: "MessageScreen"
            fields: {
                title: movie.title
                message: "There are no playable video files in this folder." + Chr(10) + Chr(10) + "Supported: .mp4 .m4v .mov .mkv .ts .webm"
            }
        }
        return
    end if

    playerFields = { title: movie.title, parts: parts, startPart: 0, startPos: 0 }

    ' Offer to resume, unless the saved part no longer exists on the drive.
    record = ProgressGetMovie(movie.title)
    if record <> invalid and (record.pos > 0 or record.part > 0) and record.part < parts.Count()
        resumeText = "Resume from " + FormatTime(record.pos)
        if parts.Count() > 1
            resumeText = "Resume part " + (record.part + 1).ToStr() + " of " + parts.Count().ToStr() + " at " + FormatTime(record.pos)
        end if

        m.top.navigate = {
            screen: "ResumeDialog"
            fields: {
                title: movie.title
                resumeText: resumeText
                resumePart: record.part
                resumePos: record.pos
                playerFields: playerFields
            }
        }
    else
        m.top.navigate = { screen: "PlayerScreen", fields: playerFields }
    end if
end sub
