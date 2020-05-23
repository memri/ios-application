Country[] {
    name: all-countries
    defaultRenderer: list
    filterButtons: [ showStarred toggleFilterPanel ]
    
    [renderer = list] {
        VStack {
            alignment: left
            padding: 0 20 0 20
            
            Text {
                text: "{.computedTitle()}"
                padding: 10 0 10 0
            }
            Rectangle {
                minHeight: 1
                maxHeight: 1
                color: #efefef
                padding: 0 0 0 0
            }
    }
    
    [renderer = generalEditor] {
        EditorRow {
            title: "{title}"
            
            Text {
                text: {{.name}}
                condition: {{readOnly}}
            }
            Picker {
                empty: Country
                value: {{.}}
                title: "Select a country"
                default: {{me.address[primary = true].country}}
                optionsFromQuery: country
                condition: {{!readOnly}}
            }
        ]
    }
}
