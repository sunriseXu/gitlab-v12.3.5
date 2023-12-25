import MockAdapter from 'axios-mock-adapter';

import defaultState from 'ee/epic/store/state';
import * as actions from 'ee/epic/store/actions';
import epicUtils from 'ee/epic/utils/epic_utils';
import { statusType, dateTypes } from 'ee/epic/constants';

import axios from '~/lib/utils/axios_utils';
import testAction from 'spec/helpers/vuex_action_helper';

import { mockEpicMeta, mockEpicData } from '../mock_data';

describe('Epic Store Actions', () => {
  let state;

  beforeEach(() => {
    state = Object.assign({}, defaultState());
  });

  describe('setEpicMeta', () => {
    it('should set received Epic meta', done => {
      testAction(
        actions.setEpicMeta,
        mockEpicMeta,
        {},
        [{ type: 'SET_EPIC_META', payload: mockEpicMeta }],
        [],
        done,
      );
    });
  });

  describe('setEpicData', () => {
    it('should set received Epic data', done => {
      testAction(
        actions.setEpicData,
        mockEpicData,
        {},
        [{ type: 'SET_EPIC_DATA', payload: mockEpicData }],
        [],
        done,
      );
    });
  });

  describe('requestEpicStatusChange', () => {
    it('should set status change flag', done => {
      testAction(
        actions.requestEpicStatusChange,
        {},
        state,
        [{ type: 'REQUEST_EPIC_STATUS_CHANGE' }],
        [],
        done,
      );
    });
  });

  describe('requestEpicStatusChangeSuccess', () => {
    it('should set epic state type', done => {
      testAction(
        actions.requestEpicStatusChangeSuccess,
        { state: statusType.close },
        state,
        [{ type: 'REQUEST_EPIC_STATUS_CHANGE_SUCCESS', payload: { state: statusType.close } }],
        [],
        done,
      );
    });
  });

  describe('requestEpicStatusChangeFailure', () => {
    beforeEach(() => {
      setFixtures('<div class="flash-container"></div>');
    });

    it('should set status change flag', done => {
      testAction(
        actions.requestEpicStatusChangeFailure,
        {},
        state,
        [{ type: 'REQUEST_EPIC_STATUS_CHANGE_FAILURE' }],
        [],
        done,
      );
    });

    it('should show flash error', () => {
      actions.requestEpicStatusChangeFailure({ commit: () => {} });

      expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
        'Unable to update this epic at this time.',
      );
    });
  });

  describe('triggerIssuableEvent', () => {
    it('Calls `triggerDocumentEvent` with events `issuable_vue_app:change`, `issuable:change` and passes `isEpicOpen` as param', () => {
      spyOn(epicUtils, 'triggerDocumentEvent').and.returnValue(false);

      const data = { isEpicOpen: true };
      actions.triggerIssuableEvent({}, data);

      expect(epicUtils.triggerDocumentEvent).toHaveBeenCalledWith(
        'issuable_vue_app:change',
        data.isEpicOpen,
      );

      expect(epicUtils.triggerDocumentEvent).toHaveBeenCalledWith(
        'issuable:change',
        data.isEpicOpen,
      );
    });
  });

  describe('toggleEpicStatus', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      it('dispatches requestEpicStatusChange and requestEpicStatusChangeSuccess when request is complete', done => {
        mock.onPut(/(.*)/).replyOnce(200, {
          state: statusType.close,
        });

        testAction(
          actions.toggleEpicStatus,
          null,
          state,
          [],
          [
            {
              type: 'requestEpicStatusChange',
            },
            {
              type: 'requestEpicStatusChangeSuccess',
              payload: { state: statusType.close },
            },
            {
              type: 'triggerIssuableEvent',
              payload: { isEpicOpen: true },
            },
          ],
          done,
        );
      });
    });

    describe('failure', () => {
      it('dispatches requestEpicStatusChange and requestEpicStatusChangeFailure when request fails', done => {
        mock.onPut(/(.*)/).replyOnce(500, {});

        testAction(
          actions.toggleEpicStatus,
          null,
          state,
          [],
          [
            {
              type: 'requestEpicStatusChange',
            },
            {
              type: 'requestEpicStatusChangeFailure',
            },
            {
              type: 'triggerIssuableEvent',
              payload: { isEpicOpen: true },
            },
          ],
          done,
        );
      });
    });
  });

  describe('toggleSidebarFlag', () => {
    it('should call `TOGGLE_SIDEBAR` mutation with param `sidebarCollapsed`', done => {
      const sidebarCollapsed = true;

      testAction(
        actions.toggleSidebarFlag,
        sidebarCollapsed,
        state,
        [{ type: 'TOGGLE_SIDEBAR', payload: sidebarCollapsed }],
        [],
        done,
      );
    });
  });

  describe('toggleContainerClassAndCookie', () => {
    const sidebarCollapsed = true;

    beforeEach(() => {
      spyOn(epicUtils, 'toggleContainerClass').and.stub();
      spyOn(epicUtils, 'setCollapsedGutter').and.stub();
    });

    it('should call `epicUtils.toggleContainerClass` with classes `right-sidebar-expanded` & `right-sidebar-collapsed`', () => {
      actions.toggleContainerClassAndCookie({}, sidebarCollapsed);

      expect(epicUtils.toggleContainerClass).toHaveBeenCalledTimes(2);
      expect(epicUtils.toggleContainerClass).toHaveBeenCalledWith('right-sidebar-expanded');
      expect(epicUtils.toggleContainerClass).toHaveBeenCalledWith('right-sidebar-collapsed');
    });

    it('should call `epicUtils.setCollapsedGutter` with param `isSidebarCollapsed`', () => {
      actions.toggleContainerClassAndCookie({}, sidebarCollapsed);

      expect(epicUtils.setCollapsedGutter).toHaveBeenCalledWith(sidebarCollapsed);
    });
  });

  describe('toggleSidebar', () => {
    it('dispatches toggleContainerClassAndCookie and toggleSidebarFlag actions with opposite value of `isSidebarCollapsed` param', done => {
      const sidebarCollapsed = true;

      testAction(
        actions.toggleSidebar,
        { sidebarCollapsed },
        state,
        [],
        [
          {
            type: 'toggleContainerClassAndCookie',
            payload: !sidebarCollapsed,
          },
          {
            type: 'toggleSidebarFlag',
            payload: !sidebarCollapsed,
          },
        ],
        done,
      );
    });
  });

  describe('requestEpicTodoToggle', () => {
    it('should set `state.epicTodoToggleInProgress` flag to `true`', done => {
      testAction(
        actions.requestEpicTodoToggle,
        {},
        state,
        [{ type: 'REQUEST_EPIC_TODO_TOGGLE' }],
        [],
        done,
      );
    });
  });

  describe('requestEpicTodoToggleSuccess', () => {
    it('should set epic state type', done => {
      testAction(
        actions.requestEpicTodoToggleSuccess,
        { todoDeletePath: '/foo/bar' },
        state,
        [{ type: 'REQUEST_EPIC_TODO_TOGGLE_SUCCESS', payload: { todoDeletePath: '/foo/bar' } }],
        [],
        done,
      );
    });
  });

  describe('requestEpicTodoToggleFailure', () => {
    beforeEach(() => {
      setFixtures('<div class="flash-container"></div>');
    });

    it('Should set `state.epicTodoToggleInProgress` flag to `false`', done => {
      testAction(
        actions.requestEpicTodoToggleFailure,
        {},
        state,
        [{ type: 'REQUEST_EPIC_TODO_TOGGLE_FAILURE', payload: {} }],
        [],
        done,
      );
    });

    it('Should show flash error with message "There was an error deleting the To Do." when `state.todoExists` is `true`', () => {
      actions.requestEpicTodoToggleFailure(
        {
          commit: () => {},
          state: { todoExists: true },
        },
        {},
      );

      expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
        'There was an error deleting the To Do.',
      );
    });

    it('Should show flash error with message "There was an error adding a To Do." when `state.todoExists` is `false`', () => {
      actions.requestEpicTodoToggleFailure(
        {
          commit: () => {},
          state: { todoExists: false },
        },
        {},
      );

      expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
        'There was an error adding a To Do.',
      );
    });
  });

  describe('triggerTodoToggleEvent', () => {
    it('Calls `triggerDocumentEvent` with event `todo:toggle` and passes `count` as param', () => {
      spyOn(epicUtils, 'triggerDocumentEvent').and.returnValue(false);

      const data = { count: 5 };
      actions.triggerTodoToggleEvent({}, data);

      expect(epicUtils.triggerDocumentEvent).toHaveBeenCalledWith('todo:toggle', data.count);
    });
  });

  describe('toggleTodo', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('when `state.togoExists` is false', () => {
      it('dispatches requestEpicTodoToggle, triggerTodoToggleEvent and requestEpicTodoToggleSuccess when request is successful', done => {
        mock.onPost(/(.*)/).replyOnce(200, {
          count: 5,
          delete_path: '/foo/bar',
        });

        testAction(
          actions.toggleTodo,
          null,
          { todoExists: false },
          [],
          [
            {
              type: 'requestEpicTodoToggle',
            },
            {
              type: 'triggerTodoToggleEvent',
              payload: { count: 5 },
            },
            {
              type: 'requestEpicTodoToggleSuccess',
              payload: { todoDeletePath: '/foo/bar' },
            },
          ],
          done,
        );
      });

      it('dispatches requestEpicTodoToggle and requestEpicTodoToggleFailure when request fails', done => {
        mock.onPost(/(.*)/).replyOnce(500, {});

        testAction(
          actions.toggleTodo,
          null,
          { todoExists: false },
          [],
          [
            {
              type: 'requestEpicTodoToggle',
            },
            {
              type: 'requestEpicTodoToggleFailure',
            },
          ],
          done,
        );
      });
    });

    describe('when `state.togoExists` is true', () => {
      it('dispatches requestEpicTodoToggle, triggerTodoToggleEvent and requestEpicTodoToggleSuccess when request is successful', done => {
        mock.onDelete(/(.*)/).replyOnce(200, {
          count: 5,
        });

        testAction(
          actions.toggleTodo,
          null,
          { todoExists: true },
          [],
          [
            {
              type: 'requestEpicTodoToggle',
            },
            {
              type: 'triggerTodoToggleEvent',
              payload: { count: 5 },
            },
            {
              type: 'requestEpicTodoToggleSuccess',
              payload: { todoDeletePath: undefined },
            },
          ],
          done,
        );
      });

      it('dispatches requestEpicTodoToggle and requestEpicTodoToggleFailure when request fails', done => {
        mock.onDelete(/(.*)/).replyOnce(500, {});

        testAction(
          actions.toggleTodo,
          null,
          { todoExists: true },
          [],
          [
            {
              type: 'requestEpicTodoToggle',
            },
            {
              type: 'requestEpicTodoToggleFailure',
            },
          ],
          done,
        );
      });
    });
  });

  describe('toggleStartDateType', () => {
    it('should set `state.startDateIsFixed` flag to `true`', done => {
      const dateTypeIsFixed = true;

      testAction(
        actions.toggleStartDateType,
        { dateTypeIsFixed },
        state,
        [{ type: 'TOGGLE_EPIC_START_DATE_TYPE', payload: { dateTypeIsFixed } }],
        [],
        done,
      );
    });
  });

  describe('toggleDueDateType', () => {
    it('should set `state.dueDateIsFixed` flag to `true`', done => {
      const dateTypeIsFixed = true;

      testAction(
        actions.toggleDueDateType,
        { dateTypeIsFixed },
        state,
        [{ type: 'TOGGLE_EPIC_DUE_DATE_TYPE', payload: { dateTypeIsFixed } }],
        [],
        done,
      );
    });
  });

  describe('requestEpicDateSave', () => {
    it('should set `state.epicStartDateSaveInProgress` flag to `true` when called with `dateType` as `start`', done => {
      const dateType = dateTypes.start;

      testAction(
        actions.requestEpicDateSave,
        { dateType },
        state,
        [{ type: 'REQUEST_EPIC_DATE_SAVE', payload: { dateType } }],
        [],
        done,
      );
    });

    it('should set `state.epicDueDateSaveInProgress` flag to `true` when called with `dateType` as `due`', done => {
      const dateType = dateTypes.due;

      testAction(
        actions.requestEpicDateSave,
        { dateType },
        state,
        [{ type: 'REQUEST_EPIC_DATE_SAVE', payload: { dateType } }],
        [],
        done,
      );
    });
  });

  describe('requestEpicDateSaveSuccess', () => {
    it('should set `state.epicStartDateSaveInProgress` flag to `false` and set values of `startDateIsFixed` & `startDate` with params `dateTypeIsFixed` & `newDate` when called with `dateType` as `start`', done => {
      const data = {
        dateType: dateTypes.start,
        dateTypeIsFixed: true,
        mewDate: '2018-1-1',
      };

      testAction(
        actions.requestEpicDateSaveSuccess,
        data,
        state,
        [{ type: 'REQUEST_EPIC_DATE_SAVE_SUCCESS', payload: { ...data } }],
        [],
        done,
      );
    });

    it('should set `state.epicDueDateSaveInProgress` flag to `false` and set values of `dueDateIsFixed` & `dueDate` with params `dateTypeIsFixed` & `newDate` when called with `dateType` as `due`', done => {
      const data = {
        dateType: dateTypes.due,
        dateTypeIsFixed: true,
        mewDate: '2018-1-1',
      };

      testAction(
        actions.requestEpicDateSaveSuccess,
        data,
        state,
        [{ type: 'REQUEST_EPIC_DATE_SAVE_SUCCESS', payload: { ...data } }],
        [],
        done,
      );
    });
  });

  describe('requestEpicDateSaveFailure', () => {
    beforeEach(() => {
      setFixtures('<div class="flash-container"></div>');
    });

    it('should set `state.epicStartDateSaveInProgress` flag to `false` and set value of `startDateIsFixed` to that of param `dateTypeIsFixed` when called with `dateType` as `start`', done => {
      const data = {
        dateType: dateTypes.start,
        dateTypeIsFixed: true,
      };

      testAction(
        actions.requestEpicDateSaveFailure,
        data,
        state,
        [
          {
            type: 'REQUEST_EPIC_DATE_SAVE_FAILURE',
            payload: { ...data },
          },
        ],
        [],
        done,
      );
    });

    it('should set `state.epicDueDateSaveInProgress` flag to `false` and set value of `dueDateIsFixed` to that of param `dateTypeIsFixed` when called with `dateType` as `due`', done => {
      const data = {
        dateType: dateTypes.due,
        dateTypeIsFixed: true,
      };

      testAction(
        actions.requestEpicDateSaveFailure,
        data,
        state,
        [
          {
            type: 'REQUEST_EPIC_DATE_SAVE_FAILURE',
            payload: { ...data },
          },
        ],
        [],
        done,
      );
    });

    it('should show flash error with message "An error occurred while saving the start date" when called with `dateType` as `start`', () => {
      actions.requestEpicDateSaveFailure(
        {
          commit: () => {},
        },
        { dateType: dateTypes.start },
      );

      expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
        'An error occurred while saving the start date',
      );
    });

    it('should show flash error with message "An error occurred while saving the due date" when called with `dateType` as `due`', () => {
      actions.requestEpicDateSaveFailure(
        {
          commit: () => {},
        },
        { dateType: dateTypes.due },
      );

      expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
        'An error occurred while saving the due date',
      );
    });
  });

  describe('saveDate', () => {
    let mock;
    const data = {
      dateType: dateTypes.start,
      dateTypeIsFixed: true,
      newDate: '2018-1-1',
    };

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    it('dispatches requestEpicDateSave and requestEpicDateSaveSuccess when request is successful', done => {
      mock.onPut(/(.*)/).replyOnce(200, {});

      testAction(
        actions.saveDate,
        { ...data },
        state,
        [],
        [
          {
            type: 'requestEpicDateSave',
            payload: { dateType: data.dateType },
          },
          {
            type: 'requestEpicDateSaveSuccess',
            payload: { ...data },
          },
        ],
        done,
      );
    });

    it('dispatches requestEpicDateSave and requestEpicDateSaveFailure when request fails', done => {
      mock.onPut(/(.*)/).replyOnce(500, {});

      testAction(
        actions.saveDate,
        { ...data },
        state,
        [],
        [
          {
            type: 'requestEpicDateSave',
            payload: { dateType: data.dateType },
          },
          {
            type: 'requestEpicDateSaveFailure',
            payload: { dateType: data.dateType, dateTypeIsFixed: !data.dateTypeIsFixed },
          },
        ],
        done,
      );
    });

    it('calls `axios.put` with request body containing start date related payload when called with `dateType` as `start`', () => {
      spyOn(axios, 'put').and.callFake(() => new Promise(() => {}));

      actions.saveDate(
        {
          state: { endpoint: '/foo/bar' },
          dispatch: () => {},
        },
        {
          dateType: dateTypes.start,
          newDate: '2018-1-1',
          dateTypeIsFixed: true,
        },
      );

      expect(axios.put).toHaveBeenCalledWith(
        '/foo/bar',
        jasmine.objectContaining({
          start_date_is_fixed: true,
          start_date_fixed: '2018-1-1',
        }),
      );
    });

    it('calls `axios.put` with request body containing due date related payload when called with `dateType` as `due`', () => {
      spyOn(axios, 'put').and.callFake(() => new Promise(() => {}));

      actions.saveDate(
        {
          state: { endpoint: '/foo/bar' },
          dispatch: () => {},
        },
        {
          dateType: dateTypes.due,
          newDate: '2018-1-1',
          dateTypeIsFixed: true,
        },
      );

      expect(axios.put).toHaveBeenCalledWith(
        '/foo/bar',
        jasmine.objectContaining({
          due_date_is_fixed: true,
          due_date_fixed: '2018-1-1',
        }),
      );
    });
  });

  describe('requestEpicSubscriptionToggle', () => {
    it('should set `state.epicSubscriptionToggleInProgress` flag to `true`', done => {
      testAction(
        actions.requestEpicSubscriptionToggle,
        {},
        state,
        [{ type: 'REQUEST_EPIC_SUBSCRIPTION_TOGGLE' }],
        [],
        done,
      );
    });
  });

  describe('requestEpicSubscriptionToggleSuccess', () => {
    it('should set `state.requestEpicSubscriptionToggleSuccess` flag to `false` and passes opposite of the value of `subscribed` as param', done => {
      const stateSubscribed = {
        subscribed: false,
      };

      testAction(
        actions.requestEpicSubscriptionToggleSuccess,
        { subscribed: !stateSubscribed.subscribed },
        stateSubscribed,
        [
          {
            type: 'REQUEST_EPIC_SUBSCRIPTION_TOGGLE_SUCCESS',
            payload: { subscribed: !stateSubscribed.subscribed },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('requestEpicSubscriptionToggleFailure', () => {
    beforeEach(() => {
      setFixtures('<div class="flash-container"></div>');
    });

    it('should set `state.requestEpicSubscriptionToggleFailure` flag to `false`', done => {
      testAction(
        actions.requestEpicSubscriptionToggleFailure,
        {},
        state,
        [{ type: 'REQUEST_EPIC_SUBSCRIPTION_TOGGLE_FAILURE' }],
        [],
        done,
      );
    });

    it('should show flash error with message "An error occurred while subscribing to notifications." when `state.subscribed` is `false`', () => {
      actions.requestEpicSubscriptionToggleFailure(
        {
          commit: () => {},
          state: { subscribed: false },
        },
        {},
      );

      expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
        'An error occurred while subscribing to notifications.',
      );
    });

    it('should show flash error with message "An error occurred while unsubscribing to notifications." when `state.subscribed` is `true`', () => {
      actions.requestEpicSubscriptionToggleFailure(
        {
          commit: () => {},
          state: { subscribed: true },
        },
        {},
      );

      expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
        'An error occurred while unsubscribing to notifications.',
      );
    });
  });

  describe('toggleEpicSubscription', () => {
    let mock;
    const stateSubscribed = {
      subscribed: false,
    };

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      it('dispatches requestEpicSubscriptionToggle and requestEpicSubscriptionToggleSuccess with param `subscribed` when request is complete', done => {
        mock.onPost(/(.*)/).replyOnce(200, {});

        testAction(
          actions.toggleEpicSubscription,
          { subscribed: !stateSubscribed.subscribed },
          stateSubscribed,
          [],
          [
            {
              type: 'requestEpicSubscriptionToggle',
            },
            {
              type: 'requestEpicSubscriptionToggleSuccess',
              payload: { subscribed: !stateSubscribed.subscribed },
            },
          ],
          done,
        );
      });
    });

    describe('failure', () => {
      it('dispatches requestEpicSubscriptionToggle and requestEpicSubscriptionToggleFailure when request fails', done => {
        mock.onPost(/(.*)/).replyOnce(500, {});

        testAction(
          actions.toggleEpicSubscription,
          { subscribed: !stateSubscribed.subscribed },
          stateSubscribed,
          [],
          [
            {
              type: 'requestEpicSubscriptionToggle',
            },
            {
              type: 'requestEpicSubscriptionToggleFailure',
            },
          ],
          done,
        );
      });
    });
  });

  describe('setEpicCreateTitle', () => {
    it('should set `state.newEpicTitle` value to the value of `newEpicTitle` param', done => {
      const data = {
        newEpicTitle: 'foobar',
      };

      testAction(
        actions.setEpicCreateTitle,
        data,
        { newEpicTitle: '' },
        [{ type: 'SET_EPIC_CREATE_TITLE', payload: { ...data } }],
        [],
        done,
      );
    });
  });

  describe('requestEpicCreate', () => {
    it('should set `state.epicCreateInProgress` flag to `true`', done => {
      testAction(
        actions.requestEpicCreate,
        {},
        { epicCreateInProgress: false },
        [{ type: 'REQUEST_EPIC_CREATE' }],
        [],
        done,
      );
    });
  });

  describe('requestEpicCreateFailure', () => {
    beforeEach(() => {
      setFixtures('<div class="flash-container"></div>');
    });

    it('should set `state.epicCreateInProgress` flag to `false`', done => {
      testAction(
        actions.requestEpicCreateFailure,
        {},
        { epicCreateInProgress: true },
        [{ type: 'REQUEST_EPIC_CREATE_FAILURE' }],
        [],
        done,
      );
    });

    it('should show flash error with message "Error creating epic."', () => {
      actions.requestEpicCreateFailure({
        commit: () => {},
      });

      expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
        'Error creating epic',
      );
    });
  });

  describe('createEpic', () => {
    let mock;
    const stateCreateEpic = {
      newEpicTitle: 'foobar',
    };

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      it('dispatches requestEpicCreate when request is complete', done => {
        mock.onPost(/(.*)/).replyOnce(200, {});

        testAction(
          actions.createEpic,
          { ...stateCreateEpic },
          stateCreateEpic,
          [],
          [
            {
              type: 'requestEpicCreate',
            },
            {
              type: 'requestEpicCreateSuccess',
            },
          ],
          done,
        );
      });
    });

    describe('failure', () => {
      it('dispatches requestEpicCreate and requestEpicCreateFailure when request fails', done => {
        mock.onPost(/(.*)/).replyOnce(500, {});

        testAction(
          actions.createEpic,
          { ...stateCreateEpic },
          stateCreateEpic,
          [],
          [
            {
              type: 'requestEpicCreate',
            },
            {
              type: 'requestEpicCreateFailure',
            },
          ],
          done,
        );
      });
    });
  });
});
