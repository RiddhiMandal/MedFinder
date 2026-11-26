module Tools
  # A tool the agent can call.
  #
  # Subclasses declare a name, a description written for the model, and a
  # JSON Schema for the input, then implement #call. #call returns a Hash; the
  # agent serializes it to JSON and hands it back to Claude as the tool result.
  #
  # Raise Tools::InputError for bad input. The agent turns it into an error
  # tool result so Claude can correct itself instead of the request failing.

  class Base
    class << self
      attr_reader :tool_name, :tool_description, :schema

      def name_as(value) = @tool_name = value
      def description(value) = @tool_description = value
      def input_schema(value) = @schema = value

      # The definition sent to the Messages API in `tools:`.
      def definition
        { name: tool_name, description: tool_description, input_schema: schema }
      end
    end

    def call(_input)
      raise NotImplementedError
    end

    private

    def require_string(input, key)
      value = input[key]
      raise InputError, "`#{key}` is required and must be a non-empty string" unless value.is_a?(String) && value.strip.present?

      value.strip
    end
  end
end
