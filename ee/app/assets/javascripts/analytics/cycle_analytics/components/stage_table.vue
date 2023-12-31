<script>
import { __, s__ } from '~/locale';
import { GlTooltipDirective, GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import StageNavItem from './stage_nav_item.vue';
import StageEventList from './stage_event_list.vue';
import StageTableHeader from './stage_table_header.vue';
import AddStageButton from './add_stage_button.vue';
import CustomStageForm from './custom_stage_form.vue';

export default {
  name: 'StageTable',
  components: {
    Icon,
    GlLoadingIcon,
    GlEmptyState,
    StageEventList,
    StageNavItem,
    StageTableHeader,
    AddStageButton,
    CustomStageForm,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    stages: {
      type: Array,
      required: true,
    },
    currentStage: {
      type: Object,
      required: true,
    },
    isLoadingStage: {
      type: Boolean,
      required: true,
    },
    isEmptyStage: {
      type: Boolean,
      required: true,
    },
    isAddingCustomStage: {
      type: Boolean,
      required: true,
    },
    events: {
      type: Array,
      required: true,
    },
    noDataSvgPath: {
      type: String,
      required: true,
    },
    noAccessSvgPath: {
      type: String,
      required: true,
    },
    canEditStages: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    stageName() {
      return this.currentStage ? this.currentStage.legend : __('Related Issues');
    },
    shouldDisplayStage() {
      const { events = [], isLoadingStage, isEmptyStage } = this;
      return events.length && !isLoadingStage && !isEmptyStage;
    },
    stageHeaders() {
      return [
        {
          title: s__('ProjectLifecycle|Stage'),
          description: __('The phase of the development lifecycle.'),
          classes: 'stage-header pl-5',
        },
        {
          title: __('Median'),
          description: __(
            'The value lying at the midpoint of a series of observed values. E.g., between 3, 5, 9, the median is 5. Between 3, 5, 7, 8, the median is (5+7)/2 = 6.',
          ),
          classes: 'median-header',
        },
        {
          title: this.stageName,
          description: __('The collection of events added to the data gathered for that stage.'),
          classes: 'event-header pl-3',
        },
        {
          title: __('Total Time'),
          description: __('The time taken by each data entry gathered by that stage.'),
          classes: 'total-time-header pr-5 text-right',
        },
      ];
    },
  },
  methods: {
    selectStage(stage) {
      this.$emit('selectStage', stage);
    },
    showAddStageForm() {
      this.$emit('showAddStageForm');
    },
  },
};
</script>
<template>
  <div class="stage-panel-container">
    <div class="card stage-panel">
      <div class="card-header border-bottom-0">
        <nav class="col-headers">
          <ul>
            <stage-table-header
              v-for="({ title, description, classes }, i) in stageHeaders"
              :key="`stage-header-${i}`"
              :header-classes="classes"
              :title="title"
              :tooltip-title="description"
            />
          </ul>
        </nav>
      </div>
      <div class="stage-panel-body">
        <nav class="stage-nav">
          <ul>
            <stage-nav-item
              v-for="stage in stages"
              :key="`ca-stage-title-${stage.title}`"
              :title="stage.title"
              :value="stage.value"
              :is-active="!isAddingCustomStage && stage.name === currentStage.name"
              :is-user-allowed="stage.isUserAllowed"
              @select="selectStage(stage)"
            />
            <add-stage-button
              v-if="canEditStages"
              :active="isAddingCustomStage"
              @showform="showAddStageForm"
            />
          </ul>
        </nav>
        <div class="section stage-events">
          <gl-loading-icon v-if="isLoadingStage" class="mt-4" size="md" />
          <gl-empty-state
            v-else-if="currentStage && !currentStage.isUserAllowed"
            :title="__('You need permission.')"
            :description="__('Want to see the data? Please ask an administrator for access.')"
            :svg-path="noAccessSvgPath"
          />
          <custom-stage-form v-else-if="isAddingCustomStage" />
          <template v-else>
            <stage-event-list v-if="shouldDisplayStage" :stage="currentStage" :events="events" />
            <gl-empty-state
              v-if="isEmptyStage"
              :title="__('We don\'t have enough data to show this stage.')"
              :description="currentStage.emptyStageText"
              :svg-path="noDataSvgPath"
            />
          </template>
        </div>
      </div>
    </div>
  </div>
</template>
