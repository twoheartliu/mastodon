# frozen_string_literal: true

# == Schema Information
#
# Table name: on_this_day_records
#
#  id         :bigint(8)        not null, primary key
#  data       :jsonb            not null
#  date       :date             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint(8)        not null
#

class OnThisDayRecord < ApplicationRecord
  belongs_to :account

  validates :date, uniqueness: { scope: :account_id }

  # @return [Array<String>] all status IDs across all years, flattened
  def status_ids
    data['years']&.values&.flatten || []
  end

  # @return [Array<String>] sorted year keys descending (newest first)
  def years
    data['years']&.keys&.sort&.reverse || []
  end

  # @return [Boolean] whether this record is for today (UTC+8)
  def today?
    date == OnThisDay.today_cst
  end
end
