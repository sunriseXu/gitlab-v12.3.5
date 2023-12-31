<script>
import Icon from '../../vue_shared/components/icon.vue';

/**
 * Renders CI icon based on API response shared between all places where it is used.
 *
 * Receives status object containing:
 * status: {
 *   details_path: "/gitlab-org/gitlab-foss/pipelines/8150156" // url
 *   group:"running" // used for CSS class
 *   icon: "icon_status_running" // used to render the icon
 *   label:"running" // used for potential tooltip
 *   text:"running" // text rendered
 * }
 *
 * Used in:
 * - Pipelines table Badge
 * - Pipelines table mini graph
 * - Pipeline graph
 * - Pipeline show view badge
 * - Jobs table
 * - Jobs show view header
 * - Jobs show view sidebar
 * - Linked pipelines
 * - Extended MR Popover
 */
const validSizes = [8, 12, 16, 18, 24, 32, 48, 72];

export default {
  components: {
    Icon,
  },
  props: {
    status: {
      type: Object,
      required: true,
    },
    size: {
      type: Number,
      required: false,
      default: 16,
      validator(value) {
        return validSizes.includes(value);
      },
    },
    borderless: {
      type: Boolean,
      required: false,
      default: false,
    },
    cssClasses: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    cssClass() {
      const status = this.status.group;
      return `ci-status-icon ci-status-icon-${status} js-ci-status-icon-${status}`;
    },
    icon() {
      return this.borderless ? `${this.status.icon}_borderless` : this.status.icon;
    },
  },
};
</script>
<template>
  <span :class="cssClass"> <icon :name="icon" :size="size" :css-classes="cssClasses" /> </span>
</template>
