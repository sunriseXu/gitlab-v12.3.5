<script>
import { monthInWords } from '~/lib/utils/datetime_utility';

import WeeksHeaderSubItem from './weeks_header_sub_item.vue';

export default {
  components: {
    WeeksHeaderSubItem,
  },
  props: {
    timeframeIndex: {
      type: Number,
      required: true,
    },
    timeframeItem: {
      type: Date,
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
    lastDayOfCurrentWeek() {
      const lastDayOfCurrentWeek = new Date(this.timeframeItem.getTime());
      lastDayOfCurrentWeek.setDate(lastDayOfCurrentWeek.getDate() + 7);

      return lastDayOfCurrentWeek;
    },
    timelineHeaderLabel() {
      const timeframeItemMonth = this.timeframeItem.getMonth();
      const timeframeItemDate = this.timeframeItem.getDate();

      if (this.timeframeIndex === 0 || (timeframeItemMonth === 0 && timeframeItemDate <= 7)) {
        return `${this.timeframeItem.getFullYear()} ${monthInWords(
          this.timeframeItem,
          true,
        )} ${timeframeItemDate}`;
      }

      return `${monthInWords(this.timeframeItem, true)} ${timeframeItemDate}`;
    },
    timelineHeaderClass() {
      const currentDateTime = this.currentDate.getTime();
      const lastDayOfCurrentWeekTime = this.lastDayOfCurrentWeek.getTime();

      if (
        currentDateTime >= this.timeframeItem.getTime() &&
        currentDateTime <= lastDayOfCurrentWeekTime
      ) {
        return 'label-dark label-bold';
      } else if (currentDateTime < lastDayOfCurrentWeekTime) {
        return 'label-dark';
      }
      return '';
    },
  },
};
</script>

<template>
  <span :style="itemStyles" class="timeline-header-item">
    <div :class="timelineHeaderClass" class="item-label">{{ timelineHeaderLabel }}</div>
    <weeks-header-sub-item :timeframe-item="timeframeItem" :current-date="currentDate" />
  </span>
</template>
