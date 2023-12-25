import { mount } from '@vue/test-utils';
import $ from 'jquery';
import 'bootstrap';
import '~/gl_dropdown';
import ProjectsDropdownFilter from 'ee/analytics/shared/components/projects_dropdown_filter.vue';
import Api from '~/api';
import { TEST_HOST } from 'helpers/test_constants';

jest.mock('~/api', () => ({
  groupProjects: jest.fn(),
}));

const projects = [
  {
    id: 1,
    name: 'foo',
    avatar_url: `${TEST_HOST}/images/home/nasa.svg`,
  },
  {
    id: 2,
    name: 'foobar',
    avatar_url: null,
  },
  {
    id: 3,
    name: 'foooooooo',
    avatar_url: null,
  },
];

describe('ProjectsDropdownFilter component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(ProjectsDropdownFilter, {
      sync: false,
      propsData: {
        groupId: 1,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  beforeEach(() => {
    jest.spyOn($.fn, 'glDropdown');
    Api.groupProjects.mockImplementation((groupId, term, options, callback) => {
      callback(projects);
    });
  });

  const findDropdown = () => wrapper.find('.dropdown');
  const openDropdown = () => {
    $(findDropdown().element)
      .parent()
      .trigger('shown.bs.dropdown');
  };
  const findDropdownItems = () => findDropdown().findAll('a');
  const findDropdownButton = () => findDropdown().find('button');

  describe('when multiSelect is false', () => {
    beforeEach(() => {
      createComponent({ multiSelect: false });
    });

    it('calls glDropdown', () => {
      expect($.fn.glDropdown).toHaveBeenCalled();
    });

    describe('displays the correct information', () => {
      beforeEach(() => {
        openDropdown();

        return wrapper.vm.$nextTick();
      });

      it('contains 3 items', () => {
        expect(findDropdownItems().length).toEqual(3);
      });

      it('renders an avatar when the project has an avatar_url', () => {
        expect(
          findDropdownItems()
            .at(0)
            .contains('img.avatar'),
        ).toBe(true);
        expect(
          findDropdownItems()
            .at(0)
            .contains('div.identicon'),
        ).toBe(false);
      });

      it("renders an identicon when the project doesn't have an avatar_url", () => {
        expect(
          findDropdownItems()
            .at(1)
            .contains('img.avatar'),
        ).toBe(false);
        expect(
          findDropdownItems()
            .at(1)
            .contains('div.identicon'),
        ).toBe(true);
      });
    });

    describe('on project click', () => {
      beforeEach(() => {
        openDropdown();

        return wrapper.vm.$nextTick();
      });

      it('should emit the "selected" event with the selected project', () => {
        findDropdownItems()
          .at(0)
          .trigger('click');

        expect(wrapper.emittedByOrder()).toEqual([
          {
            name: 'selected',
            args: [[projects[0]]],
          },
        ]);
      });

      it('should change selection when new project is clicked', () => {
        findDropdownItems()
          .at(1)
          .trigger('click');

        expect(wrapper.emittedByOrder()).toEqual([
          {
            name: 'selected',
            args: [[projects[1]]],
          },
        ]);
      });

      it('selection should be emptied when a project is deselected', () => {
        const project = findDropdownItems().at(0);
        project.trigger('click');
        project.trigger('click');

        expect(wrapper.emittedByOrder()).toEqual([
          {
            name: 'selected',
            args: [[projects[0]]],
          },
          {
            name: 'selected',
            args: [[]],
          },
        ]);
      });

      it('renders an avatar in the dropdown button when the project has an avatar_url', done => {
        findDropdownItems()
          .at(0)
          .trigger('click');

        wrapper.vm.$nextTick(() => {
          expect(findDropdownButton().contains('img.gl-avatar')).toBe(true);
          expect(findDropdownButton().contains('.gl-avatar-identicon')).toBe(false);
          done();
        });
      });

      it("renders an identicon in the dropdown button when the project doesn't have an avatar_url", done => {
        findDropdownItems()
          .at(1)
          .trigger('click');

        wrapper.vm.$nextTick(() => {
          expect(findDropdownButton().contains('img.gl-avatar')).toBe(false);
          expect(findDropdownButton().contains('.gl-avatar-identicon')).toBe(true);
          done();
        });
      });
    });
  });

  describe('when multiSelect is true', () => {
    beforeEach(() => {
      createComponent({ multiSelect: true });
    });

    describe('displays the correct information', () => {
      beforeEach(() => {
        openDropdown();

        return wrapper.vm.$nextTick();
      });

      it('contains 3 items', () => {
        expect(findDropdownItems().length).toEqual(3);
      });

      it('renders an avatar when the project has an avatar_url', () => {
        expect(
          findDropdownItems()
            .at(0)
            .contains('img.avatar'),
        ).toBe(true);
        expect(
          findDropdownItems()
            .at(0)
            .contains('div.identicon'),
        ).toBe(false);
      });

      it("renders an identicon when the project doesn't have an avatar_url", () => {
        expect(
          findDropdownItems()
            .at(1)
            .contains('img.avatar'),
        ).toBe(false);
        expect(
          findDropdownItems()
            .at(1)
            .contains('div.identicon'),
        ).toBe(true);
      });
    });

    describe('on project click', () => {
      beforeEach(() => {
        openDropdown();

        return wrapper.vm.$nextTick();
      });

      it('should add to selection when new project is clicked', () => {
        findDropdownItems()
          .at(0)
          .trigger('click');

        findDropdownItems()
          .at(1)
          .trigger('click');

        expect(wrapper.emittedByOrder()).toEqual([
          {
            name: 'selected',
            args: [[projects[0]]],
          },
          {
            name: 'selected',
            args: [[projects[0], projects[1]]],
          },
        ]);
      });

      it('should remove from selection when clicked again', () => {
        const item = findDropdownItems().at(0);

        item.trigger('click');
        item.trigger('click');

        expect(wrapper.emittedByOrder()).toEqual([
          {
            name: 'selected',
            args: [[projects[0]]],
          },
          {
            name: 'selected',
            args: [[]],
          },
        ]);
      });

      it('renders the correct placeholder text when multiple projects are selected', done => {
        findDropdownItems()
          .at(0)
          .trigger('click');

        findDropdownItems()
          .at(1)
          .trigger('click');

        wrapper.vm.$nextTick(() => {
          expect(findDropdownButton().text()).toBe('2 projects selected');
          done();
        });
      });
    });
  });
});
