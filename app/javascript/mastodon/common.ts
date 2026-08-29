import { setupCustomEmojiPreview } from './utils/custom_emoji_preview';
import { setupLinkListeners } from './utils/links';

export function start() {
  setupCustomEmojiPreview();
  setupLinkListeners();
}
