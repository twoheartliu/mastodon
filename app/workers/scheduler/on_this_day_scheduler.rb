# frozen_string_literal: true

class Scheduler::OnThisDayScheduler
  include Sidekiq::Worker

  sidekiq_options retry: 0, lock: :until_executed, lock_ttl: 1.day.to_i

  # Runs daily at ~00:05 CST (16:05 UTC).
  # Finds all opted-in users and fans out generation workers.
  def perform
    User.confirmed
        .where("settings->>'on_this_day_enabled' = 'true'")
        .includes(:account)
        .find_each do |user|
      GenerateOnThisDayWorker.perform_async(user.account_id) if user.account
    end
  end
end
