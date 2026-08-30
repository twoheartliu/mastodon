# frozen_string_literal: true

# == Schema Information
#
# Table name: wxw_emoji_sections
#
#  id         :bigint(8)        not null, primary key
#  name       :string           default(""), not null
#  position   :integer          default(0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Wxw::EmojiSection < ApplicationRecord
  include Wxw::Named

  has_many :packs,
           class_name: 'Wxw::EmojiPack',
           foreign_key: :section_id,
           inverse_of: :section,
           dependent: :restrict_with_error
  scope :ordered, -> { includes(:translations).order(:position, :id) }
end
