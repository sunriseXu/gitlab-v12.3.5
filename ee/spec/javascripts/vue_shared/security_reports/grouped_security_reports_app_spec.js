import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import component from 'ee/vue_shared/security_reports/grouped_security_reports_app.vue';
import state from 'ee/vue_shared/security_reports/store/state';
import * as types from 'ee/vue_shared/security_reports/store/mutation_types';
import sastState from 'ee/vue_shared/security_reports/store/modules/sast/state';
import * as sastTypes from 'ee/vue_shared/security_reports/store/modules/sast/mutation_types';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { waitForMutation } from 'spec/helpers/vue_test_utils_helper';
import { trimText } from 'spec/helpers/text_helper';
import {
  sastIssues,
  sastIssuesBase,
  dockerReport,
  dockerBaseReport,
  dast,
  dastBase,
} from './mock_data';

describe('Grouped security reports app', () => {
  let vm;
  let mock;
  const Component = Vue.extend(component);

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    vm.$store.replaceState({
      ...state(),
      sast: sastState(),
    });
    vm.$destroy();
    mock.restore();
  });

  describe('with error', () => {
    beforeEach(done => {
      mock.onGet('sast_head.json').reply(500);
      mock.onGet('sast_base.json').reply(500);
      mock.onGet('dast_head.json').reply(500);
      mock.onGet('dast_base.json').reply(500);
      mock.onGet('sast_container_head.json').reply(500);
      mock.onGet('sast_container_base.json').reply(500);
      mock.onGet('dss_head.json').reply(500);
      mock.onGet('dss_base.json').reply(500);
      mock.onGet('vulnerability_feedback_path.json').reply(500, []);

      vm = mountComponent(Component, {
        headBlobPath: 'path',
        baseBlobPath: 'path',
        sastHeadPath: 'sast_head.json',
        sastBasePath: 'sast_base.json',
        dastHeadPath: 'dast_head.json',
        dastBasePath: 'dast_base.json',
        sastContainerHeadPath: 'sast_container_head.json',
        sastContainerBasePath: 'sast_container_base.json',
        dependencyScanningHeadPath: 'dss_head.json',
        dependencyScanningBasePath: 'dss_base.json',
        sastHelpPath: 'path',
        sastContainerHelpPath: 'path',
        dastHelpPath: 'path',
        dependencyScanningHelpPath: 'path',
        vulnerabilityFeedbackPath: 'vulnerability_feedback_path.json',
        vulnerabilityFeedbackHelpPath: 'path',
        pipelineId: 123,
        canCreateIssue: true,
        canCreateMergeRequest: true,
        canDismissVulnerability: true,
      });

      Promise.all([
        waitForMutation(vm.$store, `sast/${sastTypes.RECEIVE_REPORTS_ERROR}`),
        waitForMutation(vm.$store, types.RECEIVE_SAST_CONTAINER_ERROR),
        waitForMutation(vm.$store, types.RECEIVE_DAST_ERROR),
        waitForMutation(vm.$store, types.RECEIVE_DEPENDENCY_SCANNING_ERROR),
      ])
        .then(done)
        .catch();
    });

    it('renders error state', () => {
      expect(vm.$el.querySelector('.gl-spinner')).toBeNull();
      expect(vm.$el.querySelector('.js-code-text').textContent.trim()).toEqual(
        'Security scanning failed loading any results',
      );

      expect(vm.$el.querySelector('.js-collapse-btn').textContent.trim()).toEqual('Expand');

      expect(trimText(vm.$el.textContent)).toContain('SAST: Loading resulted in an error');
      expect(trimText(vm.$el.textContent)).toContain(
        'Dependency scanning: Loading resulted in an error',
      );

      expect(vm.$el.textContent).toContain('Container scanning: Loading resulted in an error');
      expect(vm.$el.textContent).toContain('DAST: Loading resulted in an error');
    });
  });

  describe('while loading', () => {
    beforeEach(() => {
      mock.onGet('sast_head.json').reply(200, sastIssues);
      mock.onGet('sast_base.json').reply(200, sastIssuesBase);
      mock.onGet('dast_head.json').reply(200, dast);
      mock.onGet('dast_base.json').reply(200, dastBase);
      mock.onGet('sast_container_head.json').reply(200, dockerReport);
      mock.onGet('sast_container_base.json').reply(200, dockerBaseReport);
      mock.onGet('dss_head.json').reply(200, sastIssues);
      mock.onGet('dss_base.json').reply(200, sastIssuesBase);
      mock.onGet('vulnerability_feedback_path.json').reply(200, []);

      vm = mountComponent(Component, {
        headBlobPath: 'path',
        baseBlobPath: 'path',
        sastHeadPath: 'sast_head.json',
        sastBasePath: 'sast_base.json',
        dastHeadPath: 'dast_head.json',
        dastBasePath: 'dast_base.json',
        sastContainerHeadPath: 'sast_container_head.json',
        sastContainerBasePath: 'sast_container_base.json',
        dependencyScanningHeadPath: 'dss_head.json',
        dependencyScanningBasePath: 'dss_base.json',
        sastHelpPath: 'path',
        sastContainerHelpPath: 'path',
        dastHelpPath: 'path',
        dependencyScanningHelpPath: 'path',
        vulnerabilityFeedbackPath: 'vulnerability_feedback_path.json',
        vulnerabilityFeedbackHelpPath: 'path',
        pipelineId: 123,
        canCreateIssue: true,
        canCreateMergeRequest: true,
        canDismissVulnerability: true,
      });
    });

    it('renders loading summary text + spinner', () => {
      expect(vm.$el.querySelector('.gl-spinner')).not.toBeNull();
      expect(vm.$el.querySelector('.js-code-text').textContent.trim()).toEqual(
        'Security scanning is loading',
      );

      expect(vm.$el.querySelector('.js-collapse-btn').textContent.trim()).toEqual('Expand');

      expect(vm.$el.textContent).toContain('SAST is loading');
      expect(vm.$el.textContent).toContain('Dependency scanning is loading');
      expect(vm.$el.textContent).toContain('Container scanning is loading');
      expect(vm.$el.textContent).toContain('DAST is loading');
    });
  });

  describe('with all reports', () => {
    beforeEach(done => {
      mock.onGet('sast_head.json').reply(200, sastIssues);
      mock.onGet('sast_base.json').reply(200, sastIssuesBase);
      mock.onGet('dast_head.json').reply(200, dast);
      mock.onGet('dast_base.json').reply(200, dastBase);
      mock.onGet('sast_container_head.json').reply(200, dockerReport);
      mock.onGet('sast_container_base.json').reply(200, dockerBaseReport);
      mock.onGet('dss_head.json').reply(200, sastIssues);
      mock.onGet('dss_base.json').reply(200, sastIssuesBase);
      mock.onGet('vulnerability_feedback_path.json').reply(200, []);

      vm = mountComponent(Component, {
        headBlobPath: 'path',
        baseBlobPath: 'path',
        sastHeadPath: 'sast_head.json',
        sastBasePath: 'sast_base.json',
        dastHeadPath: 'dast_head.json',
        dastBasePath: 'dast_base.json',
        sastContainerHeadPath: 'sast_container_head.json',
        sastContainerBasePath: 'sast_container_base.json',
        dependencyScanningHeadPath: 'dss_head.json',
        dependencyScanningBasePath: 'dss_base.json',
        sastHelpPath: 'path',
        sastContainerHelpPath: 'path',
        dastHelpPath: 'path',
        dependencyScanningHelpPath: 'path',
        vulnerabilityFeedbackPath: 'vulnerability_feedback_path.json',
        vulnerabilityFeedbackHelpPath: 'path',
        pipelineId: 123,
        canCreateIssue: true,
        canCreateMergeRequest: true,
        canDismissVulnerability: true,
      });

      Promise.all([
        waitForMutation(vm.$store, `sast/${sastTypes.RECEIVE_REPORTS}`),
        waitForMutation(vm.$store, types.RECEIVE_DAST_REPORTS),
        waitForMutation(vm.$store, types.RECEIVE_SAST_CONTAINER_REPORTS),
        waitForMutation(vm.$store, types.RECEIVE_DEPENDENCY_SCANNING_REPORTS),
      ])
        .then(done)
        .catch();
    });

    it('renders reports', () => {
      // It's not loading
      expect(vm.$el.querySelector('.gl-spinner')).toBeNull();

      // Renders the summary text
      expect(vm.$el.querySelector('.js-code-text').textContent.trim()).toEqual(
        'Security scanning detected 6 new, and 3 fixed vulnerabilities',
      );

      // Renders the expand button
      expect(vm.$el.querySelector('.js-collapse-btn').textContent.trim()).toEqual('Expand');

      // Renders Sast result
      expect(trimText(vm.$el.textContent)).toContain(
        'SAST detected 2 new, and 1 fixed vulnerabilities',
      );

      // Renders DSS result
      expect(trimText(vm.$el.textContent)).toContain(
        'Dependency scanning detected 2 new, and 1 fixed vulnerabilities',
      );

      // Renders container scanning result
      expect(vm.$el.textContent).toContain(
        'Container scanning detected 1 new, and 1 fixed vulnerabilities',
      );

      // Renders DAST result
      expect(vm.$el.textContent).toContain('DAST detected 1 new vulnerability');
    });

    it('opens modal with more information', done => {
      setTimeout(() => {
        vm.$el.querySelector('.break-link').click();

        Vue.nextTick(() => {
          expect(vm.$el.querySelector('.modal-title').textContent.trim()).toEqual(
            sastIssues[0].message,
          );

          expect(vm.$el.querySelector('.modal-body').textContent).toContain(sastIssues[0].solution);

          done();
        });
      }, 0);
    });

    it('has the success icon for fixed vulnerabilities', done => {
      setTimeout(() => {
        const icon = vm.$el.querySelector(
          '.js-sast-container~.js-plain-element .ic-status_success_borderless',
        );

        expect(icon).not.toBeNull();
        done();
      }, 0);
    });
  });

  describe('with the pipelinePath prop', () => {
    const pipelinePath = '/path/to/the/pipeline';

    beforeEach(() => {
      vm = mountComponent(Component, {
        headBlobPath: 'path',
        canCreateIssue: false,
        canCreateMergeRequest: false,
        canDismissVulnerability: false,
        pipelinePath,
      });
    });

    it('should calculate the security tab path', () => {
      expect(vm.securityTab).toEqual(`${pipelinePath}/security`);
    });
  });

  describe('with the reports API enabled', () => {
    describe('container scanning reports', () => {
      const sastContainerEndpoint = 'sast_container.json';

      beforeEach(done => {
        gon.features = gon.features || {};
        gon.features.containerScanningMergeRequestReportApi = true;

        gl.mrWidgetData = gl.mrWidgetData || {};
        gl.mrWidgetData.container_scanning_comparison_path = sastContainerEndpoint;

        mock.onGet(sastContainerEndpoint).reply(200, {
          added: [dockerReport.vulnerabilities[0], dockerReport.vulnerabilities[1]],
          fixed: [dockerReport.vulnerabilities[2]],
        });

        mock.onGet('vulnerability_feedback_path.json').reply(200, []);

        vm = mountComponent(Component, {
          headBlobPath: 'path',
          baseBlobPath: 'path',
          sastHelpPath: 'path',
          sastContainerHelpPath: 'path',
          dastHelpPath: 'path',
          dependencyScanningHelpPath: 'path',
          vulnerabilityFeedbackPath: 'vulnerability_feedback_path.json',
          vulnerabilityFeedbackHelpPath: 'path',
          pipelineId: 123,
          canCreateIssue: true,
          canCreateMergeRequest: true,
          canDismissVulnerability: true,
        });

        waitForMutation(vm.$store, types.RECEIVE_SAST_CONTAINER_DIFF_SUCCESS)
          .then(done)
          .catch(done.fail);
      });

      it('should set setSastContainerDiffEndpoint', () => {
        expect(vm.sastContainer.paths.diffEndpoint).toEqual(sastContainerEndpoint);
      });

      it('should display the correct numbers of vulnerabilities', () => {
        expect(vm.$el.textContent).toContain(
          'Container scanning detected 2 new, and 1 fixed vulnerabilities',
        );
      });
    });

    describe('dependency scanning reports', () => {
      const dependencyScanningEndpoint = 'dependency_scanning.json';

      beforeEach(done => {
        gon.features = gon.features || {};
        gon.features.dependencyScanningMergeRequestReportApi = true;

        gl.mrWidgetData = gl.mrWidgetData || {};
        gl.mrWidgetData.dependency_scanning_comparison_path = dependencyScanningEndpoint;

        mock.onGet(dependencyScanningEndpoint).reply(200, {
          added: [dockerReport.vulnerabilities[0], dockerReport.vulnerabilities[1]],
          fixed: [dockerReport.vulnerabilities[2]],
        });

        mock.onGet('vulnerability_feedback_path.json').reply(200, []);

        vm = mountComponent(Component, {
          headBlobPath: 'path',
          baseBlobPath: 'path',
          sastHelpPath: 'path',
          sastContainerHelpPath: 'path',
          dastHelpPath: 'path',
          dependencyScanningHelpPath: 'path',
          vulnerabilityFeedbackPath: 'vulnerability_feedback_path.json',
          vulnerabilityFeedbackHelpPath: 'path',
          pipelineId: 123,
          canCreateIssue: true,
          canCreateMergeRequest: true,
          canDismissVulnerability: true,
        });

        waitForMutation(vm.$store, types.RECEIVE_DEPENDENCY_SCANNING_DIFF_SUCCESS)
          .then(done)
          .catch();
      });

      it('should set setDependencyScanningDiffEndpoint', () => {
        expect(vm.dependencyScanning.paths.diffEndpoint).toEqual(dependencyScanningEndpoint);
      });

      it('should display the correct numbers of vulnerabilities', () => {
        expect(vm.$el.textContent).toContain(
          'Dependency scanning detected 2 new, and 1 fixed vulnerabilities',
        );
      });
    });

    describe('dast reports', () => {
      const dastEndpoint = 'dast.json';

      beforeEach(done => {
        gon.features = gon.features || {};
        gon.features.dastMergeRequestReportApi = true;

        gl.mrWidgetData = gl.mrWidgetData || {};
        gl.mrWidgetData.dast_comparison_path = dastEndpoint;

        mock.onGet(dastEndpoint).reply(200, {
          added: [dockerReport.vulnerabilities[0]],
          fixed: [dockerReport.vulnerabilities[1], dockerReport.vulnerabilities[2]],
        });

        mock.onGet('vulnerability_feedback_path.json').reply(200, []);

        vm = mountComponent(Component, {
          headBlobPath: 'path',
          baseBlobPath: 'path',
          sastHelpPath: 'path',
          sastContainerHelpPath: 'path',
          dastHelpPath: 'path',
          dependencyScanningHelpPath: 'path',
          vulnerabilityFeedbackPath: 'vulnerability_feedback_path.json',
          vulnerabilityFeedbackHelpPath: 'path',
          pipelineId: 123,
          canCreateIssue: true,
          canCreateMergeRequest: true,
          canDismissVulnerability: true,
        });

        waitForMutation(vm.$store, types.RECEIVE_DAST_DIFF_SUCCESS)
          .then(done)
          .catch(done.fail);
      });

      it('should set setDastDiffEndpoint', () => {
        expect(vm.dast.paths.diffEndpoint).toEqual(dastEndpoint);
      });

      it('should display the correct numbers of vulnerabilities', () => {
        expect(vm.$el.textContent).toContain('DAST detected 1 new, and 2 fixed vulnerabilities');
      });
    });

    describe('sast reports', () => {
      const sastEndpoint = 'sast.json';

      beforeEach(done => {
        gon.features = gon.features || {};
        gon.features.sastMergeRequestReportApi = true;

        gl.mrWidgetData = gl.mrWidgetData || {};
        gl.mrWidgetData.sast_comparison_path = sastEndpoint;

        mock.onGet(sastEndpoint).reply(200, {
          added: [dockerReport.vulnerabilities[0]],
          fixed: [dockerReport.vulnerabilities[1], dockerReport.vulnerabilities[2]],
          existing: [dockerReport.vulnerabilities[2]],
        });

        mock.onGet('vulnerability_feedback_path.json').reply(200, []);

        vm = mountComponent(Component, {
          headBlobPath: 'path',
          baseBlobPath: 'path',
          sastHelpPath: 'path',
          sastContainerHelpPath: 'path',
          dastHelpPath: 'path',
          dependencyScanningHelpPath: 'path',
          vulnerabilityFeedbackPath: 'vulnerability_feedback_path.json',
          vulnerabilityFeedbackHelpPath: 'path',
          pipelineId: 123,
          canCreateIssue: true,
          canCreateMergeRequest: true,
          canDismissVulnerability: true,
        });

        waitForMutation(vm.$store, `sast/${sastTypes.RECEIVE_DIFF_SUCCESS}`)
          .then(done)
          .catch(done.fail);
      });

      it('should set setSastDiffEndpoint', () => {
        expect(vm.sast.paths.diffEndpoint).toEqual(sastEndpoint);
      });

      it('should display the correct numbers of vulnerabilities', () => {
        expect(vm.$el.textContent).toContain('SAST detected 1 new, and 2 fixed vulnerabilities');
      });
    });
  });
});
