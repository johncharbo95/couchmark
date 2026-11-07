' ============================================================================
' Folders.brs (test double) — replaces the drive access in lib/Scan.brs with
' a fake folder tree in GetGlobalAA().tree: path -> [ names ], one entry per
' folder. Paths in the tree are folders; any other path is a file.
'
'   setTree({ "ext1:/Shows": ["Lost"], "ext1:/Shows/Lost": ["S01E01.mkv"] })
' ============================================================================

sub setTree(tree as Object)
    GetGlobalAA().tree = tree
end sub

function listDirectory(folder as String) as Object
    tree = GetGlobalAA().tree
    if tree.DoesExist(folder) then return tree[folder]
    return []
end function

function isDirectory(path as String) as Boolean
    return GetGlobalAA().tree.DoesExist(path)
end function
