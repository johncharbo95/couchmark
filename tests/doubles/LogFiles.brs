' ============================================================================
' LogFiles.brs (test double) — replaces the device access in lib/Log.brs
' with a fake file system and clock.
'
'   GetGlobalAA().fakeFs = {
'       volumes:  ["ext1:", "tmp:", ...]     what logVolumes() returns
'       readOnly: { "ext1:": true }          volumes where nothing can be written
'       files:    { path: text }             file contents
'       dirs:     { path: true }             folders that exist
'   }
'   GetGlobalAA().sent  lines passed to logSend()
' ============================================================================

sub resetFakeFs(volumes as Object)
    g = GetGlobalAA()
    g.fakeFs = { volumes: volumes, readOnly: {}, files: {}, dirs: {} }
    g.sent = []
end sub

function fakeVolumeOf(path as String) as String
    return Left(path, Instr(1, path, ":"))
end function

function fakeWritable(path as String) as Boolean
    fs = GetGlobalAA().fakeFs
    volume = fakeVolumeOf(path)
    if fs.readOnly.DoesExist(volume) then return false
    for each v in fs.volumes
        if v = volume then return true
    end for
    return false
end function

function logNow() as Object
    return { year: 2026, month: 3, day: 7, hour: 9, minute: 5, second: 2, ms: 42 }
end function

sub logSend(line as String)
    GetGlobalAA().sent.Push(line)
end sub

function logVolumes() as Object
    return GetGlobalAA().fakeFs.volumes
end function

function logMakeDirs(dir as String) as Boolean
    if not fakeWritable(dir) then return false
    GetGlobalAA().fakeFs.dirs[dir] = true
    return true
end function

function logReadFile(path as String) as String
    files = GetGlobalAA().fakeFs.files
    if files.DoesExist(path) then return files[path]
    return ""
end function

function logWriteFile(path as String, text as String) as Boolean
    if not fakeWritable(path) then return false
    GetGlobalAA().fakeFs.files[path] = text
    return true
end function

function logListDir(dir as String) as Object
    names = []
    prefix = dir + "/"
    for each path in GetGlobalAA().fakeFs.files
        if LCase(Left(path, Len(prefix))) = LCase(prefix) then names.Push(Mid(path, Len(prefix) + 1))
    end for
    return names
end function

sub logDeleteFile(path as String)
    GetGlobalAA().fakeFs.files.Delete(path)
end sub
