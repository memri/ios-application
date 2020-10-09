# Memri iOS App Text editor

This text editor is built using the Vue framework and is based off [TipTap (an open-source prosemirror-based js editor)](https://github.com/ueberdosis/tiptap)

In order to compile it you must install [Vue command line tools](https://cli.vuejs.org/)

**To develop:**
```
vue serve editor.vue
```
The command line will tell you the url to open from your browser. It is best to open this from safari on the target device (eg your phone) as this will best replicate use in the app

**To build:**
```
cd PATHTOTHISFOLDER;
vue build editor.vue --dest textEditorDist
```

The distribution folder is used within the main iOS project, so once you have run the above command you can rebuild the app to include the new version.