import PersistentUserCallout from '~/persistent_user_callout';

document.addEventListener('DOMContentLoaded', () =>
  PersistentUserCallout.factory(document.querySelector('.js-gold-trial-callout')),
);
