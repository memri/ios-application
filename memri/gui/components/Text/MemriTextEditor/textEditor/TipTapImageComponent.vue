<template>
  <div class="tiptap-custom-image-container">
    <vue-draggable-resizable
      :w="width"
      :h="height"
      @resizestop="onResize"
      :draggable="false"
      :handles="['br']"
      :enable-native-drag="true"
      :lock-aspect-ratio="true"
      class-name="resizableElement"
      ref="content"
      contenteditable="false"
    >
      <img :src="src" />
    </vue-draggable-resizable>
  </div>
</template>
<script>
import VueDraggableResizable from "vue-draggable-resizable";
import "vue-draggable-resizable/dist/VueDraggableResizable.css";
export default {
  props: ["node", "updateAttrs", "view", "selected", "getPos", "options"],
  components: {
    "vue-draggable-resizable": VueDraggableResizable,
  },
  computed: {
    src: {
      get() {
        return this.node.attrs.src;
      },
      set(src) {
        this.updateAttrs({ src });
      },
    },
    width: {
      get() {
        return parseInt(this.node.attrs.width);
      },
      set(width) {
        this.updateAttrs({
          width: width,
        });
      },
    },
    height: {
      get() {
        return parseInt(this.node.attrs.height);
      },
      set(height) {
        this.updateAttrs({
          height: height,
        });
      },
    },
  },
  methods: {
    onResize(x, y, width, height) {
      this.width = width;
      this.height = height;
    },
  },
};
</script>