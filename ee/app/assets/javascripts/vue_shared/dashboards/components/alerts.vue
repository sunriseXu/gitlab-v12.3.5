<script>
import _ from 'underscore';
import { __, n__, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
  },
  props: {
    count: {
      type: Number,
      required: false,
      default: 0,
    },
    lastAlert: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    alertClasses() {
      return {
        'text-tertiary': this.count <= 0,
        'text-warning': this.count > 0,
      };
    },
    alertCount() {
      const text = this.lastAlert ? '%{count} %{alerts}:' : '%{count} %{alerts}';
      return sprintf(__(text), {
        count: this.count,
        alerts: this.pluralizedAlerts,
      });
    },
    pluralizedAlerts() {
      return n__('Alert', 'Alerts', this.count);
    },
    alertText() {
      return sprintf(
        __('%{title} %{operator} %{threshold}'),
        {
          title: _.escape(this.lastAlert.title),
          threshold: `${_.escape(this.lastAlert.threshold)}%`,
          operator: this.lastAlert.operator,
        },
        false,
      );
    },
  },
};
</script>

<template>
  <div class="dashboard-card-alert row">
    <div class="col-12">
      <icon
        :class="alertClasses"
        class="align-text-bottom js-dashboard-alerts-icon"
        name="warning"
      />
      <span class="js-alert-count text-secondary prepend-left-4"> {{ alertCount }} </span>
      <span v-if="lastAlert" class="text-secondary">{{ alertText }}</span>
    </div>
  </div>
</template>
