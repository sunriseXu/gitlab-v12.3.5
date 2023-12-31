<script>
import ReplyPlaceholder from './discussion_reply_placeholder.vue';
import ResolveDiscussionButton from './discussion_resolve_button.vue';
import ResolveWithIssueButton from './discussion_resolve_with_issue_button.vue';
import JumpToNextDiscussionButton from './discussion_jump_to_next_button.vue';

export default {
  name: 'DiscussionActions',
  components: {
    ReplyPlaceholder,
    ResolveDiscussionButton,
    ResolveWithIssueButton,
    JumpToNextDiscussionButton,
  },
  props: {
    discussion: {
      type: Object,
      required: true,
    },
    isResolving: {
      type: Boolean,
      required: true,
    },
    resolveButtonTitle: {
      type: String,
      required: true,
    },
    resolveWithIssuePath: {
      type: String,
      required: false,
      default: '',
    },
    shouldShowJumpToNextDiscussion: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    resolvableNotes() {
      return this.discussion.notes.filter(x => x.resolvable);
    },
    userCanResolveDiscussion() {
      return this.resolvableNotes.every(note => note.current_user && note.current_user.can_resolve);
    },
  },
};
</script>

<template>
  <div class="discussion-with-resolve-btn clearfix">
    <reply-placeholder
      data-qa-selector="discussion_reply_tab"
      :button-text="s__('MergeRequests|Reply...')"
      @onClick="$emit('showReplyForm')"
    />

    <div v-if="userCanResolveDiscussion" class="btn-group discussion-actions" role="group">
      <div class="btn-group">
        <resolve-discussion-button
          v-if="discussion.resolvable"
          :is-resolving="isResolving"
          :button-title="resolveButtonTitle"
          @onClick="$emit('resolve')"
        />
      </div>
      <resolve-with-issue-button
        v-if="discussion.resolvable && resolveWithIssuePath"
        :url="resolveWithIssuePath"
      />
    </div>
    <div
      v-if="discussion.resolvable && shouldShowJumpToNextDiscussion"
      class="btn-group discussion-actions ml-sm-2"
    >
      <jump-to-next-discussion-button @onClick="$emit('jumpToNextDiscussion')" />
    </div>
  </div>
</template>
