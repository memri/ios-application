function markApplies(doc, ranges, type) {
    for (let i = 0; i < ranges.length; i++) {
        let { $from, $to } = ranges[i]
        let can = $from.depth == 0 ? doc.type.allowsMarkType(type) : false
        doc.nodesBetween($from.pos, $to.pos, node => {
            if (can) return false
            can = node.inlineContent && node.type.allowsMarkType(type)
        })
        if (can) return true
    }
    return false
}

export function toggleMark(markType, attrs) {
    return function (state, dispatch) {
        let { empty, $cursor, ranges } = state.selection
        const shouldOverride = attrs["override"] ?? false
        if ((empty && !$cursor) || !markApplies(state.doc, ranges, markType)) return false
        if (dispatch) {
            if ($cursor) {
                const has = markType.isInSet(state.storedMarks || $cursor.marks())
                if (has && !shouldOverride) {
                    dispatch(state.tr.removeStoredMark(markType))
                } else {
                    state.tr.removeStoredMark(markType)
                    dispatch(state.tr.addStoredMark(markType.create(attrs)))
                }
            } else {
                let has = false, tr = state.tr
                for (let i = 0; !has && i < ranges.length; i++) {
                    let { $from, $to } = ranges[i]
                    has = state.doc.rangeHasMark($from.pos, $to.pos, markType)
                }
                for (let i = 0; i < ranges.length; i++) {
                    let { $from, $to } = ranges[i]
                    if (has) {
                        tr.removeMark($from.pos, $to.pos, markType)
                    }
                    if (!has || (has && shouldOverride)) {
                        tr.addMark($from.pos, $to.pos, markType.create(attrs))
                    }
                }
                dispatch(tr.scrollIntoView())
            }
        }
        return true
    }
}

export function currentMarkAttribs(type) {
    const { from, to } = window.editor.state.selection

    // Check if we've set a mark to type with
    let storedMark = window.editor.state.storedMarks?.find(markItem => markItem.type.name === type)

    if (storedMark) {
        return storedMark.attrs
    }

    // Check for existing marks at selection head
    let selectionHeadMark = window.editor.state.selection.$cursor?.marks().find(markItem => markItem.type.name === type)
    if (selectionHeadMark) {
        return selectionHeadMark.attrs
    }

    // Check for existing marks in nested nodes
    let marks = []
    window.editor.state.doc.nodesBetween(from, to, node => {
        marks = [...marks, ...node.marks]
    })
    const mark = marks.find(markItem => markItem.type.name === type)

    if (mark) {
        return mark.attrs
    }

    return {}
}