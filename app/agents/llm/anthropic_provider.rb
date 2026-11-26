module Llm
  # Claude through the official `anthropic` gem. The agent's message format
  # is already the Messages API format, so this mostly passes things through.
  class AnthropicProvider
    DEFAULT_MODEL = "claude-opus-5-5"
    MAX_TOKENS = 16_000

    attr_reader :model

    def initialize(client: nil, model: ENV.fetch("ANTHROPIC_MODEL", DEFAULT_MODEL))
      @client = client || Anthropic::Client.new
      @model = model
    end

    def chat(system:, messages:, tools:)
      response = @client.beta.messages.create(
        model: model,
        max_tokens: MAX_TOKENS,
        system_: system,
        tools: tools,
        messages: claude_messages(messages),
        # Summarized thinking is what the UI shows as the agent's reasoning.
        thinking: { type: :adaptive, display_: :summarized },
        output_config: { effort: :medium },
        # Cache the growing prefix (tools, system prompt, history) across the
        # several requests one question can take.
        cache_control: { type: :ephemeral },
        # If a safety classifier declines, retry server-side on the model's
        # default fallback instead of failing the turn.
        fallbacks: :default,
        betas: [ "server-side-fallback-2026-07-01" ]
      )

      # Claude's blocks are kept exactly as returned (thinking signatures
      # included): the API needs them back unchanged on the next request.
      Response.new(
        content: response.content.map { |block| block.to_h.deep_symbolize_keys.compact },
        stop_reason: response.stop_reason.to_s,
        model: "Claude (#{model})"
      )
    end

    private

    # A conversation may have started on another provider. Thinking blocks
    # from other models have no signature, and Claude rejects them, so drop those.
    def claude_messages(messages)
      messages.map do |message|
        next message unless message[:role] == "assistant" && message[:content].is_a?(Array)

        content = message[:content].reject { |b| b[:type].to_s == "thinking" && b[:signature].blank? }
        message.merge(content: content.presence || [ { type: "text", text: "(no text)" } ])
      end
    end
  end
end
