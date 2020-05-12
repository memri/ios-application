[renderer = generalEditor] {
    sequence: labels starred other dates
    excluded: deleted syncState uid
    readOnly: uid
    
    groups {
        dates: dateCreated dateModified dateAccessed changelog
    }
    
    starred {
        Action {
            press: star
        }
    }
    
    labels {
        foreach: false
        
        EditorRow {
            title: "{displayName}"
            
            Text {
                show: {{!.labels.count}}
                text: no labels yet
            }
            FlowStack {
                list: {{.labels}}
            
                Button {
                    press: openViewByName {
                        name: "all-items-with-label"
                        arguments: {
                            name: "Soccer team"
                            uid: 0x0124
                        }
                    }
                
                    VStack {
                        background: {{.color}}
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
    
    dates {
        foreach: false
        sectionTitle: ""
        
        Text {
            alignment: center
            textalign: center
            text: "{.describeChangelog()}"
            padding: 30 40 40 40
            color: #999
            font: 13
            maxChar: 300
        }
    }
}
