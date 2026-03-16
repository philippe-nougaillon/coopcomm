module DefaultRateLimits
  extend ActiveSupport::Concern

  # included do
  #   rate_limit to: 45, within: 1.minute, by: -> { request.ip }, name: "long-term"
  #   rate_limit to: 3, within: 2.seconds, by: -> { request.ip }, name: "short-term"
  # end
end
