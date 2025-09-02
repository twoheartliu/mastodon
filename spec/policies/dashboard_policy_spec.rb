# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DashboardPolicy do
  subject { described_class }

<<<<<<< HEAD
  let(:admin) { Fabricate(:user, role: UserRole.find_by(name: 'Admin')).account }
=======
  let(:admin) { Fabricate(:admin_user).account }
>>>>>>> v4.4.3
  let(:account) { Fabricate(:account) }

  permissions :index? do
    context 'with an admin' do
      it { is_expected.to permit(admin, nil) }
    end

    context 'with a non-admin' do
      it { is_expected.to_not permit(account, nil) }
    end
  end
end
