# frozen_string_literal: true

class OnThisDayPresenter
  alias read_attribute_for_serialization send

  attr_reader :record

  def initialize(record)
    @record = record
  end

  def date
    record.date.to_s
  end

  def data
    record.data
  end

  def accounts
    @accounts ||= Account.where(id: record.account_id).includes(:account_stat)
  end

  def statuses
    @statuses ||= Status.where(id: record.status_ids)
                        .with_includes
                        .order(created_at: :asc)
  end

  def self.model_name
    @model_name ||= ActiveModel::Name.new(self)
  end
end
