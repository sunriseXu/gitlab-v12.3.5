import ZenMode from '~/zen_mode';
import ShortcutsEpic from 'ee/behaviors/shortcuts/shortcuts_epic';
import EpicTabs from 'ee/epic/epic_tabs';
import initEpicApp from 'ee/epic/epic_bundle';
import '~/notes/index';

document.addEventListener('DOMContentLoaded', () => {
  new ZenMode(); // eslint-disable-line no-new
  initEpicApp();
  new ShortcutsEpic(); // eslint-disable-line no-new
  new EpicTabs(); // eslint-disable-line no-new
});
