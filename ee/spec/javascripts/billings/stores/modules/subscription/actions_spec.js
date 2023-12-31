import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import testAction from 'spec/helpers/vuex_action_helper';

import state from 'ee/billings/stores/modules/subscription/state';
import * as types from 'ee/billings/stores/modules/subscription/mutation_types';
import * as actions from 'ee/billings/stores/modules/subscription/actions';

import mockDataSubscription from '../../../mock_data';

describe('subscription actions', () => {
  let mockedState;
  let mock;

  beforeEach(() => {
    mockedState = state();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('setNamespaceId', () => {
    it('should commit the correct mutuation', done => {
      const namespaceId = 1;

      testAction(
        actions.setNamespaceId,
        namespaceId,
        mockedState,
        [
          {
            type: types.SET_NAMESPACE_ID,
            payload: namespaceId,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchSubscription', () => {
    beforeEach(() => {
      gon.api_version = 'v4';
      mockedState.namespaceId = 1;
    });

    describe('on success', () => {
      beforeEach(() => {
        mock
          .onGet(/\/api\/v4\/namespaces\/\d+\/gitlab_subscription(.*)$/)
          .replyOnce(200, mockDataSubscription.gold);
      });

      it('should dispatch the request and success actions', done => {
        testAction(
          actions.fetchSubscription,
          {},
          mockedState,
          [],
          [
            { type: 'requestSubscription' },
            {
              type: 'receiveSubscriptionSuccess',
              payload: mockDataSubscription.gold,
            },
          ],
          done,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onGet(/\/api\/v4\/namespaces\/\d+\/gitlab_subscription(.*)$/).replyOnce(404, {});
      });

      it('should dispatch the request and error actions', done => {
        testAction(
          actions.fetchSubscription,
          {},
          mockedState,
          [],
          [{ type: 'requestSubscription' }, { type: 'receiveSubscriptionError' }],
          done,
        );
      });
    });
  });

  describe('requestSubscription', () => {
    it('should commit the request mutation', done => {
      testAction(
        actions.requestSubscription,
        {},
        state,
        [{ type: types.REQUEST_SUBSCRIPTION }],
        [],
        done,
      );
    });
  });

  describe('receiveSubscriptionSuccess', () => {
    it('should commit the success mutation', done => {
      testAction(
        actions.receiveSubscriptionSuccess,
        mockDataSubscription.gold,
        mockedState,
        [
          {
            type: types.RECEIVE_SUBSCRIPTION_SUCCESS,
            payload: mockDataSubscription.gold,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveSubscriptionError', () => {
    it('should commit the error mutation', done => {
      testAction(
        actions.receiveSubscriptionError,
        {},
        mockedState,
        [{ type: types.RECEIVE_SUBSCRIPTION_ERROR }],
        [],
        done,
      );
    });
  });
});
