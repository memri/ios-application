# Memri iOS App Text editor

This text editor is built using the Vue framework and based off [TipTap / Prosemirror](https://github.com/ueberdosis/tiptap)

In order to compile changes to the source code you must install [Vue command line tools](https://cli.vuejs.org/)

## Testing outside of app:
```
vue serve editor.vue
```
The command line will tell you the url to open from your browser. It is best to open this from safari on the target device (eg your phone) as this will best replicate use in the app

## Building for use in the app:
```
vue build editor.vue --dest textEditorDist
```

The output folder (textEditorDist) is directly referenced by the iOS  Xcode project. This means that **once you have run the above command you can rebuild the app to include the new version**.

## Note format
Notes are stored in **html** format.
- Text content is held in `<p>` tags. Line breaks `<br>` are also supported within a paragraph.
- Text formatting uses the following tags: Bold `<strong>`, Italic `<em>`, Underline `<u>`, Strikethrough `<s>`.
- Other text formatting (color, highlight) is applied using the style attribute of a `<span>` tag.
- Lists items use the `<li>` tag and are held within either `<ol>` (ordered) or `<ul>` (unordered) nodes.
- Todo items are `<li data-type="todo_item">` tags within an `<ul data-type="todo_list">` and store their completion status as a boolean in the `data-done` attribute.
- Web links use `<a>` tags.
- Images are referenced as `<img>` tags. Note that the src attribute is a custom url scheme that the app fulfills with the appropriate data.


## Project structure
- `editor.vue`
    - this creates an editor object in js and assigns it to `window.editor` so that it can be directly accessed from our iOS code.
    - It imports the plugins that are used to add support for various nodes to the editor (eg. lists, headings, etc) as well as marks (eg. text color, text highlighting)
- `index.html`
    - This file provides Vue with a template for the page html
- `editor.css`
    - This file provides styles for the editor contents. It is designed to support light & dark mode on iOS
- `Extensions`
    - This directory contains all of the custom code and plugins used in our editor (those that aren't provided by TipTap by default)