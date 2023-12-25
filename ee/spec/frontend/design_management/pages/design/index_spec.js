import { shallowMount } from '@vue/test-utils';
import DesignIndex from 'ee/design_management/pages/design/index.vue';
import DesignDiscussion from 'ee/design_management/components/design_notes/design_discussion.vue';
import DesignReplyForm from 'ee/design_management/components/design_notes/design_reply_form.vue';
import createImageDiffNoteMutation from 'ee/design_management/graphql/mutations/createImageDiffNote.mutation.graphql';
import design from '../../mock_data/design';

jest.mock('mousetrap', () => ({
  bind: jest.fn(),
  unbind: jest.fn(),
}));

describe('Design management design index page', () => {
  let wrapper;
  const newComment = 'new comment';
  const annotationCoordinates = {
    x: 10,
    y: 10,
    width: 100,
    height: 100,
  };
  const mutationVariables = {
    mutation: createImageDiffNoteMutation,
    update: expect.anything(),
    variables: {
      input: {
        body: newComment,
        noteableId: design.id,
        position: {
          headSha: 'headSha',
          baseSha: 'baseSha',
          startSha: 'startSha',
          paths: {
            newPath: 'full-design-path',
          },
          ...annotationCoordinates,
        },
      },
    },
  };
  const mutate = jest.fn(() => Promise.resolve());

  const findDiscussions = () => wrapper.findAll(DesignDiscussion);
  const findDiscussionForm = () => wrapper.find(DesignReplyForm);

  function createComponent(loading = false) {
    const $apollo = {
      queries: {
        design: {
          loading,
        },
      },
      mutate,
    };

    wrapper = shallowMount(DesignIndex, {
      sync: false,
      propsData: { id: '1' },
      mocks: { $apollo },
    });
  }

  function setDesign() {
    createComponent(true);
    wrapper.vm.$apollo.queries.design.loading = false;
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('sets loading state', () => {
    createComponent(true);

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders design index', () => {
    setDesign();

    wrapper.setData({
      design,
    });

    expect(wrapper.element).toMatchSnapshot();
  });

  describe('when has no discussions', () => {
    beforeEach(() => {
      setDesign();

      wrapper.setData({
        design: {
          ...design,
          discussions: {
            edges: [],
          },
        },
      });
    });

    it('does not render discussions', () => {
      expect(findDiscussions().exists()).toBe(false);
    });

    it('renders a message about possibility to create a new discussion', () => {
      expect(wrapper.find('.new-discussion-disclaimer').exists()).toBe(true);
    });
  });

  describe('when has discussions', () => {
    beforeEach(() => {
      setDesign();

      wrapper.setData({
        design,
      });
    });

    it('renders correct amount of discussions', () => {
      expect(wrapper.findAll(DesignDiscussion).length).toBe(1);
    });
  });

  it('opens a new discussion form', () => {
    setDesign();

    wrapper.setData({
      design: {
        ...design,
        discussions: {
          edges: [],
        },
      },
    });

    wrapper.vm.openCommentForm({ x: 0, y: 0 });

    wrapper.vm.$nextTick(() => {
      expect(findDiscussionForm().exists()).toBe(true);
    });
  });

  it('sends a mutation on submitting form and closes form', () => {
    setDesign();

    wrapper.setData({
      design: {
        ...design,
        discussions: {
          edges: [],
        },
      },
      annotationCoordinates,
      comment: newComment,
    });

    wrapper.vm.$nextTick(() => {
      findDiscussionForm().vm.$emit('submitForm');

      expect(mutate).toHaveBeenCalledWith(mutationVariables);
      const addNote = wrapper.vm.addImageDiffNote();

      return addNote.then(() => {
        expect(findDiscussionForm().exists()).toBe(false);
      });
    });
  });
});
