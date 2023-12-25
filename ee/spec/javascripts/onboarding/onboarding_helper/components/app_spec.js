import Vue from 'vue';
import OnboardingHelperApp from 'ee/onboarding/onboarding_helper/components/app.vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import eventHub from 'ee/onboarding/onboarding_helper/event_hub';
import createStore from 'ee/onboarding/onboarding_helper/store';
import actionPopoverUtils from 'ee/onboarding/onboarding_helper/action_popover_utils';
import { mockTourData } from '../mock_data';

describe('User onboarding helper app', () => {
  let vm;
  let store;
  const initialData = {
    url: 'http://gitlab-org/gitlab-test/foo',
    projectFullPath: 'http://gitlab-org/gitlab-test',
    projectName: 'Mock Project',
    tourData: mockTourData,
    tourKey: 1,
    lastStepIndex: -1,
    createdProjectPath: '',
  };
  const tourTitles = [{ id: 1, title: 'First tour' }, { id: 2, title: 'Second tour' }];
  const exitTourContent = {
    text: 'feedback content',
    feedbackButtons: true,
    feedbackSize: 5,
  };
  const feedbackContent = {
    text: 'exit tour content',
    buttons: [{ text: 'OK', btnClass: 'btn-primary' }],
  };

  const defaultProps = {
    tourTitles,
    exitTourContent,
    feedbackContent,
    goldenTanukiSvgPath: 'illustrations/golden_tanuki.svg',
  };

  const createComponent = ({ props = defaultProps } = {}) => {
    const Component = Vue.extend(OnboardingHelperApp);

    store = createStore();
    store.dispatch('setInitialData', initialData);

    return mountComponentWithStore(Component, { props, store });
  };

  beforeEach(() => {
    vm = createComponent();

    spyOn(vm, 'init');

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('helpContentData', () => {
      it('returns an object containing the help content data', () => {
        const helpContent = mockTourData[initialData.tourKey][0].getHelpContent()[0];

        expect(vm.helpContentData).toEqual(helpContent);
      });

      it('returns null if showStepContent is false', () => {
        vm.showStepContent = false;

        expect(vm.helpContentData).toBeNull();
      });

      it('returns an object containing exit tour content if exitTour is true', () => {
        store.dispatch('setExitTour', true);

        expect(vm.helpContentData).toEqual(exitTourContent);
      });

      it('returns an object containing tour feedback content if tourFeedback is true', () => {
        store.dispatch('setTourFeedback', true);

        expect(vm.helpContentData).toEqual(feedbackContent);
      });
    });

    describe('completedSteps', () => {
      it('returns 3 if the lastStepIndex is 1', () => {
        vm.$store.state.lastStepIndex = 3;

        expect(vm.completedSteps).toBe(3);
      });

      it('returns 0 if the lastStepIndex is -1', () => {
        vm.$store.state.lastStepIndex = -1;

        expect(vm.completedSteps).toBe(0);
      });
    });
  });

  describe('mounted', () => {
    it('calls the init method', () => {
      expect(vm.init).toHaveBeenCalled();
      expect(vm.showStepContent).toBe(true);
    });
  });

  describe('methods', () => {
    describe('initActionPopover', () => {
      it('calls renderPopover with the correct data', () => {
        spyOn(actionPopoverUtils, 'renderPopover');

        const expected = {
          selector: '.popup-trigger',
          text: 'foo',
          placement: 'top',
          showPopover: false,
        };

        const { selector, text, placement, showPopover } = expected;

        vm.initActionPopover();

        expect(actionPopoverUtils.renderPopover).toHaveBeenCalledWith(
          selector,
          text,
          placement,
          showPopover,
        );
      });

      it('calls renderPopover with showPopover=true if there is no helpContent data and no popover selector for the current url', () => {
        spyOn(actionPopoverUtils, 'renderPopover');

        vm.$store.state.url = 'http://gitlab-org/gitlab-test/xyz';

        const expected = {
          selector: null,
          text: 'foo',
          placement: 'top',
          showPopover: true,
        };

        const { selector, text, placement, showPopover } = expected;

        vm.initActionPopover();

        expect(actionPopoverUtils.renderPopover).toHaveBeenCalledWith(
          selector,
          text,
          placement,
          showPopover,
        );
      });
    });

    describe('showActionPopover', () => {
      it('emits the "onboardingHelper.showActionPopover" event', () => {
        spyOn(eventHub, '$emit');

        vm.showActionPopover();

        expect(eventHub.$emit).toHaveBeenCalledWith('onboardingHelper.showActionPopover');
      });
    });

    describe('hideActionPopover', () => {
      it('emits the "onboardingHelper.hideActionPopover" event', () => {
        spyOn(eventHub, '$emit');

        vm.hideActionPopover();

        expect(eventHub.$emit).toHaveBeenCalledWith('onboardingHelper.hideActionPopover');
      });
    });

    describe('handleRestartStep', () => {
      it('calls the "showExitTourContent" and "handleFeedbackTourContent" methods', () => {
        spyOn(vm, 'showExitTourContent');
        spyOn(vm, 'handleFeedbackTourContent');

        vm.handleRestartStep();

        expect(vm.showExitTourContent).toHaveBeenCalledWith(false);
        expect(vm.handleFeedbackTourContent).toHaveBeenCalledWith(false);
      });

      it('emits the "onboardingHelper.hideActionPopover" event', () => {
        spyOn(eventHub, '$emit');

        vm.handleRestartStep();

        expect(eventHub.$emit).toHaveBeenCalledWith('onboardingHelper.hideActionPopover');
      });
    });

    describe('handleSkipStep', () => {
      it('calls the click method on given popover selector if there is a stepContent', () => {
        const {
          actionPopover: { selector },
        } = vm.stepContent;

        const fakeLink = {
          click: () => {},
        };

        spyOn(document, 'querySelector').and.returnValue(fakeLink);
        spyOn(fakeLink, 'click');

        vm.handleSkipStep();

        expect(document.querySelector).toHaveBeenCalledWith(`${selector}`);
        expect(fakeLink.click).toHaveBeenCalled();
      });
    });

    describe('handleClickPopoverButton', () => {
      it('shows the exitTour content', () => {
        spyOn(vm, 'showExitTourContent');

        const button = {
          showExitTourContent: true,
        };

        vm.handleClickPopoverButton(button);

        expect(vm.showExitTourContent).toHaveBeenCalledWith(true);
      });

      it('quits the tour', () => {
        spyOn(vm, 'handleExitTour');

        const button = {
          exitTour: true,
        };

        vm.handleClickPopoverButton(button);

        expect(vm.handleExitTour).toHaveBeenCalled();
      });

      it('sets dismissPopover to true when true/undefined on button config', () => {
        let button = {
          dismissPopover: true,
        };

        vm.handleClickPopoverButton(button);

        expect(vm.dismissPopover).toBe(true);

        button = {};

        vm.handleClickPopoverButton(button);

        expect(vm.dismissPopover).toBe(true);
      });

      it('does not set dismissPopover to true when false on button config', () => {
        const button = {
          dismissPopover: false,
        };

        vm.handleClickPopoverButton(button);

        expect(vm.dismissPopover).toBe(false);
      });

      it('redirects to the redirectPath', () => {
        const redirectSpy = spyOnDependency(OnboardingHelperApp, 'redirectTo');
        const button = {
          redirectPath: 'my-redirect/path',
        };

        vm.handleClickPopoverButton(button);

        expect(redirectSpy).toHaveBeenCalledWith(button.redirectPath);
      });

      it('switches to the next tour part and calls initActionPopover', () => {
        spyOn(vm.$store, 'dispatch');
        spyOn(vm, 'initActionPopover');

        const nextPart = 2;
        const button = {
          nextPart,
        };

        vm.handleClickPopoverButton(button);

        expect(vm.$store.dispatch).toHaveBeenCalledWith('switchTourPart', nextPart);
        expect(vm.initActionPopover).toHaveBeenCalled();
      });

      it('shows the next content item', () => {
        spyOn(vm.$store, 'dispatch');

        const button = {};

        vm.$store.state.url = 'http://gitlab-org/gitlab-test/foo';
        vm.$store.state.lastStepIndex = 0;

        vm.handleClickPopoverButton(button);

        expect(vm.$store.dispatch).toHaveBeenCalledWith('setHelpContentIndex', 1);
      });
    });

    describe('showExitTourContent', () => {
      it('sets the "dismissPopover" prop to false', () => {
        vm.showExitTourContent(true);

        expect(vm.dismissPopover).toBeFalsy();
      });

      it('calls the "setExitTour" method', () => {
        spyOn(vm.$store, 'dispatch');

        vm.showExitTourContent(true);

        expect(vm.$store.dispatch).toHaveBeenCalledWith('setExitTour', true);
      });
    });

    describe('handleFeedbackTourContent', () => {
      it('sets the "dismissPopover" prop to false', () => {
        vm.handleFeedbackTourContent(true);

        expect(vm.dismissPopover).toBeFalsy();
      });

      it('calls the "setTourFeedback" method', () => {
        spyOn(vm.$store, 'dispatch');

        vm.handleFeedbackTourContent(true);

        expect(vm.$store.dispatch).toHaveBeenCalledWith('setTourFeedback', true);
      });
    });

    describe('handleExitTour', () => {
      it('calls the "hideActionPopover" method', () => {
        spyOn(vm, 'hideActionPopover');

        vm.handleExitTour();

        expect(vm.hideActionPopover).toHaveBeenCalled();
      });

      it('calls the "setDismissed" method with true', () => {
        spyOn(vm.$store, 'dispatch');

        vm.handleExitTour();

        expect(vm.$store.dispatch).toHaveBeenCalledWith('setDismissed', true);
      });

      it('emits the "onboardingHelper.destroyActionPopover" event', () => {
        spyOn(eventHub, '$emit');

        vm.handleExitTour();

        expect(eventHub.$emit).toHaveBeenCalledWith('onboardingHelper.destroyActionPopover');
      });
    });
  });
});
