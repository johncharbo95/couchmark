' ============================================================================
' FolderScanTask.brs — see lib/Scan.brs for the actual scanning
' ============================================================================

sub init()
    m.top.functionName = "scan"
end sub

sub scan()
    if m.top.mode = "files"
        scanFilesMode()
        return
    end if

    if m.top.mode = "videos"
        entries = ScanVideos(m.top.paths, false)
    else
        entries = ScanFolders(m.top.paths)
    end if

    ' Nodes created in a Task can be handed to the UI through a node field.
    content = CreateObject("roSGNode", "ContentNode")
    ' For a movie folder ("videos"), also report its artwork, if any.
    if m.top.mode = "videos" then content.hdPosterUrl = FindArtwork(m.top.paths)
    ' For an Other folder ("browse"), also count the photos/videos in it.
    if m.top.mode = "browse"
        found = ScanMedia(m.top.paths)
        photos = 0
        for each item in found.media
            if item.kind = "photo" then photos = photos + 1
        end for
        content.AddFields({ photoCount: photos, videoCount: found.media.Count() - photos, unsupportedCount: found.unsupported })
    end if
    for each entry in entries
        child = content.CreateChild("ContentNode")
        child.title = entry.title
        child.url = entry.path
        paths = [entry.path]
        if entry.DoesExist("paths") then paths = entry.paths
        child.AddFields({ paths: paths })
    end for

    LogInfo("FolderScanTask", m.top.mode + ": " + entries.Count().ToStr() + " entries; listings: " + ListingCounts(m.top.paths))
    m.top.content = content
end sub

' Files browser: every entry of the folder(s), plus ready-made player items
' for its videos (see FileContext / FilePlayerItems).
sub scanFilesMode()
    entries = ScanFiles(m.top.paths)
    context = FileContext(m.top.paths[0], m.global.library.roots, m.top.title)

    content = CreateObject("roSGNode", "ContentNode")
    videos = []
    counts = { folder: 0, video: 0, photo: 0, other: 0 }
    for each entry in entries
        child = content.CreateChild("ContentNode")
        child.title = entry.title
        child.url = entry.path
        videoIndex = -1
        if entry.kind = "video"
            videoIndex = videos.Count()
            videos.Push(entry)
        end if
        child.AddFields({ paths: entry.paths, kind: entry.kind, videoIndex: videoIndex })
        if entry.kind = "" then counts.other = counts.other + 1 else counts[entry.kind] = counts[entry.kind] + 1
    end for

    content.AddFields({
        playerKind: context.kind
        playerTitle: context.title
        playerItems: FilePlayerItems(videos, context)
        folderCount: counts.folder
        videoCount: counts.video
        photoCount: counts.photo
        otherCount: counts.other
    })
    LogInfo("FolderScanTask", "files: " + FormatJson(counts) + " in " + FormatJson(m.top.paths) + " as " + context.kind + " " + context.title)
    m.top.content = content
end sub
