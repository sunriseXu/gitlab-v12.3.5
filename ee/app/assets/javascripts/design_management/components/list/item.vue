<script>
import Icon from '~/vue_shared/components/icon.vue';
import Timeago from '~/vue_shared/components/time_ago_tooltip.vue';
import { n__, __ } from '~/locale';

export default {
  components: {
    Icon,
    Timeago,
  },
  props: {
    id: {
      type: [Number, String],
      required: true,
    },
    event: {
      type: String,
      required: true,
    },
    notesCount: {
      type: Number,
      required: true,
    },
    image: {
      type: String,
      required: true,
    },
    name: {
      type: String,
      required: true,
    },
    updatedAt: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    icon() {
      const normalizedEvent = this.event.toLowerCase();
      const icons = {
        creation: {
          name: 'file-addition-solid',
          classes: 'text-success-500',
          tooltip: __('Added in this version'),
        },
        modification: {
          name: 'file-modified-solid',
          classes: 'text-primary-500',
          tooltip: __('Modified in this version'),
        },
        deletion: {
          name: 'file-deletion-solid',
          classes: 'text-danger-500',
          tooltip: __('Deleted in this version'),
        },
      };

      return icons[normalizedEvent] ? icons[normalizedEvent] : {};
    },
    notesLabel() {
      return n__('%d comment', '%d comments', this.notesCount);
    },
  },
};
</script>

<template>
  <router-link
    :to="{
      name: 'design',
      params: { id: name },
      query: $route.query,
    }"
    class="card cursor-pointer text-plain js-design-list-item design-list-item"
  >
    <div class="card-body p-0 d-flex align-items-center overflow-hidden position-relative">
      <div v-if="icon.name" class="design-event position-absolute">
        <span :title="icon.tooltip" :aria-label="icon.tooltip">
          <icon :name="icon.name" :size="18" :css-classes="icon.classes" />
        </span>
      </div>
      <img :src="image" :alt="name" class="block ml-auto mr-auto mw-100 mh-100 design-img" />
    </div>
    <div class="card-footer d-flex w-100">
      <div class="d-flex flex-column str-truncated-100">
        <span class="bold str-truncated-100">{{ name }}</span>
        <span v-if="updatedAt" class="str-truncated-100">
          {{ __('Updated') }} <timeago :time="updatedAt" tooltip-placement="bottom" />
        </span>
      </div>
      <div v-if="notesCount" class="ml-auto d-flex align-items-center text-secondary">
        <icon name="comments" class="ml-1" />
        <span :aria-label="notesLabel" class="ml-1">
          {{ notesCount }}
        </span>
      </div>
    </div>
  </router-link>
</template>
