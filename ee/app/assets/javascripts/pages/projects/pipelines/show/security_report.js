import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import createDashboardStore from 'ee/security_dashboard/store';
import SecurityDashboardApp from 'ee/security_dashboard/components/app.vue';
import SecurityReportApp from 'ee/vue_shared/security_reports/split_security_reports_app.vue';
import createStore from 'ee/vue_shared/security_reports/store';
import { updateBadgeCount } from './utils';

Vue.use(Translate);

const initSecurityDashboardApp = el => {
  const {
    dashboardDocumentation,
    emptyStateSvgPath,
    pipelineId,
    projectId,
    vulnerabilitiesEndpoint,
    vulnerabilityFeedbackHelpPath,
  } = el.dataset;

  return new Vue({
    el,
    store: createDashboardStore(),
    render(createElement) {
      return createElement(SecurityDashboardApp, {
        props: {
          dashboardDocumentation,
          emptyStateSvgPath,
          lockToProject: {
            id: parseInt(projectId, 10),
          },
          pipelineId: parseInt(pipelineId, 10),
          vulnerabilitiesEndpoint,
          vulnerabilityFeedbackHelpPath,
        },
        on: {
          vulnerabilitiesCountChanged(count) {
            updateBadgeCount('.js-security-counter', count);
          },
        },
      });
    },
  });
};

const initSplitSecurityReportsApp = el => {
  const datasetOptions = el.dataset;
  const {
    headBlobPath,
    sourceBranch,
    sastHeadPath,
    sastHelpPath,
    dependencyScanningHeadPath,
    dependencyScanningHelpPath,
    vulnerabilityFeedbackPath,
    vulnerabilityFeedbackHelpPath,
    createVulnerabilityFeedbackIssuePath,
    createVulnerabilityFeedbackMergeRequestPath,
    createVulnerabilityFeedbackDismissalPath,
    dastHeadPath,
    sastContainerHeadPath,
    dastHelpPath,
    sastContainerHelpPath,
  } = datasetOptions;
  const pipelineId = parseInt(datasetOptions.pipelineId, 10);

  const store = createStore();

  return new Vue({
    el,
    store,
    components: {
      SecurityReportApp,
    },
    render(createElement) {
      return createElement('security-report-app', {
        props: {
          headBlobPath,
          sourceBranch,
          sastHeadPath,
          sastHelpPath,
          dependencyScanningHeadPath,
          dependencyScanningHelpPath,
          vulnerabilityFeedbackPath,
          vulnerabilityFeedbackHelpPath,
          createVulnerabilityFeedbackIssuePath,
          createVulnerabilityFeedbackMergeRequestPath,
          createVulnerabilityFeedbackDismissalPath,
          pipelineId,
          dastHeadPath,
          sastContainerHeadPath,
          dastHelpPath,
          sastContainerHelpPath,
          canCreateIssue: Boolean(createVulnerabilityFeedbackIssuePath),
          canCreateMergeRequest: Boolean(createVulnerabilityFeedbackMergeRequestPath),
          canDismissVulnerability: Boolean(createVulnerabilityFeedbackDismissalPath),
        },
        on: {
          updateBadgeCount: count => {
            updateBadgeCount('.js-security-counter', count);
          },
        },
      });
    },
  });
};

export default () => {
  const securityTab = document.getElementById('js-security-report-app');

  if (securityTab) {
    if (gon.features && gon.features.pipelineReportApi) {
      initSecurityDashboardApp(securityTab);
    } else {
      initSplitSecurityReportsApp(securityTab);
    }
  }
};
