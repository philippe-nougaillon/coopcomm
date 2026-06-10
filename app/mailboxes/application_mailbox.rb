# frozen_string_literal: true

class ApplicationMailbox < ActionMailbox::Base
  # routing /something/i => :somewhere
  routing 'support@mg.coopcom.fr' => :support
end
