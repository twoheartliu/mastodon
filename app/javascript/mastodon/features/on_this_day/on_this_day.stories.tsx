import type { Meta, StoryObj } from '@storybook/react-vite';
import { action } from 'storybook/actions';

import type { AnyFunction, OmitValueType } from '@/mastodon/utils/types';

import type { OnThisDayAnnouncementProps } from './announcement';
import { OnThisDayAnnouncement } from './announcement';

type Props = OmitValueType<
  Omit<OnThisDayAnnouncementProps, 'state'> & {
    reportState: OnThisDayAnnouncementProps['state'];
  },
  AnyFunction
>;

const meta = {
  title: 'Components/OnThisDay/Announcement',
  args: {
    reportState: 'ready',
  },
  argTypes: {
    reportState: {
      control: {
        type: 'select',
      },
      options: ['ready', 'pending'],
    },
  },
  render({ reportState, ...args }: Props) {
    return (
      <OnThisDayAnnouncement
        state={reportState}
        {...args}
        onDismiss={action('dismissed announcement')}
        onShow={action('opened on this day')}
      />
    );
  },
} satisfies Meta<Props>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Ready: Story = {};

export const Pending: Story = {
  args: {
    reportState: 'pending',
  },
};
