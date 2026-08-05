import type { PayloadAction } from '@reduxjs/toolkit';
import { createSlice } from '@reduxjs/toolkit';

import {
  importFetchedAccounts,
  importFetchedStatuses,
} from '@/mastodon/actions/importer';
import type {
  ApiOnThisDayState,
  ApiOnThisDayResponse,
} from '@/mastodon/api/on_this_day';
import {
  apiGetOnThisDayState,
  apiGetOnThisDay,
} from '@/mastodon/api/on_this_day';
import { onThisDay as initialOnThisDay } from '@/mastodon/initial_state';
import {
  createAppThunk,
  createDataLoadingThunk,
} from '@/mastodon/store/typed_functions';

interface OnThisDaySliceState {
  state?: ApiOnThisDayState;
  date?: string;
  data?: { years: Record<string, string[]> };
  error: boolean;
}

const onThisDaySlice = createSlice({
  name: 'onThisDay',
  initialState: {
    state: initialOnThisDay?.state,
    date: initialOnThisDay?.date,
    error: false,
  } as OnThisDaySliceState,
  reducers: {
    setData(state, action: PayloadAction<ApiOnThisDayResponse>) {
      state.data = action.payload.data;
      state.state = 'ready';
    },
  },
  extraReducers(builder) {
    builder
      .addCase(fetchOnThisDayState.fulfilled, (state, action) => {
        state.state = action.payload.state;
        state.date = action.payload.date;
      })
      .addCase(fetchOnThisDayState.rejected, (state) => {
        state.error = true;
      })
      .addCase(fetchOnThisDayData.fulfilled, (state) => {
        state.error = false;
      })
      .addCase(fetchOnThisDayData.rejected, (state) => {
        state.error = true;
      });
  },
});

export const onThisDay = onThisDaySlice.reducer;
export const { setData } = onThisDaySlice.actions;

// Called on initial load to check if we need to refresh state.
export const checkOnThisDay = createAppThunk(
  `${onThisDaySlice.name}/checkOnThisDay`,
  (_arg, { dispatch, getState }) => {
    const { state } = getState().onThisDay;
    if (!state || state === 'pending') {
      void dispatch(fetchOnThisDayState());
    }
  },
);

export const fetchOnThisDayState = createDataLoadingThunk(
  `${onThisDaySlice.name}/fetchOnThisDayState`,
  async () => apiGetOnThisDayState(),
  (data) => data,
  { useLoadingBar: false },
);

export const fetchOnThisDayData = createDataLoadingThunk(
  `${onThisDaySlice.name}/fetchOnThisDayData`,
  async () => apiGetOnThisDay(),
  (data: ApiOnThisDayResponse, { dispatch }) => {
    dispatch(importFetchedStatuses(data.statuses));
    dispatch(importFetchedAccounts(data.accounts));
    dispatch(setData(data));
  },
);
