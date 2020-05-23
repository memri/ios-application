SessionView[] {
    name: "all-sessionviews"
    title: "All Session Views"
    queryOptions: {
        query: "sessionview"
        sortProperty: dateAccessed
        sortAscending: false
    }
    emptyResultText: "No views in this session"
    defaultRenderer: list
    editActionButton: { actionName: toggleEditMode }
    filterButtons [ showStarred toggleFilterPanel ]
    
    [renderer = list] {
        VStack {
            alignment: left
            rowInset: 12 20 -12 20
        
            HStack {
                alignment: top
            
                Text {
                    text: {.computedDescription()}
                    font: 18 semibold
                    color: #333
                    padding: 0 0 3 0
                }
                Spacer
                Text {
                    text: {.dateAccessed}
                    font: 11 regular
                    color: #888
                    padding: 8050
                }
            }
            
            Rectangle {
                maxHeight: 1
                color: #efefef
                padding: 7 -20 12 0
            }
        }
    }
}
