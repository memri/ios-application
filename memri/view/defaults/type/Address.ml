Address[] {
    defaultRenderer: list
    filterButtons: [ showStarred toggleFilterPanel ]

    [renderer = list]{
        HStack {
            Text {
                text: "{.computedTitle()}"
                font: [16]
                padding: 0 0 10 0
            }
            Spacer
            Map {
                address: "{dataItem}"
                maxWidth: 150
                minHeight: 150
                maxHeight: 150
                cornerRadius: 10
                border: "#DDD" 1
                margin: 0 0 10 0
            }
        }
    }
    [renderer = generalEditor]{
        EditorRow {
            title: "{.type}"
            nopadding: {{!readOnly}}
        } [
            HStack {
                condition: {{readOnly}}
                Text {
                    text: "{.computedTitle()}"
                    font: [16]
                    padding: 0 0 10 0
                }
                Spacer
                Map{
                    address: "{.}"
                    maxWidth: 150
                    minHeight: 150
                    maxHeight: 150
                    cornerRadius: 10
                    border: "#DDD" 1
                    margin: 0 0 10 0
                }
            ]
            HStack {
                condition: {{!readOnly}}
                EditorLabel {
                    title: "{.type}"
                    edge: {{edge}}
                    hierarchy: address
                }
                VStack {
                    Textfield { hint: Street value: "{.street}" rows: 2 }
                    Textfield { hint: City value: "{.city}" }
                    HStack {
                        Textfield { hint: "State" value: "{.state}" }
                        Textfield { hint: "Zip" value: "{.postalCode}" }
                    }
                    Picker {
                        empty: Country
                        value: "{.country}"
                        default: "{me.address[primary = true].country}"
                        queryOptions: {
                            query: "country"
                            sortProperty: name
                        }
                    }
                }
            ]
        ]
        
    }
}
            
Address {
    title: "{.computedTitle}"
    defaultRenderer: generalEditor
    editActionButton: toggleEditMode
    contextButtons: star schedule
    
    [renderer = generalEditor] {
        groups {
            dates: dateCreated dateModified dateAccessed changelog
            address: street city state postalCode country
            location: [location]
        }
        sequence: location labels address other dates
        
        location: {
            for: group
            sectionTitle: ""
            
            Map {
                location: {.}
                minHeight: 150
                maxHeight: 150
            }
        }
        
        labels: {
            VSTack {
                for: group
                sectionTitle: ""
                padding: 10 36 5 36
                
                Text {
                    condition: {!.labels.count}
                    text: "no labels yet"
                }
                FlowStack {
                    list {.labels}
                    
                    button {
                        press: {
                            actionName: openViewByName
                            actionArgs: [
                                all-items-with-label
                                {
                                    name: Soccer team
                                    uid: 0x0124
                                }
                            ]
                        }
                        VStack {
                            background: {.color}
                            cornerRadius: 5
                            
                            Text {
                                text: "{.name}"
                                font: 16 semibold
                                color: #fff
                                padding: 5 8 5 8
                            }
                        }
                    }
                }
            }
        }
        country: {
            VStack {
                Text {
                    text: {{.country.name}}
                    condition: {{readOnly}}
                }
                Picker {
                    empty: Country
                    value: {{.country}}
                    default: {{me.address[primary = true].country}}
                    condition: {{!readOnly}}
                    queryOptions: {
                        query: "country"
                        sortProperty: name
                    }
                }
            }
        }
    }
}
