<style>
@import "./editor.css";
@import "./codeBlockHighlight.css";
</style>


<template>
  <editor-content id="container" :editor="editor" />
</template>

        
<script>
import { Editor, EditorContent } from "tiptap";

import {
  Blockquote,
  Heading,
  ListItem,
  HardBreak,
  TodoList,
  Bold,
  Code,
  Italic,
  Link,
  Strike,
  Underline,
  Search,
  Placeholder,
  TrailingNode,
  History,
} from "tiptap-extensions";

import Document from "./Extensions/Document";
import DocumentTitle from "./Extensions/DocumentTitle";
import ExtraCommands from "./Extensions/ExtraCommands";
import CodeBlock from "./Extensions/CodeBlock";
import OrderedList from "./Extensions/OrderedList";
import BulletList from "./Extensions/BulletList";
import TodoItem from "./Extensions/TodoItem";
import TextColor from "./Extensions/TextColor";
import TextHighlight from "./Extensions/TextHighlight";
import Image from "./Extensions/Image";
import NativeUndo from "./Extensions/NativeUndo";
import { currentMarkAttribs } from "./Extensions/MarkFunctions";

// Highlight.js imports
import javascript from "highlight.js/lib/languages/javascript";
import css from "highlight.js/lib/languages/css";
import swift from "highlight.js/lib/languages/swift";
import rust from "highlight.js/lib/languages/rust";
import python from "highlight.js/lib/languages/python";

// Enable smooth scrolling on safari iOS
import { scrollIntoView } from "./Extensions/ScrollIntoView";
window.scrollToSelection = () => {
  scrollIntoView(window.getSelection());
};

window.editor = new Editor({
  extensions: [
    new Document(),
    new DocumentTitle(),
    new ExtraCommands(),
    new Blockquote(),
    new BulletList(),
    new CodeBlock({
      languages: {
        javascript,
        css,
        swift,
        rust,
        python,
      },
    }),
    new HardBreak(),
    new Heading({ levels: [1, 2, 3, 4] }),
    new ListItem(),
    new OrderedList(),
    new TodoItem({
      nested: true,
    }),
    new TodoList(),
    new Link(),
    new Bold(),
    new Code(),
    new Italic(),
    new Strike(),
    new Underline(),
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
    new TextColor(),
    new TextHighlight(),
    new Image(),
    new History({
      newGroupDelay: 500,
    }),
    new NativeUndo(),
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
        heading: isActive.heading({ level: 1 })
          ? 1
          : isActive.heading({ level: 2 })
          ? 2
          : isActive.heading({ level: 3 })
          ? 3
          : isActive.heading({ level: 4 })
          ? 4
          : 0,
        todo_list: isActive.todo_list(),
        ordered_list: isActive.ordered_list(),
        bullet_list: isActive.bullet_list(),
        sink_list: window.editor.commands.can_sink_list(),
        lift_list: window.editor.commands.can_lift_list(),
        code_block: isActive.code_block(),
        blockquote: isActive.blockquote(),
        text_color: currentMarkAttribs("text_color")?.color,
        highlight_color: currentMarkAttribs("highlight_color")?.backColor,
        selected_image: window.editor.state.selection?.node?.attrs?.src,
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