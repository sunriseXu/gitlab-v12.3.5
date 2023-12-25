import { GlBadge, GlEmptyState, GlLoadingIcon, GlTab } from '@gitlab/ui';
import { createLocalVue, shallowMount, mount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import createStore from 'ee/dependencies/store';
import { addListType } from 'ee/dependencies/store/utils';
import { DEPENDENCY_LIST_TYPES } from 'ee/dependencies/store/constants';
import { REPORT_STATUS } from 'ee/dependencies/store/modules/list/constants';
import DependenciesApp from 'ee/dependencies/components/app.vue';
import DependenciesActions from 'ee/dependencies/components/dependencies_actions.vue';
import DependencyListIncompleteAlert from 'ee/dependencies/components/dependency_list_incomplete_alert.vue';
import DependencyListJobFailedAlert from 'ee/dependencies/components/dependency_list_job_failed_alert.vue';
import PaginatedDependenciesTable from 'ee/dependencies/components/paginated_dependencies_table.vue';

describe('DependenciesApp component', () => {
  let store;
  let wrapper;
  const { namespace } = DEPENDENCY_LIST_TYPES.all;

  const basicAppProps = {
    endpoint: '/foo',
    emptyStateSvgPath: '/bar.svg',
    documentationPath: TEST_HOST,
  };

  const factory = (props = basicAppProps) => {
    const localVue = createLocalVue();

    store = createStore();
    jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = shallowMount(DependenciesApp, {
      localVue,
      store,
      sync: false,
      propsData: { ...props },
    });
  };

  const expectComponentWithProps = (Component, props = {}) => {
    const componentWrapper = wrapper.find(Component);
    expect(componentWrapper.isVisible()).toBe(true);
    expect(componentWrapper.props()).toEqual(expect.objectContaining(props));
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('on creation', () => {
    let dependencies;

    beforeEach(() => {
      factory();
    });

    it('dispatches the correct initial actions', () => {
      expect(store.dispatch.mock.calls).toEqual([
        ['setDependenciesEndpoint', basicAppProps.endpoint],
        ['fetchDependencies'],
      ]);
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    describe('given a list of dependencies and ok report', () => {
      beforeEach(() => {
        dependencies = ['foo', 'bar'];

        Object.assign(store.state[namespace], {
          initialized: true,
          isLoading: false,
          dependencies,
        });
        store.state[namespace].pageInfo.total = 100;
        store.state[namespace].reportInfo.status = REPORT_STATUS.ok;

        return wrapper.vm.$nextTick();
      });

      it('matches the snapshot', () => {
        expect(wrapper.element).toMatchSnapshot();
      });

      it('passes the correct props to the paginated dependencies table', () => {
        expectComponentWithProps(PaginatedDependenciesTable, {
          namespace,
        });
      });
    });

    describe('given the dependency list job has not yet run', () => {
      beforeEach(() => {
        dependencies = [];

        Object.assign(store.state[namespace], {
          initialized: true,
          isLoading: false,
          dependencies,
        });
        store.state[namespace].pageInfo.total = 0;
        store.state[namespace].reportInfo.status = REPORT_STATUS.jobNotSetUp;

        return wrapper.vm.$nextTick();
      });

      it('matches the snapshot', () => {
        expect(wrapper.element).toMatchSnapshot();
      });
    });

    describe('given the dependency list job failed', () => {
      beforeEach(() => {
        dependencies = [];

        Object.assign(store.state[namespace], {
          initialized: true,
          isLoading: false,
          dependencies,
        });
        store.state[namespace].pageInfo.total = 0;
        store.state[namespace].reportInfo.status = REPORT_STATUS.jobFailed;
        store.state[namespace].reportInfo.jobPath = '/jobs/foo/321';

        return wrapper.vm.$nextTick();
      });

      it('matches the snapshot', () => {
        expect(wrapper.element).toMatchSnapshot();
      });

      it('passes the correct props to the job failure alert', () => {
        expectComponentWithProps(DependencyListJobFailedAlert, {
          jobPath: store.state[namespace].reportInfo.jobPath,
        });
      });

      it('passes the correct props to the paginated dependencies table', () => {
        expectComponentWithProps(PaginatedDependenciesTable, {
          namespace,
        });
      });

      describe('when the job failure alert emits the close event', () => {
        beforeEach(() => {
          const alertWrapper = wrapper.find(DependencyListJobFailedAlert);
          alertWrapper.vm.$emit('close');
          return wrapper.vm.$nextTick();
        });

        it('does not render the job failure alert', () => {
          expect(wrapper.find(DependencyListJobFailedAlert).exists()).toBe(false);
        });
      });
    });

    describe('given a dependency list which is known to be incomplete', () => {
      beforeEach(() => {
        dependencies = ['foo', 'bar'];

        Object.assign(store.state[namespace], {
          initialized: true,
          isLoading: false,
          dependencies,
        });
        store.state[namespace].pageInfo.total = 100;
        store.state[namespace].reportInfo.status = REPORT_STATUS.incomplete;

        return wrapper.vm.$nextTick();
      });

      it('matches the snapshot', () => {
        expect(wrapper.element).toMatchSnapshot();
      });

      it('passes the correct props to the incomplete-list alert', () => {
        const alert = wrapper.find(DependencyListIncompleteAlert);
        expect(alert.isVisible()).toBe(true);
      });

      it('passes the correct props to the paginated dependencies table', () => {
        expectComponentWithProps(PaginatedDependenciesTable, {
          namespace,
        });
      });

      describe('when the incomplete-list alert emits the close event', () => {
        beforeEach(() => {
          const alertWrapper = wrapper.find(DependencyListIncompleteAlert);
          alertWrapper.vm.$emit('close');
          return wrapper.vm.$nextTick();
        });

        it('does not render the incomplete-list alert', () => {
          expect(wrapper.find(DependencyListIncompleteAlert).exists()).toBe(false);
        });
      });
    });

    describe('given a fetch error', () => {
      beforeEach(() => {
        dependencies = [];

        Object.assign(store.state[namespace], {
          initialized: true,
          isLoading: false,
          errorLoading: true,
          dependencies,
        });

        return wrapper.vm.$nextTick();
      });

      it('matches the snapshot', () => {
        expect(wrapper.element).toMatchSnapshot();
      });

      it('passes the correct props to the paginated dependencies table', () => {
        expectComponentWithProps(PaginatedDependenciesTable, {
          namespace,
        });
      });
    });
  });
});

describe('DependenciesApp component with dependencyListVulnerabilities feature flag enabled', () => {
  let store;
  let wrapper;
  const { namespace: allNamespace } = DEPENDENCY_LIST_TYPES.all;
  const { namespace: vulnerableNamespace } = DEPENDENCY_LIST_TYPES.vulnerable;

  const basicAppProps = {
    endpoint: '/foo',
    emptyStateSvgPath: '/bar.svg',
    documentationPath: TEST_HOST,
  };

  const factory = (props = basicAppProps) => {
    const localVue = createLocalVue();

    store = createStore();
    addListType(store, DEPENDENCY_LIST_TYPES.vulnerable);
    jest.spyOn(store, 'dispatch').mockImplementation();

    const canBeStubbed = component => !['GlTab', 'GlTabs'].includes(component);
    const stubs = Object.keys(DependenciesApp.components).filter(canBeStubbed);

    wrapper = mount(DependenciesApp, {
      localVue,
      store,
      sync: false,
      propsData: { ...props },
      provide: {
        dependencyListVulnerabilities: true,
      },
      stubs,
    });
  };

  const setStateJobNotRun = () => {
    Object.assign(store.state[allNamespace], {
      initialized: true,
      isLoading: false,
      dependencies: [],
    });
    store.state[allNamespace].pageInfo.total = 0;
    store.state[allNamespace].reportInfo.status = REPORT_STATUS.jobNotSetUp;
  };

  const setStateLoaded = () => {
    [allNamespace, vulnerableNamespace].forEach((namespace, i, { length }) => {
      const total = length - i;
      Object.assign(store.state[namespace], {
        initialized: true,
        isLoading: false,
        dependencies: Array(total)
          .fill(null)
          .map((_, id) => ({ id })),
      });
      store.state[namespace].pageInfo.total = total;
      store.state[namespace].reportInfo.status = REPORT_STATUS.ok;
    });
  };

  const setStateJobFailed = () => {
    Object.assign(store.state[allNamespace], {
      initialized: true,
      isLoading: false,
      dependencies: [],
    });
    store.state[allNamespace].pageInfo.total = 0;
    store.state[allNamespace].reportInfo.status = REPORT_STATUS.jobFailed;
    store.state[allNamespace].reportInfo.jobPath = '/jobs/foo/321';
  };

  const setStateListIncomplete = () => {
    Object.assign(store.state[allNamespace], {
      initialized: true,
      isLoading: false,
      dependencies: [{ id: 0 }],
    });
    store.state[allNamespace].pageInfo.total = 1;
    store.state[allNamespace].reportInfo.status = REPORT_STATUS.incomplete;
  };

  const findJobFailedAlert = () => wrapper.find(DependencyListJobFailedAlert);
  const findIncompleteListAlert = () => wrapper.find(DependencyListIncompleteAlert);
  const findDependenciesTables = () => wrapper.findAll(PaginatedDependenciesTable);
  const findTabControls = () => wrapper.findAll('.gl-tab-nav-item');
  const findVulnerableTabControl = () => findTabControls().at(1);
  const findVulnerableTabComponent = () => wrapper.findAll(GlTab).at(1);

  const expectComponentWithProps = (Component, props = {}) => {
    const componentWrapper = wrapper.find(Component);
    expect(componentWrapper.isVisible()).toBe(true);
    expect(componentWrapper.props()).toEqual(expect.objectContaining(props));
  };

  const expectNoDependenciesTables = () => expect(findDependenciesTables()).toHaveLength(0);

  const expectDependenciesTables = () => {
    const { wrappers } = findDependenciesTables();
    expect(wrappers).toHaveLength(2);
    expect(wrappers[0].props()).toEqual({ namespace: allNamespace });
    expect(wrappers[1].props()).toEqual({ namespace: vulnerableNamespace });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('on creation', () => {
    beforeEach(() => {
      factory();
    });

    it('dispatches the correct initial actions', () => {
      expect(store.dispatch.mock.calls).toEqual([
        ['setDependenciesEndpoint', basicAppProps.endpoint],
        ['fetchDependencies'],
      ]);
    });

    it('shows only the loading icon', () => {
      expectComponentWithProps(GlLoadingIcon);
      expectNoDependenciesTables();
    });

    describe('given the dependency list job has not yet run', () => {
      beforeEach(() => {
        setStateJobNotRun();

        return wrapper.vm.$nextTick();
      });

      it('shows only the empty state', () => {
        expectComponentWithProps(GlEmptyState, { svgPath: basicAppProps.emptyStateSvgPath });
        expectNoDependenciesTables();
      });
    });

    describe('given a list of dependencies and ok report', () => {
      beforeEach(() => {
        setStateLoaded();

        return wrapper.vm.$nextTick();
      });

      it('shows both dependencies tables with the correct props', () => {
        expectDependenciesTables();
      });

      it('displays the tabs correctly', () => {
        const expected = [
          {
            text: 'All',
            total: '2',
          },
          {
            text: 'Vulnerable',
            total: '1',
          },
        ];

        const tabs = findTabControls();
        expected.forEach(({ text, total }, i) => {
          const tab = tabs.at(i);
          expect(tab.text()).toEqual(expect.stringContaining(text));
          expect(
            tab
              .find(GlBadge)
              .text()
              .trim(),
          ).toEqual(total);
        });
      });

      it('passes the correct namespace to dependencies actions component', () => {
        expectComponentWithProps(DependenciesActions, { namespace: allNamespace });
      });

      describe('given the user clicks on the vulnerable tab', () => {
        beforeEach(() => {
          findVulnerableTabControl().trigger('click');

          return wrapper.vm.$nextTick();
        });

        it('changes the current list', () => {
          expect(store.dispatch).toHaveBeenCalledWith('setCurrentList', vulnerableNamespace);
        });
      });

      describe('given the current list is the vulnerable dependencies list', () => {
        const namespace = vulnerableNamespace;
        beforeEach(() => {
          store.state.currentList = namespace;

          return wrapper.vm.$nextTick();
        });

        it('passes the correct namespace to dependencies actions component', () => {
          expectComponentWithProps(DependenciesActions, { namespace });
        });
      });

      it('has enabled vulnerable tab', () => {
        expect(findVulnerableTabComponent().classes('disabled')).toBe(false);
      });

      describe('given there are no vulnerable dependencies', () => {
        beforeEach(() => {
          store.state[vulnerableNamespace].dependencies = [];
          store.state[vulnerableNamespace].pageInfo.total = 0;

          return wrapper.vm.$nextTick();
        });

        it('disables the vulnerable tab', () => {
          expect(findVulnerableTabComponent().classes('disabled')).toBe(true);
        });
      });
    });

    describe('given the dependency list job failed', () => {
      beforeEach(() => {
        setStateJobFailed();

        return wrapper.vm.$nextTick();
      });

      it('passes the correct props to the job failure alert', () => {
        expectComponentWithProps(DependencyListJobFailedAlert, {
          jobPath: '/jobs/foo/321',
        });
      });

      it('shows both dependencies tables with the correct props', expectDependenciesTables);

      describe('when the job failure alert emits the close event', () => {
        beforeEach(() => {
          const alertWrapper = findJobFailedAlert();
          alertWrapper.vm.$emit('close');
          return wrapper.vm.$nextTick();
        });

        it('does not render the job failure alert', () => {
          expect(findJobFailedAlert().exists()).toBe(false);
        });
      });
    });

    describe('given a dependency list which is known to be incomplete', () => {
      beforeEach(() => {
        setStateListIncomplete();

        return wrapper.vm.$nextTick();
      });

      it('passes the correct props to the incomplete-list alert', () => {
        expectComponentWithProps(DependencyListIncompleteAlert);
      });

      it('shows both dependencies tables with the correct props', expectDependenciesTables);

      describe('when the incomplete-list alert emits the close event', () => {
        beforeEach(() => {
          const alertWrapper = findIncompleteListAlert();
          alertWrapper.vm.$emit('close');
          return wrapper.vm.$nextTick();
        });

        it('does not render the incomplete-list alert', () => {
          expect(findIncompleteListAlert().exists()).toBe(false);
        });
      });
    });
  });
});
