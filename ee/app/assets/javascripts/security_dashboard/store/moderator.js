import * as filtersMutationTypes from './modules/filters/mutation_types';
import * as projectsMutationTypes from './modules/projects/mutation_types';
import { BASE_FILTERS } from './modules/filters/constants';

export default function configureModerator(store) {
  store.subscribe(({ type, payload }) => {
    switch (type) {
      case `projects/${projectsMutationTypes.RECEIVE_PROJECTS_SUCCESS}`:
        store.dispatch('filters/setFilterOptions', {
          filterId: 'project_id',
          options: [
            BASE_FILTERS.project_id,
            ...payload.projects.map(project => ({
              name: project.name,
              id: project.id.toString(),
            })),
          ],
        });
        break;
      case `filters/${filtersMutationTypes.SET_ALL_FILTERS}`:
      case `filters/${filtersMutationTypes.SET_FILTER}`:
      case `filters/${filtersMutationTypes.SET_TOGGLE_VALUE}`: {
        const activeFilters = store.getters['filters/activeFilters'];
        store.dispatch('vulnerabilities/fetchVulnerabilities', activeFilters);
        store.dispatch('vulnerabilities/fetchVulnerabilitiesCount', activeFilters);
        store.dispatch('vulnerabilities/fetchVulnerabilitiesHistory', activeFilters);
        break;
      }
      default:
    }
  });
}
