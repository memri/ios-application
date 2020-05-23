Label[]: {
    name: "all-labels"
    title: "All Labels"
    queryOptions: {
        query: "label"
        sortProperty: dateCreated
        sortAscending: true
    }
    emptyResultText: "You have not added any labels yet"
    defaultRenderer: thumbnail
    
    [renderer = list]{
        VStack {
            rowInset: 7 20 -7 20
            
            HStack {
                alignment: center
                padding: 5 0 5 0
                
                VStack {
                    alignment: left
                    spacing: 5
                    
                    Text { text: {.name} bold: true }
                    Text {
                        text: {.comment}
                        removeWhiteSpace: true
                        maxChar: 100
                    }
                }
                Spacer
                RoundedRectangle {
                    color: {.color}
                    maxHeight: 25
                    maxWidth: 25
                    align: center
                    padding: 0 10 0 0
                }
            }
            
            Rectangle {
                maxHeight: 1
                color: #efefef
                padding: 5 -20 5 0
            }
        }
    }
    
    [renderer = thumbnail] {
        VStack {
            VStack {
                padding: 5 0 5 0
                alignment: center
                
                HStack {
                    color: #FFF
                    cornerRadius: 5
                    background: {.color}
                    
                    Spacer
                    Text {
                        text: {.name}
                        bold: true
                        padding: 3 0 3 0
                    }
                    Spacer
                }
                Spacer
                Text {
                    text: {.comment}
                    removeWhiteSpace: true
                    font: 10
                    maxChar: 100
                }
            }
        }
    }
    actionButton: {
        actionName: add
        actionArgs: {
            type: label
            name: new label
        }
    }
    editActionButton: { actionName: toggleEditMode }
    filterButtons: [ showStarred, toggleFilterPanel ]
}
