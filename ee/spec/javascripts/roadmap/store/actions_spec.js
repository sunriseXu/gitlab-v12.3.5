import MockAdapter from 'axios-mock-adapter';

import * as actions from 'ee/roadmap/store/actions';
import * as types from 'ee/roadmap/store/mutation_types';

import defaultState from 'ee/roadmap/store/state';
import { getTimeframeForMonthsView } from 'ee/roadmap/utils/roadmap_utils';
import { formatEpicDetails } from 'ee/roadmap/utils/epic_utils';
import { PRESET_TYPES, EXTEND_AS } from 'ee/roadmap/constants';

import axios from '~/lib/utils/axios_utils';
import testAction from 'spec/helpers/vuex_action_helper';

import {
  mockGroupId,
  basePath,
  epicsPath,
  mockTimeframeInitialDate,
  mockTimeframeMonthsPrepend,
  mockTimeframeMonthsAppend,
  rawEpics,
  mockRawEpic,
  mockFormattedEpic,
  mockSortedBy,
} from '../mock_data';

const mockTimeframeMonths = getTimeframeForMonthsView(mockTimeframeInitialDate);

describe('Roadmap Vuex Actions', () => {
  const timeframeStartDate = mockTimeframeMonths[0];
  const timeframeEndDate = mockTimeframeMonths[mockTimeframeMonths.length - 1];
  let state;

  beforeEach(() => {
    state = Object.assign({}, defaultState(), {
      groupId: mockGroupId,
      timeframe: mockTimeframeMonths,
      presetType: PRESET_TYPES.MONTHS,
      sortedBy: mockSortedBy,
      initialEpicsPath: epicsPath,
      filterQueryString: '',
      basePath,
      timeframeStartDate,
      timeframeEndDate,
    });
  });

  describe('setInitialData', () => {
    it('Should set initial roadmap props', done => {
      const mockRoadmap = {
        foo: 'bar',
        bar: 'baz',
      };

      testAction(
        actions.setInitialData,
        mockRoadmap,
        {},
        [{ type: types.SET_INITIAL_DATA, payload: mockRoadmap }],
        [],
        done,
      );
    });
  });

  describe('setWindowResizeInProgress', () => {
    it('Should set value of `state.windowResizeInProgress` based on provided value', done => {
      testAction(
        actions.setWindowResizeInProgress,
        true,
        state,
        [{ type: types.SET_WINDOW_RESIZE_IN_PROGRESS, payload: true }],
        [],
        done,
      );
    });
  });

  describe('requestEpics', () => {
    it('Should set `epicsFetchInProgress` to true', done => {
      testAction(actions.requestEpics, {}, state, [{ type: 'REQUEST_EPICS' }], [], done);
    });
  });

  describe('requestEpicsForTimeframe', () => {
    it('Should set `epicsFetchForTimeframeInProgress` to true', done => {
      testAction(
        actions.requestEpicsForTimeframe,
        {},
        state,
        [{ type: types.REQUEST_EPICS_FOR_TIMEFRAME }],
        [],
        done,
      );
    });
  });

  describe('receiveEpicsSuccess', () => {
    it('Should set formatted epics array and epicId to IDs array in state based on provided epics list', done => {
      testAction(
        actions.receiveEpicsSuccess,
        {
          rawEpics: [
            Object.assign({}, mockRawEpic, {
              start_date: '2017-12-31',
              end_date: '2018-2-15',
            }),
          ],
        },
        state,
        [
          { type: types.UPDATE_EPIC_IDS, payload: mockRawEpic.id },
          {
            type: types.RECEIVE_EPICS_SUCCESS,
            payload: [
              Object.assign({}, mockFormattedEpic, {
                startDateOutOfRange: false,
                endDateOutOfRange: false,
                startDate: new Date(2017, 11, 31),
                originalStartDate: new Date(2017, 11, 31),
                endDate: new Date(2018, 1, 15),
                originalEndDate: new Date(2018, 1, 15),
              }),
            ],
          },
        ],
        [],
        done,
      );
    });

    it('Should set formatted epics array and epicId to IDs array in state based on provided epics list when timeframe was extended', done => {
      testAction(
        actions.receiveEpicsSuccess,
        { rawEpics: [mockRawEpic], newEpic: true, timeframeExtended: true },
        state,
        [
          { type: types.UPDATE_EPIC_IDS, payload: mockRawEpic.id },
          {
            type: types.RECEIVE_EPICS_FOR_TIMEFRAME_SUCCESS,
            payload: [Object.assign({}, mockFormattedEpic, { newEpic: true })],
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveEpicsFailure', () => {
    beforeEach(() => {
      setFixtures('<div class="flash-container"></div>');
    });

    it('Should set epicsFetchInProgress, epicsFetchForTimeframeInProgress to false and epicsFetchFailure to true', done => {
      testAction(
        actions.receiveEpicsFailure,
        {},
        state,
        [{ type: types.RECEIVE_EPICS_FAILURE }],
        [],
        done,
      );
    });

    it('Should show flash error', () => {
      actions.receiveEpicsFailure({ commit: () => {} });

      expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
        'Something went wrong while fetching epics',
      );
    });
  });

  describe('fetchEpics', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      it('Should dispatch requestEpics and receiveEpicsSuccess when request is successful', done => {
        mock.onGet(epicsPath).replyOnce(200, rawEpics);

        testAction(
          actions.fetchEpics,
          null,
          state,
          [],
          [
            {
              type: 'requestEpics',
            },
            {
              type: 'receiveEpicsSuccess',
              payload: { rawEpics },
            },
          ],
          done,
        );
      });
    });

    describe('failure', () => {
      it('Should dispatch requestEpics and receiveEpicsFailure when request fails', done => {
        mock.onGet(epicsPath).replyOnce(500, {});

        testAction(
          actions.fetchEpics,
          null,
          state,
          [],
          [
            {
              type: 'requestEpics',
            },
            {
              type: 'receiveEpicsFailure',
            },
          ],
          done,
        );
      });
    });
  });

  describe('fetchEpicsForTimeframe', () => {
    const mockEpicsPath =
      '/groups/gitlab-org/-/epics.json?state=&start_date=2017-11-1&end_date=2018-6-30';
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      it('Should dispatch requestEpicsForTimeframe and receiveEpicsSuccess when request is successful', done => {
        mock.onGet(mockEpicsPath).replyOnce(200, rawEpics);

        testAction(
          actions.fetchEpicsForTimeframe,
          { timeframe: mockTimeframeMonths },
          state,
          [],
          [
            {
              type: 'requestEpicsForTimeframe',
            },
            {
              type: 'receiveEpicsSuccess',
              payload: { rawEpics, newEpic: true, timeframeExtended: true },
            },
          ],
          done,
        );
      });
    });

    describe('failure', () => {
      it('Should dispatch requestEpicsForTimeframe and requestEpicsFailure when request fails', done => {
        mock.onGet(mockEpicsPath).replyOnce(500, {});

        testAction(
          actions.fetchEpicsForTimeframe,
          { timeframe: mockTimeframeMonths },
          state,
          [],
          [
            {
              type: 'requestEpicsForTimeframe',
            },
            {
              type: 'receiveEpicsFailure',
            },
          ],
          done,
        );
      });
    });
  });

  describe('extendTimeframe', () => {
    it('Should prepend to timeframe when called with extend type prepend', done => {
      testAction(
        actions.extendTimeframe,
        { extendAs: EXTEND_AS.PREPEND },
        state,
        [{ type: types.PREPEND_TIMEFRAME, payload: mockTimeframeMonthsPrepend }],
        [],
        done,
      );
    });

    it('Should append to timeframe when called with extend type append', done => {
      testAction(
        actions.extendTimeframe,
        { extendAs: EXTEND_AS.APPEND },
        state,
        [{ type: types.APPEND_TIMEFRAME, payload: mockTimeframeMonthsAppend }],
        [],
        done,
      );
    });
  });

  describe('refreshEpicDates', () => {
    it('Should update epics after refreshing epic dates to match with updated timeframe', done => {
      const epics = rawEpics.map(epic =>
        formatEpicDetails(epic, state.timeframeStartDate, state.timeframeEndDate),
      );

      testAction(
        actions.refreshEpicDates,
        {},
        { ...state, timeframe: mockTimeframeMonths.concat(mockTimeframeMonthsAppend), epics },
        [{ type: types.SET_EPICS, payload: epics }],
        [],
        done,
      );
    });
  });
});
