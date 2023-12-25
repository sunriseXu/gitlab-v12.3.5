import initShow from '~/pages/projects/issues/show';
import initSidebarBundle from 'ee/sidebar/sidebar_bundle';
import initRelatedIssues from 'ee/related_issues';
import UserCallout from '~/user_callout';

document.addEventListener('DOMContentLoaded', () => {
  initShow();
  initSidebarBundle();
  initRelatedIssues();

  if (document.getElementById('js-design-management')) {
    import(/* webpackChunkName: 'design_management' */ 'ee/design_management')
      .then(module => module.default())
      .catch(() => {});
  }

  // eslint-disable-next-line no-new
  new UserCallout({ className: 'js-epics-sidebar-callout' });
  // eslint-disable-next-line no-new
  new UserCallout({ className: 'js-weight-sidebar-callout' });
});
