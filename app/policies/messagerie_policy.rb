# frozen_string_literal: true

class MessageriePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user
  end

  def conversation?
    index?
  end

  def send_message?
    index?
  end

  def search_contact?
    index?
  end

  def mark_as_read?
    index?
  end
end
