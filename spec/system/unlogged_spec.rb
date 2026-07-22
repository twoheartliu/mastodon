# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'UnloggedBrowsing', :js, :streaming do
  subject { page }

  before do
    visit root_path
  end

  it 'is redirected to the static welcome page' do
    expect(subject).to have_current_path('/overview')
  end
end
