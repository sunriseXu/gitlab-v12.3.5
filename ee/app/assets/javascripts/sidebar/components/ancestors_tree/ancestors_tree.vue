<script>
import { GlLoadingIcon, GlLink, GlTooltip } from '@gitlab/ui';
import { escape } from 'underscore';

import { __ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'AncestorsTree',
  components: {
    Icon,
    GlLoadingIcon,
    GlLink,
    GlTooltip,
  },
  props: {
    ancestors: {
      type: Array,
      required: true,
      default: () => [],
    },
    isFetching: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    tooltipText() {
      /**
       * Since the list is reveresed, our immediate parent is
       * the last element of the list
       */
      const immediateParent = this.ancestors.slice(-1)[0];

      if (!immediateParent) {
        return __('None');
      }
      // Fallback to None if immediate parent is unavailable.

      let { title } = immediateParent;
      title = escape(title);

      const { humanReadableEndDate, humanReadableTimestamp } = immediateParent;

      if (humanReadableEndDate || humanReadableTimestamp) {
        title += '<br />';
        title += humanReadableEndDate ? `${humanReadableEndDate} ` : '';
        title += humanReadableTimestamp ? `(${humanReadableTimestamp})` : '';
      }

      return title;
    },
  },
  methods: {
    getIcon(ancestor) {
      return ancestor.state === 'opened' ? 'issue-open-m' : 'issue-close';
    },
    getTimelineClass(ancestor) {
      return ancestor.state === 'opened' ? 'opened' : 'closed';
    },
  },
};
</script>

<template>
  <div class="ancestor-tree">
    <div ref="sidebarIcon" class="sidebar-collapsed-icon">
      <div><icon name="epic" /></div>
      <span v-if="!isFetching" class="collapse-truncated-title">{{ tooltipText }}</span>
    </div>

    <gl-tooltip :target="() => $refs.sidebarIcon" placement="left" boundary="viewport">
      <span v-html="tooltipText"></span>
    </gl-tooltip>
    <div class="title hide-collapsed">{{ __('Ancestors') }}</div>

    <ul v-if="!isFetching && ancestors.length" class="vertical-timeline hide-collapsed">
      <li v-for="(ancestor, id) in ancestors" :key="id" class="vertical-timeline-row d-flex">
        <div class="vertical-timeline-icon" :class="getTimelineClass(ancestor)">
          <icon :name="getIcon(ancestor)" />
        </div>
        <div class="vertical-timeline-content">
          <gl-link :href="ancestor.url">{{ ancestor.title }}</gl-link>
        </div>
      </li>
    </ul>

    <div v-if="!isFetching && !ancestors.length" class="value hide-collapsed">
      <span class="no-value">{{ __('None') }}</span>
    </div>

    <gl-loading-icon v-if="isFetching" />
  </div>
</template>
