import initFilteredSearch from '~/pages/search/init_filtered_search';
import issuableInitBulkUpdateSidebar from '~/issuable_init_bulk_update_sidebar';
import FilteredSearchTokenKeysEpics from 'ee/filtered_search/filtered_search_token_keys_epics';
import initEpicCreateApp from 'ee/epic/epic_bundle';

const EPIC_BULK_UPDATE_PREFIX = 'epic_';

document.addEventListener('DOMContentLoaded', () => {
  initFilteredSearch({
    page: 'epics',
    isGroup: true,
    isGroupDecendent: true,
    filteredSearchTokenKeys: FilteredSearchTokenKeysEpics,
    stateFiltersSelector: '.epics-state-filters',
  });

  initEpicCreateApp(true);

  issuableInitBulkUpdateSidebar.init(EPIC_BULK_UPDATE_PREFIX);
});
