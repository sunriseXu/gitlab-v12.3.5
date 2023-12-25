import Vue from 'vue';

import roadmapTimelineSectionComponent from 'ee/roadmap/components/roadmap_timeline_section.vue';
import { getTimeframeForMonthsView } from 'ee/roadmap/utils/roadmap_utils';

import { PRESET_TYPES } from 'ee/roadmap/constants';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import {
  mockEpic,
  mockTimeframeInitialDate,
  mockShellWidth,
  mockScrollBarSize,
} from '../mock_data';

const mockTimeframeMonths = getTimeframeForMonthsView(mockTimeframeInitialDate);

const createComponent = ({
  presetType = PRESET_TYPES.MONTHS,
  epics = [mockEpic],
  timeframe = mockTimeframeMonths,
  shellWidth = mockShellWidth,
  listScrollable = false,
}) => {
  const Component = Vue.extend(roadmapTimelineSectionComponent);

  return mountComponent(Component, {
    presetType,
    epics,
    timeframe,
    shellWidth,
    listScrollable,
  });
};

describe('SectionMixin', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent({});
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('sectionShellWidth', () => {
      it('returns shellWidth as it is when `listScrollable` prop is false', () => {
        expect(vm.sectionShellWidth).toBe(mockShellWidth);
      });

      it('returns shellWidth after deducating value of SCROLL_BAR_SIZE when `listScrollable` prop is true', () => {
        const vmScrollable = createComponent({ listScrollable: true });

        expect(vmScrollable.sectionShellWidth).toBe(mockShellWidth - mockScrollBarSize);
        vmScrollable.$destroy();
      });
    });

    describe('sectionItemWidth', () => {
      it('returns calculated item width based on sectionShellWidth and timeframe size', () => {
        expect(vm.sectionItemWidth).toBe(210);
      });
    });

    describe('sectionContainerStyles', () => {
      it('returns style string for container element based on sectionShellWidth', () => {
        expect(vm.sectionContainerStyles.width).toBe(`${mockShellWidth}px`);
      });
    });
  });
});
