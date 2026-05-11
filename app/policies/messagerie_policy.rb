class MessageriePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user
  end

  def send_notification?
    index?
  end

  def search_contact?
    index?
  end

  def mark_as_read?
    index?
  end
end