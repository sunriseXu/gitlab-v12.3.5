<script>
import Design from './item.vue';

export default {
  components: {
    Design,
  },
  props: {
    designs: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <ol class="list-unstyled row">
    <li v-for="design in designs" :key="design.id" class="col-md-6 col-lg-4 mb-3">
      <design
        :id="design.id"
        :event="design.event"
        :notes-count="design.notesCount"
        :image="design.image"
        :name="design.filename"
        :updated-at="design.updatedAt"
      />
    </li>
  </ol>
</template>
