require "test_helper"

class SupplementAssistantTest < ActiveSupport::TestCase
  test "runs tools, sends results back, and returns the final answer with a trace" do
    client = FakeAnthropicClient.new(
      FakeAnthropicClient.tool_turn(
        [ "search_knowledge_base", { "query" => "magnesium sleep" } ],
        [ "search_products", { "query" => "magnesium glycinate", "in_stock_only" => true } ]
      ),
      FakeAnthropicClient.answer("Try magnesium glycinate [KB #1] [Product #1].")
    )

    result = SupplementAssistant.new(provider: claude(client)).ask("Best magnesium for sleep?")

    assert_equal :done, result.status
    assert_equal "Try magnesium glycinate [KB #1] [Product #1].", result.answer
    assert_equal %w[reasoning tool_call tool_result tool_call tool_result answer], result.trace.map { _1["type"] }

    # Both tool results go back in ONE user message, matched by tool_use_id.
    second_request = client.requests.last
    tool_results = second_request[:messages].last[:content]
    assert_equal %w[toolu_search_knowledge_base_0 toolu_search_products_1], tool_results.map { _1[:tool_use_id] }
    assert_includes JSON.parse(tool_results.last[:content])["results"].map { _1["name"] }, "Magnesium Glycinate 120 mg"

    # The assistant turn, thinking block included, is passed back unchanged.
    assistant_turn = second_request[:messages][-2]
    assert_equal "assistant", assistant_turn[:role]
    assert_equal "sig", assistant_turn[:content].first[:signature]
  end

  test "sends the expected request settings" do
    client = FakeAnthropicClient.new(FakeAnthropicClient.answer("Hi"))
    SupplementAssistant.new(provider: claude(client)).ask("Hello")

    request = client.requests.first
    assert_equal "claude-opus-5-5", request[:model]
    assert_equal({ type: :adaptive, display_: :summarized }, request[:thinking])
    assert_equal %w[search_knowledge_base search_products check_interactions], request[:tools].map { _1[:name] }
  end

  test "includes earlier turns so follow-up questions have context" do
    client = FakeAnthropicClient.new(FakeAnthropicClient.answer("Yes."))
    history = [
      { "role" => "user", "content" => "Tell me about B12" },
      { "role" => "assistant", "content" => [ { "type" => "text", "text" => "B12 is..." } ] }
    ]

    result = SupplementAssistant.new(provider: claude(client)).ask("Is it vegan?", history: history)

    assert_equal 3, client.requests.first[:messages].size
    assert_equal 4, result.api_messages.size
  end

  test "an unknown tool or bad input becomes an error result, not a crash" do
    client = FakeAnthropicClient.new(
      FakeAnthropicClient.tool_turn([ "check_interactions", { "substances" => [ "iron" ] } ], [ "made_up_tool", {} ]),
      FakeAnthropicClient.answer("Sorry.")
    )

    result = SupplementAssistant.new(provider: claude(client)).ask("Iron?")

    tool_results = client.requests.last[:messages].last[:content]
    assert tool_results.all? { _1[:is_error] }
    assert_equal :done, result.status
  end

  test "stops after MAX_STEPS when the model keeps calling tools" do
    turns = Array.new(SupplementAssistant::MAX_STEPS) { FakeAnthropicClient.tool_turn([ "search_knowledge_base", { "query" => "iron" } ]) }
    result = SupplementAssistant.new(provider: claude(FakeAnthropicClient.new(*turns))).ask("Iron?")

    assert_equal :step_limit, result.status
  end

  test "handles a refusal" do
    client = FakeAnthropicClient.new({ stop_reason: "refusal", content: [] })
    result = SupplementAssistant.new(provider: claude(client)).ask("…")

    assert_equal :refused, result.status
  end

  test "reports each step through on_step as it happens" do
    seen = []
    client = FakeAnthropicClient.new(
      FakeAnthropicClient.tool_turn([ "search_knowledge_base", { "query" => "iron" } ]),
      FakeAnthropicClient.answer("Done.")
    )
    SupplementAssistant.new(provider: claude(client), on_step: ->(step) { seen << step["type"] }).ask("Iron?")

    assert_equal %w[reasoning tool_call tool_result answer], seen
  end
end
