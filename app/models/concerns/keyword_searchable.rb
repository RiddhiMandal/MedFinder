# Small, dependency-free keyword search.
#
# Each model lists the columns to search and a weight for each. A query is
# split into terms (stop words dropped), each term is matched against each
# column, and records are ranked by the summed weight of the matches.
#
# Matching happens in Ruby rather than SQL because the knowledge base is a few
# dozen rows. That keeps the project easy to run (SQLite, no vector database).
# Swapping in full-text search or embeddings later only means replacing this
# module; the agent's tools don't change.
module KeywordSearchable
  extend ActiveSupport::Concern

  STOP_WORDS = %w[
    a an and are as at be by can do does for from how i in is it me my of on or
    should take taking the to what which with you your about best good
  ].freeze

  def self.terms(query)
    query.to_s.downcase.scan(/[a-z0-9\-]+/).reject { |t| STOP_WORDS.include?(t) || t.length < 2 }.uniq
  end

  class_methods do
    def search_columns(weights = nil)
      @search_columns = weights if weights
      @search_columns
    end

    # Returns [[record, score], ...] sorted by score, best first.
    def keyword_search(query, scope: all, limit: 5)
      terms = KeywordSearchable.terms(query)
      return [] if terms.empty?

      scope.to_a.filter_map do |record|
        score = terms.sum do |term|
          search_columns.sum do |column, weight|
            record.public_send(column).to_s.downcase.include?(term) ? weight : 0
          end
        end
        [ record, score ] if score.positive?
      end.sort_by { |(_, score)| -score }.first(limit)
    end
  end
end
