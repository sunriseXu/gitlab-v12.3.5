import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import Form from 'ee/feature_flags/components/form.vue';
import editModule from 'ee/feature_flags/store/modules/edit';
import EditFeatureFlag from 'ee/feature_flags/components/edit_feature_flag.vue';
import { TEST_HOST } from 'spec/test_constants';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Edit feature flag form', () => {
  let wrapper;
  let mock;

  const store = new Vuex.Store({
    modules: {
      edit: editModule,
    },
  });

  const factory = () => {
    wrapper = shallowMount(localVue.extend(EditFeatureFlag), {
      localVue,
      propsData: {
        endpoint: `${TEST_HOST}/feature_flags.json'`,
        path: '/feature_flags',
        environmentsEndpoint: 'environments.json',
      },
      store,
      sync: false,
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);

    mock.onGet(`${TEST_HOST}/feature_flags.json'`).replyOnce(200, {
      id: 21,
      active: false,
      created_at: '2019-01-17T17:27:39.778Z',
      updated_at: '2019-01-17T17:27:39.778Z',
      name: 'feature_flag',
      description: '',
      edit_path: '/h5bp/html5-boilerplate/-/feature_flags/21/edit',
      destroy_path: '/h5bp/html5-boilerplate/-/feature_flags/21',
      scopes: [
        {
          id: 21,
          active: false,
          environment_scope: '*',
          created_at: '2019-01-17T17:27:39.778Z',
          updated_at: '2019-01-17T17:27:39.778Z',
        },
      ],
    });

    factory();
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  describe('with error', () => {
    it('should render the error', done => {
      setTimeout(() => {
        store.dispatch('edit/receiveUpdateFeatureFlagError', { message: ['The name is required'] });

        wrapper.vm.$nextTick(() => {
          expect(wrapper.find('.alert-danger').exists()).toEqual(true);
          expect(wrapper.find('.alert-danger').text()).toContain('The name is required');
          done();
        });
      }, 0);
    });
  });

  describe('without error', () => {
    it('renders form title', done => {
      setTimeout(() => {
        expect(wrapper.text()).toContain('Edit feature_flag');
        done();
      }, 0);
    });

    it('should render feature flag form', done => {
      setTimeout(() => {
        expect(wrapper.find(Form).exists()).toEqual(true);
        done();
      }, 0);
    });
  });
});
