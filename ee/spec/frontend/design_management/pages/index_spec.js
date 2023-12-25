import { createLocalVue, shallowMount } from '@vue/test-utils';
import VueRouter from 'vue-router';
import Index from 'ee/design_management/pages/index.vue';
import UploadForm from 'ee/design_management/components/upload/form.vue';
import uploadDesignQuery from 'ee/design_management/graphql/mutations/uploadDesign.mutation.graphql';

const localVue = createLocalVue();
localVue.use(VueRouter);
const router = new VueRouter({
  routes: [
    {
      name: 'designs',
      path: '/designs',
      component: Index,
    },
  ],
});

describe('Design management index page', () => {
  let mutate;
  let vm;

  function createComponent(loading = false, designs = []) {
    mutate = jest.fn(() => Promise.resolve());
    const $apollo = {
      queries: {
        designs: {
          loading,
        },
        permissions: {
          loading,
        },
      },
      mutate,
    };

    vm = shallowMount(Index, {
      mocks: { $apollo },
      stubs: ['router-view'],
      localVue,
      router,
    });

    vm.setData({
      designs,
      permissions: {
        createDesign: true,
      },
    });
  }

  afterEach(() => {
    vm.destroy();
  });

  describe('designs', () => {
    it('renders loading icon', () => {
      createComponent(true);

      expect(vm.element).toMatchSnapshot();
    });

    it('renders error', () => {
      createComponent();

      vm.setData({ error: true });

      expect(vm.element).toMatchSnapshot();
    });

    it('renders empty text', () => {
      createComponent();

      expect(vm.element).toMatchSnapshot();
    });

    it('renders designs list', () => {
      createComponent(false, ['design']);

      expect(vm.element).toMatchSnapshot();
    });
  });

  describe('upload form', () => {
    it('hides upload form', () => {
      createComponent();

      expect(vm.find(UploadForm).exists()).toBe(false);
    });

    it('renders upload form', () => {
      createComponent(false, ['design']);

      expect(vm.find(UploadForm).exists()).toBe(true);
    });
  });

  describe('onUploadDesign', () => {
    it('calls apollo mutate', () => {
      createComponent();

      return vm.vm
        .onUploadDesign([
          {
            name: 'test',
          },
        ])
        .then(() => {
          expect(mutate).toHaveBeenCalledWith({
            context: {
              hasUpload: true,
            },
            mutation: uploadDesignQuery,
            variables: {
              files: [{ name: 'test' }],
              projectPath: '',
              iid: null,
            },
            update: expect.anything(),
            optimisticResponse: {
              __typename: 'Mutation',
              designManagementUpload: {
                __typename: 'DesignManagementUploadPayload',
                designs: [
                  {
                    __typename: 'Design',
                    id: expect.anything(),
                    image: '',
                    filename: 'test',
                    fullPath: '',
                    diffRefs: {
                      __typename: 'DiffRefs',
                      baseSha: '',
                      startSha: '',
                      headSha: '',
                    },
                    versions: {
                      __typename: 'DesignVersionConnection',
                      edges: {
                        __typename: 'DesignVersionEdge',
                        node: {
                          __typename: 'DesignVersion',
                          id: expect.anything(),
                          sha: expect.anything(),
                        },
                      },
                    },
                  },
                ],
              },
            },
          });
        });
    });

    it('does not call apollo mutate if createDesign is false', () => {
      createComponent();

      vm.setData({
        permissions: {
          createDesign: false,
        },
      });

      vm.vm.onUploadDesign([]);

      expect(mutate).not.toHaveBeenCalled();
    });

    it('sets isSaving', () => {
      createComponent();

      const uploadDesign = vm.vm.onUploadDesign([
        {
          name: 'test',
        },
      ]);

      expect(vm.vm.isSaving).toBe(true);

      return uploadDesign.then(() => {
        expect(vm.vm.isSaving).toBe(false);
      });
    });
  });
});
