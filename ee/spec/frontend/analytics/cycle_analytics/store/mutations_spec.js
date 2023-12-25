import mutations from 'ee/analytics/cycle_analytics/store/mutations';
import * as types from 'ee/analytics/cycle_analytics/store/mutation_types';
import {
  cycleAnalyticsData,
  rawEvents as events,
  issueEvents as transformedEvents,
  issueStage,
  planStage,
  codeStage,
  stagingStage,
  reviewStage,
  productionStage,
} from '../mock_data';

describe('Cycle analytics mutations', () => {
  it.each`
    mutation                                    | stateKey                 | value
    ${types.REQUEST_STAGE_DATA}                 | ${'isLoadingStage'}      | ${true}
    ${types.RECEIVE_STAGE_DATA_ERROR}           | ${'isEmptyStage'}        | ${true}
    ${types.RECEIVE_STAGE_DATA_ERROR}           | ${'isLoadingStage'}      | ${false}
    ${types.REQUEST_CYCLE_ANALYTICS_DATA}       | ${'isLoading'}           | ${true}
    ${types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR} | ${'isLoading'}           | ${false}
    ${types.SHOW_CUSTOM_STAGE_FORM}             | ${'isAddingCustomStage'} | ${true}
    ${types.HIDE_CUSTOM_STAGE_FORM}             | ${'isAddingCustomStage'} | ${false}
  `('$mutation will set $stateKey=$value', ({ mutation, stateKey, value }) => {
    const state = {};
    mutations[mutation](state);

    expect(state[stateKey]).toBe(value);
  });

  it.each`
    mutation                                   | payload                 | expectedState
    ${types.SET_CYCLE_ANALYTICS_DATA_ENDPOINT} | ${'cool-beans'}         | ${{ endpoints: { cycleAnalyticsData: '/groups/cool-beans/-/cycle_analytics' } }}
    ${types.SET_STAGE_DATA_ENDPOINT}           | ${'rad-stage'}          | ${{ endpoints: { stageData: '/fake/api/events/rad-stage.json' } }}
    ${types.SET_SELECTED_GROUP}                | ${'cool-beans'}         | ${{ selectedGroup: 'cool-beans', selectedProjectIds: [] }}
    ${types.SET_SELECTED_PROJECTS}             | ${[606, 707, 808, 909]} | ${{ selectedProjectIds: [606, 707, 808, 909] }}
    ${types.SET_SELECTED_TIMEFRAME}            | ${60}                   | ${{ dataTimeframe: 60 }}
    ${types.SET_SELECTED_STAGE_NAME}           | ${'first-stage'}        | ${{ selectedStageName: 'first-stage' }}
  `(
    '$mutation with payload $payload will update state with $expectedState',
    ({ mutation, payload, expectedState }) => {
      const state = { endpoints: { cycleAnalyticsData: '/fake/api' } };
      mutations[mutation](state, payload);

      expect(state).toMatchObject(expectedState);
    },
  );

  describe(`${types.RECEIVE_STAGE_DATA_SUCCESS}`, () => {
    it('will set the events state item with the camelCased events', () => {
      const state = {};

      mutations[types.RECEIVE_STAGE_DATA_SUCCESS](state, { events });

      expect(state.events).toEqual(transformedEvents);
      expect(state.isLoadingStage).toBe(false);
      expect(state.isEmptyStage).toBe(false);
    });
  });

  describe(`${types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS}`, () => {
    it('will set isLoading=false', () => {
      const state = {};

      mutations[types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS](state, {
        stats: [],
        summary: [],
        stages: [],
      });

      expect(state.isLoading).toBe(false);
    });

    describe('with data', () => {
      it('will convert the stats object to stages', () => {
        const state = {};

        mutations[types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS](state, cycleAnalyticsData);

        [issueStage, planStage, codeStage, stagingStage, reviewStage, productionStage].forEach(
          stage => {
            expect(state.stages).toContainEqual(stage);
          },
        );
      });

      it('will set the selectedStageName to the name of the first stage', () => {
        const state = {};

        mutations[types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS](state, cycleAnalyticsData);

        expect(state.selectedStageName).toEqual('issue');
      });

      it('will set each summary item with a value of 0 to "-"', () => {
        // { value: '-', title: 'New Issues' }, { value: '-', title: 'Deploys' }

        const state = {};

        mutations[types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS](state, {
          ...cycleAnalyticsData,
          summary: [{ value: 0, title: 'New Issues' }, { value: 0, title: 'Deploys' }],
        });

        expect(state.summary).toEqual([
          { value: '-', title: 'New Issues' },
          { value: '-', title: 'Deploys' },
        ]);
      });
    });
  });
});
