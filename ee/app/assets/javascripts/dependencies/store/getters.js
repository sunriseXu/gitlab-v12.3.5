export const isInitialized = ({ currentList, ...state }) => state[currentList].initialized;
export const reportInfo = ({ currentList, ...state }) => state[currentList].reportInfo;

export const isJobNotSetUp = ({ currentList }, getters) => getters[`${currentList}/isJobNotSetUp`];
export const isJobFailed = ({ currentList }, getters) => getters[`${currentList}/isJobFailed`];
export const isIncomplete = ({ currentList }, getters) => getters[`${currentList}/isIncomplete`];

export const totals = state =>
  state.listTypes.reduce(
    (acc, { namespace }) => ({
      ...acc,
      [namespace]: state[namespace].pageInfo.total || 0,
    }),
    {},
  );
