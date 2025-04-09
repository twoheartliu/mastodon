// app/javascript/mastodon/is_mobile.ts
import { supportsPassiveEvents } from 'detect-passive-events';

import {
  forceSingleColumn,
  hasMultiColumnPath,
  layoutType,
} from './initial_state';

const LAYOUT_BREAKPOINT = 630;

export const isMobile = (width: number) => width <= LAYOUT_BREAKPOINT;

export const transientSingleColumn = !forceSingleColumn && !hasMultiColumnPath;

export type LayoutType = 'mobile' | 'single-column' | 'advanced' | 'two-column';
export const layoutFromWindow = (): LayoutType => {
  if (isMobile(window.innerWidth)) {
    return 'mobile';
  } else if (!forceSingleColumn && !transientSingleColumn) {
    // 根据用户设置返回不同的布局类型
    if (layoutType === 'two_column') {
      return 'two-column';
    } else {
      return 'advanced'; // advanced 或其他情况使用多列布局
    }
  } else {
    return 'single-column';
  }
};

const listenerOptions = supportsPassiveEvents ? { passive: true } : false;

let userTouching = false;

const touchListener = () => {
  userTouching = true;

  window.removeEventListener('touchstart', touchListener);
};

window.addEventListener('touchstart', touchListener, listenerOptions);

export const isUserTouching = () => userTouching;
