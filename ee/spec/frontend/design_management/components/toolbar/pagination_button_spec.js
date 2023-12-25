import { createLocalVue, shallowMount } from '@vue/test-utils';
import VueRouter from 'vue-router';
import PaginationButton from 'ee/design_management/components/toolbar/pagination_button.vue';

const localVue = createLocalVue();
localVue.use(VueRouter);
const router = new VueRouter();

describe('Design management pagination button component', () => {
  let wrapper;

  function createComponent(design = null) {
    wrapper = shallowMount(PaginationButton, {
      sync: false,
      localVue,
      router,
      propsData: {
        design,
        title: 'Test title',
        iconName: 'angle-right',
      },
      stubs: ['router-link'],
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('disables button when no design is passed', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders router-link', () => {
    createComponent({ id: '2' });

    expect(wrapper.element).toMatchSnapshot();
  });

  describe('designLink', () => {
    it('returns empty link when design is null', () => {
      createComponent();

      expect(wrapper.vm.designLink).toEqual({});
    });

    it('returns design link', () => {
      createComponent({ id: '2', filename: 'test' });

      wrapper.vm.$router.replace('/root/test-project/issues/1/designs/test?version=1');

      expect(wrapper.vm.designLink).toEqual({
        name: 'design',
        params: { id: 'test' },
        query: { version: '1' },
      });
    });
  });
});
