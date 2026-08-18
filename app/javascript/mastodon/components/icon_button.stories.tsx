import { useCallback, useEffect, useState } from 'react';

import type { Meta, StoryObj } from '@storybook/react-vite';
import { expect, waitFor } from 'storybook/test';

import StarIcon from '@/material-icons/400-24px/star-fill.svg?react';
import StarBorderIcon from '@/material-icons/400-24px/star.svg?react';

import { IconButton } from './icon_button';

import '../../styles/mastodon-bird-ui-auto.scss';

const FavouriteButton = () => {
  const [active, setActive] = useState(false);
  const [count, setCount] = useState(0);

  useEffect(() => {
    document.documentElement.classList.add('no-reduce-motion');

    return () => {
      document.documentElement.classList.remove('no-reduce-motion');
    };
  }, []);

  const handleClick = useCallback(() => {
    setActive((previousActive) => {
      setCount(previousActive ? 0 : 1);
      return !previousActive;
    });
  }, []);

  return (
    <div className='layout-single-column'>
      <div className='status'>
        <div className='status__action-bar'>
          <div className='status__action-bar__button-wrapper'>
            <IconButton
              className='status__action-bar__button star-icon'
              animate
              active={active}
              title={active ? 'Remove from favorites' : 'Favorite'}
              icon='star'
              iconComponent={active ? StarIcon : StarBorderIcon}
              onClick={handleClick}
              counter={count}
            />
          </div>
        </div>
      </div>
    </div>
  );
};

const meta = {
  title: 'Components/IconButton/Favourite',
  component: FavouriteButton,
} satisfies Meta<typeof FavouriteButton>;

export default meta;
type Story = StoryObj<typeof meta>;

export const CounterAlignment: Story = {
  play: async ({ canvas, userEvent }) => {
    const button = canvas.getByRole('button', { name: 'Favorite' });
    const icon = button.querySelector('.icon');

    await expect(icon).not.toBeNull();
    const rectBefore = icon?.getBoundingClientRect();
    const centerBefore = (rectBefore?.x ?? 0) + (rectBefore?.width ?? 0) / 2;

    await userEvent.click(button);
    await waitFor(() => expect(button).toHaveTextContent('1'));
    await new Promise<void>((resolve) => {
      window.setTimeout(resolve, 250);
    });

    const activeIcon = button.querySelector('.icon');
    const activeStyle = activeIcon ? window.getComputedStyle(activeIcon) : null;
    const rectDuring = activeIcon?.getBoundingClientRect();
    const centerDuring = (rectDuring?.x ?? 0) + (rectDuring?.width ?? 0) / 2;

    await expect(activeStyle?.animationName).toBe('spring-rotate-in');
    await expect(Math.abs(centerDuring - centerBefore)).toBeLessThan(0.1);

    await new Promise<void>((resolve) => {
      window.setTimeout(resolve, 850);
    });

    const rectAfter = activeIcon?.getBoundingClientRect();
    const centerAfter = (rectAfter?.x ?? 0) + (rectAfter?.width ?? 0) / 2;

    await expect(button).toHaveClass('activate');
    await expect(Math.abs(centerAfter - centerBefore)).toBeLessThan(0.1);
  },
};
