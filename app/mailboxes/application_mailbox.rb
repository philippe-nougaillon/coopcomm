# frozen_string_literal: true

class ApplicationMailbox < ActionMailbox::Base
  # routing /something/i => :somewhere
  routing 'support@mg.coopcomm.fr' => :support
end
