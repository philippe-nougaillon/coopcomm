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

  def show?
    manager_or_admin? || (adhérent? && record.publiée?) || (record.publiée? && !record.private?)
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

  def purge_photo?
    destroy?
  end

  def purge_document?
    destroy?
  end
  
end
