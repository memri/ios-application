/*
    Session[labels.count > 0]
    [renderer = list]
    Session[]
*/
Session {
    name: "all-sessions"
    title: "All Sessions"
    emptyResultText: "There are no sessions here yet"
    defaultRenderer: thumbnail
    
    /* sortFields: [title, dateModified, dateAccessed, dateCreated] */
    /* sortFields: title dateModified dateAccessed dateCreated */
    sortFields:
        title
        dateModified
        dateAccessed
        dateCreated
    
    queryOptions {
        query: "session"
        sortProperty: dateAccessed
        sortAscending: false
    }
    
    editActionButton: toggleEditMode
    filterButtons: showStarred toggleFilterPanel

    [renderer = list] {
        press: openSession
        
        VStack {
            alignment: left
            rowInset: 12 20 -12 20
        
            HStack {
                VStack {
                    Text {
                        text: "Name: {.name}"
                        font: 18 semibold
                        color: #333
                        padding: 5 0 0 0
                    }
                    Text {
                        text: "Accessed: {.dateModified}"
                        font: 11 regular
                        color: #888
                        padding: 5 0 5 0
                    }
                }
                Spacer
                Image {
                    image: {{.screenshot}}
                    border: #ccc 1
                    resizable: fill
                    maxWidth: 150
                    maxHeight: 150
                    cornerRadius: 10
                    padding: -5 0 0 0
                }
            }
            Rectangle {
                minHeight: 1
                maxHeight: 1
                color: #efefef
                padding: 7 -20 12 0
            }
        }
    }
    
    [renderer = thumbnail] {
        columns: 2
        hSpacing: 20
        press: openSession
        
        VStack {
            minWidth: 10
            padding: 0 0 5 0
            alignment: center
            
            Image {
                image: {{.screenshot}}
                border: #ccc 1
                resizable: fill
                maxHeight: 180
                cornerRadius: 10
            }
            Text {
                text: "{.name}"
                padding: 5 0 0 0
                color: #333
                font: 12 semibold
                maxChar: 100
            }
            Text {
                text: "{.dateModified}"
                font: 9 regular
                color: #888
                padding: 3 0 0 0
            }
        }
    }
}
