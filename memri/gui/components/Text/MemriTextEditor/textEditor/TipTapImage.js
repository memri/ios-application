import { Node } from 'tiptap';
import { nodeInputRule } from 'tiptap-commands';
import TipTapImageComponent from './TipTapImageComponent';
const IMAGE_INPUT_REGEX = /!\[(.+|:?)]\((\S+)(?:(?:\s+)["'](\S+)["'])?\)/;
export default class CustomImage extends Node {
    get name() {
        return 'image'
    }

    get schema() {
        return {
            inline: false,
            group: 'block',
            attrs: {
                src: {},
                alt: {
                    default: null,
                },
                title: {
                    default: null,
                },
                width: {
                    default: "auto",
                },
                height: {
                    default: "auto"
                }
            },
            draggable: true,
            parseDOM: [
                {
                    tag: 'img[src]',
                    getAttrs: dom => ({
                        src: dom.getAttribute('src'),
                        title: dom.getAttribute('title'),
                        alt: dom.getAttribute('alt'),
                        height: dom.getAttribute('height'),
                        width: dom.getAttribute('width') || 300
                    }),
                },
            ],
            toDOM: (node) => {
                return ['img', {
                    src: node.attrs.src,
                    height: node.attrs.height,
                    width: node.attrs.width,
                    alt: node.attrs.alt,
                    title: node.attrs.title
                }, 0];
            },
        }
    }
    commands({ type }) {
        return attrs => (state, dispatch) => {
            const { selection } = state;
            const position = selection.$cursor ? selection.$cursor.pos : selection.$to.pos;
            const node = type.create(attrs);
            const transaction = state.tr.insert(position, node);
            dispatch(transaction);
        }
    }

    inputRules(context) {
        const { type } = context;
        return [
            nodeInputRule(IMAGE_INPUT_REGEX, type, match => {
                const [, alt, src, title, height, width] = match;
                return {
                    src,
                    alt,
                    title,
                    height,
                    width
                }
            }),
        ];
    }

    get view() {
        return TipTapImageComponent;
    }
}