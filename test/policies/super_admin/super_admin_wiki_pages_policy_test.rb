# frozen_string_literal: true

require 'test_helper'

class SuperAdminWikiPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    super_admin = users(:philippe_super_admin)

    @super_admin_initial = ENV.fetch('SUPER_ADMIN', nil)
    ENV['SUPER_ADMIN'] = super_admin.email

    @policy = WikiPagePolicy.new(super_admin, wiki_pages(:blog_public))
  end

  def teardown
    ENV['SUPER_ADMIN'] = @super_admin_initial
  end

  test 'accès autorisé pour un super admin sur une documentation' do
    assert @policy.copie?
    assert @policy.copier?
  end
end
