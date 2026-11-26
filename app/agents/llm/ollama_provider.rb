require "net/http"

module Llm
  # A free, local model served by Ollama (https://ollama.com).
  #
  # Ollama's /api/chat uses a different message shape from Claude's, so this
  # class translates both ways:
  #
  #   agent (Claude-style blocks)           Ollama
  #   ---------------------------           ------
  #   assistant tool_use blocks       <->   assistant message with tool_calls
  #   user message of tool_result     <->   one {role: "tool"} message per result
  #   thinking block                  <->   message.thinking (when think: true)
  #
  # Ollama doesn't give tool calls ids, so we make them up here to keep the
  # agent's call/result pairing working.
  class OllamaProvider
    DEFAULT_URL = "http://localhost:11434"
    DEFAULT_MODEL = "qwen3:8b"

    attr_reader :model

    def initialize(url: ENV.fetch("OLLAMA_URL", DEFAULT_URL), model: ENV.fetch("OLLAMA_MODEL", DEFAULT_MODEL),
                   think: ENV.fetch("OLLAMA_THINK", "true") == "true", http: nil)
      @uri = URI.join(url, "/api/chat")
      @model = model
      @think = think
      @http = http # injectable for tests: anything with #post_json(uri, body) -> Hash
    end

    def chat(system:, messages:, tools:)
      body = {
        model: model,
        stream: false,
        think: @think,
        options: { temperature: 0.2 },
        tools: tools.map { |t| ollama_tool(t) },
        messages: [ { role: "system", content: system } ] + ollama_messages(messages)
      }
      to_response(post_json(body))
    end

    private

    # --- request: agent format -> Ollama ---------------------------------------

    def ollama_tool(tool)
      { type: "function", function: { name: tool[:name], description: tool[:description], parameters: tool[:input_schema] } }
    end

    def ollama_messages(messages)
      tool_names = {} # tool_use id -> tool name, needed for Ollama's tool messages

      messages.flat_map do |message|
        message = message.deep_symbolize_keys
        content = message[:content]

        if content.is_a?(String)
          [ { role: message[:role], content: content } ]
        elsif message[:role] == "assistant"
          calls = content.select { |b| b[:type].to_s == "tool_use" }
          calls.each { |c| tool_names[c[:id]] = c[:name] }
          [ {
            role: "assistant",
            content: content.select { |b| b[:type].to_s == "text" }.map { |b| b[:text] }.join("\n\n"),
            tool_calls: calls.map { |c| { function: { name: c[:name], arguments: c[:input] || {} } } }.presence
          }.compact ]
        else
          content.map do |block|
            if block[:type].to_s == "tool_result"
              { role: "tool", tool_name: tool_names[block[:tool_use_id]], content: block[:content].to_s }.compact
            else
              { role: "user", content: block[:text].to_s }
            end
          end
        end
      end
    end

    # --- response: Ollama -> agent format ----------------------------------------

    def to_response(data)
      message = data.fetch("message", {})
      blocks = []
      blocks << { type: "thinking", thinking: message["thinking"] } if message["thinking"].present?
      text = strip_think_tags(message["content"].to_s)
      blocks << { type: "text", text: text } if text.present?

      calls = Array(message["tool_calls"])
      calls.each do |call|
        fn = call["function"] || {}
        blocks << { type: "tool_use", id: "call_#{SecureRandom.hex(6)}", name: fn["name"], input: parse_arguments(fn["arguments"]) }
      end

      stop_reason =
        if calls.any? then "tool_use"
        elsif data["done_reason"] == "length" then "max_tokens"
        else "end_turn"
        end

      Response.new(content: blocks, stop_reason: stop_reason, model: "#{model} (local, Ollama)")
    end

    # Some models return arguments as a JSON string instead of an object.
    def parse_arguments(args)
      return args if args.is_a?(Hash)

      JSON.parse(args.to_s)
    rescue JSON::ParserError
      {}
    end

    # If thinking isn't split out by Ollama, don't show raw <think> tags.
    def strip_think_tags(text)
      text.gsub(%r{<think>.*?</think>}m, "").strip
    end

    # --- HTTP --------------------------------------------------------------------

    def post_json(body)
      return @http.post_json(@uri, body) if @http

      response = Net::HTTP.start(@uri.host, @uri.port, use_ssl: @uri.scheme == "https", open_timeout: 5, read_timeout: 300) do |http|
        http.post(@uri.path, body.to_json, "Content-Type" => "application/json")
      end
      data = JSON.parse(response.body)
      raise ProviderError, ollama_error(data["error"]) unless response.is_a?(Net::HTTPSuccess)

      data
    rescue Errno::ECONNREFUSED, Errno::EADDRNOTAVAIL, SocketError
      raise ProviderError, "Ollama isn't running at #{@uri.host}:#{@uri.port}. Start it with `ollama serve` (or open the Ollama app), then try again."
    rescue Net::ReadTimeout
      raise ProviderError, "The local model took too long to answer. Try a shorter question or a smaller model."
    rescue JSON::ParserError
      raise ProviderError, "Ollama returned a response that wasn't JSON."
    end

    def ollama_error(message)
      if message.to_s.include?("not found")
        "The model #{model} isn't downloaded yet. Run `ollama pull #{model}`, then try again."
      else
        "Ollama returned an error: #{message}"
      end
    end
  end
end
