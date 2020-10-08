import { Node } from 'tiptap'

export default class Title extends Node {

    get name() {
        return 'title'
    }

    get schema() {
        return {
            content: 'inline*',
            parseDOM: [{
                tag: 'h1[id="title"]',
            }],
            toDOM: () => ['h1', { id: "title" }, 0],
        }
    }

}