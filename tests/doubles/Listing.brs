' ============================================================================
' Listing.brs (test double) — replaces reportListDir() in lib/ScanReport.brs.
' Listings come from GetGlobalAA().listings: folder -> [names].
' ============================================================================

function reportListDir(folder as String) as Object
    listings = GetGlobalAA().listings
    if listings <> invalid and listings.DoesExist(folder) then return listings[folder]
    return []
end function
