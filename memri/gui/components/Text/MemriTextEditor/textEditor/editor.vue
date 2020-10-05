<style>
@import "./editor.css";
@import "./codehighlight.css";
</style>


<template>
  <editor-content id="container" :editor="editor" />
</template>

        
<script>
import { Editor, EditorContent } from "tiptap";
import Doc from "./customDoc";
import Title from "./title";

import CodeBlockHighlight from "./codeBlockHighlight";
import TipTapCustomImage from "./TipTapImage";
import OrderedList from "./OrderedList";
import BulletList from "./BulletList";
import TodoItem from "./TodoItem";

import {
  Blockquote,
  Heading,
  ListItem,
  HardBreak,
  TodoList,
  Bold,
  Code,
  Italic,
  // Link,
  Strike,
  Underline,
  History,
  Search,
  Placeholder,
  TrailingNode,
} from "tiptap-extensions";

// Highlight.js imports
import javascript from "highlight.js/lib/languages/javascript";
import css from "highlight.js/lib/languages/css";
import swift from "highlight.js/lib/languages/swift";
import rust from "highlight.js/lib/languages/rust";
import python from "highlight.js/lib/languages/python";

window.editor = new Editor({
  extensions: [
    new Doc(),
    new Title(),
    new Blockquote(),
    new BulletList(),
    new CodeBlockHighlight({
      languages: {
        javascript,
        css,
        swift,
        rust,
        python,
      },
    }),
    new HardBreak(),
    new Heading({ levels: [1, 2, 3] }),
    new ListItem(),
    new OrderedList(),
    new TodoItem({
      nested: true,
    }),
    new TodoList(),
    // new Link(),
    new Bold(),
    new Code(),
    new Italic(),
    new Strike(),
    new Underline(),
    new History(),
    new Search(),
    new Placeholder({
      showOnlyCurrent: false,
      emptyNodeText: (node) => {
        if (node.type.name === "title") {
          return "Untitled";
        }
        return "Write something here...";
      },
    }),
    new TrailingNode({
      node: "paragraph",
      notAfter: ["paragraph"],
    }),
    new TipTapCustomImage(),
  ],
  autoFocus: true,
  onTransaction: () => {
    var isActive = window.editor.isActive;

    try {
      var format = {
        bold: isActive.bold(),
        italic: isActive.italic(),
        underline: isActive.underline(),
        strike: isActive.strike(),
        heading: isActive.heading(),
        todo_list: isActive.todo_list(),
        ordered_list: isActive.ordered_list(),
        bullet_list: isActive.bullet_list(),
        sink_list: window.editor.commands.can_sink_list(),
        lift_list: window.editor.commands.can_lift_list(),
        code_block: isActive.code_block(),
        blockquote: isActive.blockquote(),
      };
    } catch (err) {
      console.log(err);
    }
    try {
      window.webkit.messageHandlers.formatChange.postMessage({
        format: format,
      });
    } catch {
      console.log("Couldn't send format change event to WebKit");
      console.log(format);
    }
  },
  onUpdate: (data) => {
    let html = data.getHTML();
    try {
      window.webkit.messageHandlers.textChange.postMessage({
        html: html,
      });
    } catch {
      console.log("Couldn't send textChange event to WebKit");
      console.log(html);
    }
  },
});

export default {
  name: "TextEditor",
  components: {
    EditorContent,
  },
  data() {
    return {
      editor: window.editor,
    };
  },
  beforeDestroy() {
    this.editor.destroy();
  },
};
</script>