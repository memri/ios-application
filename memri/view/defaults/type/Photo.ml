Photo {
    name: "all-photos"
    title: "All Photos"
    defaultRenderer: thumbnail
    queryOptions {
        query: "photo"
        sortProperty: dateModified
        sortAscending: false
    },
    emptyResultText: "There are no photos here yet",
    [renderer = thumbnail] {
        itemInset: 1
        edgeInset: 0 0 0 0
        Image, {
            image: "{.file}" /* ALLOW BOTH STRINGS AND FILES*/
            resizable: fill
        }
    },
    editActionButton: toggleEditMode
    filterButtons: [ showStarred toggleFilterPanel ]
}
