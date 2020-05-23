AuditItem[]: {
    name: "all-audititems"
    title: "All Log Entries"
    queryOptions {
        query: "audititem"
        sortProperty: date
        sortAscending: false
    }
    emptyResultText: "There are no log entries here yet"
    sortFields: [date]
    defaultrenderer: list
    [renderer = list]{
        VStack {
            padding: 5
            spacing: 3
            rowInset: 0 20 0 20
            
            HStack {
                alignment: center
                
                Text {
                    text: "{.action}"
                    font: 14 semibold
                }
                Spacer
                Text {
                    text: "{.date}"
                    font: 11 regular
                    color: #888
                }
            }
            Text {
                text: "{.contents}"
                font: 14 light]
                removeWhiteSpace: true
                maxChar: 100
                cornerRadius: 5
                background: #f3f3f3
                padding: 5
            }
        }
    }
    editActionButton: { actionName: toggleEditMode }
    filterButtons: [ showStarred toggleFilterPanel ]
}
