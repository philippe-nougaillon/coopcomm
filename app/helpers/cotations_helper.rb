module CotationsHelper
  STATUT_BADGE = {
    "créé"    => "badge-ghost",
    "envoyé"  => "badge-info",
    "validé"  => "badge-success",
    "refusé"  => "badge-error",
    "archivé" => "badge-neutral"
  }.freeze

  def cotation_statut_badge_class(statut)
    STATUT_BADGE.fetch(statut.to_s, "badge-ghost")
  end
end
