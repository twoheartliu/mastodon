import { useEffect, useMemo } from 'react';
import type { FC } from 'react';

import { FormattedMessage } from 'react-intl';

import { Helmet } from '@unhead/react/helmet';

import Column from '@/mastodon/components/column';
import ColumnHeader from '@/mastodon/components/column_header';
import HistoryIcon from '@/material-icons/400-24px/history.svg?react';
import { LoadingIndicator } from '@/mastodon/components/loading_indicator';
import { StatusQuoteManager } from '@/mastodon/components/status_quoted';
import {
  checkOnThisDay,
  fetchOnThisDayData,
  fetchOnThisDayState,
} from '@/mastodon/reducers/slices/on_this_day';
import { useAppDispatch, useAppSelector } from '@/mastodon/store';

import styles from './page.module.scss';

export const OnThisDayPage: FC = () => {
  const dispatch = useAppDispatch();
  const { state, data, error } = useAppSelector((s) => s.onThisDay);

  // Always check state on mount (handles direct URL access)
  useEffect(() => {
    void dispatch(checkOnThisDay());
  }, [dispatch]);

  // Fetch full data when state becomes ready
  useEffect(() => {
    if (!data && state === 'ready') {
      void dispatch(fetchOnThisDayData());
    }
  }, [dispatch, data, state]);

  // While the record is being generated in the background (state is
  // 'pending'), poll until it resolves to 'ready' or 'empty'
  useEffect(() => {
    if (state !== 'pending') return;

    const timer = setTimeout(() => {
      void dispatch(fetchOnThisDayState());
    }, 3_000);

    return () => {
      clearTimeout(timer);
    };
  }, [dispatch, state]);

  const years = useMemo(() => {
    if (!data?.years) return [];
    return Object.keys(data.years).sort((a, b) => Number(b) - Number(a));
  }, [data]);

  const isLoading = !data && !error && state !== 'empty' && state !== 'disabled';

  const showError = error && !data;

  const showDisabled = state === 'disabled' && !data && !error;

  return (
    <Column>
      <ColumnHeader
        icon='history'
        iconComponent={HistoryIcon}
        title='On This Day'
        multiColumn={false}
      />

      {isLoading ? (
        <LoadingIndicator />
      ) : showError ? (
        <div className={styles.wrapper}>
          <Helmet>
            <title>On This Day</title>
          </Helmet>
          <h1 className={styles.heading}>
            <FormattedMessage
              id='on_this_day.page.heading'
              defaultMessage='On This Day'
            />
          </h1>
          <p className={styles.emptyMessage}>
            <FormattedMessage
              id='on_this_day.page.error'
              defaultMessage='Failed to load memories. Try again later.'
            />
          </p>
        </div>
      ) : showDisabled ? (
        <div className={styles.wrapper}>
          <Helmet>
            <title>On This Day</title>
          </Helmet>
          <h1 className={styles.heading}>
            <FormattedMessage
              id='on_this_day.page.heading'
              defaultMessage='On This Day'
            />
          </h1>
          <p className={styles.emptyMessage}>
            <FormattedMessage
              id='on_this_day.page.disabled'
              defaultMessage='On This Day is not enabled. You can enable it in your preferences.'
            />
          </p>
        </div>
      ) : (
        <div className={styles.wrapper}>
          <Helmet>
            <title>On This Day</title>
          </Helmet>

          <h1 className={styles.heading}>
            <FormattedMessage
              id='on_this_day.page.heading'
              defaultMessage='On This Day'
            />
          </h1>

          {years.length === 0 ? (
            <p className={styles.emptyMessage}>
              <FormattedMessage
                id='on_this_day.page.empty'
                defaultMessage='No memories for today. Come back tomorrow!'
              />
            </p>
          ) : (
            years.map((year) => (
              <section key={year} className={styles.yearSection}>
                <h2 className={styles.yearHeading}>{year}</h2>
                <div className={styles.statusList}>
                  {data?.years[year]?.map((statusId) => (
                    <StatusQuoteManager
                      key={statusId}
                      id={statusId}
                      showActions
                    />
                  ))}
                </div>
              </section>
            ))
          )}
        </div>
      )}
    </Column>
  );
};

export default OnThisDayPage;
