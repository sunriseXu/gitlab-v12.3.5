document.addEventListener('DOMContentLoaded', () => {
  if (gon.features.createEksClusters) {
    import(/* webpackChunkName: 'eks_cluster' */ '~/create_cluster/eks_cluster')
      .then(({ default: initCreateEKSCluster }) => initCreateEKSCluster())
      .catch(() => {});
  }
});
