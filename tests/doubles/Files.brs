' ============================================================================
' Files.brs (test double) — replaces the file access in lib/MediaDate.brs.
' File contents come from @fixture files (see tests/run.js), stored by name
' in GetGlobalAA().files. Call loadFixtures() first.
' ============================================================================

function readBytes(path as String, offset as LongInteger, length as Integer) as Dynamic
    data = GetGlobalAA().files[path]
    if offset + length > data.Count() then return invalid
    start = offset.ToStr().ToInt()
    bytes = []
    for i = 0 to length - 1
        bytes.Push(data[start + i])
    end for
    return bytes
end function

function fileSizeOf(path as String) as LongInteger
    return GetGlobalAA().files[path].Count() + 0&
end function

' Fixed "modified time" and UTC offset so results don't depend on the PC.
function FileModifiedTime(path as String) as Integer
    return 123456
end function

function localOffsetSeconds() as Integer
    return 0
end function
