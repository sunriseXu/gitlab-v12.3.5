/* eslint-disable prefer-arrow-callback, one-var, no-var, no-shadow, no-else-return, func-names */

import $ from 'jquery';
import '~/gl_dropdown';

function WeightSelect(els, options = {}) {
  const $els = $(els || '.js-weight-select');

  $els.each(function(i, dropdown) {
    var $block, $dropdown, $selectbox, $value;
    $dropdown = $(dropdown);
    $selectbox = $dropdown.closest('.selectbox');
    $block = $selectbox.closest('.block');
    $value = $block.find('.value');
    $block.find('.block-loading').fadeOut();
    const fieldName = options.fieldName || $dropdown.data('fieldName');
    const inputField = $dropdown.closest('.selectbox').find(`input[name='${fieldName}']`);

    if (Object.keys(options).includes('selected')) {
      inputField.val(options.selected);
    }

    return $dropdown.glDropdown({
      selectable: true,
      fieldName,
      toggleLabel(selected, el) {
        return $(el).data('id');
      },
      hidden() {
        $selectbox.hide();
        return $value.css('display', '');
      },
      id(obj, el) {
        if ($(el).data('none') == null) {
          return $(el).data('id');
        } else {
          return '';
        }
      },
      clicked(glDropdownEvt) {
        const { e } = glDropdownEvt;
        let selected = glDropdownEvt.selectedObj;
        const inputField = $dropdown.closest('.selectbox').find(`input[name='${fieldName}']`);

        if (options.handleClick) {
          e.preventDefault();
          selected = inputField.val();
          options.handleClick(selected);
        } else if ($dropdown.is('.js-issuable-form-weight')) {
          e.preventDefault();
        }
      },
    });
  });
}

export default WeightSelect;
