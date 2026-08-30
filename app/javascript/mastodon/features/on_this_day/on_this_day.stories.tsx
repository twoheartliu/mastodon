import type { Meta, StoryObj } from '@storybook/react-vite';
import { action } from 'storybook/actions';

import type { OnThisDayAnnouncementProps } from './announcement';
import { OnThisDayAnnouncement } from './announcement';

interface StoryProps {
  reportState: OnThisDayAnnouncementProps['state'];
}

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
  render({ reportState }: StoryProps) {
    return (
      <OnThisDayAnnouncement
        state={reportState}
        onDismiss={action('dismissed announcement')}
        onShow={action('opened on this day')}
      />
    );
  },
} satisfies Meta<StoryProps>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Ready: Story = {};

export const Pending: Story = {
  args: {
    reportState: 'pending',
  },
};
