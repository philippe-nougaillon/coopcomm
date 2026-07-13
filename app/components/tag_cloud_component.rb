# frozen_string_literal: true

class TagCloudComponent < ViewComponent::Base
  def initialize(intervention_tags:)
    @intervention_tags = intervention_tags
  end
end
