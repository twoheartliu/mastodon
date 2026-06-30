import { useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';

import { FormattedMessage } from 'react-intl';

import classNames from 'classnames';

import HistoryIcon from '@/material-icons/400-24px/history.svg?react';
import { Icon } from '@/mastodon/components/icon';
import { checkOnThisDay } from '@/mastodon/reducers/slices/on_this_day';
import { useAppDispatch, useAppSelector } from '@/mastodon/store';

export const OnThisDayNavItem: React.FC = () => {
  const dispatch = useAppDispatch();
  const { state } = useAppSelector((state) => state.onThisDay);
  const location = useLocation();
  const active = location.pathname.startsWith('/on_this_day');

  useEffect(() => {
    void dispatch(checkOnThisDay());
  }, [dispatch]);

  if (!state || state === 'pending' || state === 'disabled') {
    return null;
  }

  return (
    <Link
      to='/on_this_day'
      className={classNames('column-link column-link--transparent', { active })}
    >
      <Icon icon={HistoryIcon} width='24' height='24' />
      <FormattedMessage
        id='on_this_day.nav_item.title'
        defaultMessage='On This Day'
      />
    </Link>
  );
};
