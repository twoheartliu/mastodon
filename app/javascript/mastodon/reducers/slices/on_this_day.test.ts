import { describe, expect, it, vi } from 'vitest';

import type { AppDispatch, RootState } from '@/mastodon/store';

import { checkOnThisDay } from './on_this_day';

type OnThisDayState = RootState['onThisDay']['state'];

const checkWithState = (state: OnThisDayState) => {
  const dispatch = vi.fn();
  const getState = () =>
    ({
      onThisDay: { state },
    }) as unknown as RootState;

  checkOnThisDay()(dispatch as unknown as AppDispatch, getState);

  return dispatch.mock.calls.filter(([action]) => typeof action === 'function');
};

describe('checkOnThisDay', () => {
  it.each([undefined, 'pending'] satisfies OnThisDayState[])(
    'requests the state when the current state is %s',
    (state) => {
      expect(checkWithState(state)).toHaveLength(1);
    },
  );

  it.each(['ready', 'empty', 'disabled'] satisfies OnThisDayState[])(
    'does not request the state when the current state is %s',
    (state) => {
      expect(checkWithState(state)).toHaveLength(0);
    },
  );
});
