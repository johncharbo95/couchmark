' ============================================================================
' HomeScreen.brs
' ============================================================================

sub init()
    m.grid = m.top.FindNode("grid")
    m.status = m.top.FindNode("status")

    m.grid.ObserveField("itemSelected", "onItemSelected")

    ' When MainScene focuses this screen, pass focus on to the grid
    ' (only the focused node receives remote-control keys).
    m.top.ObserveField("focusedChild", "onFocusedChildChange")

    buildMenu()
end sub

sub buildMenu()
    roots = m.global.library.roots

    ' A grid's items are described by a tree of ContentNodes.
    content = CreateObject("roSGNode", "ContentNode")
    addTile(content, "movies", "Movies", "Films, one folder each", roots.movies.Count() > 0)
    addTile(content, "shows", "Shows", "Series, seasons, episodes", roots.shows.Count() > 0)
    addTile(content, "other", "Other", "Photo & video slideshows", roots.other.Count() > 0)
    addTile(content, "settings", "Settings", "Slideshow & history", true)
    m.grid.content = content

    m.status.text = statusText()
end sub

sub addTile(parent as Object, id as String, title as String, subtitle as String, enabled as Boolean)
    tile = parent.CreateChild("ContentNode")
    tile.id = id
    tile.title = title
    tile.description = subtitle
    ' "enabled" isn't a standard ContentNode field, so we add it.
    tile.AddFields({ enabled: enabled })
end sub

' e.g. "Library on ext1:  ·  No Shows folder found"
function statusText() as String
    library = m.global.library
    text = "Library on " + library.volumes.Join(", ")

    missing = []
    if library.roots.movies.Count() = 0 then missing.Push("Movies")
    if library.roots.shows.Count() = 0 then missing.Push("Shows")
    if library.roots.other.Count() = 0 then missing.Push("Other")
    if missing.Count() > 0
        text = text + "   ·   No " + missing.Join(" / ") + " folder found"
    end if
    return text
end function

sub onFocusedChildChange()
    if m.top.HasFocus() then m.grid.SetFocus(true)
end sub

sub onItemSelected()
    tile = m.grid.content.GetChild(m.grid.itemSelected)

    if not tile.enabled
        m.top.navigate = {
            screen: "MessageScreen"
            fields: {
                title: "No " + tile.title + " folder"
                message: "Create a folder named """ + tile.title + """ at the top of your USB drive." + Chr(10) + Chr(10) + UsbLayoutHelp()
            }
        }
        return
    end if

    ' The real screens arrive in later milestones.
    milestones = { movies: "2", shows: "3", other: "4", settings: "5" }
    m.top.navigate = {
        screen: "MessageScreen"
        fields: {
            title: tile.title
            message: "Coming in milestone " + milestones[tile.id] + "."
        }
    }
end sub
