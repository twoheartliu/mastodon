# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdvancedTextFormatter do
  subject(:formatted) { described_class.new(text, preloaded_accounts: preloaded_accounts, content_type: content_type).to_s }

  let(:preloaded_accounts) { nil }

  context 'with Markdown input' do
    let(:content_type) { 'text/markdown' }

    context 'with common formatting' do
      let(:text) { "# Heading\n\n**strong** and `code`" }

      it 'renders Markdown as safe HTML' do
        expect(formatted).to eq '<h1>Heading</h1><p><strong>strong</strong> and <code>code</code></p>'
      end
    end

    context 'with a fenced code block' do
      let(:text) { "```\nreturn 0; // https://example.com\n```" }

      it 'preserves code without linkifying it' do
        expect(formatted).to include '<pre><code>return 0; // https://example.com<br></code></pre>'
        expect(formatted).to_not include 'href='
      end
    end

    context 'with a mention and hashtag' do
      let(:preloaded_accounts) { [Fabricate(:account, username: 'alice')] }
      let(:text) { '@alice #welcome' }

      it 'linkifies Mastodon entities' do
        expect(formatted).to include 'class="u-url mention"'
        expect(formatted).to include 'class="mention hashtag"'
      end
    end

    context 'with unsafe embedded HTML' do
      let(:text) { '<script>alert("xss")</script><img src="javascript:alert(1)">' }

      it 'removes executable markup' do
        expect(formatted).to_not include '<script>'
        expect(formatted).to_not include 'javascript:'
      end
    end
  end

  context 'with HTML input' do
    let(:content_type) { 'text/html' }
    let(:text) { '<h2>Heading</h2><p><em>Hello</em> <a href="https://example.com">world</a></p>' }

    it 'keeps supported formatting and secures external links' do
      expect(formatted).to include '<h2>Heading</h2>'
      expect(formatted).to include '<em>Hello</em>'
      expect(formatted).to include 'rel="nofollow noopener" target="_blank"'
    end

    context 'with executable markup and attributes' do
      let(:text) { '<p onclick="alert(1)" style="color:red">Safe</p><a href="javascript:alert(1)">bad</a><iframe src="https://example.com"></iframe>' }

      it 'keeps only safe content' do
        expect(formatted).to eq '<p>Safe</p>bad'
      end
    end
  end
end
