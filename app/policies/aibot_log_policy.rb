# frozen_string_literal: true

class AibotLogPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user&.super_admin?
  end

  def show?
    index?
  end
end
