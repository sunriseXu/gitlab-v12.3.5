<script>
import Mousetrap from 'mousetrap';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import { GlLoadingIcon } from '@gitlab/ui';
import allVersionsMixin from '../../mixins/all_versions';
import Toolbar from '../../components/toolbar/index.vue';
import DesignImage from '../../components/image.vue';
import DesignOverlay from '../../components/design_overlay.vue';
import DesignDiscussion from '../../components/design_notes/design_discussion.vue';
import DesignReplyForm from '../../components/design_notes/design_reply_form.vue';
import getDesignQuery from '../../graphql/queries/getDesign.query.graphql';
import createImageDiffNoteMutation from '../../graphql/mutations/createImageDiffNote.mutation.graphql';
import { extractDiscussions } from '../../utils/design_management_utils';

export default {
  components: {
    DesignImage,
    DesignOverlay,
    DesignDiscussion,
    Toolbar,
    DesignReplyForm,
    GlLoadingIcon,
  },
  mixins: [allVersionsMixin],
  props: {
    id: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      design: {},
      comment: '',
      annotationCoordinates: null,
      overlayDimensions: {
        width: 0,
        height: 0,
      },
      projectPath: '',
      isNoteSaving: false,
    };
  },
  apollo: {
    design: {
      query: getDesignQuery,
      variables() {
        return {
          id: this.id,
          version: this.designsVersion,
        };
      },
      result({ data }) {
        if (!data) {
          createFlash(s__('DesignManagement|Could not find design, please try again.'));
          this.$router.push({ name: 'designs' });
        }
        if (this.$route.query.version && !this.hasValidVersion) {
          createFlash(s__('DesignManagement|Requested design version does not exist'));
          this.$router.push({ name: 'designs' });
        }
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.design.loading;
    },
    discussions() {
      return extractDiscussions(this.design.discussions);
    },
    discussionStartingNotes() {
      return this.discussions.map(discussion => discussion.notes[0]);
    },
    markdownPreviewPath() {
      return `/${this.projectPath}/preview_markdown?target_type=Issue`;
    },
    isSubmitButtonDisabled() {
      return this.comment.trim().length === 0;
    },
    renderDiscussions() {
      return this.discussions.length || this.annotationCoordinates;
    },
  },
  mounted() {
    Mousetrap.bind('esc', this.closeDesign);
  },
  beforeDestroy() {
    Mousetrap.unbind('esc', this.closeDesign);
  },
  methods: {
    addImageDiffNote() {
      const { x, y, width, height } = this.annotationCoordinates;
      this.isNoteSaving = true;
      return this.$apollo
        .mutate({
          mutation: createImageDiffNoteMutation,
          variables: {
            input: {
              noteableId: this.design.id,
              body: this.comment,
              position: {
                headSha: this.design.diffRefs.headSha,
                baseSha: this.design.diffRefs.baseSha,
                startSha: this.design.diffRefs.startSha,
                x,
                y,
                width,
                height,
                paths: {
                  newPath: this.design.fullPath,
                },
              },
            },
          },
          update: (store, { data: { createImageDiffNote } }) => {
            const data = store.readQuery({
              query: getDesignQuery,
              variables: {
                id: this.id,
                version: this.designsVersion,
              },
            });
            const newDiscussion = {
              __typename: 'DiscussionEdge',
              node: {
                // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26
                // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
                __typename: 'Discussion',
                id: createImageDiffNote.note.discussion.id,
                replyId: createImageDiffNote.note.discussion.replyId,
                notes: {
                  __typename: 'NoteConnection',
                  edges: [
                    {
                      __typename: 'NoteEdge',
                      node: createImageDiffNote.note,
                    },
                  ],
                },
              },
            };
            data.design.discussions.edges.push(newDiscussion);
            store.writeQuery({ query: getDesignQuery, data });
          },
        })
        .then(() => {
          this.closeCommentForm();
          this.isNoteSaving = false;
        })
        .catch(e => {
          this.isNoteSaving = false;
          createFlash(s__('DesignManagement|Could not create new discussion, please try again.'));
          throw e;
        });
    },
    openCommentForm(position) {
      const { x, y } = position;
      const { width, height } = this.overlayDimensions;
      this.annotationCoordinates = {
        ...this.annotationCoordinates,
        x,
        y,
        width,
        height,
      };
    },
    closeCommentForm() {
      this.comment = '';
      this.annotationCoordinates = null;
    },
    setOverlayDimensions(position) {
      this.overlayDimensions.width = position.width;
      this.overlayDimensions.height = position.height;
    },
    closeDesign() {
      this.$router.push({
        name: 'designs',
        query: this.$route.query,
      });
    },
  },
  beforeRouteUpdate(to, from, next) {
    this.closeCommentForm();
    next();
  },
};
</script>

<template>
  <div class="design-detail fixed-top w-100 position-bottom-0 d-sm-flex justify-content-center">
    <gl-loading-icon v-if="isLoading" size="xl" class="align-self-center" />
    <template v-else>
      <div class="d-flex flex-column w-100">
        <toolbar
          :id="id"
          :name="design.filename"
          :updated-at="design.updatedAt"
          :updated-by="design.updatedBy"
        />
        <div class="d-flex flex-column w-100 h-100 mh-100 position-relative">
          <design-image
            :image="design.image"
            :name="design.filename"
            @setOverlayDimensions="setOverlayDimensions"
          />
          <design-overlay
            :position="overlayDimensions"
            :notes="discussionStartingNotes"
            :current-comment-form="annotationCoordinates"
            @openCommentForm="openCommentForm"
          />
        </div>
      </div>
      <div class="image-notes">
        <template v-if="renderDiscussions">
          <design-discussion
            v-for="(discussion, index) in discussions"
            :key="discussion.id"
            :discussion="discussion"
            :design-id="id"
            :noteable-id="design.id"
            :discussion-index="index + 1"
            :markdown-preview-path="markdownPreviewPath"
          />
          <design-reply-form
            v-if="annotationCoordinates"
            v-model="comment"
            :is-saving="isNoteSaving"
            :markdown-preview-path="markdownPreviewPath"
            @submitForm="addImageDiffNote"
            @cancelForm="closeCommentForm"
          />
        </template>
        <h2 v-else class="new-discussion-disclaimer m-0">
          {{ __("Click the image where you'd like to start a new discussion") }}
        </h2>
      </div>
    </template>
  </div>
</template>
