import { shallowMount, createLocalVue } from '@vue/test-utils';
import Commit from '~/vue_shared/components/commit.vue';
import component from 'ee/environments_dashboard/components/dashboard/environment.vue';
import EnvironmentHeader from 'ee/environments_dashboard/components/dashboard/environment_header.vue';
import Alert from 'ee/vue_shared/dashboards/components/alerts.vue';
import environment from './mock_environment.json';

const localVue = createLocalVue();

describe('Environment', () => {
  const Component = localVue.extend(component);
  let wrapper;
  let propsData;

  beforeEach(() => {
    propsData = {
      environment,
    };
    wrapper = shallowMount(Component, {
      localVue,
      propsData,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('matchs the snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('wrapped components', () => {
    describe('environment header', () => {
      it('binds environment', () => {
        expect(wrapper.find(EnvironmentHeader).props('environment')).toBe(environment);
      });
    });
    describe('alerts', () => {
      let alert;

      beforeEach(() => {
        alert = wrapper.find(Alert);
      });
      it('binds alert count to count', () => {
        expect(alert.props('count')).toBe(environment.alert_count);
      });
      it('binds last alert', () => {
        expect(alert.props('lastAlert')).toBe(environment.last_alert);
      });
    });
    describe('commit', () => {
      let commit;

      beforeEach(() => {
        commit = wrapper.find(Commit);
      });

      it('binds commitRef', () => {
        expect(commit.props('commitRef')).toBe(wrapper.vm.commitRef);
      });

      it('binds short_id to shortSha', () => {
        expect(commit.props('shortSha')).toBe(environment.last_deployment.commit.short_id);
      });

      it('binds commitUrl', () => {
        expect(commit.props('commitUrl')).toBe(environment.last_deployment.commit.commit_url);
      });

      it('binds title', () => {
        expect(commit.props('title')).toBe(environment.last_deployment.commit.title);
      });

      it('binds author', () => {
        expect(commit.props('author')).toBe(environment.last_deployment.commit.author);
      });

      it('binds tag', () => {
        expect(commit.props('tag')).toBe(environment.last_deployment.ref.tag);
      });
    });
  });
});
