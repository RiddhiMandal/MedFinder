class ConversationsController < ApplicationController
  def index
    @conversations = Conversation.order(updated_at: :desc).limit(20)
  end

  def show
    @conversation = Conversation.find(params[:id])
    @conversations = Conversation.order(updated_at: :desc).limit(20)
  end

  def create
    redirect_to Conversation.create!
  end

  def destroy
    Conversation.find(params[:id]).destroy
    redirect_to root_path, status: :see_other
  end
end
