# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def organisation?
    user && record.organisation == user.organisation
  end

  def administrateur?
    user&.administrateur?
  end

  def manager_or_admin?
    user&.manager_or_admin?
  end

  def adhérent?
    user&.adhérent?
  end

  def agent?
    user&.agent?
  end

  def shared_service?(record_services = record.services)
    # "&" désigne l'intersection entre deux listes
    (record_services & user.services).any?
  end

  def manage?
    organisation? && (administrateur? || (user.manager? && user.services.include?(record.service)))
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end
end
