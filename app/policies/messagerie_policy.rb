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

  # Le record est le service dont on lit les annonces, ou l'organisation pour les annonces générales
  def annonces?
    return false if adhérent?

    record.is_a?(Service) ? user.get_services_by_role.exists?(record.id) : record == user.organisation
  end

  def send_annonce?
    annonces? && (administrateur? || (user.manager? && record.is_a?(Service)))
  end
end
