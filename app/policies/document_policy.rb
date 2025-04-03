class DocumentPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def valider?
    user&.manager? && record.tool.organisation == user.organisation
  end

  def refuser?
    valider?
  end
end