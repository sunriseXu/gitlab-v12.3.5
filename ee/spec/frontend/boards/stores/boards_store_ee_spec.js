import AxiosMockAdapter from 'axios-mock-adapter';
import BoardsStoreEE from 'ee_else_ce/boards/stores/boards_store_ee';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import { TEST_HOST } from 'helpers/test_constants';

jest.mock('~/flash');

describe('BoardsStoreEE', () => {
  let setCurrentBoard;
  let axiosMock;

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);

    setCurrentBoard = jest.fn();

    // mock CE store
    const storeMock = {
      state: {},
      create() {},
      setCurrentBoard,
    };

    BoardsStoreEE.initEESpecific(storeMock);
  });

  describe('loadList', () => {
    const listPath = `${TEST_HOST}/list/path`;
    const listType = 'D-negative';

    it('fetches from listPath and stores the result', () => {
      const dummyResponse = { uni: 'corn' };
      axiosMock.onGet(listPath).replyOnce(200, dummyResponse);
      const { state } = BoardsStoreEE.store;
      state[listType] = [];

      return BoardsStoreEE.loadList(listPath, listType).then(() => {
        expect(state[listType]).toEqual(dummyResponse);
      });
    });

    it('displays error if fetching fails', () => {
      axiosMock.onGet(listPath).replyOnce(500);
      const { state } = BoardsStoreEE.store;
      state[listType] = [];

      return BoardsStoreEE.loadList(listPath, listType).then(() => {
        expect(state[listType]).toEqual([]);
        expect(createFlash).toHaveBeenCalled();
      });
    });

    it('does not make a request if response is cached', () => {
      const { state } = BoardsStoreEE.store;
      state[listType] = ['something'];

      return BoardsStoreEE.loadList(listPath, listType).then(() => {
        expect(axiosMock.history.get.length).toBe(0);
      });
    });
  });

  describe('setCurrentBoard', () => {
    const dummyBoard = 'skateboard';

    it('calls setCurrentBoard() of the base store', () => {
      BoardsStoreEE.store.setCurrentBoard(dummyBoard);

      expect(setCurrentBoard).toHaveBeenCalledWith(dummyBoard);
    });

    it('resets assignees', () => {
      const { state } = BoardsStoreEE.store;
      state.assignees = 'some assignees';

      BoardsStoreEE.store.setCurrentBoard(dummyBoard);

      expect(state.assignees).toEqual([]);
    });

    it('resets milestones', () => {
      const { state } = BoardsStoreEE.store;
      state.milestones = 'some milestones';

      BoardsStoreEE.store.setCurrentBoard(dummyBoard);

      expect(state.milestones).toEqual([]);
    });
  });
});
