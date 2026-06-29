# frozen_string_literal: true

class REST::OnThisDaySerializer < ActiveModel::Serializer
  attributes :date, :data

  has_many :accounts, serializer: REST::AccountSerializer
  has_many :statuses, serializer: REST::StatusSerializer
end
