import { Doc } from 'tiptap'

export default class Document extends Doc {

    get schema() {
        return {
            content: 'title block+',
        }
    }

}