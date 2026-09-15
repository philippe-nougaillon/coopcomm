class SendRequestToBoxcarsJob < ApplicationJob
  queue_as :default

  def perform(user_sender, message)
    response = FetchBoxcarsInfos.new.call(user_sender, message)

    Message.create!(message: response, from_id: ENV["UUID_AIBOT"], to_id: user_sender.id)
  end
end
