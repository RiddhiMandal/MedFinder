# Runs the agent for one question and streams its progress to the browser:
# each step is appended to the answer's trace as it happens, and the finished
# answer replaces the "working" placeholder at the end.
class AgentRunJob < ApplicationJob
  queue_as :default

  # `provider:` exists so tests can pass a fake model.
  def perform(answer_id, question, provider: nil)
    @answer = Message.find(answer_id)
    @steps = []
    conversation = @answer.conversation

    on_step = lambda do |step|
      @steps << step
      broadcast_step(step)
    end
    agent = SupplementAssistant.new(**{ provider:, on_step: }.compact)
    result = agent.ask(question, history: conversation.api_messages)

    conversation.update!(api_messages: result.api_messages)
    @answer.update!(body: result.answer.presence || "(no answer)", trace: result.trace, status: "done")
  rescue Llm::ProviderError => e
    fail_with e.message
  rescue Anthropic::Errors::AuthenticationError
    fail_with "The Anthropic API key is missing or invalid. Set ANTHROPIC_API_KEY in `.env` and restart the server."
  rescue Anthropic::Errors::RateLimitError, Anthropic::Errors::InternalServerError
    fail_with "The model is busy right now. Please try again in a moment."
  rescue Anthropic::Errors::APIConnectionError
    fail_with "Couldn't reach the Anthropic API. Check your connection and try again."
  rescue StandardError => e
    Rails.logger.error("[agent] #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    fail_with "Something went wrong (#{e.class.name.demodulize}). Check the server log for details."
  ensure
    if @answer
      @answer.broadcast_replace_to(@answer.conversation, partial: "messages/message", locals: { message: @answer })
    end
  end

  private

  def broadcast_step(step)
    Turbo::StreamsChannel.broadcast_append_to(
      @answer.conversation,
      target: "trace_#{@answer.id}",
      partial: "messages/step",
      locals: { step: step }
    )
  end

  # The question was not answered, so the conversation's api_messages are
  # left as they were. The steps gathered so far are kept for debugging.
  def fail_with(text)
    @answer&.update!(body: text, trace: @steps || [], status: "error")
  end
end
