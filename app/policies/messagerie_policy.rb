class MessageriePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def messagerie?
    user
  end

  def send_notification?
    messagerie?
  end

  def search_contact?
    messagerie?
  end

  def mark_as_read?
    messagerie?
  end
end