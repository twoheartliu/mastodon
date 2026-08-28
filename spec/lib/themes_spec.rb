# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Themes do
  subject(:themes) { described_class.instance }

  describe '#flavours' do
    it 'includes every packaged flavour' do
      expect(themes.flavours).to contain_exactly('nofan', 'fanfou')
    end
  end

  describe '#flavour' do
    it 'exposes the pack directory' do
      expect(themes.flavour('nofan'))
        .to include('pack_directory' => 'app/javascript/entrypoints')
    end

    it 'returns nil for unknown flavours' do
      expect(themes.flavour('nonexistent')).to be_nil
    end
  end

  describe '#skins_for' do
    it 'lists every skin shipped under the nofan flavour' do
      expect(themes.skins_for('nofan')).to contain_exactly(
        'default', 'mastodon-bird-ui-auto', 'fanfou_classic',
        'vermilion_seal', 'space_fanfou', 'graphite'
      )
    end

    it 'lists the fanfou flavour skins' do
      expect(themes.skins_for('fanfou')).to eq(['default'])
    end

    it 'returns an empty list for unknown flavours' do
      expect(themes.skins_for('nonexistent')).to eq([])
    end
  end

  describe '#all_skins' do
    it 'unions skins across flavours' do
      expect(themes.all_skins).to include('default', 'graphite', 'fanfou_classic')
    end
  end
end
