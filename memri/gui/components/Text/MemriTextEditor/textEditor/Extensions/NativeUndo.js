import { Extension, Plugin } from 'tiptap'
import { undo, redo } from 'prosemirror-history'

function beforeinputHandler(event, view) {
    switch (event.inputType) {
        case 'historyUndo':
            event.preventDefault()
            undo(view.state, view.dispatch)
            return true
        case 'historyRedo':
            event.preventDefault()
            redo(view.state, view.dispatch)
            return true
    }
    return false
}

export default class NativeUndo extends Extension {

    get name() {
        return 'nativeUndo'
    }

    get plugins() {
        return [
            new Plugin({
                view(view) {
                    view.dom.addEventListener('beforeinput', event => {
                        beforeinputHandler(event, view)
                    })
                    return {
                        update: () => { },
                        destroy: () => { }
                    }
                },
                props: {
                    handleDOMEvents: {
                        beforeinput(view, event) {
                            beforeinputHandler(event, view)
                        },
                    }
                },
            }),
        ]
    }

}