# frozen_string_literal: true

class CrmPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user&.adhérent?
  end
end