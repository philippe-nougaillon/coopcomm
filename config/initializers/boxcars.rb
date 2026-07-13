Boxcars.configure do |config|
  config.default_model = "gpt-5.5"
  config.log_prompts = Rails.env.development?
end
