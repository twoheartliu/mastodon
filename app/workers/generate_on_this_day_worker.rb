# frozen_string_literal: true

class GenerateOnThisDayWorker
  include Sidekiq::Worker

  def perform(account_id)
    OnThisDay.new(Account.find(account_id)).generate
  rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordNotUnique
    true
  end
end
