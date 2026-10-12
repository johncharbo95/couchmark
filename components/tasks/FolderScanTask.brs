' ============================================================================
' FolderScanTask.brs
' ============================================================================

sub init()
    m.top.functionName = "scan"
end sub

sub scan()
    fs = CreateObject("roFileSystem")
    mode = m.top.mode

    ' Collect entries as plain associative arrays first; sorting those is
    ' much cheaper than sorting nodes. "seen" merges same-named folders that
    ' exist on two drives (the first drive wins).
    entries = []
    seen = {}

    for each folder in m.top.paths
        for each name in fs.GetDirectoryListing(folder + "/")
            path = folder + "/" + name
            if wantEntry(fs, mode, name, path) and not seen.DoesExist(name)
                seen[name] = true
                title = name
                if mode = "videos" then title = StripExtension(name)
                entries.Push({ name: name, title: title, path: path })
            end if
        end for
    end for

    NaturalSortByName(entries, m.top.episodeAware)

    ' Nodes created in a Task can be handed to the UI through a node field.
    content = CreateObject("roSGNode", "ContentNode")
    for each entry in entries
        child = content.CreateChild("ContentNode")
        child.title = entry.title
        child.url = entry.path
    end for

    print "[FolderScanTask] "; mode; ": "; entries.Count(); " entries in "; FormatJson(m.top.paths)
    m.top.content = content
end sub

function wantEntry(fs as Object, mode as String, name as String, path as String) as Boolean
    if mode = "videos"
        ' The extension check is enough here; no need to Stat every file.
        return MediaKind(name) = "video"
    end if

    ' mode = "folders"
    if IsJunkName(name) then return false
    info = fs.Stat(path)
    return info <> invalid and info.type = "directory"
end function
