organisation = Organisation.create(nom: "Communauté d'agglomération Plaine Vallée")

User.create!([
  {nom: "MANAGER", prénom: "Thierry", email: "manager.thierry@coopcomm.fr", organisation_id: organisation.id, rôle: "manager", password: "sdm2025", password_confirmation: "sdm2025", slug: SecureRandom.uuid},
  {nom: "Bouffémont", prénom: "", email: "adherent.bouffémont@coopcomm.fr", organisation_id: organisation.id, rôle: "adhérent", password: "sdm2025", password_confirmation: "sdm2025", localisation: "49.0433021567701, 2.3001033039257464", slug: SecureRandom.uuid},
])


adhérent_montmorency = User.create(nom: "Montmorency", prénom: "", email: "adherent.montmorency@coopcomm.fr", organisation_id: organisation.id, rôle: "adhérent", password: "sdm2025", password_confirmation: "sdm2025", localisation: "48.98963358128416, 2.3212285907717924", slug: SecureRandom.uuid)
adhérent_attainville = User.create(nom: "Attainville", prénom: "", email: "adherent.attainville@coopcomm.fr", organisation_id: organisation.id, rôle: "adhérent", password: "sdm2025", password_confirmation: "sdm2025", localisation: "49.057101562313406, 2.345911077521958", slug: SecureRandom.uuid)
adhérent_andilly = User.create(nom: "Andilly", prénom: "", email: "adherent.andilly@coopcomm.fr", organisation_id: organisation.id, rôle: "adhérent", password: "sdm2025", password_confirmation: "sdm2025", localisation: "49.00496449442205, 2.2991233958758164", slug: SecureRandom.uuid)
agent_technique1 = User.create({nom: "Technique", prénom: "Jean", email: "agent.technique1@coopcomm.fr", organisation_id: organisation.id, rôle: "agent", service: "Technique", password: "sdm2025", password_confirmation: "sdm2025", slug: SecureRandom.uuid})
agent_technique2 = User.create({nom: "Technique", prénom: "André", email: "agent.technique2@coopcomm.fr", organisation_id: organisation.id, rôle: "agent", service: "Technique", password: "sdm2025", password_confirmation: "sdm2025", slug: SecureRandom.uuid})
agent_ménage = User.create({nom: "Ménage", prénom: "Nicole", email: "agent.menage@coopcomm.fr", organisation_id: organisation.id, rôle: "agent", service: "Ménage", password: "sdm2025", password_confirmation: "sdm2025", slug: SecureRandom.uuid})

tondeuse_gazon = Tool.create(name: "Tondeuse à gazon", description: "", icon_name: "agriculture", modèle: "Estate 7122 W", marque: "Stiga", organisation_id: organisation.id, slug: SecureRandom.uuid)
# brouette = Tool.create(name: "Brouette", description: "polyvalente 100 L / 180 kg galvanisée, roue gonflable", icon_name: "agriculture", modèle: "Estate 7122 W", marque: "Altrad", organisation_id: organisation.id, slug: SecureRandom.uuid)

intervention_tonte_pelouse = Intervention.create(description: "Tondre pelouse parc hôtel de ville", adherent_id: adhérent_montmorency.id, début_prévue: "2025-09-01 08:00:00.000000000 +0100", fin_prévue: "2025-09-01 11:00:00.000000000 +0100", début: "2025-09-01 08:04:00.000000000 +0100", fin: "2025-09-01 10:43:00.000000000 +0100", workflow_state: "validé", organisation_id: organisation.id, slug: SecureRandom.uuid)
ToolIntervention.create!(tool_id: tondeuse_gazon.id, intervention_id: intervention_tonte_pelouse.id)
AgentIntervention.create!(agent_id: agent_technique1.id, intervention_id: intervention_tonte_pelouse.id)

intervention_elagage_arbre = Intervention.create(description: "Élagage des arbres du parc", adherent_id: adhérent_montmorency.id, début_prévue: "2025-09-01 08:00:00.000000000 +0100", fin_prévue: "2025-09-01 11:00:00.000000000 +0100", organisation_id: organisation.id, slug: SecureRandom.uuid)
AgentIntervention.create!(agent_id: agent_technique2.id, intervention_id: intervention_elagage_arbre.id)


intervention_recurrente_menage_mère = Intervention.create(description: "Ménage mairie d'Andilly", repeter: true, workflow_state: "attente", adherent_id: adhérent_andilly.id, organisation_id: organisation.id, slug: SecureRandom.uuid, created_at: "2025-09-01 14:55:05.000000000 +0100")
AgentIntervention.create!(agent_id: agent_ménage.id, intervention_id: intervention_recurrente_menage_mère.id)

(intervention_recurrente_menage_mère.created_at.to_date..Date.today).each do |date|
  next if date.saturday? || date.sunday?

  hour = 8
  minute = rand(50..70)  # 50 à 70 → 8h50 à 9h10
  if minute >= 60
    hour += 1
    minute -= 60
  end
  debut = Time.zone.local(date.year, date.month, date.day, hour, minute, rand(0..59))
  duree = rand(50.minutes..70.minutes)
  fin = debut + duree

  intervention_fille = Intervention.create(description: intervention_recurrente_menage_mère.description, workflow_state: "validé", adherent_id: intervention_recurrente_menage_mère.adherent_id, template_slug: intervention_recurrente_menage_mère.slug, début: debut, fin: fin, organisation_id: intervention_recurrente_menage_mère.organisation.id, slug: SecureRandom.uuid)
  intervention_recurrente_menage_mère.agent_interventions.each do |agent_intervention|
    intervention_fille.agent_interventions.create(agent: agent_intervention.agent)
  end
end

Intervention.create!([
  {description: "Reboucher le nid-de-poule devant l'école", adherent_id: adhérent_attainville.id, début_prévue: "2025-09-01 13:00:00.000000000 +0100", fin_prévue: "2025-09-01 15:00:00.000000000 +0100", organisation_id: organisation.id, slug: SecureRandom.uuid},
  {description: "Balayage de la voirie", adherent_id: adhérent_attainville.id, début_prévue: "2025-09-02 09:00:00.000000000 +0100", fin_prévue: "2025-09-02 12:00:00.000000000 +0100", organisation_id: organisation.id, slug: SecureRandom.uuid},
  {description: "Entretien des aires de jeux et des installations sportives", adherent_id: adhérent_andilly.id, début_prévue: "2025-09-02 14:00:00.000000000 +0100", fin_prévue: "2025-09-02 16:00:00.000000000 +0100", organisation_id: organisation.id, slug: SecureRandom.uuid},
  {description: "Ramassage des encombrants", adherent_id: adhérent_andilly.id, début_prévue: "2025-09-0 14:00:00.000000000 +0100", fin_prévue: "2025-09-02 16:00:00.000000000 +0100", organisation_id: organisation.id, slug: SecureRandom.uuid}
])


# Interventions : workflow, avis, météo, tags
# Abscence
# Notification
# Mouvement (pas besoin pour l'instant)
# Document
# ? MailLog
# ? Audit
# ? modification d'interventions