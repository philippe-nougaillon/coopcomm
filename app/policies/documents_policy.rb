# frozen_string_literal: true

class DocumentsPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def documents?
    user && (manager_or_admin? || user.adhérent?)
  end
end
