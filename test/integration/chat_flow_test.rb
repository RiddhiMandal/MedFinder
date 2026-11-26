require "test_helper"

class ChatFlowTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "asking a question saves it and queues the agent" do
    post conversations_path
    conversation = Conversation.last
    follow_redirect!
    assert_response :success

    assert_enqueued_with(job: AgentRunJob) do
      post conversation_messages_path(conversation), params: { message: { body: "Is B12 vegan?" } }, as: :turbo_stream
    end
    assert_response :success
    assert_equal %w[user assistant], conversation.messages.map(&:role)
    assert_equal "Is B12 vegan?", conversation.reload.title
  end

  test "a second question waits until the first is answered" do
    conversation = Conversation.create!
    conversation.messages.create!(role: "assistant", body: "…", status: "working")

    post conversation_messages_path(conversation), params: { message: { body: "Another?" } }, as: :turbo_stream
    assert_response :conflict
  end
end
