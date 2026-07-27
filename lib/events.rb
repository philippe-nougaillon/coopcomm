# frozen_string_literal: true

require 'dry/events/publisher'

class Events
  include Singleton
  include Dry::Events::Publisher[:my_publisher]

  register_event('intervention.workflow_changed')
  register_event('intervention.done')
  register_event('organisation.created')
  register_event('intervention.pointage')
  register_event('create.newsletter')
end
