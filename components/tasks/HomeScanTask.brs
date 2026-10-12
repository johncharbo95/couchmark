' ============================================================================
' HomeScanTask.brs
' ============================================================================

sub init()
    m.top.functionName = "scan"
end sub

sub scan()
    if m.top.mode = "continue"
        m.top.continueTiles = buildContinue()
    else
        m.top.library = buildLibrary()
    end if
end sub

' Every show and movie folder, with artwork if the folder has any.
function buildLibrary() as Object
    roots = m.top.roots

    shows = []
    for each entry in ScanFolders(roots.shows)
        shows.Push({ title: entry.title, paths: entry.paths, art: FindArtwork(entry.paths) })
    end for

    movies = []
    for each entry in ScanFolders(roots.movies)
        movies.Push({ title: entry.title, path: entry.path, art: FindArtwork([entry.path]) })
    end for

    print "[HomeScanTask] library: "; shows.Count(); " shows, "; movies.Count(); " movies"
    return { shows: shows, movies: movies }
end function

' Continue Watching: recently played titles that still have something to
' watch, each with ready-to-use PlayerScreen fields.
function buildContinue() as Object
    tiles = []
    for each recent in ProgressListRecent()
        if tiles.Count() >= 12 then exit for
        if recent.kind = "movie"
            tile = movieTile(recent.record)
        else
            tile = showTile(recent.record)
        end if
        if tile <> invalid then tiles.Push(tile)
    end for
    print "[HomeScanTask] continue: "; tiles.Count(); " tiles"
    return tiles
end function

function movieTile(record as Object) as Dynamic
    if not MovieInProgress(record) then return invalid

    ' Titles come from the registry; the drive may have changed since.
    folders = FindTitleFolders(m.top.roots.movies, record.title)
    if folders.Count() = 0 then return invalid
    parts = ScanVideos([folders[0]], false)
    if record.part >= parts.Count() then return invalid

    return {
        kind: "movie"
        title: record.title
        subtitle: MovieResumeText(record)
        art: FindArtwork([folders[0]])
        progress: MovieFraction(record)
        path: folders[0]
        player: { kind: "movie", title: record.title, items: MoviePlayerItems(parts), startIndex: record.part, startPos: record.pos }
    }
end function

function showTile(record as Object) as Dynamic
    folders = FindTitleFolders(m.top.roots.shows, record.title)
    if folders.Count() = 0 then return invalid

    show = ScanShow(folders)
    target = ContinueTarget(record, show.items)
    if target = invalid then return invalid   ' everything watched

    item = show.items[target.index]
    subtitle = EpisodeShortLabel(item)
    progress = 0.0
    partial = ProgressFindPartial(record, item.id)
    if partial <> invalid and partial.dur > 0
        progress = partial.pos / partial.dur
        subtitle = subtitle + "  ·  " + FormatRemaining(partial.dur - partial.pos) + " left"
    else if record.watched.Count() > 0
        subtitle = "Next: " + subtitle
    end if

    return {
        kind: "show"
        title: record.title
        subtitle: subtitle
        art: FindArtwork(folders)
        progress: progress
        paths: folders
        player: { kind: "show", title: record.title, items: show.items, startIndex: target.index, startPos: target.pos }
    }
end function
