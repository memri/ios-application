
.filter-starred {
    title: "Starred {cascadingView.title}"
    fromTemplate: {{view}},
    queryOptions: {
        query: "{cascadingView.queryOptions.query} AND starred = true"
    }
}
