require "test_helper"

class AgentRunJobTest < ActiveJob::TestCase
  setup do
    @conversation = Conversation.create!
    @conversation.messages.create!(role: "user", body: "Iron and calcium?")
    @answer = @conversation.messages.create!(role: "assistant", body: "…", status: "working")
  end

  test "saves the answer, the trace and the API transcript" do
    client = FakeAnthropicClient.new(
      FakeAnthropicClient.tool_turn([ "check_interactions", { "substances" => [ "iron", "calcium" ] } ]),
      FakeAnthropicClient.answer("Take them two hours apart.")
    )

    AgentRunJob.perform_now(@answer.id, "Iron and calcium?", provider: claude(client))

    @answer.reload
    assert_equal "done", @answer.status
    assert_equal "Take them two hours apart.", @answer.body
    assert_equal 1, @answer.tool_calls.size
    assert_equal 4, @conversation.reload.api_messages.size
  end

  test "shows a helpful message when the API key is wrong" do
    error = Anthropic::Errors::AuthenticationError.new(
      url: URI("https://api.anthropic.com/v1/messages"), status: 401, headers: {}, body: nil, request: nil, response: nil
    )
    AgentRunJob.perform_now(@answer.id, "Iron and calcium?", provider: claude(FakeAnthropicClient.new(error)))

    @answer.reload
    assert_equal "error", @answer.status
    assert_match(/ANTHROPIC_API_KEY/, @answer.body)
    assert_empty @conversation.reload.api_messages
  end
end
