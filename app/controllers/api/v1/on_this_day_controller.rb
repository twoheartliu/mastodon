# frozen_string_literal: true

class Api::V1::OnThisDayController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read, :'read:statuses' }
  before_action :require_user!
  before_action :require_on_this_day_enabled!, only: [:show]

  def show
    record = OnThisDayRecord.find_by(
      account_id: current_account.id,
      date: OnThisDay.today_cst
    )

    raise ActiveRecord::RecordNotFound unless record
    raise ActiveRecord::RecordNotFound if record.status_ids.empty?

    @presenter = OnThisDayPresenter.new(record)
    @relationships = StatusRelationshipsPresenter.new(@presenter.statuses, current_account.id)

    render json: @presenter,
           serializer: REST::OnThisDaySerializer,
           relationships: @relationships
  end

  def state
    unless current_account.user.setting_on_this_day_enabled
      return render json: { state: 'disabled', date: OnThisDay.today_cst.to_s }
    end

    on_this_day = OnThisDay.new(current_account)
    on_this_day.generate if on_this_day.state == 'pending'
    render json: { state: on_this_day.state, date: OnThisDay.today_cst.to_s }
  rescue => e
    Rails.logger.error "OnThisDay#state failed: #{e.class}: #{e.message}"
    render json: { state: 'error', date: OnThisDay.today_cst.to_s }, status: 500
  end

  private

  def require_on_this_day_enabled!
    render json: { error: 'Feature not enabled' }, status: 403 unless current_account.user.setting_on_this_day_enabled
  end
end
