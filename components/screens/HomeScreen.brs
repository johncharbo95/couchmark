' ============================================================================
' HomeScreen.brs
'
'   1. HomeScanTask "library": every show/movie folder + artwork (once).
'   2. HomeScanTask "continue": the Continue Watching tiles. Re-run every
'      time the home screen reappears, e.g. after watching something.
'   3. buildRows() turns both into RowList content and keeps the focus.
'
' Each tile's "action" field says what OK does:
'   { type: "play",   player: {...PlayerScreen fields} }   Continue Watching
'   { type: "show",   paths, art }                          → ShowScreen
'   { type: "movie",  path, art }                           → MovieScreen
'   { type: "browse", id: "movies" | "shows" | "other" | "settings" }
' ============================================================================

sub init()
    m.rows = m.top.FindNode("rows")
    m.heroArt = m.top.FindNode("heroArt")
    m.heroTitle = m.top.FindNode("heroTitle")
    m.heroSubtitle = m.top.FindNode("heroSubtitle")
    m.loading = m.top.FindNode("loading")

    m.rows.ObserveField("rowItemSelected", "onTileSelected")
    m.rows.ObserveField("rowItemFocused", "onTileFocused")
    m.top.ObserveField("focusedChild", "onFocusedChildChange")
    m.top.ObserveField("visible", "onVisibleChange")

    m.libraryData = invalid
    m.continueTiles = []
    m.rowKeys = []

    m.loading.message = "Loading your library…"
    m.loading.visible = true
    startScan("library")
end sub

sub onFocusedChildChange()
    if m.top.HasFocus() then m.rows.SetFocus(true)
end sub

sub onVisibleChange()
    ' Back from the player etc.: progress may have changed.
    if m.top.visible and m.libraryData <> invalid then startScan("continue")
end sub

' ----------------------------------------------------------------------------
' Scanning
' ----------------------------------------------------------------------------

sub startScan(mode as String)
    m.scanTask = CreateObject("roSGNode", "HomeScanTask")
    m.scanTask.roots = m.global.library.roots
    m.scanTask.mode = mode
    if mode = "library"
        m.scanTask.ObserveField("library", "onLibraryScanned")
    else
        m.scanTask.ObserveField("continueTiles", "onContinueScanned")
    end if
    m.scanTask.control = "run"
end sub

sub onLibraryScanned(event as Object)
    m.libraryData = event.GetData()
    startScan("continue")
end sub

sub onContinueScanned(event as Object)
    m.continueTiles = event.GetData()
    m.loading.visible = false
    buildRows()
end sub

' ----------------------------------------------------------------------------
' Rows
' ----------------------------------------------------------------------------

sub buildRows()
    ' Remember which row/tile was focused so a rebuild doesn't move it.
    previousKey = ""
    previousCol = 0
    focused = m.rows.rowItemFocused
    if focused <> invalid and focused.Count() = 2 and focused[0] >= 0 and focused[0] < m.rowKeys.Count()
        previousKey = m.rowKeys[focused[0]]
        previousCol = focused[1]
    end if

    root = CreateObject("roSGNode", "ContentNode")
    m.rowKeys = []
    roots = m.global.library.roots

    if m.continueTiles.Count() > 0
        row = addRow(root, "continue", "Continue Watching")
        for each tile in m.continueTiles
            addTile(row, tile.title, tile.subtitle, tile.art, "partial", tile.progress, true, { type: "play", player: tile.player })
        end for
    end if

    if m.libraryData.shows.Count() > 0
        row = addRow(root, "shows", "Shows")
        for each show in m.libraryData.shows
            addTile(row, show.title, "", show.art, "", 0.0, true, { type: "show", paths: show.paths, art: show.art })
        end for
    end if

    if m.libraryData.movies.Count() > 0
        row = addRow(root, "movies", "Movies")
        for each movie in m.libraryData.movies
            record = ProgressGetMovie(movie.title)
            state = MovieBadge(record)
            subtitle = ""
            if state.badge = "partial" then subtitle = MovieResumeText(record)
            if state.badge = "watched" then subtitle = "Watched"
            addTile(row, movie.title, subtitle, movie.art, state.badge, state.progress, true, { type: "movie", path: movie.path, art: movie.art })
        end for
    end if

    row = addRow(root, "browse", "Browse")
    addTile(row, "All Shows", "A–Z list", "", "", 0.0, roots.shows.Count() > 0, { type: "browse", id: "shows" })
    addTile(row, "All Movies", "A–Z list", "", "", 0.0, roots.movies.Count() > 0, { type: "browse", id: "movies" })
    addTile(row, "Other", "Photo & video slideshows", "", "", 0.0, roots.other.Count() > 0, { type: "browse", id: "other" })
    addTile(row, "Settings", "Slideshow & history", "", "", 0.0, true, { type: "browse", id: "settings" })

    m.rows.content = root

    ' Restore focus (same row by key, same column if it still exists).
    rowIndex = 0
    for i = 0 to m.rowKeys.Count() - 1
        if m.rowKeys[i] = previousKey then rowIndex = i
    end for
    if previousKey = "" then previousCol = 0
    colCount = root.GetChild(rowIndex).GetChildCount()
    if previousCol >= colCount then previousCol = colCount - 1
    m.rows.jumpToRowItem = [rowIndex, previousCol]
    updateHero(root.GetChild(rowIndex).GetChild(previousCol))
end sub

function addRow(root as Object, key as String, title as String) as Object
    row = root.CreateChild("ContentNode")
    row.title = title
    m.rowKeys.Push(key)
    return row
end function

sub addTile(row as Object, title as String, subtitle as String, art as String, badge as String, progress as Float, enabled as Boolean, action as Object)
    tile = row.CreateChild("ContentNode")
    tile.title = title
    tile.description = subtitle
    tile.hdPosterUrl = art
    tile.AddFields({ badge: badge, progress: progress, enabled: enabled, action: action })
end sub

' ----------------------------------------------------------------------------
' Focus & selection
' ----------------------------------------------------------------------------

sub onTileFocused()
    tile = tileAt(m.rows.rowItemFocused)
    if tile <> invalid then updateHero(tile)
end sub

sub updateHero(tile as Object)
    m.heroTitle.text = tile.title
    m.heroSubtitle.text = tile.description
    m.heroArt.uri = tile.hdPosterUrl
end sub

function tileAt(position as Dynamic) as Dynamic
    if position = invalid or position.Count() <> 2 then return invalid
    if m.rows.content = invalid then return invalid
    row = m.rows.content.GetChild(position[0])
    if row = invalid then return invalid
    return row.GetChild(position[1])
end function

sub onTileSelected()
    tile = tileAt(m.rows.rowItemSelected)
    if tile = invalid then return
    action = tile.action

    if action.type = "play"
        m.top.navigate = { screen: "PlayerScreen", fields: action.player }
    else if action.type = "show"
        m.top.navigate = { screen: "ShowScreen", fields: { title: tile.title, paths: action.paths, art: action.art } }
    else if action.type = "movie"
        m.top.navigate = { screen: "MovieScreen", fields: { title: tile.title, path: action.path, art: action.art } }
    else
        openBrowse(tile, action.id)
    end if
end sub

sub openBrowse(tile as Object, id as String)
    roots = m.global.library.roots

    if not tile.enabled
        folder = "Movies"
        if id = "shows" then folder = "Shows"
        if id = "other" then folder = "Other"
        m.top.navigate = {
            screen: "MessageScreen"
            fields: {
                title: "No " + folder + " folder"
                message: "Create a folder named """ + folder + """ at the top of your USB drive." + Chr(10) + Chr(10) + UsbLayoutHelp()
            }
        }
        return
    end if

    if id = "movies"
        m.top.navigate = { screen: "FolderListScreen", fields: { title: "Movies", kind: "movies", paths: roots.movies } }
    else if id = "shows"
        m.top.navigate = { screen: "FolderListScreen", fields: { title: "Shows", kind: "shows", paths: roots.shows } }
    else if id = "other"
        m.top.navigate = { screen: "FolderListScreen", fields: { title: "Other", kind: "other", paths: roots.other } }
    else
        ' The settings screen arrives in milestone 5.
        m.top.navigate = {
            screen: "MessageScreen"
            fields: { title: tile.title, message: "Coming in milestone 5." }
        }
    end if
end sub
