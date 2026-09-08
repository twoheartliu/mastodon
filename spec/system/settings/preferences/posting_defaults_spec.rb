# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Settings preferences posting defaults page' do
  let(:user) { Fabricate :user }

  before { sign_in user }

  it 'Views and updates user prefs' do
    visit settings_preferences_posting_defaults_path

    expect(page)
      .to have_private_cache_control
    expect(page).to have_checked_field(show_content_type_choice_field)

    check mark_sensitive_field
    choose markdown_content_type_field
    check show_content_type_choice_field

    expect { save_changes }
      .to change { user.reload.settings.default_sensitive }.to(true)
    expect(user.settings.default_content_type).to eq 'text/markdown'
    expect(user.settings.show_content_type_choice).to be true
    expect(page)
      .to have_title(I18n.t('preferences.posting_defaults'))
  end

  it 'preserves an explicit choice to hide the posting format selector' do
    visit settings_preferences_posting_defaults_path

    uncheck show_content_type_choice_field

    expect { save_changes }
      .to change { user.reload.settings.show_content_type_choice }.from(true).to(false)

    visit settings_preferences_posting_defaults_path

    expect(page).to have_unchecked_field(show_content_type_choice_field)
  end

  def save_changes
    click_on submit_button
  end

  def mark_sensitive_field
    form_label('defaults.setting_default_sensitive')
  end

  def markdown_content_type_field
    form_label('defaults.setting_default_content_type_markdown')
  end

  def show_content_type_choice_field
    form_label('defaults.setting_show_content_type_choice')
  end
end
