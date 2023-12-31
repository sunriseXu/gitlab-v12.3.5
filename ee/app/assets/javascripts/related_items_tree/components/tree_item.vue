<script>
import { mapGetters, mapActions, mapState } from 'vuex';

import { GlTooltipDirective, GlLoadingIcon, GlButton } from '@gitlab/ui';

import { __ } from '~/locale';

import Icon from '~/vue_shared/components/icon.vue';

import TreeItemBody from './tree_item_body.vue';

import { ChildType } from '../constants';

export default {
  ChildType,
  components: {
    Icon,
    TreeItemBody,
    GlLoadingIcon,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    parentItem: {
      type: Object,
      required: true,
    },
    item: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState(['children', 'childrenFlags']),
    ...mapGetters(['anyParentHasChildren']),
    itemReference() {
      return this.item.reference;
    },
    hasChildren() {
      return this.childrenFlags[this.itemReference].itemHasChildren;
    },
    chevronType() {
      return this.childrenFlags[this.itemReference].itemExpanded ? 'chevron-down' : 'chevron-right';
    },
    chevronTooltip() {
      return this.childrenFlags[this.itemReference].itemExpanded ? __('Collapse') : __('Expand');
    },
    childrenFetchInProgress() {
      return (
        this.hasChildren && !this.childrenFlags[this.itemReference].itemChildrenFetchInProgress
      );
    },
    itemExpanded() {
      return this.hasChildren && this.childrenFlags[this.itemReference].itemExpanded;
    },
    hasNoChildren() {
      return (
        this.anyParentHasChildren &&
        !this.hasChildren &&
        !this.childrenFlags[this.itemReference].itemChildrenFetchInProgress
      );
    },
  },
  methods: {
    ...mapActions(['toggleItem']),
    handleChevronClick() {
      this.toggleItem({
        parentItem: this.item,
      });
    },
  },
};
</script>

<template>
  <li
    class="tree-item list-item pt-0 pb-0"
    :class="{
      'has-children': hasChildren,
      'item-expanded': childrenFlags[itemReference].itemExpanded,
      'js-item-type-epic item-type-epic': item.type === $options.ChildType.Epic,
      'js-item-type-issue item-type-issue': item.type === $options.ChildType.Issue,
    }"
  >
    <div class="list-item-body d-flex align-items-center">
      <gl-button
        v-if="childrenFetchInProgress"
        v-gl-tooltip.hover
        :title="chevronTooltip"
        :class="chevronType"
        variant="link"
        class="btn-svg btn-tree-item-chevron"
        @click="handleChevronClick"
      >
        <icon :name="chevronType" />
      </gl-button>
      <gl-loading-icon v-if="childrenFlags[itemReference].itemChildrenFetchInProgress" size="sm" />
      <tree-item-body
        class="tree-item-row"
        :parent-item="parentItem"
        :item="item"
        :class="{
          'tree-item-noexpand': hasNoChildren,
        }"
      />
    </div>
    <tree-root
      v-if="itemExpanded"
      :parent-item="item"
      :children="children[itemReference]"
      class="sub-tree-root"
    />
  </li>
</template>
