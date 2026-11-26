' ============================================================================
' Scan.brs — reading folders on the USB drive
'
' These functions touch the drive, so only call them from Task nodes.
' Needs: MediaTypes.brs, NaturalSort.brs, Progress.brs, Format.brs, Library.brs
' ============================================================================

' Subfolders of one or more folders, merged by name and naturally sorted:
'   [ { name, title, path, paths }, ... ]
' "paths" lists every folder with that name (several drives); path = first.
function ScanFolders(folders as Object) as Object
    entries = []
    byName = {}
    for each folder in folders
        for each name in listDirectory(folder)
            path = folder + "/" + name
            if byName.DoesExist(name)
                byName[name].paths.Push(path)
            else if not IsJunkName(name) and isDirectory(path)
                entry = { name: name, title: name, path: path, paths: [path] }
                byName[name] = entry
                entries.Push(entry)
            end if
        end for
    end for
    NaturalSortByName(entries, false)
    return entries
end function

' Playable video files in one or more folders, naturally sorted:
'   [ { name, title (no extension), path }, ... ]
function ScanVideos(folders as Object, episodeAware as Boolean) as Object
    entries = []
    seen = {}
    for each folder in folders
        for each name in listDirectory(folder)
            if MediaKind(name) = "video" and not seen.DoesExist(name)
                seen[name] = true
                entries.Push({ name: name, title: StripExtension(name), path: folder + "/" + name })
            end if
        end for
    end for
    NaturalSortByName(entries, episodeAware)
    return entries
end function

' Photos and videos directly inside one or more folders (not subfolders):
'   { media: [ { name, path, kind: "photo" | "video" }, ... ], unsupported: n }
' "unsupported" counts other files (e.g. HEIC photos) so the UI can say
' why they're missing. Hidden/system files aren't counted.
function ScanMedia(folders as Object) as Object
    media = []
    unsupported = 0
    seen = {}
    for each folder in folders
        for each name in listDirectory(folder)
            path = folder + "/" + name
            kind = MediaKind(name)
            if kind <> "" and not seen.DoesExist(name)
                seen[name] = true
                media.Push({ name: name, path: path, kind: kind })
            else if kind = "" and not IsJunkName(name) and not isDirectory(path) and not isSidecarName(name)
                unsupported = unsupported + 1
            end if
        end for
    end for
    return { media: media, unsupported: unsupported }
end function

' Everything in one or more folders, as the drive has it (Files browser):
'   [ { name, title, path, paths, kind }, ... ]
' kind: "folder", "video", "photo", or "" (a file Couchmark can't play).
' Folders come first, merged by name across drives (paths = every
' location); then files, naturally sorted. Hidden/system files are skipped.
function ScanFiles(folders as Object) as Object
    subfolders = ScanFolders(folders)
    for each entry in subfolders
        entry.kind = "folder"
    end for

    files = []
    seen = {}
    for each folder in folders
        for each name in listDirectory(folder)
            path = folder + "/" + name
            if not seen.DoesExist(name) and not IsJunkName(name) and not isDirectory(path)
                seen[name] = true
                files.Push({ name: name, title: name, path: path, paths: [path], kind: MediaKind(name) })
            end if
        end for
    end for
    NaturalSortByName(files, true)

    subfolders.Append(files)
    return subfolders
end function

' Subtitle files and similar sidecar files aren't worth reporting.
function isSidecarName(name as String) as Boolean
    ext = FileExtension(name)
    return ext = "srt" or ext = "sub" or ext = "idx" or ext = "nfo" or ext = "txt" or ext = "xml"
end function

' Every episode of a show, in watching order:
'   {
'     items:   [ { url, label, id, code }, ... ]   (PlayerScreen items)
'     seasons: [ { title, first, count }, ... ]    (each season's slice)
'   }
' Season folders are merged across drives. Videos directly in the show
' folder become a season called "Episodes".
function ScanShow(showFolders as Object) as Object
    items = []
    seasons = []

    loose = ScanVideos(showFolders, true)
    if loose.Count() > 0 then addSeason(items, seasons, "Episodes", "", loose)

    for each season in ScanFolders(showFolders)
        episodes = ScanVideos(season.paths, true)
        if episodes.Count() > 0 then addSeason(items, seasons, season.name, season.name + "/", episodes)
    end for

    return { items: items, seasons: seasons }
end function

sub addSeason(items as Object, seasons as Object, title as String, relativePrefix as String, episodes as Object)
    first = items.Count()
    for each episode in episodes
        items.Push(episodeItem(episode, relativePrefix))
    end for
    seasons.Push({ title: title, first: first, count: episodes.Count() })
end sub

' A PlayerScreen item for one episode file ({ name, path } from a scan).
' relativePrefix: its season folder + "/", or "" for a loose episode.
function episodeItem(episode as Object, relativePrefix as String) as Object
    code = episodeCodeLabel(episode.name)
    return {
        url: episode.path
        label: CleanEpisodeTitle(StripExtension(episode.name), code)
        id: ProgressEpisodeId(relativePrefix + episode.name)
        code: code
    }
end function

' PlayerScreen items for the videos of one folder in the Files browser
' ([ { name, path } ], in order), using the folder's FileContext: episode
' items for a show's folder (same ids as the show page, so progress is
' shared), part items for a movie, plain items otherwise (label = file
' name without extension).
function FilePlayerItems(videos as Object, context as Object) as Object
    if context.kind = "movie" then return MoviePlayerItems(videos)
    items = []
    for each video in videos
        if context.kind = "show"
            items.Push(episodeItem(video, context.prefix))
        else
            items.Push({ url: video.path, label: StripExtension(video.name), id: "", code: "" })
        end if
    end for
    return items
end function

' "Show.S2E5.mkv" -> "S02E05", or "" when there's no code.
function episodeCodeLabel(fileName as String) as String
    code = EpisodeCode(fileName)
    if code = invalid then return ""
    return "S" + pad2(code.season) + "E" + pad2(code.episode)
end function

' Artwork for a movie or show: the first of these files found in its
' folder(s), or "" if none. Wide images first, since tiles are 16:9.
function FindArtwork(folders as Object) as String
    candidates = ["fanart", "landscape", "backdrop", "poster", "folder", "cover", "thumb"]
    extensions = ["jpg", "jpeg", "png"]

    for each folder in folders
        ' lower-case name -> real name (file names may be "Poster.JPG")
        present = {}
        for each name in listDirectory(folder)
            present[LCase(name)] = name
        end for
        for each candidate in candidates
            for each ext in extensions
                key = candidate + "." + ext
                if present.DoesExist(key) then return folder + "/" + present[key]
            end for
        end for
    end for
    return ""
end function

' Existing folders called <title> inside any of the given root folders.
function FindTitleFolders(roots as Object, title as String) as Object
    found = []
    for each root in roots
        path = root + "/" + title
        if isDirectory(path) then found.Push(path)
    end for
    return found
end function

' ----------------------------------------------------------------------------
' Drive access (replaced by tests/doubles/Folders.brs in the tests)
' ----------------------------------------------------------------------------

' Names of the files and folders directly inside a folder.
function listDirectory(folder as String) as Object
    return CreateObject("roFileSystem").GetDirectoryListing(folder + "/")
end function

function isDirectory(path as String) as Boolean
    info = CreateObject("roFileSystem").Stat(path)
    return info <> invalid and info.type = "directory"
end function
