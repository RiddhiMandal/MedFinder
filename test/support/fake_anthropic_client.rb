# Stands in for Anthropic::Client in tests. It returns scripted responses,
# built as real SDK message objects, and records every request it receives,
# so tests can check what the agent sent without calling the API.
class FakeAnthropicClient
  attr_reader :requests

  def initialize(*responses)
    @responses = responses
    @requests = []
  end

  def beta = self
  def messages = self

  def create(**params)
    @requests << params.deep_dup # the agent keeps appending to the same messages array
    response = @responses.shift or raise "FakeAnthropicClient: no scripted response left"
    raise response if response.is_a?(Exception)

    Anthropic::Models::Beta::BetaMessage.new(
      id: "msg_#{@requests.size}", type: "message", role: "assistant", model: params[:model],
      stop_reason: response.fetch(:stop_reason), content: response.fetch(:content),
      usage: { input_tokens: 100, output_tokens: 20 }
    )
  end

  # Helpers for building scripted turns.
  def self.tool_turn(*calls, thinking: "Let me look that up.")
    {
      stop_reason: "tool_use",
      content: [ { type: "thinking", thinking: thinking, signature: "sig" } ] +
        calls.each_with_index.map { |(name, input), i| { type: "tool_use", id: "toolu_#{name}_#{i}", name: name, input: input } }
    }
  end

  def self.answer(text)
    { stop_reason: "end_turn", content: [ { type: "text", text: text } ] }
  end
end
