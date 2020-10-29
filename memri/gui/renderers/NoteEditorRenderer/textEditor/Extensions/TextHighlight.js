import { Mark } from 'tiptap';
import { toggleMark } from './MarkFunctions'


export default class TextHighlight extends Mark {
    get name() {
        return 'highlight_color';
    }

    get schema() {
        return {
            attrs: {
                backColor: '',
            },
            inline: true,
            group: 'inline',
            parseDOM: [{
                style: 'background',
                getAttrs: value => ({
                    backColor: value
                }),
            }],
            toDOM(node) {
                const { backColor } = node.attrs;
                let style = '';
                if (backColor) {
                    style += `background: ${backColor};`;
                }
                return ['span', { style }, 0];
            },
        };
    }

    commands({ type }) {
        return (attribs) => toggleMark(type, attribs)
    }
}