Rails.application.reloader.to_prepare do
  helper = ActionText::ContentHelper

  base_tags = helper.respond_to?(:sanitizer_allowed_tags) ? helper.sanitizer_allowed_tags : helper.allowed_tags
  base_attrs = helper.respond_to?(:sanitizer_allowed_attributes) ? helper.sanitizer_allowed_attributes : helper.allowed_attributes

  helper.allowed_tags = base_tags + %w[iframe]
  helper.allowed_attributes = base_attrs + %w[src allow allowfullscreen frameborder loading title]
end