# == Schema Information
#
# Table name: release_metadata
#
#  id                      :uuid             not null, primary key
#  locale                  :string           not null, indexed => [release_platform_run_id]
#  promo_text              :text
#  release_notes           :text
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  release_id              :uuid
#  release_platform_run_id :uuid             indexed, indexed => [locale]
#
class ReleaseMetadata < ApplicationRecord
  has_paper_trail

  belongs_to :release, inverse_of: :release_metadata

  DEFAULT_LOCALE = "en-US"
  DEFAULT_RELEASE_NOTES = "The latest version contains bug fixes and performance improvements."
  PLAINTEXT_REGEX = /\A[!@#$%^&*()_+\-=\[\]{};':"\\|,.\/?\s\p{Alnum}\p{P}\p{Zs}\p{Emoji_Presentation}]+\z/

  # TODO: Remove this accessor, once the migration is complete
  attr_accessor :in_data_migration_mode

  validates :release_notes, format: {with: PLAINTEXT_REGEX, message: :no_special_characters, multiline: true}, length: {maximum: 4000}
  validates :promo_text, format: {with: PLAINTEXT_REGEX, message: :no_special_characters, allow_blank: true, multiline: true}, length: {maximum: 170}, unless: :in_data_migration_mode
end
