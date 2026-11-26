# The model behind the agent is pluggable. Every provider exposes one method:
#
#   chat(system:, messages:, tools:) -> Llm::Response
#
# `messages` and the returned `content` always use one shared shape (the
# Claude Messages API block format: text, thinking, tool_use, tool_result).
# Each provider translates that shape to and from its own API, so the agent
# loop, tools, trace and UI never need to know which model is answering.
#
# Pick a provider with LLM_PROVIDER in .env:
#   ollama    - a free local model (default; needs `ollama serve` running)
#   anthropic - Claude via the Anthropic API (needs ANTHROPIC_API_KEY)
module Llm
  # content: Array of block hashes. stop_reason: "tool_use", "end_turn",
  # "max_tokens" or "refusal". model: a label for the trace.
  Response = Data.define(:content, :stop_reason, :model)

  # Raised with a message that's safe to show the user.
  class ProviderError < StandardError; end

  PROVIDERS = {
    "ollama" => -> { OllamaProvider.new },
    "anthropic" => -> { AnthropicProvider.new }
  }.freeze

  def self.default_provider
    name = ENV.fetch("LLM_PROVIDER", "ollama").downcase
    PROVIDERS.fetch(name) { raise ProviderError, "Unknown LLM_PROVIDER #{name.inspect}. Use one of: #{PROVIDERS.keys.join(", ")}." }.call
  end
end
