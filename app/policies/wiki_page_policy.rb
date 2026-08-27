# frozen_string_literal: true

class WikiPagePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  # Le wiki (blog/FAQ) est public ; le contrôleur filtre publiée/private dans l'action
  def index?
    true
  end

  # Une page non publiée ou privée n'est visible que des managers/admins
  # (l'index filtre déjà sur publiée: true, show doit suivre la même règle).
  def show?
    (record.publiée? && !record.private?) || manager_or_admin?
  end

  def new?
    manager_or_admin?
  end

  def create?
    new?
  end

  def edit?
    manager_or_admin?
  end

  def update?
    edit?
  end

  def destroy?
    edit? && record.user == user
  end

  def blog?
    index?
  end
  
  def guide?
    index?
  end

  def faq?
    index?
  end
end
