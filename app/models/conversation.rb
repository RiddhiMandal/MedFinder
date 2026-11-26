# A chat thread.
#
# `messages` are the rows the UI shows (one per question, one per answer).
# `api_messages` is the full transcript in Claude Messages API format,
# including tool calls, tool results and thinking blocks. The agent sends it
# back unchanged on the next turn, which is what lets follow-up questions
# ("is the second one cheaper?") work.
class Conversation < ApplicationRecord
  has_many :messages, -> { order(:created_at, :id) }, dependent: :destroy

  def display_title
    title.presence || "New conversation"
  end
end
