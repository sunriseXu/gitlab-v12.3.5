import { createLocalVue, shallowMount } from '@vue/test-utils';
import MetricColumn from 'ee/analytics/productivity_analytics/components/metric_column.vue';

describe('MetricColumn component', () => {
  let wrapper;

  const defaultProps = {
    type: 'time_to_last_commit',
    value: 10,
    label: 'Time from first comment to last commit',
  };

  const factory = (props = defaultProps) => {
    const localVue = createLocalVue();

    wrapper = shallowMount(localVue.extend(MetricColumn), {
      localVue,
      sync: false,
      propsData: { ...props },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findTimeContainer = () => wrapper.find('.time');

  describe('on creation', () => {
    beforeEach(() => {
      factory();
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('template', () => {
    describe('when metric has value', () => {
      beforeEach(() => {
        factory();
      });

      it('renders the value and unit', () => {
        const unit = 'hrs';
        expect(findTimeContainer().text()).toContain(`${defaultProps.value}`);
        expect(findTimeContainer().text()).toContain(unit);
      });
    });

    describe('when metric has no value', () => {
      beforeEach(() => {
        factory({
          ...defaultProps,
          value: null,
        });
      });

      it('renders a dash', () => {
        expect(findTimeContainer().text()).toContain('–');
      });
    });
  });

  describe('computed', () => {
    describe('isNumericValue', () => {
      it('returns true when the value is neither null nor undefined', () => {
        factory();
        expect(wrapper.vm.isNumericValue).toBe(true);
      });

      it('returns false when the value is null', () => {
        factory({
          ...defaultProps,
          value: null,
        });
        expect(wrapper.vm.isNumericValue).toBe(false);
      });
    });

    describe('unit', () => {
      it('returns "days" for the "days_to_merge" metric', () => {
        factory({
          ...defaultProps,
          type: 'days_to_merge',
        });

        expect(wrapper.vm.unit).toBe('days');
      });

      it('returns "hrs" for the any other metric', () => {
        factory({
          ...defaultProps,
        });

        expect(wrapper.vm.unit).toBe('hrs');
      });
    });
  });
});
