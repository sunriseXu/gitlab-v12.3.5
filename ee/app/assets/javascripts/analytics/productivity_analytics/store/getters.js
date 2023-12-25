export const getMetricTypes = state => chartKey =>
  state.metricTypes.filter(m => m.chart === chartKey);

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
