class DocumentPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def valider?
    manager_or_admin? && record.tool.organisation == user.organisation
  end

  def refuser?
    valider?
  end
end