import mutations from 'ee/boards/stores/mutations';

const expectNotImplemented = action => {
  it('is not implemented', () => {
    expect(action).toThrow(new Error('Not implemented!'));
  });
};

describe('REQUEST_AVAILABLE_BOARDS', () => {
  expectNotImplemented(mutations.REQUEST_AVAILABLE_BOARDS);
});

describe('RECEIVE_AVAILABLE_BOARDS_SUCCESS', () => {
  expectNotImplemented(mutations.RECEIVE_AVAILABLE_BOARDS_SUCCESS);
});

describe('RECEIVE_AVAILABLE_BOARDS_ERROR', () => {
  expectNotImplemented(mutations.RECEIVE_AVAILABLE_BOARDS_ERROR);
});

describe('REQUEST_RECENT_BOARDS', () => {
  expectNotImplemented(mutations.REQUEST_RECENT_BOARDS);
});

describe('RECEIVE_RECENT_BOARDS_SUCCESS', () => {
  expectNotImplemented(mutations.RECEIVE_RECENT_BOARDS_SUCCESS);
});

describe('RECEIVE_RECENT_BOARDS_ERROR', () => {
  expectNotImplemented(mutations.RECEIVE_RECENT_BOARDS_ERROR);
});

describe('REQUEST_ADD_BOARD', () => {
  expectNotImplemented(mutations.REQUEST_ADD_BOARD);
});

describe('RECEIVE_ADD_BOARD_SUCCESS', () => {
  expectNotImplemented(mutations.RECEIVE_ADD_BOARD_SUCCESS);
});

describe('RECEIVE_ADD_BOARD_ERROR', () => {
  expectNotImplemented(mutations.RECEIVE_ADD_BOARD_ERROR);
});

describe('REQUEST_REMOVE_BOARD', () => {
  expectNotImplemented(mutations.REQUEST_REMOVE_BOARD);
});

describe('RECEIVE_REMOVE_BOARD_SUCCESS', () => {
  expectNotImplemented(mutations.RECEIVE_REMOVE_BOARD_SUCCESS);
});

describe('RECEIVE_REMOVE_BOARD_ERROR', () => {
  expectNotImplemented(mutations.RECEIVE_REMOVE_BOARD_ERROR);
});

describe('TOGGLE_PROMOTION_STATE', () => {
  expectNotImplemented(mutations.TOGGLE_PROMOTION_STATE);
});
