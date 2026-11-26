# The agent: a hand-written tool-use loop.
#
#   1. Send the conversation so far, the system prompt and the tool definitions
#      to the model.
#   2. If the model answers with tool_use blocks, run each tool against our
#      database and send all the results back in one message.
#   3. Repeat until the model stops asking for tools (or MAX_STEPS is reached).
#
# Along the way it records a trace of what happened (reasoning, tool calls,
# tool results) so the UI can show how the answer was reached.
#
# The model is pluggable (see Llm): Claude via the Anthropic API, or a free
# local model via Ollama. This class doesn't know or care which one it has.
class SupplementAssistant
  MAX_STEPS = 8

  TOOLS = [ Tools::SearchKnowledgeBase, Tools::SearchProducts, Tools::CheckInteractions ].freeze

  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are a supplement information assistant for an online wellness store. You help
    people understand supplements and find products in the store's catalog.

    How to work:
    - Ground every factual claim in the knowledge base. Search it before answering
      questions about what a supplement does, forms, doses, timing or safety.
    - Use search_products for anything about products, prices or stock. Only recommend
      products the tool returned, and mention price and stock status.
    - Whenever the user mentions more than one supplement, or any medication, call
      check_interactions before recommending anything.
    - If the tools don't cover the question, say so plainly instead of filling the gap
      from general knowledge.

    How to answer:
    - Be concise and practical: a short direct answer first, then details.
    - Cite knowledge base articles inline as [KB #id] and products as [Product #id], where
      id is the number a tool returned (for example [KB #3]). Never cite anything else in
      brackets; for interaction results, write "according to the interactions database".
    - Only state doses, timing or other specifics that appear in the tool results.
    - You give general information, not medical advice. For pregnancy, prescription
      medication, chronic conditions, children, or symptoms that need diagnosis, tell
      the user to check with a healthcare practitioner or pharmacist. Never tell anyone
      to stop or change a prescribed medication.
  PROMPT

  Result = Data.define(:answer, :trace, :api_messages, :status)

  def initialize(provider: Llm.default_provider, on_step: nil)
    @provider = provider
    @on_step = on_step
    @tools = TOOLS.to_h { |tool| [ tool.tool_name, tool.new ] }
  end

  # history: the conversation's earlier api_messages. Returns a Result whose
  # api_messages include this turn, ready to be saved for the next one.
  def ask(question, history: [])
    messages = history.map(&:deep_symbolize_keys) + [ { role: "user", content: question } ]
    @trace = []

    MAX_STEPS.times do
      response = @provider.chat(system: SYSTEM_PROMPT, messages: messages, tools: TOOLS.map(&:definition))
      @model_label = response.model
      blocks = response.content

      # Append the model's turn exactly as returned (thinking blocks included);
      # Claude needs them back unchanged on the next request.
      messages << { role: "assistant", content: blocks }
      record_reasoning(blocks)

      case response.stop_reason.to_s
      when "tool_use"
        messages << { role: "user", content: run_tools(blocks) }
      when "refusal"
        return finish(messages, "I can't help with that request. Please talk to a healthcare practitioner.", :refused)
      when "max_tokens"
        return finish(messages, text_of(blocks).presence || "My answer was cut off. Please try a narrower question.", :truncated)
      else
        return finish(messages, text_of(blocks), :done)
      end
    end

    finish(messages, "I couldn't finish within #{MAX_STEPS} steps. Please try rephrasing the question.", :step_limit)
  end

  private

  # Run every tool_use block in this turn. All results go back in a single
  # user message (splitting them discourages parallel tool calls).
  def run_tools(blocks)
    blocks.select { |b| b[:type].to_s == "tool_use" }.map do |call|
      input = (call[:input] || {}).deep_stringify_keys
      step!(type: "tool_call", tool: call[:name], input: input)

      result, is_error = execute(call[:name], input)
      step!(type: "tool_result", tool: call[:name], output: result, error: is_error)

      { type: "tool_result", tool_use_id: call[:id], content: result.to_json, is_error: is_error }
    end
  end

  def execute(name, input)
    tool = @tools[name]
    return [ { error: "Unknown tool: #{name}" }, true ] unless tool

    [ tool.call(input), false ]
  rescue Tools::InputError => e
    [ { error: e.message }, true ]
  rescue StandardError => e
    Rails.logger.error("[agent] #{name} failed: #{e.class}: #{e.message}")
    [ { error: "The #{name} tool failed. Try again or continue without it." }, true ]
  end

  def record_reasoning(blocks)
    blocks.each do |block|
      case block[:type].to_s
      when "thinking"
        step!(type: "reasoning", text: block[:thinking]) if block[:thinking].present?
      when "text"
        # Text alongside tool calls is the model narrating its plan.
        step!(type: "note", text: block[:text]) if block[:text].present? && blocks.any? { |b| b[:type].to_s == "tool_use" }
      end
    end
  end

  def finish(messages, answer, status)
    step!(type: "answer", status: status.to_s, model: @model_label)
    Result.new(answer: answer, trace: @trace, api_messages: messages, status: status)
  end

  def step!(step)
    step = step.deep_stringify_keys
    @trace << step
    @on_step&.call(step)
  end

  def text_of(blocks)
    blocks.select { |b| b[:type].to_s == "text" }.map { |b| b[:text] }.join("\n\n").strip
  end
end
