# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StatusesSearchService do
  describe '#call' do
    let!(:status) { Fabricate(:status, text: 'status number one') }
    let(:results) { subject.call('one', status.account, limit: 5) }

    before { Fabricate(:status, text: 'status number two') }

    context 'when elasticsearch is enabled', :search do
      it 'runs a search for statuses' do
        expect(results)
          .to have_attributes(
            size: 1,
            first: eq(status)
          )
      end
    end

    context 'when searching Chinese text', :search do
      let!(:matching)  { Fabricate(:status, text: '在那年今日看到了三年前的回忆') }
      let!(:scattered) { Fabricate(:status, text: '今年那个日志项目今天上线了') }

      it 'matches the exact substring rather than scattered characters' do
        results = subject.call('那年今日', matching.account, limit: 5)

        expect(results).to include(matching)
        expect(results).to_not include(scattered)
      end

      it 'still matches a lone character via the unigram fallback' do
        single_char = Fabricate(:status, text: '猫')

        expect(subject.call('猫', single_char.account, limit: 5))
          .to include(single_char)
      end
    end
  end
end
