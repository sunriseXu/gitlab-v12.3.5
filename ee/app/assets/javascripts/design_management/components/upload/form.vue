<script>
import UploadButton from './button.vue';
import DesignVersionDropdown from './design_version_dropdown.vue';

export default {
  components: {
    UploadButton,
    DesignVersionDropdown,
  },
  props: {
    isSaving: {
      type: Boolean,
      required: true,
    },
    canUploadDesign: {
      type: Boolean,
      required: true,
    },
  },
  methods: {
    onFileUploadChange(files) {
      this.$emit('upload', files);
    },
  },
};
</script>

<template>
  <header class="row-content-block border-top-0 p-2 d-flex">
    <div class="d-flex justify-content-between align-items-center w-100">
      <design-version-dropdown />
      <upload-button v-if="canUploadDesign" :is-saving="isSaving" @upload="onFileUploadChange" />
    </div>
  </header>
</template>
