# frozen_string_literal: true

module UsersHelper
  def services_assignables_par(user)
    base = user.administrateur? ? user.organisation&.services : user.services
    (base || Service.none).ordered
  end

  # Un changement est soit une valeur posée (création), soit un couple
  # [avant, après] (mise à jour).
  def import_changements(changements)
    changements.map do |attribut, valeur|
      libellé = attribut.to_s.humanize
      if valeur.is_a?(Array)
        "#{libellé} : #{valeur.first.presence || '—'} → #{valeur.last.presence || '—'}"
      else
        "#{libellé} : #{valeur.presence || '—'}"
      end
    end.join(' | ')
  end
end
