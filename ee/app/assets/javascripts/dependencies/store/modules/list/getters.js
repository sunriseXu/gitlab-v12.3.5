import { REPORT_STATUS } from './constants';

export const isJobNotSetUp = state => state.reportInfo.status === REPORT_STATUS.jobNotSetUp;
export const isJobFailed = state =>
  [REPORT_STATUS.jobFailed, REPORT_STATUS.noDependencies].includes(state.reportInfo.status);
export const isIncomplete = state => state.reportInfo.status === REPORT_STATUS.incomplete;

export const downloadEndpoint = ({ endpoint }) => `${endpoint}.json`;
