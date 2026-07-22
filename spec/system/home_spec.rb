# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Home page' do
  context 'when signed in' do
    before { sign_in Fabricate(:user) }

    it 'visits the homepage and renders the web app' do
      visit root_path

      expect(page)
        .to have_css('noscript', text: /Mastodon/)
        .and have_css('body', class: 'app-body')
      expect(find('.app-holder#mastodon')['data-props'])
        .to eq('{"locale":"en"}')
    end
  end

  context 'when not signed in' do
    it 'is redirected to the static welcome page' do
      visit root_path

      expect(page).to have_current_path('/overview')
    end
  end
end
