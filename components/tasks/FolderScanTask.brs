' ============================================================================
' FolderScanTask.brs — see lib/Scan.brs for the actual scanning
' ============================================================================

sub init()
    m.top.functionName = "scan"
end sub

sub scan()
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

    print "[FolderScanTask] "; m.top.mode; ": "; entries.Count(); " entries in "; FormatJson(m.top.paths)
    m.top.content = content
end sub
