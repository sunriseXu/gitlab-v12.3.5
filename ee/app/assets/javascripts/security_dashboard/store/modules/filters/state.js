import { SEVERITY_LEVELS, CONFIDENCE_LEVELS, REPORT_TYPES, BASE_FILTERS } from './constants';
import { s__ } from '~/locale';

const optionsObjectToArray = obj => Object.entries(obj).map(([id, name]) => ({ id, name }));

export default () => ({
  filters: [
    {
      name: s__('SecurityDashboard|Severity'),
      id: 'severity',
      options: [BASE_FILTERS.severity, ...optionsObjectToArray(SEVERITY_LEVELS)],
      hidden: false,
      selection: new Set(['all']),
    },
    {
      name: s__('SecurityDashboard|Confidence'),
      id: 'confidence',
      options: [BASE_FILTERS.confidence, ...optionsObjectToArray(CONFIDENCE_LEVELS)],
      hidden: false,
      selection: new Set(['all']),
    },
    {
      name: s__('SecurityDashboard|Report type'),
      id: 'report_type',
      options: [BASE_FILTERS.report_type, ...optionsObjectToArray(REPORT_TYPES)],
      hidden: false,
      selection: new Set(['all']),
    },
    {
      name: s__('SecurityDashboard|Project'),
      id: 'project_id',
      options: [BASE_FILTERS.project_id],
      hidden: false,
      selection: new Set(['all']),
    },
  ],
  hide_dismissed: true,
});
