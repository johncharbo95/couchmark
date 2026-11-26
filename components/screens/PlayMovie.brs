' ============================================================================
' PlayMovie.brs — Play/Pause on a movie tile or row (HomeScreen,
' FolderListScreen): lists the movie's parts, then starts the player at its
' resume point (or the start). Included by those screens. Needs Progress.brs,
' Format.brs, Library.brs, and m.loading / m.toast on the screen.
' ============================================================================

sub PlayMovie(title as String, path as String)
    if m.loading.visible then return   ' still scanning something
    m.playMovieTitle = title
    m.loading.message = "Opening " + title + "…"
    m.loading.visible = true
    m.playMovieTask = CreateObject("roSGNode", "FolderScanTask")
    m.playMovieTask.paths = [path]
    m.playMovieTask.mode = "videos"
    m.playMovieTask.ObserveField("content", "onPlayMoviePartsScanned")
    m.playMovieTask.control = "run"
end sub

sub onPlayMoviePartsScanned(event as Object)
    m.loading.visible = false
    title = m.playMovieTitle
    parts = []
    for each child in event.GetData().GetChildren(-1, 0)
        parts.Push({ path: child.url })
    end for
    if parts.Count() = 0
        m.toast.message = "No playable video files in " + title
        return
    end if

    start = MovieStartPoint(ProgressGetMovie(title), parts.Count())
    m.top.navigate = {
        screen: "PlayerScreen"
        fields: { kind: "movie", title: title, items: MoviePlayerItems(parts), startIndex: start.index, startPos: start.pos }
    }
end sub
