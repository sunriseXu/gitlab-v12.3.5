<script>
import QuartersHeaderSubItem from './quarters_header_sub_item.vue';

export default {
  components: {
    QuartersHeaderSubItem,
  },
  props: {
    timeframeIndex: {
      type: Number,
      required: true,
    },
    timeframeItem: {
      type: Object,
      required: true,
    },
    timeframe: {
      type: Array,
      required: true,
    },
    itemWidth: {
      type: Number,
      required: true,
    },
  },
  data() {
    const currentDate = new Date();
    currentDate.setHours(0, 0, 0, 0);

    return {
      currentDate,
    };
  },
  computed: {
    itemStyles() {
      return {
        width: `${this.itemWidth}px`,
      };
    },
    quarterBeginDate() {
      return this.timeframeItem.range[0];
    },
    quarterEndDate() {
      return this.timeframeItem.range[2];
    },
    timelineHeaderLabel() {
      const { quarterSequence } = this.timeframeItem;
      if (quarterSequence === 1 || (this.timeframeIndex === 0 && quarterSequence !== 1)) {
        return `${this.timeframeItem.year} Q${quarterSequence}`;
      }

      return `Q${quarterSequence}`;
    },
    timelineHeaderClass() {
      let headerClass = '';
      if (this.currentDate >= this.quarterBeginDate && this.currentDate <= this.quarterEndDate) {
        headerClass = 'label-dark label-bold';
      } else if (this.currentDate < this.quarterBeginDate) {
        headerClass = 'label-dark';
      }

      return headerClass;
    },
  },
};
</script>

<template>
  <span :style="itemStyles" class="timeline-header-item">
    <div :class="timelineHeaderClass" class="item-label">{{ timelineHeaderLabel }}</div>
    <quarters-header-sub-item :timeframe-item="timeframeItem" :current-date="currentDate" />
  </span>
</template>
