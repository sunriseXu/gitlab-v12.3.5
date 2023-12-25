import { mount } from '@vue/test-utils';
import component from 'ee/vue_shared/security_reports/components/dismiss_button.vue';
import LoadingButton from '~/vue_shared/components/loading_button.vue';

describe('DismissalButton', () => {
  let wrapper;

  describe('With a non-dismissed vulnerability', () => {
    beforeEach(() => {
      const propsData = {
        isDismissed: false,
      };
      wrapper = mount(component, { propsData });
    });

    it('should render the dismiss button', () => {
      expect(wrapper.text()).toBe('Dismiss vulnerability');
    });

    it('should emit dismiss vulnerabilty when clicked', () => {
      wrapper.find(LoadingButton).trigger('click');
      expect(wrapper.emitted().dismissVulnerability).toBeTruthy();
    });

    it('should render the dismiss with comment button', () => {
      expect(wrapper.find('.js-dismiss-with-comment').exists()).toBe(true);
    });

    it('should emit openDismissalCommentBox when clicked', () => {
      wrapper.find('.js-dismiss-with-comment').trigger('click');
      expect(wrapper.emitted().openDismissalCommentBox).toBeTruthy();
    });
  });

  describe('with a dismissed vulnerability', () => {
    beforeEach(() => {
      const propsData = {
        isDismissed: true,
      };
      wrapper = mount(component, { propsData });
    });

    it('should render the undo dismiss button', () => {
      expect(wrapper.text()).toBe('Undo dismiss');
    });

    it('should emit revertDismissVulnerabilty when clicked', () => {
      wrapper.find(LoadingButton).trigger('click');
      expect(wrapper.emitted().revertDismissVulnerability).toBeTruthy();
    });

    it('should not render the dismiss with comment button', () => {
      expect(wrapper.find('.js-dismiss-with-comment').exists()).toBe(false);
    });
  });
});
