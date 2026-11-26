# One bubble in the chat. Assistant messages carry a `trace`: the ordered
# steps the agent took (reasoning summaries, tool calls, tool results), which
# the UI shows under "How I got this answer".
class Message < ApplicationRecord
  ROLES = %w[user assistant].freeze

  belongs_to :conversation

  validates :role, inclusion: { in: ROLES }
  validates :body, presence: true

  def assistant? = role == "assistant"

  def tool_calls = trace.select { |step| step["type"] == "tool_call" }
end
