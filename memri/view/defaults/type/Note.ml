Note {
    title: "{.title}"
    defaultRenderer: richTextEditor
    editActionButton: toggleEditMode
    filterButtons:
        openView {
            icon: "increase.indent"
            title: "Show Timeline"
            
            view: {
                defaultRenderer: timeline
                
                queryOptions: {
                    query: "AuditItem appliesTo:{.id}"
                    sortProperty: dateCreated
                    sortAscending: true
                }
                
                [renderer = timeline] {
                    timeProperty: dateCreated
                }
            }
        }
        showContextPane
    
    contextButtons: star schedule
    
    actionItems:
        showSharePanel { title: "Share with..." }
        addToPanel { title: "Add to list..." }
        duplicate { title: "Duplicate Note" }
    
    navigateItems:
        openView {
            title: "Timeline of this note"
            view: {
                defaultRenderer: timeline
                
                queryOptions {
                    query: "AuditItem appliesTo:{.id}"
                    sortProperty: dateCreated
                    sortAscending: true
                }
                
                [renderer = timeline] {
                    timeProperty: dateCreated
                }
            }
        }
        openViewByName {
            title: "Starred notes"
            name: "filter-starred"
            arguments: {
                fromTemplate: "all-notes"
            }
        }
        openViewByName {
            title: "All notes"
            name: "all-notes"
        }
}

Note[] {
    name: "all-notes"
    title: "All Notes"
    emptyResultText: "There are no notes here yet"
    defaultRenderer: list
    sortFields: title dateModified dateAccessed dateCreated
    
    queryOptions {
        query: "note"
        sortProperty: dateModified
        sortAscending: false
    }
    
    actionButton:
        add {
            template {
                type: note
                title: Untitled Note
            }
        }
        
    editActionButton: toggleEditMode
    filterButtons: showStarred toggleFilterPanel
    
    [renderer = list] {
        VStack {
            alignment: left
            rowInset: 12 20 -12 20
            
            Text {
                text: "{.title}"
                font: 18 semibold
                color: #333
                padding: 0 0 3 0
            }
            Text {
                text: "{.content}"
                removeWhiteSpace: true
                maxChar: 100
                color: #555
                font: 14 regular
            }
            Text {
                text: "{.dateModified}"
                font: 11 regular
                color: #888
                padding: 8050
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
        VStack {
            minWidth: 10
            padding: 0 0 5 0
            alignment: center
            
            Text {
                text: "{.content}"
                maxChar: 100
                color: #333
                background: #fff
                border: #efefef 2
                cornerRadius: 10
                padding: 10
                font: 9 regular
                minHeight: 80
                align: lefttop
            }
            Text {
                text: "{.title}"
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
