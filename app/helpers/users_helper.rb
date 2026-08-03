# frozen_string_literal: true

module UsersHelper
  def services_assignables_par(user)
    base = user.administrateur? ? user.organisation&.services : user.services
    (base || Service.none).ordered
  end
end
