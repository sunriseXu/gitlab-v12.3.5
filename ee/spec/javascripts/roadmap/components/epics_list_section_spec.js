import Vue from 'vue';

import epicsListSectionComponent from 'ee/roadmap/components/epics_list_section.vue';
import createStore from 'ee/roadmap/store';
import eventHub from 'ee/roadmap/event_hub';
import { getTimeframeForMonthsView } from 'ee/roadmap/utils/roadmap_utils';
import { PRESET_TYPES } from 'ee/roadmap/constants';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import {
  mockShellWidth,
  mockTimeframeInitialDate,
  mockGroupId,
  rawEpics,
  mockSortedBy,
  basePath,
  epicsPath,
} from '../mock_data';

const mockTimeframeMonths = getTimeframeForMonthsView(mockTimeframeInitialDate);

const store = createStore();
store.dispatch('setInitialData', {
  currentGroupId: mockGroupId,
  sortedBy: mockSortedBy,
  presetType: PRESET_TYPES.MONTHS,
  timeframe: mockTimeframeMonths,
  filterQueryString: '',
  initialEpicsPath: epicsPath,
  basePath,
});

store.dispatch('receiveEpicsSuccess', { rawEpics });

const mockEpics = store.state.epics;

const createComponent = ({
  epics = mockEpics,
  timeframe = mockTimeframeMonths,
  currentGroupId = mockGroupId,
  shellWidth = mockShellWidth,
  listScrollable = false,
  presetType = PRESET_TYPES.MONTHS,
}) => {
  const Component = Vue.extend(epicsListSectionComponent);

  return mountComponent(Component, {
    presetType,
    epics,
    timeframe,
    currentGroupId,
    shellWidth,
    listScrollable,
  });
};

describe('EpicsListSectionComponent', () => {
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      vm = createComponent({});

      expect(vm.shellHeight).toBe(0);
      expect(vm.emptyRowHeight).toBe(0);
      expect(vm.showEmptyRow).toBe(false);
      expect(vm.offsetLeft).toBe(0);
      expect(vm.showBottomShadow).toBe(false);
    });
  });

  describe('computed', () => {
    beforeEach(() => {
      vm = createComponent({});
    });

    describe('emptyRowContainerStyles', () => {
      it('returns computed style object based on emptyRowHeight prop value', () => {
        expect(vm.emptyRowContainerStyles.height).toBe('0px');
      });
    });

    describe('emptyRowCellStyles', () => {
      it('returns computed style object based on sectionItemWidth prop value', () => {
        expect(vm.emptyRowCellStyles.width).toBe('210px');
      });
    });

    describe('shadowCellStyles', () => {
      it('returns computed style object based on `offsetLeft` prop value', () => {
        expect(vm.shadowCellStyles.left).toBe('0px');
      });
    });
  });

  describe('methods', () => {
    beforeEach(() => {
      vm = createComponent({});
    });

    describe('initMounted', () => {
      it('initializes shellHeight based on window.innerHeight and component element position', done => {
        vm.$nextTick(() => {
          expect(vm.shellHeight).toBe(600);
          done();
        });
      });

      it('calls initEmptyRow() when there are Epics to render', done => {
        spyOn(vm, 'initEmptyRow').and.callThrough();

        vm.$nextTick(() => {
          expect(vm.initEmptyRow).toHaveBeenCalled();
          done();
        });
      });

      it('emits `epicsListRendered` via eventHub', done => {
        spyOn(eventHub, '$emit');

        vm.$nextTick(() => {
          expect(eventHub.$emit).toHaveBeenCalledWith('epicsListRendered', jasmine.any(Object));
          done();
        });
      });
    });

    describe('initEmptyRow', () => {
      it('sets `emptyRowHeight` and `showEmptyRow` props when shellHeight is greater than approximate height of epics list', done => {
        vm.$nextTick(() => {
          expect(vm.emptyRowHeight).toBe(600);
          expect(vm.showEmptyRow).toBe(true);
          done();
        });
      });

      it('does not set `emptyRowHeight` and `showEmptyRow` props when shellHeight is less than approximate height of epics list', done => {
        const initialHeight = window.innerHeight;
        window.innerHeight = 0;
        const vmMoreEpics = createComponent({
          epics: mockEpics.concat(mockEpics).concat(mockEpics),
        });
        vmMoreEpics.$nextTick(() => {
          expect(vmMoreEpics.emptyRowHeight).toBe(0);
          expect(vmMoreEpics.showEmptyRow).toBe(false);
          window.innerHeight = initialHeight; // reset to prevent any side effects
          done();
        });
      });
    });
  });

  describe('template', () => {
    beforeEach(() => {
      vm = createComponent({});
    });

    it('renders component container element with class `epics-list-section`', done => {
      vm.$nextTick(() => {
        expect(vm.$el.classList.contains('epics-list-section')).toBe(true);
        done();
      });
    });

    it('renders component container element with `width` property applied via style attribute', done => {
      vm.$nextTick(() => {
        expect(vm.$el.getAttribute('style')).toBe(`width: ${mockShellWidth}px;`);
        done();
      });
    });

    it('renders bottom shadow element when `showBottomShadow` prop is true', done => {
      vm.showBottomShadow = true;
      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.scroll-bottom-shadow')).not.toBe(null);
        done();
      });
    });
  });
});
