# frozen_string_literal: true

class StatusesIndex < Chewy::Index
  include DatetimeClampingConcern

  settings index: index_preset(refresh_interval: '30s', number_of_shards: 5), analysis: {
    filter: {
      english_stop: {
        type: 'stop',
        stopwords: '_english_',
      },

      english_stemmer: {
        type: 'stemmer',
        language: 'english',
      },

      english_possessive_stemmer: {
        type: 'stemmer',
        language: 'possessive_english',
      },

      # Group adjacent CJK characters into overlapping bigrams so that
      # searching a Chinese word matches the exact substring instead of
      # the individual characters scattered anywhere in the document.
      # output_unigrams keeps single characters searchable.
      cjk_bigram: {
        type: 'cjk_bigram',
        output_unigrams: true,
      },

      # Search-time counterpart: emit only bigrams for CJK runs (lone
      # characters are still emitted). With unigrams present, the match
      # query would treat each unigram+bigram pair as synonyms and the
      # adjacency requirement would be lost.
      cjk_bigram_search: {
        type: 'cjk_bigram',
        output_unigrams: false,
      },
    },

    analyzer: {
      verbatim: {
        tokenizer: 'uax_url_email',
        filter: %w(lowercase cjk_bigram),
      },

      verbatim_search: {
        tokenizer: 'uax_url_email',
        filter: %w(lowercase cjk_bigram_search),
      },

      content: {
        tokenizer: 'standard',
        filter: %w(
          lowercase
          asciifolding
          cjk_width
          cjk_bigram
          elision
          english_possessive_stemmer
          english_stop
          english_stemmer
        ),
      },

      content_search: {
        tokenizer: 'standard',
        filter: %w(
          lowercase
          asciifolding
          cjk_width
          cjk_bigram_search
          elision
          english_possessive_stemmer
          english_stop
          english_stemmer
        ),
      },

      hashtag: {
        tokenizer: 'keyword',
        filter: %w(
          word_delimiter_graph
          lowercase
          asciifolding
          cjk_width
        ),
      },
    },
  }

  index_scope ::Status.unscoped.kept.without_reblogs.includes(:media_attachments, :local_mentioned, :local_favorited, :local_reblogged, :local_bookmarked, :tags, preview_cards_status: :preview_card, preloadable_poll: :local_voters), delete_if: ->(status) { status.searchable_by.empty? }

  root date_detection: false do
    field(:id, type: 'long')
    field(:account_id, type: 'long')
    field(:text, type: 'text', analyzer: 'verbatim', search_analyzer: 'verbatim_search', value: ->(status) { status.searchable_text }) { field(:stemmed, type: 'text', analyzer: 'content', search_analyzer: 'content_search') }
    field(:tags, type: 'text', analyzer: 'hashtag',  value: ->(status) { status.tags.map(&:display_name) })
    field(:searchable_by, type: 'long', value: ->(status) { status.searchable_by })
    field(:language, type: 'keyword')
    field(:properties, type: 'keyword', value: ->(status) { status.searchable_properties })
    field(:created_at, type: 'date', value: ->(status) { clamp_date(status.created_at) })
  end
end
