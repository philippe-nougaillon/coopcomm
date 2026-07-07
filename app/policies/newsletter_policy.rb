# frozen_string_literal: true

class NewsletterPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user&.super_admin?
  end

  def new?
    true
  end

  def destroy?
    true
  end
end
