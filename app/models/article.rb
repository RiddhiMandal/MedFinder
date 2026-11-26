# One entry in the knowledge base: a short, plain-language note on a
# supplement or topic. The agent searches these and cites them by id.
class Article < ApplicationRecord
  include KeywordSearchable

  search_columns title: 5, topic: 4, body: 1

  validates :title, :topic, :body, presence: true

  def to_tool_json
    { id: id, title: title, body: body.squish, sources: sources }
  end
end
