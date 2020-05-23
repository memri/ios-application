
.all-items-with-label{
    title: "Items with label {name}"
    queryOptions: {
        query: "* AND ANY labels.uid = '{uid}'"
    }
    defaultRenderer: list
    
    [renderer = list]{
        ItemCell {
            rendererNames: [list thumbnail]
            variables: {variables}
        }
    }
}
