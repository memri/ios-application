import { Node } from 'tiptap'
import { wrappingInputRule, toggleList, liftListItem, sinkListItem } from 'tiptap-commands'


export default class OrderedList extends Node {

  get name() {
    return 'ordered_list'
  }

  get schema() {
    return {
      attrs: {
        order: {
          default: 1,
        },
      },
      content: 'list_item+',
      group: 'block',
      parseDOM: [
        {
          tag: 'ol',
          getAttrs: dom => ({
            order: dom.hasAttribute('start') ? +dom.getAttribute('start') : 1,
          }),
        },
      ],
      toDOM: node => (node.attrs.order === 1 ? ['ol', 0] : ['ol', { start: node.attrs.order }, 0]),
    }
  }

  commands({ type, schema }) {
    return {
      'ordered_list': () => toggleList(type, schema.nodes.list_item),
      'lift_list': () => liftListItem(schema.nodes.list_item),
      'sink_list': () => sinkListItem(schema.nodes.list_item),
      'can_lift_list': () => (state, _dispatch, view) => liftListItem(schema.nodes.list_item)(state, null, view),
      'can_sink_list': () => (state, _dispatch, view) => sinkListItem(schema.nodes.list_item)(state, null, view)
    }
  }

  keys({ type, schema }) {
    return {
      'Shift-Ctrl-9': toggleList(type, schema.nodes.list_item),
    }
  }

  inputRules({ type }) {
    return [
      wrappingInputRule(
        /^(\d+)(\.|\))\s$/,
        type,
        match => ({ order: +match[1] }),
        (match, node) => node.childCount + node.attrs.order === +match[1],
      ),
    ]
  }

}
