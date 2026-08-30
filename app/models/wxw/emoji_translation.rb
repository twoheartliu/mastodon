# frozen_string_literal: true

# == Schema Information
#
# Table name: wxw_emoji_translations
#
#  id                :bigint(8)        not null, primary key
#  language          :string           not null
#  name              :string           default(""), not null
#  translatable_type :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  translatable_id   :bigint(8)        not null
#
class Wxw::EmojiTranslation < ApplicationRecord
  belongs_to :translatable, polymorphic: true
  validates :language, presence: true, uniqueness: { scope: [:translatable_type, :translatable_id] }
  validates :name, presence: true, length: { maximum: Wxw::Named::NAME_LIMIT }
end
