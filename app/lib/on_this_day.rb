# frozen_string_literal: true

class OnThisDay
  CST_ZONE = 'Asia/Shanghai'

  # Return today's date in Beijing time (UTC+8)
  def self.today_cst
    Time.now.utc.in_time_zone(CST_ZONE).to_date
  end

  def self.cst_time_zone
    @cst_time_zone ||= ActiveSupport::TimeZone[CST_ZONE]
  end

  def initialize(account, date = nil)
    @account = account
    @date = date || self.class.today_cst
  end

  # Returns the state of today's record for this account.
  # 'ready'   → record exists and has statuses (data['years'] is non-empty)
  # 'empty'   → record exists but has no matching statuses
  # 'pending' → no record exists yet
  def state
    record = OnThisDayRecord.find_by(account: @account, date: @date)
    return 'pending' unless record

    record.status_ids.any? ? 'ready' : 'empty'
  end

  # Generate the on_this_day record for the given date.
  # Queries statuses from past years matching the month+day,
  # groups them by year, and stores the result.
  # No-op if a record already exists for this account+date.
  def generate
    return if OnThisDayRecord.exists?(account: @account, date: @date)

    statuses = find_statuses

    OnThisDayRecord.create!(
      account: @account,
      date: @date,
      data: build_data(statuses)
    )
  rescue ActiveRecord::RecordNotUnique
    # Another worker already created the record — fine
    true
  end

  private

  # Query statuses from the same month+day in past years (registration year through last year).
  # Visibility: public + unlisted only. Excludes reblogs, replies (except self-replies).
  # Respects current blocks and mutes.
  # Sorted by created_at ascending (chronological order from morning to night).
  def find_statuses
    month = @date.month
    day = @date.day
    start_year = @account.created_at.year
    end_year = @date.year - 1

    return Status.none if start_year > end_year

    all_statuses = Status.none

    (start_year..end_year).each do |year|
      begin
        Date.new(year, month, day)
      rescue Date::Error
        # Skip Feb 29 in non-leap years
        next
      end

      cst_begin = self.class.cst_time_zone.local(year, month, day).beginning_of_day
      cst_end   = self.class.cst_time_zone.local(year, month, day).end_of_day
      next if cst_end >= Time.now.utc

      year_statuses = @account.statuses
                              .distributable_visibility
                              .without_reblogs
                              .without_replies
                              .kept
                              .where(created_at: cst_begin..cst_end)

      all_statuses = all_statuses.or(Status.where(id: year_statuses.select(:id)))
    end

    # Respect blocks and mutes
    all_statuses = all_statuses.not_excluded_by_account(@account)
    all_statuses = all_statuses.not_domain_blocked_by_account(@account)

    all_statuses.order(created_at: :asc)
  end

  # Build the data JSONB hash from queried statuses.
  # Groups status IDs by year, oldest year first in the hash.
  def build_data(statuses)
    grouped = statuses.group_by { |s| s.created_at.year }
                      .transform_values { |list| list.map(&:id).map(&:to_s) }

    { 'years' => grouped }
  end
end
