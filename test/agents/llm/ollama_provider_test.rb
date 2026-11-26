require "test_helper"

class OllamaProviderTest < ActiveSupport::TestCase
  # Records the request body and returns a scripted Ollama /api/chat response.
  class FakeHttp
    attr_reader :bodies

    def initialize(*responses) = (@responses = responses; @bodies = [])

    def post_json(_uri, body)
      @bodies << body.deep_dup
      @responses.shift
    end
  end

  def provider(http) = Llm::OllamaProvider.new(model: "qwen3:8b", http: http)

  TOOLS = SupplementAssistant::TOOLS.map(&:definition)

  test "turns Ollama tool_calls and thinking into tool_use and thinking blocks" do
    http = FakeHttp.new({
      "message" => {
        "role" => "assistant", "content" => "", "thinking" => "Check the knowledge base.",
        "tool_calls" => [ { "function" => { "name" => "search_knowledge_base", "arguments" => { "query" => "iron" } } } ]
      },
      "done_reason" => "stop"
    })

    response = provider(http).chat(system: "sys", messages: [ { role: "user", content: "Iron?" } ], tools: TOOLS)

    assert_equal "tool_use", response.stop_reason
    assert_equal %w[thinking tool_use], response.content.map { _1[:type] }
    call = response.content.last
    assert_equal "search_knowledge_base", call[:name]
    assert_equal({ "query" => "iron" }, call[:input])
    assert_match(/\Acall_/, call[:id])
  end

  test "sends tools in Ollama's function format with the system prompt first" do
    http = FakeHttp.new({ "message" => { "role" => "assistant", "content" => "Hi" }, "done_reason" => "stop" })
    provider(http).chat(system: "sys", messages: [ { role: "user", content: "Hello" } ], tools: TOOLS)

    body = http.bodies.first
    assert_equal({ role: "system", content: "sys" }, body[:messages].first)
    assert_equal "function", body[:tools].first[:type]
    assert_equal "search_knowledge_base", body[:tools].first[:function][:name]
    assert_equal "object", body[:tools].first[:function][:parameters][:type]
  end

  test "translates the agent's tool turn history into assistant tool_calls and tool messages" do
    http = FakeHttp.new({ "message" => { "role" => "assistant", "content" => "Done" }, "done_reason" => "stop" })
    history = [
      { role: "user", content: "Iron?" },
      { role: "assistant", content: [
        { type: "thinking", thinking: "hmm" },
        { type: "tool_use", id: "call_1", name: "search_knowledge_base", input: { "query" => "iron" } }
      ] },
      { role: "user", content: [ { type: "tool_result", tool_use_id: "call_1", content: "{\"results\":[]}" } ] }
    ]

    response = provider(http).chat(system: "sys", messages: history, tools: TOOLS)
    sent = http.bodies.first[:messages]

    assert_equal %w[system user assistant tool], sent.map { _1[:role] }
    assert_equal "search_knowledge_base", sent[2][:tool_calls].first[:function][:name]
    assert_equal({ role: "tool", tool_name: "search_knowledge_base", content: "{\"results\":[]}" }, sent[3])
    assert_equal "end_turn", response.stop_reason
    assert_equal [ { type: "text", text: "Done" } ], response.content
  end

  test "parses string arguments and strips stray <think> tags" do
    http = FakeHttp.new({
      "message" => { "role" => "assistant", "content" => "<think>x</think>Answer",
                     "tool_calls" => [ { "function" => { "name" => "search_products", "arguments" => "{\"query\":\"b12\"}" } } ] }
    })
    response = provider(http).chat(system: "s", messages: [ { role: "user", content: "q" } ], tools: TOOLS)

    assert_equal({ "query" => "b12" }, response.content.last[:input])
    assert_equal "Answer", response.content.first[:text]
  end

  test "a connection failure becomes a friendly ProviderError" do
    unreachable = Llm::OllamaProvider.new(url: "http://127.0.0.1:9")
    error = assert_raises(Llm::ProviderError) { unreachable.chat(system: "s", messages: [], tools: []) }
    assert_match(/ollama serve/, error.message)
  end

  test "the full agent loop runs on the Ollama provider" do
    http = FakeHttp.new(
      { "message" => { "role" => "assistant", "content" => "",
                       "tool_calls" => [ { "function" => { "name" => "check_interactions", "arguments" => { "substances" => %w[iron calcium] } } } ] } },
      { "message" => { "role" => "assistant", "content" => "Take them two hours apart." }, "done_reason" => "stop" }
    )

    result = SupplementAssistant.new(provider: provider(http)).ask("Iron and calcium?")

    assert_equal :done, result.status
    assert_equal "Take them two hours apart.", result.answer
    assert_equal "qwen3:8b (local, Ollama)", result.trace.last["model"]
    assert_match(/two hours apart/, http.bodies.last[:messages].last[:content])
  end
end
