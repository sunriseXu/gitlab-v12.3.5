import Vue from 'vue';
import initBlockingMrInput from 'ee/projects/merge_requests/blocking_mr_input';

jest.mock('vue');

describe('BlockingMrInput', () => {
  let h;
  const refs = ['!1'];
  const getProps = () => h.mock.calls[0][1].props;
  const callRender = () => {
    Vue.mock.calls[0][0].render(h);
  };
  const setInnerHtml = (visibleMrs = refs, hiddenCount = 2) => {
    document.body.innerHTML += `<div id="test" data-hidden-blocking-mrs-count="${hiddenCount}" data-visible-blocking-mr-refs='${JSON.stringify(
      visibleMrs,
    )}'></div>`;
  };

  beforeEach(() => {
    h = jest.fn();
  });

  afterEach(() => {
    document.querySelector('#test').remove();
    jest.clearAllMocks();
  });

  it('adds hidden references block when hidden count is greater than 0', () => {
    setInnerHtml();
    initBlockingMrInput(document.querySelector('#test'));
    callRender();
    expect(getProps().existingRefs[refs.length].text).toBe('2 inaccessible merge requests');
  });

  it('containsHiddenBlockingMrs is true when count is greater than one', () => {
    setInnerHtml();
    initBlockingMrInput(document.querySelector('#test'));

    callRender();
    expect(getProps().containsHiddenBlockingMrs).toBe(true);
  });

  it('containsHiddenBlockingMrs is false when count is zero', () => {
    setInnerHtml(refs, 0);
    initBlockingMrInput(document.querySelector('#test'));

    callRender();
    expect(getProps().containsHiddenBlockingMrs).toBe(false);
  });
});
