* {
    searchHint: Search
}


*[]: {
    searchHint: Search
    sortFields: [dateCreated, dateModified, dateAccessed],
    [renderer = generalEditor] {
        EditorRow {
            spacing: 5
            padding: 10 0 10 0
            HStack {
                alignment: center
                MemriButton
                Spacer
                Button{
                    press: archive
                    condition: {{!readOnly}}
                    Image {
                        systemName: bolt.horizontal.circle.fill
                        color: #ff0000
                    }
                }
            }
        }
    }
}
