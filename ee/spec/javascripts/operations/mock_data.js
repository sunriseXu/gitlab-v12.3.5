import { mockProjectData, mockText as text } from 'ee_spec/vue_shared/dashboards/mock_data';

export { mockProjectData } from 'ee_spec/vue_shared/dashboards/mock_data';

export const mockText = {
  ...text,
  ADD_PROJECTS: 'Add projects',
  DASHBOARD_TITLE: 'Operations Dashboard',
  EMPTY_TITLE: 'Add a project to the dashboard',
  EMPTY_SUBTITLE:
    "The operations dashboard provides a summary of each project's operational health, including pipeline and alert statuses. More information",
  EMPTY_SVG_SOURCE: '/assets/illustrations/operations-dashboard_empty.svg',
  SEARCH_PROJECTS: 'Search your projects',
  SEARCH_DESCRIPTION_SUFFIX: 'in projects',
};

export const [mockOneProject] = mockProjectData(1);
