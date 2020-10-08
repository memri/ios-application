import { Mark } from 'tiptap';
import applyMark from './applyMark';

function hexColorRegex() {
    return /#([a-f0-9]{3}|[a-f0-9]{4}(?:[a-f0-9]{2}){0,2})\b/gi;
}

function isHexColor(color) {
    return hexColorRegex().test(color);
}

export default class TextColor extends Mark {
    get name() {
        return 'text_color';
    }

    get schema() {
        return {
            attrs: {
                color: '',
            },
            inline: true,
            group: 'inline',
            parseDOM: [{
                style: 'color',
                getAttrs: color => {
                    return {
                        color,
                    };
                },
            }],
            toDOM(node) {
                const { color } = node.attrs;
                let style = '';
                if (color) {
                    style += `color: ${color};`;
                }
                return ['span', { style }, 0];
            },
        };
    }

    commands() {
        return (color) => (state, dispatch) => {
            if (color !== undefined) {
                const { schema } = state;
                let { tr } = state;
                const markType = schema.marks.text_color;
                const attrs = color && isHexColor(color) ? { color } : null;
                tr = applyMark(
                    state.tr.setSelection(state.selection),
                    markType,
                    attrs
                );
                if (tr.docChanged || tr.storedMarksSet) {
                    dispatch && dispatch(tr);
                    return true;
                }
            }
            return false;
        };
    }
}