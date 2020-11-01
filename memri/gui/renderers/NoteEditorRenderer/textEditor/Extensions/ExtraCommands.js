import { Extension } from 'tiptap'

export default class ExtraCommands extends Extension {

    get name() {
        return 'extraCommands'
    }

    commands() {
        return {
            deleteSelection: () => {
                this.editor.dispatchTransaction(this.editor.state.tr.deleteSelection());
            }
        };
    }
}