# frozen_string_literal: true

class PrecomputeFeedService < BaseService
  include Redisable

<<<<<<< HEAD
  def call(account)
    FeedManager.instance.populate_home(account)

    account.owned_lists.each do |list|
      FeedManager.instance.populate_list(list)
=======
  def call(account, skip_filled_timelines: false)
    @skip_filled_timelines = skip_filled_timelines

    FeedManager.instance.populate_home(account) unless skip_timeline?(:home, account.id)

    account.owned_lists.each do |list|
      FeedManager.instance.populate_list(list) unless skip_timeline?(:list, list.id)
>>>>>>> v4.4.3
    end
  ensure
    HomeFeed.new(account).regeneration_finished!
  end

  private

  def skip_timeline?(type, id)
    @skip_filled_timelines && FeedManager.instance.timeline_size(type, id) * 2 > FeedManager::MAX_ITEMS
  end
end
