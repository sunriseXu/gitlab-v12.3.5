import { s__ } from '~/locale';

export default () => ({
  isLoadingVulnerabilities: true,
  errorLoadingVulnerabilities: false,
  vulnerabilities: [],
  isLoadingVulnerabilitiesCount: true,
  errorLoadingVulnerabilitiesCount: false,
  vulnerabilitiesCount: {},
  isLoadingVulnerabilitiesHistory: true,
  errorLoadingVulnerabilitiesHistory: false,
  vulnerabilitiesHistory: {},
  vulnerabilitiesHistoryDayRange: 90,
  vulnerabilitiesHistoryMaxDayInterval: 7,
  pageInfo: {},
  pipelineId: null,
  vulnerabilitiesCountEndpoint: null,
  vulnerabilitiesHistoryEndpoint: null,
  vulnerabilitiesEndpoint: null,
  activeVulnerability: null,
  modal: {
    data: {
      description: { text: s__('Vulnerability|Description') },
      project: {
        text: s__('Vulnerability|Project'),
        isLink: true,
      },
      file: { text: s__('Vulnerability|File') },
      identifiers: { text: s__('Vulnerability|Identifiers') },
      severity: { text: s__('Vulnerability|Severity') },
      confidence: { text: s__('Vulnerability|Confidence') },
      reportType: { text: s__('Vulnerability|Report Type') },
      className: { text: s__('Vulnerability|Class') },
      image: { text: s__('Vulnerability|Image') },
      namespace: { text: s__('Vulnerability|Namespace') },
      links: { text: s__('Vulnerability|Links') },
      instances: { text: s__('Vulnerability|Instances') },
    },
    vulnerability: {},
    isCreatingNewIssue: false,
    isCreatingMergeRequest: false,
    isDismissingVulnerability: false,
    isCommentingOnDismissal: false,
    isShowingDeleteButtons: false,
  },
  isCreatingIssue: false,
  isCreatingMergeRequest: false,
});
