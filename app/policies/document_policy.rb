class DocumentPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def valider?
    manager && record.tool.organisation == user.organisation
  end

  def refuser?
    valider?
  end
end