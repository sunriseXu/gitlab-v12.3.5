import Vue from 'vue';
import { shallowMount, mount } from '@vue/test-utils';
import StageTable from 'ee/analytics/cycle_analytics/components/stage_table.vue';
import { issueEvents, issueStage, allowedStages } from '../mock_data';

let wrapper = null;
const $sel = {
  nav: '.stage-nav',
  navItems: '.stage-nav-item',
  eventList: '.stage-events',
  events: '.stage-event-item',
  description: '.events-description',
  headers: '.col-headers li',
  headersList: '.col-headers',
  illustration: '.empty-state .svg-content',
};

const headers = ['Stage', 'Median', issueStage.legend, 'Total Time'];
const noDataSvgPath = 'path/to/no/data';
const noAccessSvgPath = 'path/to/no/access';

function createComponent(props = {}, shallow = false) {
  const func = shallow ? shallowMount : mount;
  return func(StageTable, {
    propsData: {
      stages: allowedStages,
      currentStage: issueStage,
      events: issueEvents,
      isLoadingStage: false,
      isEmptyStage: false,
      isUserAllowed: true,
      isAddingCustomStage: false,
      noDataSvgPath,
      noAccessSvgPath,
      canEditStages: false,
      ...props,
    },
    stubs: {
      'gl-loading-icon': true,
    },
    sync: false,
  });
}

describe('StageTable', () => {
  describe('headers', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    afterEach(() => {
      wrapper.destroy();
    });
    it('will render the headers', () => {
      const renderedHeaders = wrapper.findAll($sel.headers);
      expect(renderedHeaders.length).toEqual(headers.length);

      const headerText = wrapper.find($sel.headersList).text();
      headers.forEach(title => {
        expect(headerText).toContain(title);
      });
    });
  });

  describe('is loaded with data', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('will render the events list', () => {
      expect(wrapper.find($sel.eventList).exists()).toBeTruthy();
    });

    it('will render the correct stages', () => {
      const evs = wrapper.findAll({ name: 'StageNavItem' });
      expect(evs.length).toEqual(allowedStages.length);

      const nav = wrapper.find($sel.nav).html();
      allowedStages.forEach(stage => {
        expect(nav).toContain(stage.title);
      });
    });

    it('will render the current stage', () => {
      expect(wrapper.find($sel.description).exists()).toBeTruthy();
      expect(wrapper.find($sel.description).text()).toEqual(issueStage.description);
    });

    it('will render the event list', () => {
      expect(wrapper.find($sel.eventList).exists()).toBeTruthy();
      expect(wrapper.findAll($sel.events).exists()).toBeTruthy();
    });

    it('will render the correct events', () => {
      const evs = wrapper.findAll($sel.events);
      expect(evs.length).toEqual(issueEvents.length);

      const evshtml = wrapper.find($sel.eventList).html();
      issueEvents.forEach(ev => {
        expect(evshtml).toContain(ev.title);
      });
    });

    function selectStage(index) {
      wrapper
        .findAll($sel.navItems)
        .at(index)
        .trigger('click');
    }

    describe('when a stage is clicked', () => {
      it('will emit `selectStage`', done => {
        expect(wrapper.emitted('selectStage')).toBeUndefined();

        selectStage(1);

        Vue.nextTick()
          .then(() => {
            expect(wrapper.emitted().selectStage.length).toEqual(1);
          })
          .then(done)
          .catch(done.fail);
      });

      it('will emit `selectStage` with the new stage title', done => {
        const secondStage = allowedStages[1];

        selectStage(1);

        Vue.nextTick()
          .then(() => {
            const [params] = wrapper.emitted('selectStage')[0];
            expect(params).toMatchObject({ title: secondStage.title });
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  it('isLoadingStage = true', () => {
    wrapper = createComponent({ isLoadingStage: true }, true);
    expect(wrapper.find('gl-loading-icon-stub').exists()).toEqual(true);
  });

  describe('isEmptyStage = true', () => {
    beforeEach(() => {
      wrapper = createComponent({ isEmptyStage: true });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('will render the empty stage illustration', () => {
      expect(wrapper.find($sel.illustration).exists()).toBeTruthy();
      expect(wrapper.find($sel.illustration).html()).toContain(noDataSvgPath);
    });

    it('will display the no data title', () => {
      expect(wrapper.html()).toContain("We don't have enough data to show this stage.");
    });

    it('will display the no data description', () => {
      expect(wrapper.html()).toContain(
        'The issue stage shows the time it takes from creating an issue to assigning the issue to a milestone, or add the issue to a list on your Issue Board. Begin creating issues to see data for this stage.',
      );
    });
  });

  describe('isUserAllowed = false', () => {
    beforeEach(() => {
      wrapper = createComponent({
        currentStage: {
          ...issueStage,
          isUserAllowed: false,
        },
      });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('will render the no access illustration', () => {
      expect(wrapper.find($sel.illustration).exists()).toBeTruthy();
      expect(wrapper.find($sel.illustration).html()).toContain(noAccessSvgPath);
    });

    it('will display the no access title', () => {
      expect(wrapper.html()).toContain('You need permission.');
    });

    it('will display the no access description', () => {
      expect(wrapper.html()).toContain(
        'Want to see the data? Please ask an administrator for access.',
      );
    });
  });

  describe('canEditStages = true', () => {
    beforeEach(() => {
      wrapper = createComponent({
        canEditStages: true,
      });
    });

    afterEach(() => {
      wrapper.destroy();
    });
    it('will render the add a stage button', () => {
      expect(wrapper.html()).toContain('Add a stage');
    });
  });
});
