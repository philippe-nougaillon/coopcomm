# frozen_string_literal: true

require 'simplecov'

unless SimpleCov.running
  SimpleCov.start 'rails' do
    add_group 'Components', 'app/components'
    add_group 'Mailboxes', 'app/mailboxes'
    add_group 'Policies', 'app/policies'
    add_group 'PDFs', 'app/pdfs'
    add_group 'Services', 'app/services'
    add_group 'Subscriptions', 'app/subscriptions'
  end
end
