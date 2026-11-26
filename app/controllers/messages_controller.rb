class MessagesController < ApplicationController
  before_action :set_conversation

  # Saves the question, adds an empty "working" answer, and hands the agent
  # run to a background job. The job streams the agent's steps into the page
  # over Turbo Streams as they happen.
  def create
    question = params.require(:message).fetch(:body, "").strip
    return head(:unprocessable_content) if question.blank?
    return head(:conflict) if @conversation.messages.exists?(status: "working")

    @question = @conversation.messages.create!(role: "user", body: question)
    @answer = @conversation.messages.create!(role: "assistant", body: "…", status: "working")
    @conversation.update!(title: question.truncate(60)) if @conversation.title.blank?

    AgentRunJob.perform_later(@answer.id, question)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @conversation }
    end
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end
end
