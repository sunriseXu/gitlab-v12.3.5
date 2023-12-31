<script>
import $ from 'jquery';
import GfmAutoComplete from 'ee_else_ce/gfm_auto_complete';
import issueToken from './issue_token.vue';
import { autoCompleteTextMap, inputPlaceholderTextMap, issuableTypesMap } from '../constants';

const SPACE_FACTOR = 1;

export default {
  name: 'RelatedIssuableInput',
  components: {
    issueToken,
  },
  props: {
    inputId: {
      type: String,
      required: false,
      default: '',
    },
    references: {
      type: Array,
      required: false,
      default: () => [],
    },
    pathIdSeparator: {
      type: String,
      required: true,
    },
    inputValue: {
      type: String,
      required: false,
      default: '',
    },
    focusOnMount: {
      type: Boolean,
      required: false,
      default: false,
    },
    autoCompleteSources: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    autoCompleteOptions: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    issuableType: {
      type: String,
      required: false,
      default: issuableTypesMap.ISSUE,
    },
  },
  data() {
    return {
      isInputFocused: false,
      isAutoCompleteOpen: false,
    };
  },
  computed: {
    inputPlaceholder() {
      const { issuableType, allowAutoComplete } = this;
      const allowAutoCompleteText = autoCompleteTextMap[allowAutoComplete][issuableType];
      return `${inputPlaceholderTextMap[issuableType]}${allowAutoCompleteText}`;
    },
    allowAutoComplete() {
      return Object.keys(this.autoCompleteSources).length > 0;
    },
  },
  mounted() {
    this.setupAutoComplete();
    if (this.focusOnMount) {
      this.$refs.input.focus();
    }
  },
  beforeDestroy() {
    const $input = $(this.$refs.input);
    $input.off('shown-issues.atwho');
    $input.off('hidden-issues.atwho');
    $input.off('inserted-issues.atwho', this.onInput);
  },
  methods: {
    onAutoCompleteToggled(isOpen) {
      this.isAutoCompleteOpen = isOpen;
    },
    onInputWrapperClick() {
      this.$refs.input.focus();
    },
    onInput() {
      const { value } = this.$refs.input;
      const caretPos = this.$refs.input.selectionStart;
      const rawRefs = value.split(/\s/);
      let touchedReference;
      let position = 0;

      const untouchedRawRefs = rawRefs
        .filter(ref => {
          let isTouched = false;

          if (caretPos >= position && caretPos <= position + ref.length) {
            touchedReference = ref;
            isTouched = true;
          }

          position = position + ref.length + SPACE_FACTOR;

          return !isTouched;
        })
        .filter(ref => ref.trim().length > 0);

      this.$emit('addIssuableFormInput', {
        newValue: value,
        untouchedRawReferences: untouchedRawRefs,
        touchedReference,
        caretPos,
      });
    },
    onBlur() {
      this.isInputFocused = false;

      // Avoid tokenizing partial input when clicking an autocomplete item
      if (!this.isAutoCompleteOpen) {
        const { value } = this.$refs.input;
        this.$emit('addIssuableFormBlur', value);
      }
    },
    onFocus() {
      this.isInputFocused = true;
    },
    setupAutoComplete() {
      const $input = $(this.$refs.input);

      if (this.allowAutoComplete) {
        this.gfmAutoComplete = new GfmAutoComplete(this.autoCompleteSources);
        this.gfmAutoComplete.setup($input, this.autoCompleteOptions);
      }

      $input.on('shown-issues.atwho', this.onAutoCompleteToggled.bind(this, true));
      $input.on('hidden-issues.atwho', this.onAutoCompleteToggled.bind(this, true));
    },
    onIssuableFormWrapperClick() {
      this.$refs.input.focus();
    },
  },
};
</script>

<template>
  <div
    ref="issuableFormWrapper"
    :class="{ focus: isInputFocused }"
    class="add-issuable-form-input-wrapper form-control"
    role="button"
    @click="onIssuableFormWrapperClick"
  >
    <ul class="add-issuable-form-input-token-list">
      <!--
          We need to ensure this key changes any time the pendingReferences array is updated
          else two consecutive pending ref strings in an array with the same name will collide
          and cause odd behavior when one is removed.
        -->
      <li
        v-for="(reference, index) in references"
        :key="`related-issues-token-${reference}`"
        class="js-add-issuable-form-token-list-item add-issuable-form-token-list-item"
      >
        <issue-token
          :id-key="index"
          :display-reference="reference.text || reference"
          :can-remove="true"
          :is-condensed="true"
          :path-id-separator="pathIdSeparator"
          event-namespace="pendingIssuable"
          @pendingIssuableRemoveRequest="
            params => {
              $emit('pendingIssuableRemoveRequest', params);
            }
          "
        />
      </li>
      <li class="add-issuable-form-input-list-item">
        <input
          :id="inputId"
          ref="input"
          :value="inputValue"
          :placeholder="inputPlaceholder"
          type="text"
          class="js-add-issuable-form-input add-issuable-form-input qa-add-issue-input"
          @input="onInput"
          @focus="onFocus"
          @blur="onBlur"
          @keyup.escape.exact="$emit('addIssuableFormCancel')"
        />
      </li>
    </ul>
  </div>
</template>
