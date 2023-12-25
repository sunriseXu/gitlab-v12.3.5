import Vue from 'vue';
import GroupSecurityDashboardApp from './components/app.vue';
import UnavailableState from './components/unavailable_state.vue';
import createStore from './store';
import router from './store/router';

export default function() {
  const el = document.getElementById('js-group-security-dashboard');
  const { isUnavailable, dashboardDocumentation, emptyStateSvgPath } = el.dataset;

  if (isUnavailable) {
    return new Vue({
      el,
      render(createElement) {
        return createElement(UnavailableState, {
          props: {
            link: dashboardDocumentation,
            svgPath: emptyStateSvgPath,
          },
        });
      },
    });
  }

  const store = createStore();
  return new Vue({
    el,
    store,
    router,
    components: { GroupSecurityDashboardApp },
    render(createElement) {
      return createElement('group-security-dashboard-app', {
        props: {
          dashboardDocumentation: el.dataset.dashboardDocumentation,
          emptyStateSvgPath: el.dataset.emptyStateSvgPath,
          projectsEndpoint: el.dataset.projectsEndpoint,
          vulnerabilityFeedbackHelpPath: el.dataset.vulnerabilityFeedbackHelpPath,
          vulnerabilitiesEndpoint: el.dataset.vulnerabilitiesEndpoint,
          vulnerabilitiesCountEndpoint: el.dataset.vulnerabilitiesSummaryEndpoint,
          vulnerabilitiesHistoryEndpoint: el.dataset.vulnerabilitiesHistoryEndpoint,
        },
      });
    },
  });
}
