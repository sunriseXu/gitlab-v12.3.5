import Vue from 'vue';
import { mapActions } from 'vuex';

import { parseBoolean } from '~/lib/utils/common_utils';

import createStore from './store';

import RelatedItemsTreeApp from './components/related_items_tree_app.vue';
import TreeRoot from './components/tree_root.vue';
import TreeItem from './components/tree_item.vue';

export default () => {
  const el = document.getElementById('js-tree');

  if (!el) {
    return false;
  }

  const { id, iid, fullPath, autoCompleteEpics, autoCompleteIssues } = el.dataset;
  const initialData = JSON.parse(el.dataset.initial);

  Vue.component('tree-root', TreeRoot);
  Vue.component('tree-item', TreeItem);

  return new Vue({
    el,
    store: createStore(),
    components: { RelatedItemsTreeApp },
    created() {
      this.setInitialParentItem({
        fullPath,
        id,
        iid: Number(iid),
        title: initialData.initialTitleText,
        reference: `${initialData.fullPath}${initialData.issuableRef}`,
        userPermissions: {
          adminEpic: initialData.canAdmin,
          createEpic: initialData.canUpdate,
        },
      });

      this.setInitialConfig({
        epicsEndpoint: initialData.epicLinksEndpoint,
        issuesEndpoint: initialData.issueLinksEndpoint,
        autoCompleteEpics: parseBoolean(autoCompleteEpics),
        autoCompleteIssues: parseBoolean(autoCompleteIssues),
      });
    },
    methods: {
      ...mapActions(['setInitialParentItem', 'setInitialConfig']),
    },
    render: createElement => createElement('related-items-tree-app'),
  });
};
