import { shallowMount, mount } from '@vue/test-utils';
import StageEventList from 'ee/analytics/cycle_analytics/components/stage_event_list.vue';

import {
  issueStage,
  issueEvents,
  planStage,
  planEvents,
  reviewStage,
  reviewEvents,
  testStage,
  testEvents,
  stagingStage,
  stagingEvents,
  productionStage,
  productionEvents,
  codeStage,
  codeEvents,
} from '../mock_data';

const generateEvents = n =>
  Array(n)
    .fill(issueEvents[0])
    .map((ev, k) => ({ ...ev, title: `event-${k}`, id: k }));

const mockStubs = {
  'stage-event-item': true,
  'stage-build-item': true,
};

function createComponent({ props = {}, shallow = false, Component = StageEventList, stubs }) {
  const func = shallow ? shallowMount : mount;
  return func(Component, {
    propsData: {
      stage: issueStage,
      events: issueEvents,
      ...props,
    },
    stubs,
  });
}

const $sel = {
  item: '.stage-event-item',
  description: '.events-description',
  title: '.item-title',
  eventsInfo: '.events-info',
};

describe('Stage', () => {
  let wrapper = null;

  describe('With too many events', () => {
    beforeEach(() => {
      wrapper = createComponent({
        props: {
          events: generateEvents(50),
        },
      });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('will render the limit warning', () => {
      const desc = wrapper.find($sel.description);
      expect(desc.find($sel.eventsInfo).exists()).toBe(true);
    });

    it('will render the limit warning message ', () => {
      const desc = wrapper.find($sel.description);
      expect(desc.find($sel.eventsInfo).text()).toContain('Showing 50 events');
    });
  });

  describe('Default stages', () => {
    it.each`
      name            | stage
      ${'Issue'}      | ${issueStage}
      ${'Plan'}       | ${planStage}
      ${'Review'}     | ${reviewStage}
      ${'Test'}       | ${testStage}
      ${'Code'}       | ${codeStage}
      ${'Staging'}    | ${stagingStage}
      ${'Production'} | ${productionStage}
    `('$name stage will render the stage description', ({ stage }) => {
      wrapper = createComponent({ props: { stage, events: [] } });
      expect(wrapper.find($sel.description).text()).toEqual(stage.description);
    });

    it.each`
      name            | stage              | eventList
      ${'Issue'}      | ${issueStage}      | ${issueEvents}
      ${'Plan'}       | ${planStage}       | ${planEvents}
      ${'Review'}     | ${reviewStage}     | ${reviewEvents}
      ${'Code'}       | ${codeStage}       | ${codeEvents}
      ${'Production'} | ${productionStage} | ${productionEvents}
    `('$name stage will render the list of events', ({ stage, eventList }) => {
      wrapper = createComponent({ props: { stage, events: eventList } });
      eventList.forEach((item, index) => {
        const elem = wrapper.findAll($sel.item).at(index);
        expect(elem.find($sel.title).text()).toContain(item.title);
      });
    });

    it.each`
      name            | stage              | eventList
      ${'Issue'}      | ${issueStage}      | ${issueEvents}
      ${'Plan'}       | ${planStage}       | ${planEvents}
      ${'Review'}     | ${reviewStage}     | ${reviewEvents}
      ${'Code'}       | ${codeStage}       | ${codeEvents}
      ${'Production'} | ${productionStage} | ${productionEvents}
    `('$name stage will render the items as StageEventItems', ({ stage, eventList }) => {
      wrapper = createComponent({ props: { events: eventList, stage }, stubs: mockStubs });
      expect(wrapper.find('stage-event-item-stub').exists()).toBe(true);
    });

    it.each`
      name         | stage           | eventList
      ${'Test'}    | ${testStage}    | ${testEvents}
      ${'Staging'} | ${stagingStage} | ${stagingEvents}
    `('$name stage will render the items as StageBuildItems', ({ stage, eventList }) => {
      wrapper = createComponent({ props: { events: eventList, stage }, stubs: mockStubs });
      expect(wrapper.find('stage-build-item-stub').exists()).toBe(true);
    });

    describe('Test stage', () => {
      beforeEach(() => {
        wrapper = createComponent({
          props: { stage: testStage, events: testEvents },
        });
      });

      afterEach(() => {
        wrapper.destroy();
      });
      it('will render the list of events', () => {
        testEvents.forEach((item, index) => {
          const elem = wrapper.findAll($sel.item).at(index);
          expect(elem.find($sel.title).text()).toContain(item.name);
        });
      });
    });

    describe('Staging stage', () => {
      beforeEach(() => {
        wrapper = createComponent({
          props: { stage: stagingStage, events: stagingEvents },
        });
      });

      afterEach(() => {
        wrapper.destroy();
      });
      it('will render the list of events', () => {
        stagingEvents.forEach((item, index) => {
          const elem = wrapper.findAll($sel.item).at(index);
          const title = elem.find($sel.title).text();
          expect(title).toContain(item.id);
          expect(title).toContain(item.branch.name);
          expect(title).toContain(item.shortSha);
        });
      });
    });
  });
});
