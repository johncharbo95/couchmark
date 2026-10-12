' ============================================================================
' UsbScanTask.brs
'
' USB drives appear as volumes named "ext1:", "ext2:", ... When several drives
' are attached, their folders are merged: e.g. roots.movies may contain both
' "ext1:/Movies" and "ext2:/Movies", and the Movies screen lists both.
' ============================================================================

sub init()
    ' The function that runs when control = "run".
    m.top.functionName = "scan"
end sub

sub scan()
    fs = CreateObject("roFileSystem")

    ' Map of lower-case folder name -> key in roots. Matching is
    ' case-insensitive so "movies" or "MOVIES" also work.
    wanted = { movies: "movies", shows: "shows", other: "other" }
    roots = { movies: [], shows: [], other: [] }

    volumes = []
    for each volume in fs.GetVolumeList()
        if Left(volume, 3) = "ext" then volumes.Push(volume)
    end for
    volumes.Sort()

    for each volume in volumes
        volumeRoot = volume + "/"
        for each name in fs.GetDirectoryListing(volumeRoot)
            key = wanted[LCase(name)]
            path = volumeRoot + name
            if key <> invalid and isDirectory(fs, path)
                roots[key].Push(path)
            end if
        end for
    end for

    print "[UsbScanTask] volumes="; FormatJson(volumes); " roots="; FormatJson(roots)
    m.top.result = { volumes: volumes, roots: roots }
end sub

function isDirectory(fs as Object, path as String) as Boolean
    info = fs.Stat(path)
    return info <> invalid and info.type = "directory"
end function
