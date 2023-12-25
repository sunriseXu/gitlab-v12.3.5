import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import mrWidgetOptions from 'ee/vue_merge_request_widget/mr_widget_options.vue';
import MRWidgetService from 'ee/vue_merge_request_widget/services/mr_widget_service';
import MRWidgetStore from 'ee/vue_merge_request_widget/stores/mr_widget_store';
import filterByKey from 'ee/vue_shared/security_reports/store/utils/filter_by_key';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { TEST_HOST } from 'spec/test_constants';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

import state from 'ee/vue_shared/security_reports/store/state';
import mockData, {
  baseIssues,
  headIssues,
  basePerformance,
  headPerformance,
  parsedBaseIssues,
  parsedHeadIssues,
} from 'ee_spec/vue_mr_widget/mock_data';

import {
  sastIssues,
  sastIssuesBase,
  dockerReport,
  dockerBaseReport,
  dast,
  dastBase,
  sastBaseAllIssues,
  sastHeadAllIssues,
} from 'ee_spec/vue_shared/security_reports/mock_data';
import { MTWPS_MERGE_STRATEGY, MT_MERGE_STRATEGY } from '~/vue_merge_request_widget/constants';

describe('ee merge request widget options', () => {
  let vm;
  let mock;
  let Component;

  function removeBreakLine(data) {
    return data
      .replace(/\r?\n|\r/g, '')
      .replace(/\s\s+/g, ' ')
      .trim();
  }

  beforeEach(() => {
    delete mrWidgetOptions.extends.el; // Prevent component mounting

    Component = Vue.extend(mrWidgetOptions);
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    vm.$destroy();
    mock.restore();

    if (Component.mr) {
      // Clean security reports state
      Component.mr.sast = state().sast;
      Component.mr.sastContainer = state().sastContainer;
      Component.mr.dast = state().dast;
      Component.mr.dependencyScanning = state().dependencyScanning;
    }
  });

  describe('security widget', () => {
    beforeEach(() => {
      gl.mrWidgetData = {
        ...mockData,
        sast: {
          base_path: 'path.json',
          head_path: 'head_path.json',
        },
        vulnerability_feedback_path: 'vulnerability_feedback_path',
      };

      Component.mr = new MRWidgetStore(gl.mrWidgetData);
      Component.service = new MRWidgetService({});
    });

    describe('when it is loading', () => {
      it('should render loading indicator', () => {
        mock.onGet('path.json').reply(200, sastBaseAllIssues);
        mock.onGet('head_path.json').reply(200, sastHeadAllIssues);
        mock.onGet('vulnerability_feedback_path').reply(200, []);

        vm = mountComponent(Component);

        expect(vm.$el.querySelector('.js-sast-widget').textContent.trim()).toContain(
          'SAST is loading',
        );
      });
    });

    describe('with successful request', () => {
      beforeEach(() => {
        mock.onGet('path.json').reply(200, sastIssuesBase);
        mock.onGet('head_path.json').reply(200, sastIssues);
        mock.onGet('vulnerability_feedback_path').reply(200, []);
        vm = mountComponent(Component);
      });

      it('should render provided data', done => {
        setTimeout(() => {
          expect(
            removeBreakLine(
              vm.$el.querySelector('.js-sast-widget .report-block-list-issue-description')
                .textContent,
            ),
          ).toEqual('SAST detected 2 new, and 1 fixed vulnerabilities');
          done();
        }, 0);
      });
    });

    describe('with full report and no added or fixed issues', () => {
      beforeEach(() => {
        mock.onGet('path.json').reply(200, sastBaseAllIssues);
        mock.onGet('head_path.json').reply(200, sastBaseAllIssues);
        mock.onGet('vulnerability_feedback_path').reply(200, []);

        vm = mountComponent(Component);
      });

      it('renders no new vulnerabilities message', done => {
        setTimeout(() => {
          expect(
            removeBreakLine(
              vm.$el.querySelector('.js-sast-widget .report-block-list-issue-description')
                .textContent,
            ),
          ).toEqual('SAST detected no new vulnerabilities');
          done();
        }, 0);
      });
    });

    describe('with empty successful request', () => {
      beforeEach(() => {
        mock.onGet('path.json').reply(200, []);
        mock.onGet('head_path.json').reply(200, []);
        mock.onGet('vulnerability_feedback_path').reply(200, []);

        vm = mountComponent(Component);
      });

      it('should render provided data', done => {
        setTimeout(() => {
          expect(
            removeBreakLine(
              vm.$el.querySelector('.js-sast-widget .report-block-list-issue-description')
                .textContent,
            ).trim(),
          ).toEqual('SAST detected no vulnerabilities');
          done();
        }, 0);
      });
    });

    describe('with failed request', () => {
      beforeEach(() => {
        mock.onGet('path.json').reply(500, []);
        mock.onGet('head_path.json').reply(500, []);
        mock.onGet('vulnerability_feedback_path').reply(500, []);

        vm = mountComponent(Component);
      });

      it('should render error indicator', done => {
        setTimeout(() => {
          expect(removeBreakLine(vm.$el.querySelector('.js-sast-widget').textContent)).toContain(
            'SAST: Loading resulted in an error',
          );
          done();
        }, 0);
      });
    });
  });

  describe('dependency scanning widget', () => {
    beforeEach(() => {
      gl.mrWidgetData = {
        ...mockData,
        dependency_scanning: {
          base_path: 'path.json',
          head_path: 'head_path.json',
        },
        vulnerability_feedback_path: 'vulnerability_feedback_path',
      };

      Component.mr = new MRWidgetStore(gl.mrWidgetData);
      Component.service = new MRWidgetService({});
    });

    describe('when it is loading', () => {
      it('should render loading indicator', () => {
        mock.onGet('path.json').reply(200, sastIssuesBase);
        mock.onGet('head_path.json').reply(200, sastIssues);
        mock.onGet('vulnerability_feedback_path').reply(200, []);

        vm = mountComponent(Component);

        expect(
          removeBreakLine(vm.$el.querySelector('.js-dependency-scanning-widget').textContent),
        ).toContain('Dependency scanning is loading');
      });
    });

    describe('with successful request', () => {
      beforeEach(() => {
        mock.onGet('path.json').reply(200, sastIssuesBase);
        mock.onGet('head_path.json').reply(200, sastIssues);
        mock.onGet('vulnerability_feedback_path').reply(200, []);

        vm = mountComponent(Component);
      });

      it('should render provided data', done => {
        setTimeout(() => {
          expect(
            removeBreakLine(
              vm.$el.querySelector(
                '.js-dependency-scanning-widget .report-block-list-issue-description',
              ).textContent,
            ),
          ).toEqual('Dependency scanning detected 2 new, and 1 fixed vulnerabilities');
          done();
        }, 0);
      });
    });

    describe('with full report and no added or fixed issues', () => {
      beforeEach(() => {
        mock.onGet('path.json').reply(200, sastBaseAllIssues);
        mock.onGet('head_path.json').reply(200, sastBaseAllIssues);
        mock.onGet('vulnerability_feedback_path').reply(200, []);

        vm = mountComponent(Component);
      });

      it('renders no new vulnerabilities message', done => {
        setTimeout(() => {
          expect(
            removeBreakLine(
              vm.$el.querySelector(
                '.js-dependency-scanning-widget .report-block-list-issue-description',
              ).textContent,
            ),
          ).toEqual('Dependency scanning detected no new vulnerabilities');
          done();
        }, 0);
      });
    });

    describe('with empty successful request', () => {
      beforeEach(() => {
        mock.onGet('path.json').reply(200, []);
        mock.onGet('head_path.json').reply(200, []);
        mock.onGet('vulnerability_feedback_path').reply(200, []);

        vm = mountComponent(Component);
      });

      it('should render provided data', done => {
        setTimeout(() => {
          expect(
            removeBreakLine(
              vm.$el.querySelector(
                '.js-dependency-scanning-widget .report-block-list-issue-description',
              ).textContent,
            ),
          ).toEqual('Dependency scanning detected no vulnerabilities');
          done();
        }, 0);
      });
    });

    describe('with failed request', () => {
      beforeEach(() => {
        mock.onGet('path.json').reply(500, []);
        mock.onGet('head_path.json').reply(500, []);
        mock.onGet('vulnerability_feedback_path').reply(500, []);

        vm = mountComponent(Component);
      });

      it('should render error indicator', done => {
        setTimeout(() => {
          expect(
            removeBreakLine(vm.$el.querySelector('.js-dependency-scanning-widget').textContent),
          ).toContain('Dependency scanning: Loading resulted in an error');
          done();
        }, 0);
      });
    });
  });

  describe('code quality', () => {
    beforeEach(() => {
      gl.mrWidgetData = {
        ...mockData,
        codeclimate: {
          head_path: 'head.json',
          base_path: 'base.json',
        },
      };

      Component.mr = new MRWidgetStore(gl.mrWidgetData);
      Component.service = new MRWidgetService({});
    });

    describe('when it is loading', () => {
      it('should render loading indicator', () => {
        mock.onGet('head.json').reply(200, headIssues);
        mock.onGet('base.json').reply(200, baseIssues);
        vm = mountComponent(Component);

        expect(
          removeBreakLine(vm.$el.querySelector('.js-codequality-widget').textContent),
        ).toContain('Loading codeclimate report');
      });
    });

    describe('with successful request', () => {
      beforeEach(() => {
        mock.onGet('head.json').reply(200, headIssues);
        mock.onGet('base.json').reply(200, baseIssues);
        vm = mountComponent(Component);

        // mock worker response
        spyOn(MRWidgetStore, 'doCodeClimateComparison').and.callFake(() =>
          Promise.resolve({
            newIssues: filterByKey(parsedHeadIssues, parsedBaseIssues, 'fingerprint'),
            resolvedIssues: filterByKey(parsedBaseIssues, parsedHeadIssues, 'fingerprint'),
          }),
        );
      });

      it('should render provided data', done => {
        setTimeout(() => {
          expect(
            removeBreakLine(
              vm.$el.querySelector('.js-codequality-widget .js-code-text').textContent,
            ),
          ).toEqual('Code quality improved on 1 point and degraded on 1 point');
          done();
        }, 0);
      });

      describe('text connector', () => {
        it('should only render information about fixed issues', done => {
          setTimeout(() => {
            vm.mr.codeclimateMetrics.newIssues = [];

            Vue.nextTick(() => {
              expect(
                removeBreakLine(
                  vm.$el.querySelector('.js-codequality-widget .js-code-text').textContent,
                ),
              ).toEqual('Code quality improved on 1 point');
              done();
            });
          }, 0);
        });

        it('should only render information about added issues', done => {
          setTimeout(() => {
            vm.mr.codeclimateMetrics.resolvedIssues = [];
            Vue.nextTick(() => {
              expect(
                removeBreakLine(
                  vm.$el.querySelector('.js-codequality-widget .js-code-text').textContent,
                ),
              ).toEqual('Code quality degraded on 1 point');
              done();
            });
          }, 0);
        });
      });
    });

    describe('with empty successful request', () => {
      beforeEach(() => {
        mock.onGet('head.json').reply(200, []);
        mock.onGet('base.json').reply(200, []);
        vm = mountComponent(Component);

        // mock worker response
        spyOn(MRWidgetStore, 'doCodeClimateComparison').and.callFake(() =>
          Promise.resolve({
            newIssues: filterByKey([], [], 'fingerprint'),
            resolvedIssues: filterByKey([], [], 'fingerprint'),
          }),
        );
      });

      afterEach(() => {
        mock.restore();
      });

      it('should render provided data', done => {
        setTimeout(() => {
          expect(
            removeBreakLine(
              vm.$el.querySelector('.js-codequality-widget .js-code-text').textContent,
            ),
          ).toEqual('No changes to code quality');
          done();
        }, 0);
      });
    });

    describe('with codeclimate comparison worker rejection', () => {
      beforeEach(() => {
        mock.onGet('head.json').reply(200, headIssues);
        mock.onGet('base.json').reply(200, baseIssues);
        vm = mountComponent(Component);

        // mock worker rejection
        spyOn(MRWidgetStore, 'doCodeClimateComparison').and.callFake(() => Promise.reject());
      });

      it('should render error indicator', done => {
        setTimeout(() => {
          expect(
            removeBreakLine(
              vm.$el.querySelector('.js-codequality-widget .js-code-text').textContent,
            ),
          ).toEqual('Failed to load codeclimate report');
          done();
        }, 0);
      });
    });

    describe('with failed request', () => {
      beforeEach(() => {
        mock.onGet('head.json').reply(500, []);
        mock.onGet('base.json').reply(500, []);
        vm = mountComponent(Component);
      });

      it('should render error indicator', done => {
        setTimeout(() => {
          expect(
            removeBreakLine(
              vm.$el.querySelector('.js-codequality-widget .js-code-text').textContent,
            ),
          ).toContain('Failed to load codeclimate report');
          done();
        }, 0);
      });
    });
  });

  describe('performance', () => {
    beforeEach(() => {
      gl.mrWidgetData = {
        ...mockData,
        performance: {
          head_path: 'head.json',
          base_path: 'base.json',
        },
      };

      Component.mr = new MRWidgetStore(gl.mrWidgetData);
      Component.service = new MRWidgetService({});
    });

    describe('when it is loading', () => {
      it('should render loading indicator', () => {
        mock.onGet('head.json').reply(200, headPerformance);
        mock.onGet('base.json').reply(200, basePerformance);
        vm = mountComponent(Component);

        expect(
          removeBreakLine(vm.$el.querySelector('.js-performance-widget').textContent),
        ).toContain('Loading performance report');
      });
    });

    describe('with successful request', () => {
      beforeEach(() => {
        mock.onGet('head.json').reply(200, headPerformance);
        mock.onGet('base.json').reply(200, basePerformance);
        vm = mountComponent(Component);
      });

      it('should render provided data', done => {
        setTimeout(() => {
          expect(
            removeBreakLine(
              vm.$el.querySelector('.js-performance-widget .js-code-text').textContent,
            ),
          ).toEqual('Performance metrics improved on 2 points and degraded on 1 point');
          done();
        }, 0);
      });

      describe('text connector', () => {
        it('should only render information about fixed issues', done => {
          setTimeout(() => {
            vm.mr.performanceMetrics.degraded = [];

            Vue.nextTick(() => {
              expect(
                removeBreakLine(
                  vm.$el.querySelector('.js-performance-widget .js-code-text').textContent,
                ),
              ).toEqual('Performance metrics improved on 2 points');
              done();
            });
          }, 0);
        });

        it('should only render information about added issues', done => {
          setTimeout(() => {
            vm.mr.performanceMetrics.improved = [];

            Vue.nextTick(() => {
              expect(
                removeBreakLine(
                  vm.$el.querySelector('.js-performance-widget .js-code-text').textContent,
                ),
              ).toEqual('Performance metrics degraded on 1 point');
              done();
            });
          }, 0);
        });
      });
    });

    describe('with empty successful request', () => {
      beforeEach(done => {
        mock.onGet('head.json').reply(200, []);
        mock.onGet('base.json').reply(200, []);
        vm = mountComponent(Component);
        // wait for network request from component created() method
        setTimeout(done, 0);
      });

      it('should render provided data', () => {
        expect(
          removeBreakLine(vm.$el.querySelector('.js-performance-widget .js-code-text').textContent),
        ).toEqual('No changes to performance metrics');
      });

      it('does not show Expand button', () => {
        const expandButton = vm.$el.querySelector('.js-performance-widget .js-collapse-btn');

        expect(expandButton).toBeNull();
      });

      it('shows success icon', () => {
        expect(
          vm.$el.querySelector('.js-performance-widget .js-ci-status-icon-success'),
        ).not.toBeNull();
      });
    });

    describe('with failed request', () => {
      beforeEach(() => {
        mock.onGet('head.json').reply(500, []);
        mock.onGet('base.json').reply(500, []);
        vm = mountComponent(Component);
      });

      it('should render error indicator', done => {
        setTimeout(() => {
          expect(
            removeBreakLine(
              vm.$el.querySelector('.js-performance-widget .js-code-text').textContent,
            ),
          ).toContain('Failed to load performance report');
          done();
        }, 0);
      });
    });
  });

  describe('sast container report', () => {
    beforeEach(() => {
      gl.mrWidgetData = {
        ...mockData,
        sast_container: {
          head_path: 'gl-sast-container.json',
          base_path: 'sast-container-base.json',
        },
        vulnerability_feedback_path: 'vulnerability_feedback_path',
      };

      Component.mr = new MRWidgetStore(gl.mrWidgetData);
      Component.service = new MRWidgetService({});
    });

    describe('when it is loading', () => {
      it('should render loading indicator', () => {
        mock.onGet('gl-sast-container.json').reply(200, dockerReport);
        mock.onGet('sast-container-base.json').reply(200, dockerBaseReport);
        mock.onGet('vulnerability_feedback_path').reply(200, []);

        vm = mountComponent(Component);

        expect(removeBreakLine(vm.$el.querySelector('.js-sast-container').textContent)).toContain(
          'Container scanning is loading',
        );
      });
    });

    describe('with successful request', () => {
      beforeEach(() => {
        mock.onGet('gl-sast-container.json').reply(200, dockerReport);
        mock.onGet('sast-container-base.json').reply(200, dockerBaseReport);
        mock.onGet('vulnerability_feedback_path').reply(200, []);

        vm = mountComponent(Component);
      });

      it('should render provided data', done => {
        setTimeout(() => {
          expect(
            removeBreakLine(
              vm.$el.querySelector('.js-sast-container .report-block-list-issue-description')
                .textContent,
            ),
          ).toEqual('Container scanning detected 1 new, and 1 fixed vulnerabilities');
          done();
        }, 0);
      });
    });

    describe('with failed request', () => {
      beforeEach(() => {
        mock.onGet('gl-sast-container.json').reply(500, {});
        mock.onGet('sast-container-base.json').reply(500, {});
        mock.onGet('vulnerability_feedback_path').reply(500, []);

        vm = mountComponent(Component);
      });

      it('should render error indicator', done => {
        setTimeout(() => {
          expect(vm.$el.querySelector('.js-sast-container').textContent.trim()).toContain(
            'Container scanning: Loading resulted in an error',
          );
          done();
        }, 0);
      });
    });
  });

  describe('dast report', () => {
    beforeEach(() => {
      gl.mrWidgetData = {
        ...mockData,
        dast: {
          head_path: 'dast.json',
          base_path: 'dast_base.json',
        },
        vulnerability_feedback_path: 'vulnerability_feedback_path',
      };

      Component.mr = new MRWidgetStore(gl.mrWidgetData);
      Component.service = new MRWidgetService({});
    });

    describe('when it is loading', () => {
      it('should render loading indicator', () => {
        mock.onGet('dast.json').reply(200, dast);
        mock.onGet('dast_base.json').reply(200, dastBase);
        mock.onGet('vulnerability_feedback_path').reply(200, []);

        vm = mountComponent(Component);

        expect(vm.$el.querySelector('.js-dast-widget').textContent.trim()).toContain(
          'DAST is loading',
        );
      });
    });

    describe('with successful request', () => {
      beforeEach(() => {
        mock.onGet('dast.json').reply(200, dast);
        mock.onGet('dast_base.json').reply(200, dastBase);
        mock.onGet('vulnerability_feedback_path').reply(200, []);

        vm = mountComponent(Component);
      });

      it('should render provided data', done => {
        setTimeout(() => {
          expect(
            vm.$el
              .querySelector('.js-dast-widget .report-block-list-issue-description')
              .textContent.trim(),
          ).toEqual('DAST detected 1 new vulnerability');
          done();
        }, 0);
      });
    });

    describe('with failed request', () => {
      beforeEach(() => {
        mock.onGet('dast.json').reply(500, {});
        mock.onGet('dast_base.json').reply(500, {});
        mock.onGet('vulnerability_feedback_path').reply(500, []);

        vm = mountComponent(Component);
      });

      it('should render error indicator', done => {
        setTimeout(() => {
          expect(vm.$el.querySelector('.js-dast-widget').textContent.trim()).toContain(
            'DAST: Loading resulted in an error',
          );
          done();
        }, 0);
      });
    });
  });

  describe('license management report', () => {
    const headPath = `${TEST_HOST}/head.json`;
    const basePath = `${TEST_HOST}/base.json`;
    const licenseManagementApiUrl = `${TEST_HOST}/manage_license_api`;

    it('should be rendered if license management data is set', () => {
      gl.mrWidgetData = {
        ...mockData,
        license_management: {
          head_path: headPath,
          base_path: basePath,
          managed_licenses_path: licenseManagementApiUrl,
          can_manage_licenses: false,
        },
      };

      Component.mr = new MRWidgetStore(gl.mrWidgetData);
      Component.service = new MRWidgetService({});
      vm = mountComponent(Component);

      expect(vm.$el.querySelector('.license-report-widget')).not.toBeNull();
    });

    it('should not be rendered if license management data is not set', () => {
      gl.mrWidgetData = {
        ...mockData,
        license_management: {},
      };

      Component.mr = new MRWidgetStore(gl.mrWidgetData);
      Component.service = new MRWidgetService({});
      vm = mountComponent(Component);

      expect(vm.$el.querySelector('.license-report-widget')).toBeNull();
    });
  });

  describe('computed', () => {
    describe('shouldRenderApprovals', () => {
      it('should return false when no approvals', () => {
        vm = mountComponent(Component, {
          mrData: {
            ...mockData,
            has_approvals_available: false,
          },
        });
        vm.mr.state = 'readyToMerge';

        expect(vm.shouldRenderApprovals).toBeFalsy();
      });

      it('should return false when in empty state', () => {
        vm = mountComponent(Component, {
          mrData: {
            ...mockData,
            has_approvals_available: true,
          },
        });
        vm.mr.state = 'nothingToMerge';

        expect(vm.shouldRenderApprovals).toBeFalsy();
      });

      it('should return true when requiring approvals and in non-empty state', () => {
        vm = mountComponent(Component, {
          mrData: {
            ...mockData,
            has_approvals_available: true,
          },
        });
        vm.mr.state = 'readyToMerge';

        expect(vm.shouldRenderApprovals).toBeTruthy();
      });
    });

    describe('shouldRenderMergeTrainHelperText', () => {
      it('should return true if MTWPS is available and the user has not yet pressed the MTWPS button', () => {
        vm = mountComponent(Component, {
          mrData: {
            ...mockData,
            available_auto_merge_strategies: [MTWPS_MERGE_STRATEGY],
            auto_merge_enabled: false,
          },
        });

        expect(vm.shouldRenderMergeTrainHelperText).toBe(true);
      });
    });
  });

  describe('rendering source branch removal status', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        mrData: {
          ...mockData,
        },
      });
    });

    it('renders when user cannot remove branch and branch should be removed', done => {
      vm.mr.canRemoveSourceBranch = false;
      vm.mr.shouldRemoveSourceBranch = true;
      vm.mr.state = 'readyToMerge';

      vm.$nextTick(() => {
        const tooltip = vm.$el.querySelector('.fa-question-circle');

        expect(vm.$el.textContent).toContain('Deletes source branch');
        expect(tooltip.getAttribute('data-original-title')).toBe(
          'A user with write access to the source branch selected this option',
        );

        done();
      });
    });

    it('does not render in merged state', done => {
      vm.mr.canRemoveSourceBranch = false;
      vm.mr.shouldRemoveSourceBranch = true;
      vm.mr.state = 'merged';

      vm.$nextTick(() => {
        expect(vm.$el.textContent).toContain('The source branch has been deleted');
        expect(vm.$el.textContent).not.toContain('Removes source branch');

        done();
      });
    });
  });

  describe('rendering deployments', () => {
    const deploymentMockData = {
      id: 15,
      name: 'review/diplo',
      url: '/root/acets-review-apps/environments/15',
      stop_url: '/root/acets-review-apps/environments/15/stop',
      metrics_url: '/root/acets-review-apps/environments/15/deployments/1/metrics',
      metrics_monitoring_url: '/root/acets-review-apps/environments/15/metrics',
      external_url: 'http://diplo.',
      external_url_formatted: 'diplo.',
      deployed_at: '2017-03-22T22:44:42.258Z',
      deployed_at_formatted: 'Mar 22, 2017 10:44pm',
    };

    beforeEach(done => {
      vm = mountComponent(Component, {
        mrData: {
          ...mockData,
        },
      });

      vm.mr.deployments.push(
        {
          ...deploymentMockData,
        },
        {
          ...deploymentMockData,
          id: deploymentMockData.id + 1,
        },
      );

      vm.$nextTick(done);
    });

    it('renders multiple deployments', () => {
      expect(vm.$el.querySelectorAll('.deploy-heading').length).toBe(2);
    });
  });

  describe('CI widget', () => {
    it('renders the branch in the pipeline widget', () => {
      const sourceBranchLink = '<a href="https://www.zelda.com/">Link</a>';
      vm = mountComponent(Component, {
        mrData: {
          ...mockData,
          source_branch_with_namespace_link: sourceBranchLink,
        },
      });

      const ciWidget = vm.$el.querySelector('.mr-state-widget .label-branch');

      expect(ciWidget).toContainHtml(sourceBranchLink);
    });
  });

  describe('merge train helper text', () => {
    const getHelperTextElement = () => vm.$el.querySelector('.js-merge-train-helper-text');

    it('does not render the merge train helpe text if the MTWPS strategy is not available', () => {
      vm = mountComponent(Component, {
        mrData: {
          ...mockData,
          available_auto_merge_strategies: [MT_MERGE_STRATEGY],
          pipeline: {
            ...mockData.pipeline,
            active: true,
          },
        },
      });

      const helperText = getHelperTextElement();

      expect(helperText).not.toExist();
    });

    it('renders the correct merge train helper text when there is an existing merge train', () => {
      vm = mountComponent(Component, {
        mrData: {
          ...mockData,
          available_auto_merge_strategies: [MTWPS_MERGE_STRATEGY],
          merge_trains_count: 2,
          merge_train_when_pipeline_succeeds_docs_path: 'path/to/help',
          pipeline: {
            ...mockData.pipeline,
            id: 123,
            active: true,
          },
        },
      });

      const helperText = getHelperTextElement();

      expect(helperText).toExist();
      expect(helperText).toContainText(
        'This merge request will be added to the merge train when pipeline #123 succeeds.',
      );
    });

    it('renders the correct merge train helper text when there is no existing merge train', () => {
      vm = mountComponent(Component, {
        mrData: {
          ...mockData,
          available_auto_merge_strategies: [MTWPS_MERGE_STRATEGY],
          merge_trains_count: 0,
          merge_train_when_pipeline_succeeds_docs_path: 'path/to/help',
          pipeline: {
            ...mockData.pipeline,
            id: 123,
            active: true,
          },
        },
      });

      const helperText = getHelperTextElement();

      expect(helperText).toExist();
      expect(helperText).toContainText(
        'This merge request will start a merge train when pipeline #123 succeeds.',
      );
    });

    it('renders the correct pipeline link inside the message', () => {
      vm = mountComponent(Component, {
        mrData: {
          ...mockData,
          available_auto_merge_strategies: [MTWPS_MERGE_STRATEGY],
          merge_train_when_pipeline_succeeds_docs_path: 'path/to/help',
          pipeline: {
            ...mockData.pipeline,
            id: 123,
            path: 'path/to/pipeline',
            active: true,
          },
        },
      });

      const pipelineLink = getHelperTextElement().querySelector('.js-pipeline-link');

      expect(pipelineLink).toExist();
      expect(pipelineLink).toContainText('#123');
      expect(pipelineLink).toHaveAttr('href', 'path/to/pipeline');
    });

    it('renders the documentation link inside the message', () => {
      vm = mountComponent(Component, {
        mrData: {
          ...mockData,
          available_auto_merge_strategies: [MTWPS_MERGE_STRATEGY],
          merge_train_when_pipeline_succeeds_docs_path: 'path/to/help',
          pipeline: {
            ...mockData.pipeline,
            active: true,
          },
        },
      });

      const pipelineLink = getHelperTextElement().querySelector('.js-documentation-link');

      expect(pipelineLink).toExist();
      expect(pipelineLink).toContainText('More information');
      expect(pipelineLink).toHaveAttr('href', 'path/to/help');
    });
  });

  describe('data', () => {
    it('passes approval api paths to service', () => {
      const paths = {
        api_approvals_path: `${TEST_HOST}/api/approvals/path`,
        api_approval_settings_path: `${TEST_HOST}/api/approval/settings/path`,
        api_approve_path: `${TEST_HOST}/api/approve/path`,
        api_unapprove_path: `${TEST_HOST}/api/unapprove/path`,
      };

      vm = mountComponent(Component, {
        mrData: {
          ...mockData,
          ...paths,
        },
      });

      expect(vm.service).toEqual(jasmine.objectContaining(convertObjectPropsToCamelCase(paths)));
    });
  });
});
