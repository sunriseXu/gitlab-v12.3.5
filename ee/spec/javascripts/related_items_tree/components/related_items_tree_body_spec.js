import { shallowMount, createLocalVue } from '@vue/test-utils';

import RelatedItemsBody from 'ee/related_items_tree/components/related_items_tree_body.vue';

import { mockParentItem } from '../mock_data';

const createComponent = (parentItem = mockParentItem, children = []) => {
  const localVue = createLocalVue();

  return shallowMount(RelatedItemsBody, {
    localVue,
    stubs: {
      'tree-root': true,
    },
    propsData: {
      parentItem,
      children,
    },
  });
};

describe('RelatedItemsTree', () => {
  describe('RelatedTreeBody', () => {
    let wrapper;

    beforeEach(() => {
      wrapper = createComponent();
    });

    afterEach(() => {
      wrapper.destroy();
    });

    describe('template', () => {
      it('renders component container element with class `related-items-tree-body`', () => {
        expect(wrapper.vm.$el.classList.contains('related-items-tree-body')).toBe(true);
      });

      it('renders tree-root component', () => {
        expect(wrapper.find('tree-root-stub').isVisible()).toBe(true);
      });
    });
  });
});
