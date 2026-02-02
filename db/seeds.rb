organisation = Organisation.create(nom: "Communauté d'agglomération Plaine Vallée")

# --- USERS ---

manager_thierry = User.create(nom: "MANAGER", prénom: "Thierry", email: "manager.thierry@coopcomm.fr", organisation_id: organisation.id, rôle: "manager", password: "sdm2025", password_confirmation: "sdm2025", slug: SecureRandom.uuid)
manager_béatrice = User.create(nom: "MANAGER", prénom: "Béatrice", email: "manager.beatrice@coopcomm.fr", organisation_id: organisation.id, rôle: "manager", password: "sdm2025", password_confirmation: "sdm2025", slug: SecureRandom.uuid)
adhérent_bouffémont = User.create(nom: "Bouffémont", prénom: "", email: "adherent.bouffemont@coopcomm.fr", organisation_id: organisation.id, rôle: "adhérent", password: "sdm2025", password_confirmation: "sdm2025", localisation: "49.0433021567701, 2.3001033039257464", slug: SecureRandom.uuid)
adhérent_montmorency = User.create(nom: "Montmorency", prénom: "", email: "adherent.montmorency@coopcomm.fr", organisation_id: organisation.id, rôle: "adhérent", password: "sdm2025", password_confirmation: "sdm2025", localisation: "48.98963358128416, 2.3212285907717924", slug: SecureRandom.uuid)
adhérent_attainville = User.create(nom: "Attainville", prénom: "", email: "adherent.attainville@coopcomm.fr", organisation_id: organisation.id, rôle: "adhérent", password: "sdm2025", password_confirmation: "sdm2025", localisation: "49.057101562313406, 2.345911077521958", slug: SecureRandom.uuid)
adhérent_andilly = User.create(nom: "Andilly", prénom: "", email: "adherent.andilly@coopcomm.fr", organisation_id: organisation.id, rôle: "adhérent", password: "sdm2025", password_confirmation: "sdm2025", localisation: "49.00496449442205, 2.2991233958758164", slug: SecureRandom.uuid)
agent_tech_jean = User.create({nom: "Martin", prénom: "Jean", email: "agent.technique1@coopcomm.fr", organisation_id: organisation.id, rôle: "agent", service: "Technique", password: "sdm2025", password_confirmation: "sdm2025", slug: SecureRandom.uuid})
agent_tech_andré = User.create({nom: "Bernard", prénom: "André", email: "agent.technique2@coopcomm.fr", organisation_id: organisation.id, rôle: "agent", service: "Technique", password: "sdm2025", password_confirmation: "sdm2025", slug: SecureRandom.uuid})
agent_tech_marie = User.create({nom: "Dubois", prénom: "Marie", email: "agent.technique3@coopcomm.fr", organisation_id: organisation.id, rôle: "agent", service: "Technique", password: "sdm2025", password_confirmation: "sdm2025", slug: SecureRandom.uuid})
agent_menage_nicole = User.create({nom: "Lefebvre", prénom: "Nicole", email: "agent.menage@coopcomm.fr", organisation_id: organisation.id, rôle: "agent", service: "Ménage", password: "sdm2025", password_confirmation: "sdm2025", slug: SecureRandom.uuid})
agent_plomberie_marc = User.create({nom: "Moreau", prénom: "Marc", email: "agent.plomberie@coopcomm.fr", organisation_id: organisation.id, rôle: "agent", service: "Technique", password: "sdm2025", password_confirmation: "sdm2025", slug: SecureRandom.uuid})
agent_peinture_amelie = User.create({nom: "Simon", prénom: "Amélie", email: "agent.peinture@coopcomm.fr", organisation_id: organisation.id, rôle: "agent", service: "Technique", password: "sdm2025", password_confirmation: "sdm2025", slug: SecureRandom.uuid})
agent_periscolaire_pierre = User.create({nom: "Michel", prénom: "Pierre", email: "agent.perisco1@coopcomm.fr", organisation_id: organisation.id, rôle: "agent", service: "Périscolaire", password: "sdm2025", password_confirmation: "sdm2025", slug: SecureRandom.uuid})
agent_metal_luc = User.create({nom: "Petit", prénom: "Luc", email: "agent.metal@coopcomm.fr", organisation_id: organisation.id, rôle: "agent", service: "Technique", password: "sdm2025", password_confirmation: "sdm2025", slug: SecureRandom.uuid})
agent_info_clara = User.create({nom: "Roux", prénom: "Clara", email: "agent.info1@coopcomm.fr", organisation_id: organisation.id, rôle: "agent", service: "Informatique", password: "sdm2025", password_confirmation: "sdm2025", slug: SecureRandom.uuid})
agent_secretaire_véronique = User.create({nom: "Faure", prénom: "Véronique", email: "agent.secretaire1@coopcomm.fr", organisation_id: organisation.id, rôle: "agent", service: "Secrétariat", password: "sdm2025", password_confirmation: "sdm2025", slug: SecureRandom.uuid})
agent_compta_sophie = User.create({nom: "Mercier", prénom: "Sophie", email: "agent.compta1@coopcomm.fr", organisation_id: organisation.id, rôle: "agent", service: "Comptabilité", password: "sdm2025", password_confirmation: "sdm2025", slug: SecureRandom.uuid})
agent_securite_philippe = User.create({nom: "Garnier", prénom: "Philippe", email: "agent.securite1@coopcomm.fr", organisation_id: organisation.id, rôle: "agent", service: "Technique", password: "sdm2025", password_confirmation: "sdm2025", slug: SecureRandom.uuid})

team_entretien_batiment = User.create({nom: "Entretien Bâtiment", prénom: "", email: "equipe.entretien@coopcomm.fr", organisation_id: organisation.id, rôle: "équipe", color: "#1F77B4", password: "sdm2025", password_confirmation: "sdm2025", slug: SecureRandom.uuid})
team_eclairage = User.create!(nom: "Éclairage", prénom: "", email: "equipe.eclairage@coopcomm.fr", organisation_id: organisation.id, rôle: "équipe", color: "#FF7F0E", password: "sdm2025", password_confirmation: "sdm2025", slug: SecureRandom.uuid)
team_technique = User.create!(nom: "Technique", prénom: "", email: "equipe.tech@coopcomm.fr", organisation_id: organisation.id, rôle: "équipe",  color: "#2CA02C", password: "sdm2025", password_confirmation: "sdm2025", slug: SecureRandom.uuid)
team_menage = User.create!(
  nom: "Ménage",
  prénom: "",
  email: "equipe.menage@coopcomm.fr",
  organisation_id: organisation.id,
  rôle: "équipe",
  color: "#9467BD",
  password: "sdm2025",
  password_confirmation: "sdm2025",
  slug: SecureRandom.uuid
)

team_informatique = User.create!(
  nom: "Informatique",
  prénom: "",
  email: "equipe.informatique@coopcomm.fr",
  organisation_id: organisation.id,
  rôle: "équipe",
  color: "#17BECF",
  password: "sdm2025",
  password_confirmation: "sdm2025",
  slug: SecureRandom.uuid
)

team_peinture = User.create!(
  nom: "Peinture",
  prénom: "",
  email: "equipe.peinture@coopcomm.fr",
  organisation_id: organisation.id,
  rôle: "équipe",
  color: "#D62728",
  password: "sdm2025",
  password_confirmation: "sdm2025",
  slug: SecureRandom.uuid
)

team_compta = User.create!(
  nom: "Comptabilité",
  prénom: "",
  email: "equipe.compta@coopcomm.fr",
  organisation_id: organisation.id,
  rôle: "équipe",
  color: "#E377C2",
  password: "sdm2025",
  password_confirmation: "sdm2025",
  slug: SecureRandom.uuid
)

team_plomberie = User.create!(
  nom: "Plomberie",
  prénom: "",
  email: "equipe.plomberie@coopcomm.fr",
  organisation_id: organisation.id,
  rôle: "équipe",
  color: "#8C564B",
  password: "sdm2025",
  password_confirmation: "sdm2025",
  slug: SecureRandom.uuid
)

team_metal = User.create!(
  nom: "Métallerie",
  prénom: "",
  email: "equipe.metal@coopcomm.fr",
  organisation_id: organisation.id,
  rôle: "équipe",
  color: "#7F7F7F",
  password: "sdm2025",
  password_confirmation: "sdm2025",
  slug: SecureRandom.uuid
)

team_securite = User.create!(
  nom: "Sécurité",
  prénom: "",
  email: "equipe.securite@coopcomm.fr",
  organisation_id: organisation.id,
  rôle: "équipe",
  color: "#BCBD22",
  password: "sdm2025",
  password_confirmation: "sdm2025",
  slug: SecureRandom.uuid
)

team_espaces_verts = User.create!(
  nom: "Équipe Espaces Verts",
  prénom: "",
  email: "equipe.espacesverts@coopcomm.fr",
  organisation_id: organisation.id,
  rôle: "équipe",
  color: "#2CA02C",
  password: "sdm2025",
  password_confirmation: "sdm2025",
  slug: SecureRandom.uuid
)

Absence.create!([
  { du: Date.new(2025, 9, 10), au: Date.new(2025, 9, 12), motif: "Maladie", user: agent_tech_jean },
  { du: Date.new(2025, 10, 20), au: Date.new(2025, 10, 31), motif: "Vacances Toussaint", user: agent_tech_andré },
  { du: Date.new(2025, 11, 5), au: Date.new(2025, 11, 6), motif: "Rendez-vous personnel", user: agent_tech_marie },
  { du: Date.new(2025, 12, 1), au: Date.new(2025, 12, 3), motif: "Formation", user: agent_menage_nicole },
  { du: Date.new(2025, 12, 20), au: Date.new(2025, 12, 31), motif: "Vacances Noël", user: agent_plomberie_marc },
  { du: Date.new(2025, 11, 25), au: Date.new(2025, 11, 26), motif: "Rendez-vous personnel", user: agent_periscolaire_pierre },
  { du: Date.new(2025, 1, 5), au: Date.new(2025, 1, 7), motif: "Vacances hiver", user: agent_metal_luc },
  { du: Date.new(2025, 1, 12), au: Date.new(2025, 1, 13), motif: "Formation", user: agent_info_clara },
])

# --- OUTILS ---
tondeuse_gazon = Tool.create(name: "Tondeuse à gazon", description: "", icon_name: "agriculture", modèle: "Estate 7122 W", marque: "Stiga", organisation_id: organisation.id, slug: SecureRandom.uuid)
# brouette = Tool.create(name: "Brouette", description: "polyvalente 100 L / 180 kg galvanisée, roue gonflable", icon_name: "agriculture", modèle: "Estate 7122 W", marque: "Altrad", organisation_id: organisation.id, slug: SecureRandom.uuid)
camionnette_benne = Tool.create(name: "Camionnette benne", description: "Véhicule utilitaire 3.5t", modèle: "Boxer 3.5", marque: "Peugeot", organisation_id: organisation.id, slug: SecureRandom.uuid)
taille_haies = Tool.create(name: "Taille-haies électrique", description: "", modèle: "HT 600", marque: "Bosch", organisation_id: organisation.id, slug: SecureRandom.uuid)
balayeuse = Tool.create(name: "Balayeuse mécanique", description: "", modèle: "SweepPro 200", marque: "Kärcher", organisation_id: organisation.id, slug: SecureRandom.uuid)
groupe_electrogene = Tool.create(name: "Groupe électrogène", description: "2kW", modèle: "Gen2000", marque: "Honda", organisation_id: organisation.id, slug: SecureRandom.uuid)
ordinateur_portable = Tool.create(name: "Ordinateur portable", description: "Portable service informatique", modèle: "ThinkPad T14", marque: "Lenovo", organisation_id: organisation.id, slug: SecureRandom.uuid)
projecteur = Tool.create(name: "Projecteur", description: "Vidéo projection", modèle: "PX-2200", marque: "Epson", organisation_id: organisation.id, slug: SecureRandom.uuid)
echelle_4m = Tool.create(name: "Échelle 4m", description: "", modèle: "StepPro 4", marque: "Zarges", organisation_id: organisation.id, slug: SecureRandom.uuid)
moto_scie = Tool.create(name: "Scie thermique", description: "Pour gros tronçonnage", modèle: "CS50", marque: "Stihl", organisation_id: organisation.id, slug: SecureRandom.uuid)

# Outils de nettoyage
aspirateur_industriel = Tool.create!(name: "Aspirateur industriel", organisation_id: organisation.id, slug: SecureRandom.uuid)
seau_serpillere = Tool.create!(name: "Seau et serpillère", organisation_id: organisation.id, slug: SecureRandom.uuid)
chiffon_microfibre = Tool.create!(name: "Chiffon microfibre", organisation_id: organisation.id, slug: SecureRandom.uuid)
escabeau = Tool.create!(name: "Escabeau", organisation_id: organisation.id, slug: SecureRandom.uuid)
balai_pompe = Tool.create!(name: "Balai pompe", organisation_id: organisation.id, slug: SecureRandom.uuid)

# Outils de peinture
peinture_rouge = Tool.create!(name: "Peinture rouge", organisation_id: organisation.id, slug: SecureRandom.uuid)
peinture_vert = Tool.create!(name: "Peinture verte", organisation_id: organisation.id, slug: SecureRandom.uuid)
peinture_blanc = Tool.create!(name: "Peinture blanche", organisation_id: organisation.id, slug: SecureRandom.uuid)
pinceau = Tool.create!(name: "Pinceau", organisation_id: organisation.id, slug: SecureRandom.uuid)
rouleau_peinture = Tool.create!(name: "Rouleau à peinture", organisation_id: organisation.id, slug: SecureRandom.uuid)

# Outils techniques / réparation
tournevis = Tool.create!(name: "Tournevis", organisation_id: organisation.id, slug: SecureRandom.uuid)
marteau = Tool.create!(name: "Marteau", organisation_id: organisation.id, slug: SecureRandom.uuid)
clé_molette = Tool.create!(name: "Clé à molette", organisation_id: organisation.id, slug: SecureRandom.uuid)
perceuse = Tool.create!(name: "Perçeuse", organisation_id: organisation.id, slug: SecureRandom.uuid)

# Outils sécurité
testeur_extincteur = Tool.create!(name: "Testeur d'extincteur", organisation_id: organisation.id, slug: SecureRandom.uuid)


intervention_tonte_pelouse = Intervention.create(description: "Tondre pelouse parc hôtel de ville", adherent_id: adhérent_montmorency.id, début_prévue: "2025-09-01 08:00:00.000000000 +0100", fin_prévue: "2025-09-01 11:00:00.000000000 +0100", début: "2025-09-01 08:04:00.000000000 +0100", fin: "2025-09-01 10:43:00.000000000 +0100", workflow_state: "validé", organisation_id: organisation.id, slug: SecureRandom.uuid)
ToolIntervention.create!(tool_id: tondeuse_gazon.id, intervention_id: intervention_tonte_pelouse.id)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: intervention_tonte_pelouse.id)

intervention_elagage_arbre = Intervention.create(description: "Élagage des arbres du parc", adherent_id: adhérent_montmorency.id, début_prévue: "2025-09-01 08:00:00.000000000 +0100", fin_prévue: "2025-09-01 11:00:00.000000000 +0100", organisation_id: organisation.id, slug: SecureRandom.uuid)
AgentIntervention.create!(agent_id: agent_tech_andré.id, intervention_id: intervention_elagage_arbre.id)


intervention_recurrente_menage_mère = Intervention.create(description: "Ménage mairie d'Andilly", repeter: true, workflow_state: "pointage activé", adherent_id: adhérent_andilly.id, organisation_id: organisation.id, slug: SecureRandom.uuid, created_at: "2025-09-01 14:55:05.000000000 +0100")
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: intervention_recurrente_menage_mère.id)

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

# Intervention.create!([
#   {description: "Reboucher le nid-de-poule devant l'école", adherent_id: adhérent_attainville.id, début_prévue: "2025-09-01 13:00:00.000000000 +0100", fin_prévue: "2025-09-01 15:00:00.000000000 +0100", organisation_id: organisation.id, slug: SecureRandom.uuid},
#   {description: "Balayage de la voirie", adherent_id: adhérent_attainville.id, début_prévue: "2025-09-02 09:00:00.000000000 +0100", fin_prévue: "2025-09-02 12:00:00.000000000 +0100", organisation_id: organisation.id, slug: SecureRandom.uuid},
#   {description: "Entretien des aires de jeux et des installations sportives", adherent_id: adhérent_andilly.id, début_prévue: "2025-09-02 14:00:00.000000000 +0100", fin_prévue: "2025-09-02 16:00:00.000000000 +0100", organisation_id: organisation.id, slug: SecureRandom.uuid},
#   {description: "Ramassage des encombrants", adherent_id: adhérent_andilly.id, début_prévue: "2025-09-0 14:00:00.000000000 +0100", fin_prévue: "2025-09-02 16:00:00.000000000 +0100", organisation_id: organisation.id, slug: SecureRandom.uuid}
# ])

# ---------- i1 ----------
i1 = Intervention.create!(
  description: "Tonte parc communal - parc République",
  début: "2025-09-03 08:30:00 +0200",
  fin: "2025-09-03 11:00:00 +0200",
  début_prévue: Time.zone.parse("2025-09-03 08:30:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-09-03 11:00:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i1.id)
AgentIntervention.create!(agent_id: agent_tech_andré.id, intervention_id: i1.id)
ToolIntervention.create!(tool_id: tondeuse_gazon.id, intervention_id: i1.id)
ToolIntervention.create!(tool_id: camionnette_benne.id, intervention_id: i1.id)

# ---------- i2 ----------
i2 = Intervention.create!(
  description: "Remplacement ampoules salle des fêtes",
  début: "2025-09-04 09:00:00 +0200",
  fin: "2025-09-04 10:30:00 +0200",
  début_prévue: Time.zone.parse("2025-09-04 09:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-09-04 10:30:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.0,
  workflow_state: "validé",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_marie.id, intervention_id: i2.id)
ToolIntervention.create!(tool_id: echelle_4m.id, intervention_id: i2.id)
ToolIntervention.create!(tool_id: camionnette_benne.id, intervention_id: i2.id)

# ---------- i3 ----------
i3 = Intervention.create!(
  description: "Nettoyage ponctuel - mairie",
  début: "2025-09-05 07:30:00 +0200",
  fin: "2025-09-05 09:00:00 +0200",
  début_prévue: Time.zone.parse("2025-09-05 07:30:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-09-05 09:00:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i3.id)
ToolIntervention.create!(tool_id: aspirateur_industriel.id, intervention_id: i3.id)

# ---------- i4 ----------
i4 = Intervention.create!(
  description: "Installation rétroprojecteur école élémentaire",
  début: "2025-09-08 13:30:00 +0200",
  fin: "2025-09-08 15:00:00 +0200",
  début_prévue: Time.zone.parse("2025-09-08 13:30:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-09-08 15:00:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.0,
  workflow_state: "validé",
  adherent_id: adhérent_montmorency.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_info_clara.id, intervention_id: i4.id)
ToolIntervention.create!(tool_id: projecteur.id, intervention_id: i4.id)
ToolIntervention.create!(tool_id: ordinateur_portable.id, intervention_id: i4.id)

# ---------- i5 ----------
i5 = Intervention.create!(
  description: "Réunion de coordination périscolaire",
  début: "2025-09-10 18:00:00 +0200",
  fin: "2025-09-10 19:30:00 +0200",
  début_prévue: Time.zone.parse("2025-09-10 18:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-09-10 19:30:00 +0200") + rand(-15..15).minutes,
  workflow_state: "validé",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_periscolaire_pierre.id, intervention_id: i5.id)
AgentIntervention.create!(agent_id: agent_secretaire_véronique.id, intervention_id: i5.id)

# ---------- i6 ----------
i6 = Intervention.create!(
  description: "Contrôle comptable quai marchés - vérif. factures",
  début: "2025-09-12 09:00:00 +0200",
  fin: "2025-09-12 12:30:00 +0200",
  début_prévue: Time.zone.parse("2025-09-12 09:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-09-12 12:30:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 1.0,
  workflow_state: "validé",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_compta_sophie.id, intervention_id: i6.id)

# ---------- i7 ----------
i7 = Intervention.create!(
  description: "Réparation fuites plomberie école maternelle",
  début: "2025-09-13 08:00:00 +0200",
  fin: "2025-09-13 10:30:00 +0200",
  début_prévue: Time.zone.parse("2025-09-13 08:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-09-13 10:30:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.0,
  workflow_state: "validé",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_plomberie_marc.id, intervention_id: i7.id)
ToolIntervention.create!(tool_id: clé_molette.id, intervention_id: i7.id)
ToolIntervention.create!(tool_id: camionnette_benne.id, intervention_id: i7.id)

# ---------- i8 ----------
i8 = Intervention.create!(
  description: "Peinture salle polyvalente",
  début: "2025-09-15 07:30:00 +0200",
  fin: "2025-09-15 12:00:00 +0200",
  début_prévue: Time.zone.parse("2025-09-15 07:30:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-09-15 12:00:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 1.0,
  workflow_state: "validé",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_peinture_amelie.id, intervention_id: i8.id)
ToolIntervention.create!(tool_id: pinceau.id, intervention_id: i8.id)
ToolIntervention.create!(tool_id: escabeau.id, intervention_id: i8.id)

# ---------- i9 ----------
i9 = Intervention.create!(
  description: "Tonte parc secondaire",
  début: "2025-09-16 08:00:00 +0200",
  fin: "2025-09-16 10:30:00 +0200",
  début_prévue: Time.zone.parse("2025-09-16 08:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-09-16 10:30:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i9.id)
ToolIntervention.create!(tool_id: tondeuse_gazon.id, intervention_id: i9.id)

# ---------- i10 ----------
i10 = Intervention.create!(
  description: "Entretien fontaines publiques",
  début: "2025-09-17 09:00:00 +0200",
  fin: "2025-09-17 12:00:00 +0200",
  début_prévue: Time.zone.parse("2025-09-17 09:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-09-17 12:00:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "refusé",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_andré.id, intervention_id: i10.id)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i10.id)
ToolIntervention.create!(tool_id: balai_pompe.id, intervention_id: i10.id)
ToolIntervention.create!(tool_id: camionnette_benne.id, intervention_id: i10.id)

# ---------- i11 ----------
i11 = Intervention.create!(
  description: "Réparation portail mairie",
  début: "2025-09-18 08:30:00 +0200",
  fin: "2025-09-18 11:00:00 +0200",
  début_prévue: Time.zone.parse("2025-09-18 08:30:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-09-18 11:00:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.0,
  workflow_state: "validé",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_metal_luc.id, intervention_id: i11.id)
ToolIntervention.create!(tool_id: perceuse.id, intervention_id: i11.id)
ToolIntervention.create!(tool_id: camionnette_benne.id, intervention_id: i11.id)

# ---------- i12 ----------
i12 = Intervention.create!(
  description: "Peinture barrières école primaire",
  début: "2025-09-19 07:30:00 +0200",
  fin: "2025-09-19 12:30:00 +0200",
  début_prévue: Time.zone.parse("2025-09-19 07:30:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-09-19 12:30:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 1.0,
  workflow_state: "validé",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_peinture_amelie.id, intervention_id: i12.id)
ToolIntervention.create!(tool_id: pinceau.id, intervention_id: i12.id)
ToolIntervention.create!(tool_id: escabeau.id, intervention_id: i12.id)

# ---------- i13 ----------
i13 = Intervention.create!(
  description: "Vérification extincteurs bâtiments publics",
  début: "2025-09-20 08:00:00 +0200",
  fin: "2025-09-20 11:30:00 +0200",
  début_prévue: Time.zone.parse("2025-09-20 08:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-09-20 11:30:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_montmorency.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_securite_philippe.id, intervention_id: i13.id)
ToolIntervention.create!(tool_id: testeur_extincteur.id, intervention_id: i13.id)

# ---------- i14 ----------
i14 = Intervention.create!(
  description: "Nettoyage locaux sportifs",
  début: "2025-09-21 07:00:00 +0200",
  fin: "2025-09-21 10:30:00 +0200",
  début_prévue: Time.zone.parse("2025-09-21 07:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-09-21 10:30:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i14.id)
ToolIntervention.create!(tool_id: aspirateur_industriel.id, intervention_id: i14.id)
ToolIntervention.create!(tool_id: seau_serpillere.id, intervention_id: i14.id)

# ---------- i15 ----------
i15 = Intervention.create!(
  description: "Remplacement panneaux signalisation",
  début: "2025-09-22 08:30:00 +0200",
  fin: "2025-09-22 12:00:00 +0200",
  début_prévue: Time.zone.parse("2025-09-22 08:30:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-09-22 12:00:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_andré.id, intervention_id: i15.id)
ToolIntervention.create!(tool_id: camionnette_benne.id, intervention_id: i15.id)

# ---------- i16 ----------
i16 = Intervention.create!(
  description: "Tonte parc communal secondaire",
  début: "2025-09-23 08:00:00 +0200",
  fin: "2025-09-23 10:30:00 +0200",
  début_prévue: Time.zone.parse("2025-09-23 08:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-09-23 10:30:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i16.id)
ToolIntervention.create!(tool_id: tondeuse_gazon.id, intervention_id: i16.id)
ToolIntervention.create!(tool_id: camionnette_benne.id, intervention_id: i16.id)

# ---------- i17 ----------
i17 = Intervention.create!(
  description: "Révision matériel informatique mairie",
  début: "2025-09-24 09:00:00 +0200",
  fin: "2025-09-24 11:30:00 +0200",
  début_prévue: Time.zone.parse("2025-09-24 09:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-09-24 11:30:00 +0200") + rand(-15..15).minutes,
  workflow_state: "validé",
  adherent_id: adhérent_montmorency.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_info_clara.id, intervention_id: i17.id)
ToolIntervention.create!(tool_id: ordinateur_portable.id, intervention_id: i17.id)

# ---------- i18 ----------
i18 = Intervention.create!(
  description: "Nettoyage vitres bâtiments publics",
  début: "2025-09-25 07:30:00 +0200",
  fin: "2025-09-25 12:00:00 +0200",
  début_prévue: Time.zone.parse("2025-09-25 07:30:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-09-25 12:00:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 1.0,
  workflow_state: "refusé",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i18.id)
ToolIntervention.create!(tool_id: echelle_4m.id, intervention_id: i18.id)
ToolIntervention.create!(tool_id: seau_serpillere.id, intervention_id: i18.id)

# ---------- i19 ----------
i19 = Intervention.create!(
  description: "Entretien réseau irrigation parc central",
  début: "2025-09-26 08:00:00 +0200",
  fin: "2025-09-26 11:00:00 +0200",
  début_prévue: Time.zone.parse("2025-09-26 08:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-09-26 11:00:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_andré.id, intervention_id: i19.id)
ToolIntervention.create!(tool_id: clé_molette.id, intervention_id: i19.id)
ToolIntervention.create!(tool_id: camionnette_benne.id, intervention_id: i19.id)

# ---------- i20 ----------
i20 = Intervention.create!(
  description: "Réparation bancs publics",
  début: "2025-09-27 09:00:00 +0200",
  fin: "2025-09-27 12:30:00 +0200",
  début_prévue: Time.zone.parse("2025-09-27 09:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-09-27 12:30:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i20.id)
ToolIntervention.create!(tool_id: marteau.id, intervention_id: i20.id)
ToolIntervention.create!(tool_id: perceuse.id, intervention_id: i20.id)

# ---------- i21 ----------
i21 = Intervention.create!(
  description: "Nettoyage graffiti mur école",
  début: "2025-09-28 08:30:00 +0200",
  fin: "2025-09-28 11:30:00 +0200",
  début_prévue: Time.zone.parse("2025-09-28 08:30:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-09-28 11:30:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_peinture_amelie.id, intervention_id: i21.id)
ToolIntervention.create!(tool_id: escabeau.id, intervention_id: i21.id)

# ---------- i22 ----------
i22 = Intervention.create!(
  description: "Révision alarmes incendie gymnase",
  début: "2025-09-29 09:00:00 +0200",
  fin: "2025-09-29 12:00:00 +0200",
  début_prévue: Time.zone.parse("2025-09-29 09:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-09-29 12:00:00 +0200") + rand(-15..15).minutes,
  workflow_state: "validé",
  adherent_id: adhérent_montmorency.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_securite_philippe.id, intervention_id: i22.id)
ToolIntervention.create!(tool_id: testeur_extincteur.id, intervention_id: i22.id)

# ---------- i23 ----------
i23 = Intervention.create!(
  description: "Tonte pelouse mairie",
  début: "2025-09-30 07:30:00 +0200",
  fin: "2025-09-30 10:00:00 +0200",
  début_prévue: Time.zone.parse("2025-09-30 07:30:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-09-30 10:00:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_andré.id, intervention_id: i23.id)
ToolIntervention.create!(tool_id: tondeuse_gazon.id, intervention_id: i23.id)

# ---------- i24 ----------
i24 = Intervention.create!(
  description: "Nettoyage locaux bibliothèque",
  début: "2025-10-01 08:00:00 +0200",
  fin: "2025-10-01 12:00:00 +0200",
  début_prévue: Time.zone.parse("2025-10-01 08:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-01 12:00:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 1.0,
  workflow_state: "validé",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i24.id)
ToolIntervention.create!(tool_id: aspirateur_industriel.id, intervention_id: i24.id)
ToolIntervention.create!(tool_id: seau_serpillere.id, intervention_id: i24.id)

# ---------- i25 ----------
i25 = Intervention.create!(
  description: "Réparation clôture parc",
  début: "2025-10-02 09:00:00 +0200",
  fin: "2025-10-02 11:30:00 +0200",
  début_prévue: Time.zone.parse("2025-10-02 09:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-02 11:30:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "refusé",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i25.id)
ToolIntervention.create!(tool_id: marteau.id, intervention_id: i25.id)
ToolIntervention.create!(tool_id: perceuse.id, intervention_id: i25.id)

# ---------- i26 ----------
i26 = Intervention.create!(
  description: "Peinture barrière école secondaire",
  début: "2025-10-03 07:30:00 +0200",
  fin: "2025-10-03 12:00:00 +0200",
  début_prévue: Time.zone.parse("2025-10-03 07:30:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-03 12:00:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 1.0,
  workflow_state: "validé",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_peinture_amelie.id, intervention_id: i26.id)
ToolIntervention.create!(tool_id: pinceau.id, intervention_id: i26.id)
ToolIntervention.create!(tool_id: escabeau.id, intervention_id: i26.id)

# ---------- i27 ----------
i27 = Intervention.create!(
  description: "Vérification éclairage public",
  début: "2025-10-04 08:00:00 +0200",
  fin: "2025-10-04 11:00:00 +0200",
  début_prévue: Time.zone.parse("2025-10-04 08:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-04 11:00:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_montmorency.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_andré.id, intervention_id: i27.id)
ToolIntervention.create!(tool_id: clé_molette.id, intervention_id: i27.id)
ToolIntervention.create!(tool_id: camionnette_benne.id, intervention_id: i27.id)


# ---------- i28 ----------
i28 = Intervention.create!(
  description: "Nettoyage vitres mairie",
  début: "2025-10-05 08:30:00 +0200",
  fin: "2025-10-05 11:30:00 +0200",
  début_prévue: Time.zone.parse("2025-10-05 08:30:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-05 11:30:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i28.id)
ToolIntervention.create!(tool_id: escabeau.id, intervention_id: i28.id)
ToolIntervention.create!(tool_id: chiffon_microfibre.id, intervention_id: i28.id)

# ---------- i29 ----------
i29 = Intervention.create!(
  description: "Réparation robinet fontaine parc",
  début: "2025-10-06 09:00:00 +0200",
  fin: "2025-10-06 12:00:00 +0200",
  début_prévue: Time.zone.parse("2025-10-06 09:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-06 12:00:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i29.id)
ToolIntervention.create!(tool_id: clé_molette.id, intervention_id: i29.id)

# ---------- i30 ----------
i30 = Intervention.create!(
  description: "Peinture passage piétons",
  début: "2025-10-07 07:30:00 +0200",
  fin: "2025-10-07 11:30:00 +0200",
  début_prévue: Time.zone.parse("2025-10-07 07:30:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-07 11:30:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 1.0,
  workflow_state: "validé",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_peinture_amelie.id, intervention_id: i30.id)
ToolIntervention.create!(tool_id: peinture_blanc.id, intervention_id: i30.id)
ToolIntervention.create!(tool_id: rouleau_peinture.id, intervention_id: i30.id)

# ---------- i31 ----------
i31 = Intervention.create!(
  description: "Vérification extincteurs école",
  début: "2025-10-08 08:00:00 +0200",
  fin: "2025-10-08 10:30:00 +0200",
  début_prévue: Time.zone.parse("2025-10-08 08:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-08 10:30:00 +0200") + rand(-15..15).minutes,
  workflow_state: "validé",
  adherent_id: adhérent_montmorency.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_securite_philippe.id, intervention_id: i31.id)
ToolIntervention.create!(tool_id: testeur_extincteur.id, intervention_id: i31.id)

# ---------- i32 ----------
i32 = Intervention.create!(
  description: "Nettoyage locaux salle polyvalente",
  début: "2025-10-09 08:00:00 +0200",
  fin: "2025-10-09 12:00:00 +0200",
  début_prévue: Time.zone.parse("2025-10-09 08:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-09 12:00:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 1.0,
  workflow_state: "validé",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i32.id)
ToolIntervention.create!(tool_id: aspirateur_industriel.id, intervention_id: i32.id)
ToolIntervention.create!(tool_id: seau_serpillere.id, intervention_id: i32.id)

# ---------- i33 ----------
i33 = Intervention.create!(
  description: "Réparation grille parc",
  début: "2025-10-10 09:00:00 +0200",
  fin: "2025-10-10 12:00:00 +0200",
  début_prévue: Time.zone.parse("2025-10-10 09:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-10 12:00:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i33.id)
ToolIntervention.create!(tool_id: marteau.id, intervention_id: i33.id)

# ---------- i34 ----------
i34 = Intervention.create!(
  description: "Peinture bancs parc",
  début: "2025-10-11 08:00:00 +0200",
  fin: "2025-10-11 11:30:00 +0200",
  début_prévue: Time.zone.parse("2025-10-11 08:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-11 11:30:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 1.0,
  workflow_state: "validé",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_peinture_amelie.id, intervention_id: i34.id)
ToolIntervention.create!(tool_id: pinceau.id, intervention_id: i34.id)
ToolIntervention.create!(tool_id: peinture_vert.id, intervention_id: i34.id)

# ---------- i35 ----------
i35 = Intervention.create!(
  description: "Vérification alarmes incendie mairie",
  début: "2025-10-12 09:00:00 +0200",
  fin: "2025-10-12 12:00:00 +0200",
  début_prévue: Time.zone.parse("2025-10-12 09:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-12 12:00:00 +0200") + rand(-15..15).minutes,
  workflow_state: "validé",
  adherent_id: adhérent_montmorency.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_securite_philippe.id, intervention_id: i35.id)
ToolIntervention.create!(tool_id: testeur_extincteur.id, intervention_id: i35.id)

# ---------- i36 ----------
i36 = Intervention.create!(
  description: "Tonte pelouse école primaire",
  début: "2025-10-13 07:30:00 +0200",
  fin: "2025-10-13 10:00:00 +0200",
  début_prévue: Time.zone.parse("2025-10-13 07:30:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-13 10:00:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_andré.id, intervention_id: i36.id)
ToolIntervention.create!(tool_id: tondeuse_gazon.id, intervention_id: i36.id)

# ---------- i37 ----------
i37 = Intervention.create!(
  description: "Nettoyage vitres école maternelle",
  début: "2025-10-14 08:30:00 +0200",
  fin: "2025-10-14 11:30:00 +0200",
  début_prévue: Time.zone.parse("2025-10-14 08:30:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-14 11:30:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i37.id)
ToolIntervention.create!(tool_id: escabeau.id, intervention_id: i37.id)
ToolIntervention.create!(tool_id: chiffon_microfibre.id, intervention_id: i37.id)

# ---------- i38 ----------
i38 = Intervention.create!(
  description: "Réparation porte mairie",
  début: "2025-10-15 09:00:00 +0200",
  fin: "2025-10-15 12:00:00 +0200",
  début_prévue: Time.zone.parse("2025-10-15 09:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-15 12:00:00 +0200") + rand(-15..15).minutes,
  workflow_state: "validé",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i38.id)
ToolIntervention.create!(tool_id: tournevis.id, intervention_id: i38.id)
ToolIntervention.create!(tool_id: marteau.id, intervention_id: i38.id)

# ---------- i39 ----------
i39 = Intervention.create!(
  description: "Peinture barrières parc",
  début: "2025-10-16 08:00:00 +0200",
  fin: "2025-10-16 11:30:00 +0200",
  début_prévue: Time.zone.parse("2025-10-16 08:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-16 11:30:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 1.0,
  workflow_state: "validé",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_peinture_amelie.id, intervention_id: i39.id)
ToolIntervention.create!(tool_id: pinceau.id, intervention_id: i39.id)
ToolIntervention.create!(tool_id: peinture_rouge.id, intervention_id: i39.id)

# ---------- i40 ----------
i40 = Intervention.create!(
  description: "Vérification extincteurs salle polyvalente",
  début: "2025-10-17 08:00:00 +0200",
  fin: "2025-10-17 10:30:00 +0200",
  début_prévue: Time.zone.parse("2025-10-17 08:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-17 10:30:00 +0200") + rand(-15..15).minutes,
  workflow_state: "validé",
  adherent_id: adhérent_montmorency.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_securite_philippe.id, intervention_id: i40.id)
ToolIntervention.create!(tool_id: testeur_extincteur.id, intervention_id: i40.id)

# ---------- i41 ----------
i41 = Intervention.create!(
  description: "Tonte pelouse mairie",
  début: "2025-10-18 07:30:00 +0200",
  fin: "2025-10-18 10:00:00 +0200",
  début_prévue: Time.zone.parse("2025-10-18 07:30:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-18 10:00:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_andré.id, intervention_id: i41.id)
ToolIntervention.create!(tool_id: tondeuse_gazon.id, intervention_id: i41.id)

# ---------- i42 ----------
i42 = Intervention.create!(
  description: "Nettoyage vitres mairie",
  début: "2025-10-19 08:30:00 +0200",
  fin: "2025-10-19 11:30:00 +0200",
  début_prévue: Time.zone.parse("2025-10-19 08:30:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-19 11:30:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i42.id)
ToolIntervention.create!(tool_id: escabeau.id, intervention_id: i42.id)
ToolIntervention.create!(tool_id: chiffon_microfibre.id, intervention_id: i42.id)

# ---------- i43 ----------
i43 = Intervention.create!(
  description: "Réparation robinet fontaine parc",
  début: "2025-10-20 09:00:00 +0200",
  fin: "2025-10-20 12:00:00 +0200",
  début_prévue: Time.zone.parse("2025-10-20 09:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-20 12:00:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i43.id)
ToolIntervention.create!(tool_id: clé_molette.id, intervention_id: i43.id)

# ---------- i44 ----------
i44 = Intervention.create!(
  description: "Peinture passage piétons",
  début: "2025-10-21 07:30:00 +0200",
  fin: "2025-10-21 11:30:00 +0200",
  début_prévue: Time.zone.parse("2025-10-21 07:30:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-21 11:30:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 1.0,
  workflow_state: "validé",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_peinture_amelie.id, intervention_id: i44.id)
ToolIntervention.create!(tool_id: peinture_blanc.id, intervention_id: i44.id)
ToolIntervention.create!(tool_id: rouleau_peinture.id, intervention_id: i44.id)

# ---------- i45 ----------
i45 = Intervention.create!(
  description: "Vérification extincteurs école",
  début: "2025-10-22 08:00:00 +0200",
  fin: "2025-10-22 10:30:00 +0200",
  début_prévue: Time.zone.parse("2025-10-22 08:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-22 10:30:00 +0200") + rand(-15..15).minutes,
  workflow_state: "validé",
  adherent_id: adhérent_montmorency.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_securite_philippe.id, intervention_id: i45.id)
ToolIntervention.create!(tool_id: testeur_extincteur.id, intervention_id: i45.id)

# ---------- i46 ----------
i46 = Intervention.create!(
  description: "Nettoyage locaux salle polyvalente",
  début: "2025-10-23 08:00:00 +0200",
  fin: "2025-10-23 12:00:00 +0200",
  début_prévue: Time.zone.parse("2025-10-23 08:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-23 12:00:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 1.0,
  workflow_state: "validé",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i46.id)
ToolIntervention.create!(tool_id: aspirateur_industriel.id, intervention_id: i46.id)
ToolIntervention.create!(tool_id: seau_serpillere.id, intervention_id: i46.id)

# ---------- i47 ----------
i47 = Intervention.create!(
  description: "Réparation grille parc",
  début: "2025-10-24 09:00:00 +0200",
  fin: "2025-10-24 12:00:00 +0200",
  début_prévue: Time.zone.parse("2025-10-24 09:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-24 12:00:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i47.id)
ToolIntervention.create!(tool_id: marteau.id, intervention_id: i47.id)

# ---------- i48 ----------
i48 = Intervention.create!(
  description: "Peinture bancs parc",
  début: "2025-10-25 08:00:00 +0200",
  fin: "2025-10-25 11:30:00 +0200",
  début_prévue: Time.zone.parse("2025-10-25 08:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-25 11:30:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 1.0,
  workflow_state: "validé",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_peinture_amelie.id, intervention_id: i48.id)
ToolIntervention.create!(tool_id: pinceau.id, intervention_id: i48.id)
ToolIntervention.create!(tool_id: peinture_vert.id, intervention_id: i48.id)

# ---------- i49 ----------
i49 = Intervention.create!(
  description: "Vérification alarmes incendie mairie",
  début: "2025-10-26 09:00:00 +0200",
  fin: "2025-10-26 12:00:00 +0200",
  début_prévue: Time.zone.parse("2025-10-26 09:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-26 12:00:00 +0200") + rand(-15..15).minutes,
  workflow_state: "validé",
  adherent_id: adhérent_montmorency.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_securite_philippe.id, intervention_id: i49.id)
ToolIntervention.create!(tool_id: testeur_extincteur.id, intervention_id: i49.id)

# ---------- i50 ----------
i50 = Intervention.create!(
  description: "Tonte pelouse école primaire",
  début: "2025-10-27 07:30:00 +0200",
  fin: "2025-10-27 10:00:00 +0200",
  début_prévue: Time.zone.parse("2025-10-27 07:30:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-27 10:00:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i50.id)
ToolIntervention.create!(tool_id: tondeuse_gazon.id, intervention_id: i50.id)

# ---------- i51 ----------
i51 = Intervention.create!(
  description: "Nettoyage vitres école maternelle",
  début: "2025-10-28 08:30:00 +0200",
  fin: "2025-10-28 11:30:00 +0200",
  début_prévue: Time.zone.parse("2025-10-28 08:30:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-28 11:30:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i51.id)
ToolIntervention.create!(tool_id: escabeau.id, intervention_id: i51.id)
ToolIntervention.create!(tool_id: chiffon_microfibre.id, intervention_id: i51.id)

# ---------- i52 ----------
i52 = Intervention.create!(
  description: "Réparation porte mairie",
  début: "2025-10-29 09:00:00 +0200",
  fin: "2025-10-29 12:00:00 +0200",
  début_prévue: Time.zone.parse("2025-10-29 09:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-29 12:00:00 +0200") + rand(-15..15).minutes,
  workflow_state: "validé",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i52.id)
ToolIntervention.create!(tool_id: tournevis.id, intervention_id: i52.id)
ToolIntervention.create!(tool_id: marteau.id, intervention_id: i52.id)

# ---------- i53 ----------
i53 = Intervention.create!(
  description: "Peinture barrières parc",
  début: "2025-10-30 08:00:00 +0200",
  fin: "2025-10-30 11:30:00 +0200",
  début_prévue: Time.zone.parse("2025-10-30 08:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-30 11:30:00 +0200") + rand(-15..15).minutes,
  temps_de_pause: 1.0,
  workflow_state: "validé",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_peinture_amelie.id, intervention_id: i53.id)
ToolIntervention.create!(tool_id: pinceau.id, intervention_id: i53.id)
ToolIntervention.create!(tool_id: peinture_rouge.id, intervention_id: i53.id)

# ---------- i54 ----------
i54 = Intervention.create!(
  description: "Vérification extincteurs salle polyvalente",
  début: "2025-10-31 08:00:00 +0200",
  fin: "2025-10-31 10:30:00 +0200",
  début_prévue: Time.zone.parse("2025-10-31 08:00:00 +0200") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-10-31 10:30:00 +0200") + rand(-15..15).minutes,
  workflow_state: "validé",
  adherent_id: adhérent_montmorency.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_securite_philippe.id, intervention_id: i54.id)
ToolIntervention.create!(tool_id: testeur_extincteur.id, intervention_id: i54.id)

i55 = Intervention.create!(
  description: "Tonte pelouse parc central",
  début: "2025-11-01 07:30:00 +0100",
  fin: "2025-11-01 10:00:00 +0100",
  début_prévue: Time.zone.parse("2025-11-01 07:30:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-01 10:00:00 +0100") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_andré.id, intervention_id: i55.id)
ToolIntervention.create!(tool_id: tondeuse_gazon.id, intervention_id: i55.id)

# ---------- i56 ----------
i56 = Intervention.create!(
  description: "Nettoyage vitres mairie",
  début: "2025-11-02 08:30:00 +0100",
  fin: "2025-11-02 11:30:00 +0100",
  début_prévue: Time.zone.parse("2025-11-02 08:30:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-02 11:30:00 +0100") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i56.id)
ToolIntervention.create!(tool_id: escabeau.id, intervention_id: i56.id)
ToolIntervention.create!(tool_id: chiffon_microfibre.id, intervention_id: i56.id)

# ---------- i57 ----------
i57 = Intervention.create!(
  description: "Réparation robinet école primaire",
  début: "2025-11-03 09:00:00 +0100",
  fin: "2025-11-03 12:00:00 +0100",
  début_prévue: Time.zone.parse("2025-11-03 09:00:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-03 12:00:00 +0100") + rand(-15..15).minutes,
  workflow_state: "validé",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i57.id)
ToolIntervention.create!(tool_id: clé_molette.id, intervention_id: i57.id)

# ---------- i58 ----------
i58 = Intervention.create!(
  description: "Peinture bancs parc sud",
  début: "2025-11-04 08:00:00 +0100",
  fin: "2025-11-04 11:30:00 +0100",
  début_prévue: Time.zone.parse("2025-11-04 08:00:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-04 11:30:00 +0100") + rand(-15..15).minutes,
  temps_de_pause: 1.0,
  workflow_state: "validé",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_peinture_amelie.id, intervention_id: i58.id)
ToolIntervention.create!(tool_id: pinceau.id, intervention_id: i58.id)
ToolIntervention.create!(tool_id: peinture_vert.id, intervention_id: i58.id)

# ---------- i59 ----------
i59 = Intervention.create!(
  description: "Vérification alarmes incendie école maternelle",
  début: "2025-11-05 09:00:00 +0100",
  fin: "2025-11-05 12:00:00 +0100",
  début_prévue: Time.zone.parse("2025-11-05 09:00:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-05 12:00:00 +0100") + rand(-15..15).minutes,
  workflow_state: "validé",
  adherent_id: adhérent_montmorency.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_securite_philippe.id, intervention_id: i59.id)
ToolIntervention.create!(tool_id: testeur_extincteur.id, intervention_id: i59.id)

# ---------- i60 ----------
i60 = Intervention.create!(
  description: "Nettoyage locaux salle polyvalente",
  début: "2025-11-06 08:00:00 +0100",
  fin: "2025-11-06 12:00:00 +0100",
  début_prévue: Time.zone.parse("2025-11-06 08:00:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-06 12:00:00 +0100") + rand(-15..15).minutes,
  temps_de_pause: 1.0,
  workflow_state: "validé",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i60.id)
ToolIntervention.create!(tool_id: aspirateur_industriel.id, intervention_id: i60.id)
ToolIntervention.create!(tool_id: seau_serpillere.id, intervention_id: i60.id)

# ---------- i61 ----------
i61 = Intervention.create!(
  description: "Réparation grille parc central",
  début: "2025-11-07 09:00:00 +0100",
  fin: "2025-11-07 12:00:00 +0100",
  début_prévue: Time.zone.parse("2025-11-07 09:00:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-07 12:00:00 +0100") + rand(-15..15).minutes,
  workflow_state: "validé",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i61.id)
ToolIntervention.create!(tool_id: marteau.id, intervention_id: i61.id)

# ---------- i62 ----------
i62 = Intervention.create!(
  description: "Peinture passages piétons école",
  début: "2025-11-08 07:30:00 +0100",
  fin: "2025-11-08 11:30:00 +0100",
  début_prévue: Time.zone.parse("2025-11-08 07:30:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-08 11:30:00 +0100") + rand(-15..15).minutes,
  temps_de_pause: 1.0,
  workflow_state: "validé",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_peinture_amelie.id, intervention_id: i62.id)
ToolIntervention.create!(tool_id: peinture_blanc.id, intervention_id: i62.id)
ToolIntervention.create!(tool_id: rouleau_peinture.id, intervention_id: i62.id)

# ---------- i63 ----------
i63 = Intervention.create!(
  description: "Vérification extincteurs école primaire",
  début: "2025-11-09 08:00:00 +0100",
  fin: "2025-11-09 10:30:00 +0100",
  début_prévue: Time.zone.parse("2025-11-09 08:00:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-09 10:30:00 +0100") + rand(-15..15).minutes,
  workflow_state: "validé",
  adherent_id: adhérent_montmorency.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_securite_philippe.id, intervention_id: i63.id)
ToolIntervention.create!(tool_id: testeur_extincteur.id, intervention_id: i63.id)

# ---------- i64 ----------
i64 = Intervention.create!(
  description: "Nettoyage vitres école maternelle",
  début: "2025-11-17 08:30:00 +0100",
  fin: "2025-11-17 11:30:00 +0100",
  début_prévue: Time.zone.parse("2025-11-10 08:30:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-10 11:30:00 +0100") + rand(-15..15).minutes,
  
  workflow_state: "terminé",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i64.id)
ToolIntervention.create!(tool_id: escabeau.id, intervention_id: i64.id)
ToolIntervention.create!(tool_id: chiffon_microfibre.id, intervention_id: i64.id)

# ---------- i65 ----------
i65 = Intervention.create!(
  description: "Nettoyage locaux mairie",
  début_prévue: "2025-11-28 08:00:00 +0100",
  fin_prévue: "2025-11-28 12:00:00 +0100",
  
  workflow_state: "nouveau",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i65.id)
ToolIntervention.create!(tool_id: aspirateur_industriel.id, intervention_id: i65.id)
ToolIntervention.create!(tool_id: seau_serpillere.id, intervention_id: i65.id)

# ---------- i66 ----------
i66 = Intervention.create!(
  description: "Réparation éclairage parc central",
  début_prévue: "2025-12-02 09:00:00 +0100",
  fin_prévue: "2025-12-02 11:30:00 +0100",
  workflow_state: "nouveau",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i66.id)
ToolIntervention.create!(tool_id: tournevis.id, intervention_id: i66.id)

# ---------- i67 ----------
i67 = Intervention.create!(
  description: "Peinture barrières école primaire",
  début_prévue: "2025-12-03 08:30:00 +0100",
  fin_prévue: "2025-12-03 11:30:00 +0100",
  
  workflow_state: "nouveau",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_peinture_amelie.id, intervention_id: i67.id)
ToolIntervention.create!(tool_id: peinture_rouge.id, intervention_id: i67.id)
ToolIntervention.create!(tool_id: pinceau.id, intervention_id: i67.id)

# ---------- i68 ----------
i68 = Intervention.create!(
  description: "Vérification extincteurs salle polyvalente",
  début_prévue: "2025-12-04 09:00:00 +0100",
  fin_prévue: "2025-12-04 10:30:00 +0100",
  workflow_state: "nouveau",
  adherent_id: adhérent_montmorency.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_securite_philippe.id, intervention_id: i68.id)
ToolIntervention.create!(tool_id: testeur_extincteur.id, intervention_id: i68.id)

# ---------- i69 ----------
i69 = Intervention.create!(
  description: "Nettoyage vitres mairie",
  début_prévue: "2025-12-05 08:00:00 +0100",
  fin_prévue: "2025-12-05 11:00:00 +0100",
  
  workflow_state: "nouveau",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i69.id)
ToolIntervention.create!(tool_id: escabeau.id, intervention_id: i69.id)
ToolIntervention.create!(tool_id: chiffon_microfibre.id, intervention_id: i69.id)

# ---------- i70 ----------
i70 = Intervention.create!(
  description: "Réparation portail parc sud",
  début_prévue: "2025-12-06 09:00:00 +0100",
  fin_prévue: "2025-12-06 12:00:00 +0100",
  workflow_state: "nouveau",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i70.id)
ToolIntervention.create!(tool_id: marteau.id, intervention_id: i70.id)
ToolIntervention.create!(tool_id: clé_molette.id, intervention_id: i70.id)

# ---------- i71 ----------
i71 = Intervention.create!(
  description: "Peinture bancs parc central",
  début_prévue: "2025-12-07 08:30:00 +0100",
  fin_prévue: "2025-12-07 11:30:00 +0100",
  
  workflow_state: "nouveau",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_peinture_amelie.id, intervention_id: i71.id)
ToolIntervention.create!(tool_id: peinture_vert.id, intervention_id: i71.id)
ToolIntervention.create!(tool_id: rouleau_peinture.id, intervention_id: i71.id)

# ---------- i72 ----------
i72 = Intervention.create!(
  description: "Nettoyage locaux école primaire",
  début_prévue: "2025-12-08 08:00:00 +0100",
  fin_prévue: "2025-12-08 12:00:00 +0100",
  
  workflow_state: "nouveau",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i72.id)
ToolIntervention.create!(tool_id: aspirateur_industriel.id, intervention_id: i72.id)
ToolIntervention.create!(tool_id: seau_serpillere.id, intervention_id: i72.id)

# ---------- i73 ----------
i73 = Intervention.create!(
  description: "Vérification alarmes incendie mairie",
  début_prévue: "2025-12-09 09:00:00 +0100",
  fin_prévue: "2025-12-09 12:00:00 +0100",
  workflow_state: "nouveau",
  adherent_id: adhérent_montmorency.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_securite_philippe.id, intervention_id: i73.id)
ToolIntervention.create!(tool_id: testeur_extincteur.id, intervention_id: i73.id)

# ---------- i74 ----------
i74 = Intervention.create!(
  description: "Peinture passages piétons parc sud",
  début_prévue: "2025-12-10 08:30:00 +0100",
  fin_prévue: "2025-12-10 11:30:00 +0100",
  
  workflow_state: "nouveau",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_peinture_amelie.id, intervention_id: i74.id)
ToolIntervention.create!(tool_id: peinture_blanc.id, intervention_id: i74.id)
ToolIntervention.create!(tool_id: pinceau.id, intervention_id: i74.id)

# ---------- i75 ----------
i75 = Intervention.create!(
  description: "Nettoyage vitres salle polyvalente",
  début_prévue: "2025-12-11 08:30:00 +0100",
  fin_prévue: "2025-12-11 11:30:00 +0100",
  
  workflow_state: "nouveau",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i75.id)
ToolIntervention.create!(tool_id: escabeau.id, intervention_id: i75.id)
ToolIntervention.create!(tool_id: chiffon_microfibre.id, intervention_id: i75.id)

# ---------- i76 ----------
i76 = Intervention.create!(
  description: "Réparation robinet parc central",
  début_prévue: "2025-12-12 09:00:00 +0100",
  fin_prévue: "2025-12-12 12:00:00 +0100",
  workflow_state: "nouveau",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i76.id)
ToolIntervention.create!(tool_id: clé_molette.id, intervention_id: i76.id)

# ---------- i77 ----------
i77 = Intervention.create!(
  description: "Peinture barrières parc central",
  début_prévue: "2025-12-13 08:30:00 +0100",
  fin_prévue: "2025-12-13 11:30:00 +0100",
  
  workflow_state: "nouveau",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_peinture_amelie.id, intervention_id: i77.id)
ToolIntervention.create!(tool_id: peinture_rouge.id, intervention_id: i77.id)
ToolIntervention.create!(tool_id: pinceau.id, intervention_id: i77.id)

# ---------- i78 ----------
i78 = Intervention.create!(
  description: "Nettoyage locaux mairie",
  début_prévue: "2025-12-14 08:00:00 +0100",
  fin_prévue: "2025-12-14 12:00:00 +0100",
  
  workflow_state: "nouveau",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i78.id)
ToolIntervention.create!(tool_id: aspirateur_industriel.id, intervention_id: i78.id)
ToolIntervention.create!(tool_id: seau_serpillere.id, intervention_id: i78.id)

# ---------- i79 ----------
i79 = Intervention.create!(
  description: "Vérification alarmes incendie école primaire",
  début_prévue: "2025-12-15 09:00:00 +0100",
  fin_prévue: "2025-12-15 12:00:00 +0100",
  workflow_state: "nouveau",
  adherent_id: adhérent_montmorency.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_securite_philippe.id, intervention_id: i79.id)
ToolIntervention.create!(tool_id: testeur_extincteur.id, intervention_id: i79.id)

# ---------- i80 ----------
i80 = Intervention.create!(
  description: "Peinture passages piétons parc sud",
  début_prévue: "2025-12-16 08:30:00 +0100",
  fin_prévue: "2025-12-16 11:30:00 +0100",
  
  workflow_state: "nouveau",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_peinture_amelie.id, intervention_id: i80.id)
ToolIntervention.create!(tool_id: peinture_blanc.id, intervention_id: i80.id)
ToolIntervention.create!(tool_id: pinceau.id, intervention_id: i80.id)

# ---------- i81 ----------
i81 = Intervention.create!(
  description: "Nettoyage vitres salle polyvalente",
  début_prévue: "2025-12-17 08:30:00 +0100",
  fin_prévue: "2025-12-17 11:30:00 +0100",
  
  workflow_state: "nouveau",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i81.id)
ToolIntervention.create!(tool_id: escabeau.id, intervention_id: i81.id)
ToolIntervention.create!(tool_id: chiffon_microfibre.id, intervention_id: i81.id)

# ---------- i82 ----------
i82 = Intervention.create!(
  description: "Réparation robinet parc central",
  début_prévue: "2025-12-18 09:00:00 +0100",
  fin_prévue: "2025-12-18 12:00:00 +0100",
  workflow_state: "nouveau",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i82.id)
ToolIntervention.create!(tool_id: clé_molette.id, intervention_id: i82.id)

# ---------- i83 ----------
i83 = Intervention.create!(
  description: "Peinture barrières parc central",
  début_prévue: "2025-12-19 08:30:00 +0100",
  fin_prévue: "2025-12-19 11:30:00 +0100",
  
  workflow_state: "nouveau",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_peinture_amelie.id, intervention_id: i83.id)
ToolIntervention.create!(tool_id: peinture_rouge.id, intervention_id: i83.id)
ToolIntervention.create!(tool_id: pinceau.id, intervention_id: i83.id)

# ---------- i84 ----------
i84 = Intervention.create!(
  description: "Nettoyage locaux mairie",
  début_prévue: "2025-12-20 08:00:00 +0100",
  fin_prévue: "2025-12-20 12:00:00 +0100",
  
  workflow_state: "nouveau",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i84.id)
ToolIntervention.create!(tool_id: aspirateur_industriel.id, intervention_id: i84.id)
ToolIntervention.create!(tool_id: seau_serpillere.id, intervention_id: i84.id)

# ---------- i85 ----------
i85 = Intervention.create!(
  description: "Vérification alarmes incendie école primaire",
  début_prévue: "2025-12-21 09:00:00 +0100",
  fin_prévue: "2025-12-21 12:00:00 +0100",
  workflow_state: "nouveau",
  adherent_id: adhérent_montmorency.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
AgentIntervention.create!(agent_id: agent_securite_philippe.id, intervention_id: i85.id)
ToolIntervention.create!(tool_id: testeur_extincteur.id, intervention_id: i85.id)

i86 = Intervention.create!(
  description: "Nettoyage vitres école primaire",
  début: "2025-11-12 08:30:00 +0100",
  fin: "2025-11-12 11:30:00 +0100",
  début_prévue: Time.zone.parse("2025-11-12 08:30:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-12 11:30:00 +0100") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "validé",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
i86.update!(team_id: team_menage.id)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i86.id)
ToolIntervention.create!(tool_id: escabeau.id, intervention_id: i86.id)
ToolIntervention.create!(tool_id: chiffon_microfibre.id, intervention_id: i86.id)

# ---------- 13 novembre ----------
i87 = Intervention.create!(
  description: "Réparation porte école maternelle",
  début: "2025-11-13 09:00:00 +0100",
  fin: "2025-11-13 12:00:00 +0100",
  début_prévue: Time.zone.parse("2025-11-13 09:00:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-13 12:00:00 +0100") + rand(-15..15).minutes,
  workflow_state: "validé",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
i87.update!(team_id: team_technique.id)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i87.id)
ToolIntervention.create!(tool_id: tournevis.id, intervention_id: i87.id)
ToolIntervention.create!(tool_id: marteau.id, intervention_id: i87.id)

# ---------- 14 novembre ----------
i88 = Intervention.create!(
  description: "Peinture barrières parc central",
  début: "2025-11-14 08:00:00 +0100",
  fin: "2025-11-14 11:30:00 +0100",
  début_prévue: Time.zone.parse("2025-11-14 08:00:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-14 11:30:00 +0100") + rand(-15..15).minutes,
  temps_de_pause: 1.0,
  workflow_state: "validé",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
i88.update!(team_id: team_peinture.id)
AgentIntervention.create!(agent_id: agent_peinture_amelie.id, intervention_id: i88.id)
ToolIntervention.create!(tool_id: pinceau.id, intervention_id: i88.id)
ToolIntervention.create!(tool_id: peinture_rouge.id, intervention_id: i88.id)

# ---------- 15 novembre ----------
i89 = Intervention.create!(
  description: "Vérification extincteurs mairie",
  début: "2025-11-15 08:00:00 +0100",
  fin: "2025-11-15 10:30:00 +0100",
  début_prévue: Time.zone.parse("2025-11-15 08:00:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-15 10:30:00 +0100") + rand(-15..15).minutes,
  workflow_state: "validé",
  adherent_id: adhérent_montmorency.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
i89.update!(team_id: team_securite.id)
AgentIntervention.create!(agent_id: agent_securite_philippe.id, intervention_id: i89.id)
ToolIntervention.create!(tool_id: testeur_extincteur.id, intervention_id: i89.id)

# ---------- 16 novembre ----------
i90 = Intervention.create!(
  description: "Tonte pelouse parc sud",
  début: "2025-11-16 07:30:00 +0100",
  fin: "2025-11-16 10:00:00 +0100",
  début_prévue: Time.zone.parse("2025-11-16 07:30:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-16 10:00:00 +0100") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "terminé",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
i90.update!(team_id: team_espaces_verts.id)
AgentIntervention.create!(agent_id: agent_tech_andré.id, intervention_id: i90.id)
ToolIntervention.create!(tool_id: tondeuse_gazon.id, intervention_id: i90.id)

# ---------- i86 ----------
i86 = Intervention.create!(
  description: "Nettoyage vitres école primaire",
  début_prévue: Time.zone.parse("2025-11-17 08:00:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-17 12:00:00 +0100") + rand(-15..15).minutes,
  workflow_state: "nouveau",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
i86.update!(team_id: team_menage.id)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i86.id)
ToolIntervention.create!(tool_id: escabeau.id, intervention_id: i86.id)
ToolIntervention.create!(tool_id: chiffon_microfibre.id, intervention_id: i86.id)

# ---------- i87 ----------
i87 = Intervention.create!(
  description: "Réparation portail école primaire",
  début_prévue: Time.zone.parse("2025-11-18 09:00:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-18 12:00:00 +0100") + rand(-15..15).minutes,
  workflow_state: "nouveau",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
i87.update!(team_id: team_technique.id)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i87.id)
ToolIntervention.create!(tool_id: marteau.id, intervention_id: i87.id)
ToolIntervention.create!(tool_id: clé_molette.id, intervention_id: i87.id)

# ---------- i88 ----------
i88 = Intervention.create!(
  description: "Peinture bancs école primaire",
  début_prévue: Time.zone.parse("2025-11-19 08:30:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-19 11:30:00 +0100") + rand(-15..15).minutes,
  workflow_state: "nouveau",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
i88.update!(team_id: team_peinture.id)
AgentIntervention.create!(agent_id: agent_peinture_amelie.id, intervention_id: i88.id)
ToolIntervention.create!(tool_id: pinceau.id, intervention_id: i88.id)
ToolIntervention.create!(tool_id: peinture_rouge.id, intervention_id: i88.id)

# ---------- i89 ----------
i89 = Intervention.create!(
  description: "Vérification extincteurs salle polyvalente",
  début_prévue: Time.zone.parse("2025-11-20 09:00:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-20 10:30:00 +0100") + rand(-15..15).minutes,
  workflow_state: "nouveau",
  adherent_id: adhérent_montmorency.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
i89.update!(team_id: team_securite.id)
AgentIntervention.create!(agent_id: agent_securite_philippe.id, intervention_id: i89.id)
ToolIntervention.create!(tool_id: testeur_extincteur.id, intervention_id: i89.id)

# ---------- i90 ----------
i90 = Intervention.create!(
  description: "Nettoyage locaux mairie",
  début_prévue: Time.zone.parse("2025-11-21 08:00:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-21 12:00:00 +0100") + rand(-15..15).minutes,
  workflow_state: "nouveau",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
i90.update!(team_id: team_menage.id)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i90.id)
ToolIntervention.create!(tool_id: aspirateur_industriel.id, intervention_id: i90.id)
ToolIntervention.create!(tool_id: seau_serpillere.id, intervention_id: i90.id)

# ---------- 17 novembre ----------
i91 = Intervention.create!(
  description: "Réparation bancs parc central",
  début: "2025-11-17 08:30:00 +0100",
  fin: "2025-11-17 11:00:00 +0100",
  début_prévue: Time.zone.parse("2025-11-17 08:30:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-17 11:00:00 +0100") + rand(-15..15).minutes,
  workflow_state: "nouveau",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
i91.update!(team_id: team_technique.id)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i91.id)
ToolIntervention.create!(tool_id: marteau.id, intervention_id: i91.id)
ToolIntervention.create!(tool_id: tournevis.id, intervention_id: i91.id)

# ---------- 18 novembre ----------
i92 = Intervention.create!(
  description: "Nettoyage salles mairie",
  début_prévue: Time.zone.parse("2025-11-18 09:00:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-18 12:30:00 +0100") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "nouveau",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
i92.update!(team_id: team_menage.id)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i92.id)

# # ---------- 19 novembre ----------
# i93 = Intervention.create!(
#   description: "Contrôle éclairage parc sud",
#   début_prévue: Time.zone.parse("2025-11-19 08:00:00 +0100") + rand(-15..15).minutes,
#   fin_prévue: Time.zone.parse("2025-11-19 10:00:00 +0100") + rand(-15..15).minutes,
#   workflow_state: "nouveau",
#   adherent_id: adhérent_attainville.id,
#   organisation_id: organisation.id,
#   slug: SecureRandom.uuid
# )
# i93.update!(team_id: team_electricite.id)
# AgentIntervention.create!(agent_id: agent_elec_marc.id, intervention_id: i93.id)
# ToolIntervention.create!(tool_id: testeur_lampe.id, intervention_id: i93.id)

# ---------- 20 novembre ----------
i94 = Intervention.create!(
  description: "Peinture clôture école maternelle",
  début_prévue: Time.zone.parse("2025-11-20 07:30:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-20 11:00:00 +0100") + rand(-15..15).minutes,
  temps_de_pause: 1.0,
  workflow_state: "nouveau",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
i94.update!(team_id: team_peinture.id)
AgentIntervention.create!(agent_id: agent_peinture_amelie.id, intervention_id: i94.id)
ToolIntervention.create!(tool_id: pinceau.id, intervention_id: i94.id)
ToolIntervention.create!(tool_id: peinture_blanc.id, intervention_id: i94.id)

# ---------- 21 novembre ----------
i95 = Intervention.create!(
  description: "Réparation robinet mairie",
  début_prévue: Time.zone.parse("2025-11-21 09:00:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-21 11:30:00 +0100") + rand(-15..15).minutes,
  workflow_state: "nouveau",
  adherent_id: adhérent_montmorency.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
i95.update!(team_id: team_technique.id)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i95.id)
ToolIntervention.create!(tool_id: tournevis.id, intervention_id: i95.id)

# ---------- 22 novembre ----------
i96 = Intervention.create!(
  description: "Nettoyage vitres mairie",
  début_prévue: Time.zone.parse("2025-11-22 08:30:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-22 12:00:00 +0100") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "nouveau",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
i96.update!(team_id: team_menage.id)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i96.id)
ToolIntervention.create!(tool_id: chiffon_microfibre.id, intervention_id: i96.id)

# ---------- 23 novembre ----------
i97 = Intervention.create!(
  description: "Vérification système chauffage école",
  début_prévue: Time.zone.parse("2025-11-23 07:30:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-23 10:30:00 +0100") + rand(-15..15).minutes,
  workflow_state: "nouveau",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
i97.update!(team_id: team_technique.id)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i97.id)
ToolIntervention.create!(tool_id: tournevis.id, intervention_id: i97.id)

# ---------- 24 novembre ----------
i98 = Intervention.create!(
  description: "Tonte pelouse parc nord",
  début_prévue: Time.zone.parse("2025-11-24 08:00:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-24 10:30:00 +0100") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "nouveau",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
i98.update!(team_id: team_espaces_verts.id)
AgentIntervention.create!(agent_id: agent_tech_andré.id, intervention_id: i98.id)
ToolIntervention.create!(tool_id: tondeuse_gazon.id, intervention_id: i98.id)

# ---------- 25 novembre ----------
i99 = Intervention.create!(
  description: "Peinture bancs parc sud",
  début_prévue: Time.zone.parse("2025-11-25 07:30:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-25 10:30:00 +0100") + rand(-15..15).minutes,
  temps_de_pause: 1.0,
  workflow_state: "nouveau",
  adherent_id: adhérent_bouffémont.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
i99.update!(team_id: team_peinture.id)
AgentIntervention.create!(agent_id: agent_peinture_amelie.id, intervention_id: i99.id)
ToolIntervention.create!(tool_id: pinceau.id, intervention_id: i99.id)
ToolIntervention.create!(tool_id: peinture_vert.id, intervention_id: i99.id)

# # ---------- 26 novembre ----------
# i100 = Intervention.create!(
#   description: "Contrôle éclairage parc central",
#   début_prévue: Time.zone.parse("2025-11-26 08:00:00 +0100") + rand(-15..15).minutes,
#   fin_prévue: Time.zone.parse("2025-11-26 10:00:00 +0100") + rand(-15..15).minutes,
#   workflow_state: "nouveau",
#   adherent_id: adhérent_attainville.id,
#   organisation_id: organisation.id,
#   slug: SecureRandom.uuid
# )
# i100.update!(team_id: team_electricite.id)
# AgentIntervention.create!(agent_id: agent_elec_marc.id, intervention_id: i100.id)
# ToolIntervention.create!(tool_id: testeur_lampe.id, intervention_id: i100.id)

# ---------- 27 novembre ----------
i101 = Intervention.create!(
  description: "Réparation serrure mairie",
  début_prévue: Time.zone.parse("2025-11-27 09:00:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-27 12:00:00 +0100") + rand(-15..15).minutes,
  workflow_state: "nouveau",
  adherent_id: adhérent_montmorency.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
i101.update!(team_id: team_technique.id)
AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i101.id)
ToolIntervention.create!(tool_id: tournevis.id, intervention_id: i101.id)

# ---------- 28 novembre ----------
i102 = Intervention.create!(
  description: "Nettoyage vitres école primaire",
  début_prévue: Time.zone.parse("2025-11-28 08:30:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-28 11:30:00 +0100") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "nouveau",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
i102.update!(team_id: team_menage.id)
AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i102.id)
ToolIntervention.create!(tool_id: chiffon_microfibre.id, intervention_id: i102.id)

# ---------- 29 novembre ----------
i103 = Intervention.create!(
  description: "Tonte pelouse parc central",
  début_prévue: Time.zone.parse("2025-11-29 07:30:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-29 10:30:00 +0100") + rand(-15..15).minutes,
  temps_de_pause: 0.5,
  workflow_state: "nouveau",
  adherent_id: adhérent_attainville.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
i103.update!(team_id: team_espaces_verts.id)
AgentIntervention.create!(agent_id: agent_tech_andré.id, intervention_id: i103.id)
ToolIntervention.create!(tool_id: tondeuse_gazon.id, intervention_id: i103.id)

# ---------- 30 novembre ----------
i104 = Intervention.create!(
  description: "Peinture barrières parc nord",
  début_prévue: Time.zone.parse("2025-11-30 08:00:00 +0100") + rand(-15..15).minutes,
  fin_prévue: Time.zone.parse("2025-11-30 11:00:00 +0100") + rand(-15..15).minutes,
  temps_de_pause: 1.0,
  workflow_state: "nouveau",
  adherent_id: adhérent_andilly.id,
  organisation_id: organisation.id,
  slug: SecureRandom.uuid
)
i104.update!(team_id: team_peinture.id)
AgentIntervention.create!(agent_id: agent_peinture_amelie.id, intervention_id: i104.id)
ToolIntervention.create!(tool_id: pinceau.id, intervention_id: i104.id)
ToolIntervention.create!(tool_id: peinture_rouge.id, intervention_id: i104.id)

# ---------- Notifications manager ↔ adhérent ----------
Notification.create!(message: "Bonjour, votre intervention 'Réparation robinet école primaire' est confirmée pour le 3 novembre.", from_id: manager_thierry.id, to_id: adhérent_attainville.id, created_at: i57.début_prévue - 2.days, updated_at: i57.début_prévue - 2.days)
Notification.create!(message: "Merci pour l'information, je serai présent.", from_id: adhérent_attainville.id, to_id: manager_thierry.id, created_at: i57.début_prévue - 1.day, updated_at: i57.début_prévue - 1.day)

Notification.create!(message: "Votre intervention 'Peinture bancs parc sud' est planifiée pour le 4 novembre.", from_id: manager_béatrice.id, to_id: adhérent_bouffémont.id, created_at: i58.début_prévue - 2.days, updated_at: i58.début_prévue - 2.days)
Notification.create!(message: "Parfait, merci pour la confirmation.", from_id: adhérent_bouffémont.id, to_id: manager_béatrice.id, created_at: i58.début_prévue - 1.day, updated_at: i58.début_prévue - 1.day)

Notification.create!(message: "Vérification des alarmes incendie prévue le 5 novembre.", from_id: manager_thierry.id, to_id: adhérent_montmorency.id, created_at: i59.début_prévue - 3.days, updated_at: i59.début_prévue - 3.days)
Notification.create!(message: "C'est noté, merci.", from_id: adhérent_montmorency.id, to_id: manager_thierry.id, created_at: i59.début_prévue - 1.day, updated_at: i59.début_prévue - 1.day)

# ---------- Notifications adhérent ↔ agent ----------
Notification.create!(message: "Pouvez-vous vérifier le robinet de l'école primaire le 3 novembre ?", from_id: adhérent_attainville.id, to_id: agent_tech_jean.id, created_at: i57.début_prévue - 1.day, updated_at: i57.début_prévue - 1.day)
Notification.create!(message: "Oui, je serai sur place à 9h.", from_id: agent_tech_jean.id, to_id: adhérent_attainville.id, created_at: i57.fin_prévue + 10.minutes, updated_at: i57.fin_prévue + 10.minutes)

Notification.create!(message: "Merci de peindre les bancs du parc sud le 4 novembre.", from_id: adhérent_bouffémont.id, to_id: agent_peinture_amelie.id, created_at: i58.début_prévue - 2.hours, updated_at: i58.début_prévue - 2.hours)
Notification.create!(message: "Bien reçu, je commencerai à 8h.", from_id: agent_peinture_amelie.id, to_id: adhérent_bouffémont.id, created_at: i58.fin_prévue + 15.minutes, updated_at: i58.fin_prévue + 15.minutes)

Notification.create!(message: "Vérifiez les extincteurs le 5 novembre.", from_id: adhérent_montmorency.id, to_id: agent_securite_philippe.id, created_at: i59.début_prévue - 3.hours, updated_at: i59.début_prévue - 3.hours)
Notification.create!(message: "Je m'en occupe dès 9h.", from_id: agent_securite_philippe.id, to_id: adhérent_montmorency.id, created_at: i59.fin_prévue + 5.minutes, updated_at: i59.fin_prévue + 5.minutes)

# ---------- Notifications agent ↔ manager ----------
Notification.create!(message: "Intervention 'Réparation robinet école primaire' terminée.", from_id: agent_tech_jean.id, to_id: manager_thierry.id, created_at: i57.fin_prévue + 10.minutes, updated_at: i57.fin_prévue + 10.minutes)
Notification.create!(message: "Merci pour votre retour, intervention validée.", from_id: manager_thierry.id, to_id: agent_tech_jean.id, created_at: i57.fin_prévue + 30.minutes, updated_at: i57.fin_prévue + 30.minutes)

Notification.create!(message: "Intervention peinture parc sud terminée, temps de pause respecté.", from_id: agent_peinture_amelie.id, to_id: manager_béatrice.id, created_at: i58.fin_prévue + 15.minutes, updated_at: i58.fin_prévue + 15.minutes)
Notification.create!(message: "Parfait, je mets à jour le suivi.", from_id: manager_béatrice.id, to_id: agent_peinture_amelie.id, created_at: i58.fin_prévue + 45.minutes, updated_at: i58.fin_prévue + 45.minutes)

Notification.create!(message: "Vérification extincteurs effectuée, tout est en règle.", from_id: agent_securite_philippe.id, to_id: manager_thierry.id, created_at: i59.fin_prévue + 5.minutes, updated_at: i59.fin_prévue + 5.minutes)
Notification.create!(message: "Merci pour votre réactivité.", from_id: manager_thierry.id, to_id: agent_securite_philippe.id, created_at: i59.fin_prévue + 25.minutes, updated_at: i59.fin_prévue + 25.minutes)


# i1 = Intervention.create(description: "Tonte parc communal - parc République", début: "2025-09-03 08:30:00 +0200", fin: "2025-09-03 11:00:00 +0200", temps_de_pause: 0.5, workflow_state: "validé", adherent_id: adhérent_attainville.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# # outils: [tondeuse_gazon, camionnette_benne]
# AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i1.id)
# AgentIntervention.create!(agent_id: team_espaces_verts.id, intervention_id: i1.id)

# i2 = Intervention.create(description: "Remplacement ampoules salle des fêtes", début: "2025-09-04 09:00:00 +0200", fin: "2025-09-04 10:30:00 +0200", temps_de_pause: 0.0, workflow_state: "terminé", adherent_id: adhérent_andilly.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# # outils: [echelle_4m, camionnette_benne]
# AgentIntervention.create!(agent_id: agent_tech_marie.id, intervention_id: i2.id)

# i3 = Intervention.create(description: "Nettoyage ponctuel - mairie", début: "2025-09-05 07:30:00 +0200", fin: "2025-09-05 09:00:00 +0200", temps_de_pause: 0.5, workflow_state: "terminé", adherent_id: adhérent_bouffémont.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# # outils: [aspirateur_industriel]
# AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i3.id)

# i4 = Intervention.create(description: "Installation rétroprojecteur école élémentaire", début: "2025-09-08 13:30:00 +0200", fin: "2025-09-08 15:00:00 +0200", temps_de_pause: 0.0, workflow_state: "validé", adherent_id: adhérent_montmorency.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# # outils: [projecteur, ordinateur_portable]
# AgentIntervention.create!(agent_id: agent_info_clara.id, intervention_id: i4.id)

# i5 = Intervention.create(description: "Réunion de coordination périscolaire", début: "2025-09-10 18:00:00 +0200", fin: "2025-09-10 19:30:00 +0200", workflow_state: "nouveau", adherent_id: adhérent_andilly.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_periscolaire_pierre.id, intervention_id: i5.id)
# AgentIntervention.create!(agent_id: agent_secretaire_véronique.id, intervention_id: i5.id)

# i6 = Intervention.create(description: "Contrôle comptable quai marchés - vérif. factures", début: "2025-09-12 09:00:00 +0200", fin: "2025-09-12 12:30:00 +0200", temps_de_pause: 1.0, workflow_state: "terminé", adherent_id: adhérent_attainville.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_compta_sophie.id, intervention_id: i6.id)

# i7 = Intervention.create(description: "Taille des haies - rue des écoles", début: "2025-09-15 08:00:00 +0200", fin: "2025-09-15 12:00:00 +0200", temps_de_pause: 0.5, workflow_state: "terminé", adherent_id: adhérent_bouffémont.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# # outils: [taille_haies, camionnette_benne]
# AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i7.id)
# AgentIntervention.create!(agent_id: team_espaces_verts.id, intervention_id: i7.id)

# i8 = Intervention.create(description: "Formation sécurité informatique - mairie", début: "2025-09-18 09:30:00 +0200", fin: "2025-09-18 11:30:00 +0200", workflow_state: "validé", adherent_id: adhérent_montmorency.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_info_clara.id, intervention_id: i8.id)

# i9 = Intervention.create(description: "Ramassage feuilles - square des Tilleuls", début: "2025-09-20 08:00:00 +0200", fin: "2025-09-20 11:00:00 +0200", temps_de_pause: 0.5, workflow_state: "terminé", adherent_id: adhérent_andilly.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# # outils: [balayeuse, camionnette_benne]
# AgentIntervention.create!(agent_id: agent_tech_marie.id, intervention_id: i9.id)

# i10 = Intervention.create(description: "Maintenance chaudière mairie", début: "2025-09-25 14:00:00 +0200", fin: "2025-09-25 16:00:00 +0200", workflow_state: "validé", adherent_id: adhérent_attainville.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_tech_marie.id, intervention_id: i10.id)

# i11 = Intervention.create(description: "Intervention réseau : route colmatage nid-de-poule", début: "2025-09-29 07:30:00 +0200", fin: "2025-09-29 12:00:00 +0200", temps_de_pause: 1.0, workflow_state: "terminé", adherent_id: adhérent_bouffémont.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# # outils: [camionnette_benne, groupe_electrogene]
# AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i11.id)
# AgentIntervention.create!(agent_id: team_entretien_batiment.id, intervention_id: i11.id)

# i12 = Intervention.create(description: "Campagne d'affichage - communication local", début: "2025-10-01 09:00:00 +0200", fin: "2025-10-01 12:00:00 +0200", workflow_state: "validé", adherent_id: adhérent_andilly.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_secretaire_véronique.id, intervention_id: i12.id)

# i13 = Intervention.create(description: "Inspection sécurité école maternelle", début: "2025-10-03 10:00:00 +0200", fin: "2025-10-03 11:30:00 +0200", workflow_state: "pointage activé", adherent_id: adhérent_montmorency.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_periscolaire_pierre.id, intervention_id: i13.id)

# i14 = Intervention.create(description: "Désherbage chemin piéton - lotissement sud", début: "2025-10-06 08:00:00 +0200", fin: "2025-10-06 10:30:00 +0200", temps_de_pause: 0.5, workflow_state: "terminé", adherent_id: adhérent_attainville.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# # outils: [tondeuse_gazon]
# AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i14.id)

# i15 = Intervention.create(description: "Mise à jour parc informatique - mairie", début: "2025-10-09 09:00:00 +0200", fin: "2025-10-09 12:00:00 +0200", workflow_state: "validé", adherent_id: adhérent_andilly.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# # outils: [ordinateur_portable]
# AgentIntervention.create!(agent_id: agent_info_clara.id, intervention_id: i15.id)

# i16 = Intervention.create(description: "Ramassage encombrants - zone industrielle", début: "2025-10-13 07:30:00 +0200", fin: "2025-10-13 11:30:00 +0200", temps_de_pause: 1.0, workflow_state: "terminé", adherent_id: adhérent_bouffémont.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# # outils: [camionnette_benne]
# AgentIntervention.create!(agent_id: team_entretien_batiment.id, intervention_id: i16.id)

# i17 = Intervention.create(description: "Réparation portail gymnase", début: "2025-10-17 13:00:00 +0200", fin: "2025-10-17 16:00:00 +0200", workflow_state: "validé", adherent_id: adhérent_montmorency.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_tech_marie.id, intervention_id: i17.id)

# i18 = Intervention.create(description: "Contrôle factures suivi marché public", début: "2025-10-20 09:30:00 +0200", fin: "2025-10-20 12:30:00 +0200", temps_de_pause: 0.5, workflow_state: "terminé", adherent_id: adhérent_andilly.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_compta_sophie.id, intervention_id: i18.id)

# i19 = Intervention.create(description: "Aide logistique foire annuelle", début: "2025-10-24 07:00:00 +0200", fin: "2025-10-24 18:00:00 +0200", temps_de_pause: 1.0, workflow_state: "validé", adherent_id: adhérent_attainville.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# # outils: [camionnette_benne, projecteur]
# AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i19.id)
# AgentIntervention.create!(agent_id: agent_secretaire_véronique.id, intervention_id: i19.id)

# i20 = Intervention.create(description: "Tonte zones sportives - stade municipal", début: "2025-10-28 08:00:00 +0100", fin: "2025-10-28 11:30:00 +0100", temps_de_pause: 0.5, workflow_state: "terminé", adherent_id: adhérent_bouffémont.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# # Note: changement d'heure fin octobre → heure locale +0100
# # outils: [tondeuse_gazon, camionnette_benne]
# AgentIntervention.create!(agent_id: agent_tech_marie.id, intervention_id: i20.id)
# AgentIntervention.create!(agent_id: team_espaces_verts.id, intervention_id: i20.id)

# i21 = Intervention.create(description: "Mise à jour base contacts périscolaire", début: "2025-11-03 14:00:00 +0100", fin: "2025-11-03 16:00:00 +0100", workflow_state: "validé", adherent_id: adhérent_attainville.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_periscolaire_pierre.id, intervention_id: i21.id)

# i22 = Intervention.create(description: "Réparations menues - bibliothèque", début: "2025-11-06 09:00:00 +0100", fin: "2025-11-06 11:00:00 +0100", temps_de_pause: 0.5, workflow_state: "terminé", adherent_id: adhérent_andilly.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i22.id)

# i23 = Intervention.create(description: "Migration logiciel compta - test", début: "2025-11-09 10:00:00 +0100", fin: "2025-11-09 17:00:00 +0100", workflow_state: "pointage activé", adherent_id: adhérent_montmorency.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_compta_sophie.id, intervention_id: i23.id)
# AgentIntervention.create!(agent_id: agent_info_clara.id, intervention_id: i23.id)

# i24 = Intervention.create(description: "Nettoyage ponctuel école primaire - après kermesse", début: "2025-11-12 07:30:00 +0100", fin: "2025-11-12 10:00:00 +0100", temps_de_pause: 0.5, workflow_state: "terminé", adherent_id: adhérent_bouffémont.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# # outils: [aspirateur_industriel]
# AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i24.id)

# i25 = Intervention.create(description: "Révision matériel espace vert", début: "2025-11-15 09:00:00 +0100", fin: "2025-11-15 12:00:00 +0100", workflow_state: "nouveau", adherent_id: adhérent_andilly.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# # outils: [tondeuse_gazon, taille_haies]
# AgentIntervention.create!(agent_id: agent_tech_marie.id, intervention_id: i25.id)

# i26 = Intervention.create(description: "Installation panneaux info citoyens", début: "2025-11-18 08:30:00 +0100", fin: "2025-11-18 11:30:00 +0100", workflow_state: "nouveau", adherent_id: adhérent_attainville.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_secretaire_véronique.id, intervention_id: i26.id)
# AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i26.id)

# i27 = Intervention.create(description: "Collecte archives - tri compta", début: "2025-11-21 09:00:00 +0100", fin: "2025-11-21 13:00:00 +0100", workflow_state: "pointage activé", adherent_id: adhérent_montmorency.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_compta_sophie.id, intervention_id: i27.id)

# i28 = Intervention.create(description: "Préparation salle polyvalente - réception", début: "2025-11-24 14:00:00 +0100", fin: "2025-11-24 18:00:00 +0100", temps_de_pause: 1.0, workflow_state: "validé", adherent_id: adhérent_bouffémont.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# # outils: [projecteur, camionnette_benne]
# AgentIntervention.create!(agent_id: agent_secretaire_véronique.id, intervention_id: i28.id)
# AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i28.id)

# i29 = Intervention.create(description: "Intervention urgente - dégagement arbre tombé", début: "2025-11-26 07:00:00 +0100", fin: "2025-11-26 12:00:00 +0100", temps_de_pause: 0.5, workflow_state: "terminé", adherent_id: adhérent_attainville.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# # outils: [moto_scie, camionnette_benne]
# AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i29.id)
# AgentIntervention.create!(agent_id: agent_tech_marie.id, intervention_id: i29.id)

# i30 = Intervention.create(description: "Nettoyage marché hebdomadaire - samedi", début: "2025-11-29 06:00:00 +0100", fin: "2025-11-29 09:30:00 +0100", workflow_state: "archivé", adherent_id: adhérent_andilly.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# # outils: [balayeuse]
# AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i30.id)

# i31 = Intervention.create(description: "Réunion de préparation budget communal", début: "2025-12-02 18:00:00 +0100", fin: "2025-12-02 20:00:00 +0100", workflow_state: "nouveau", adherent_id: adhérent_montmorency.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_compta_sophie.id, intervention_id: i31.id)
# AgentIntervention.create!(agent_id: agent_secretaire_véronique.id, intervention_id: i31.id)

# i32 = Intervention.create(description: "Décoration marchés de Noël - installation", début: "2025-12-05 08:30:00 +0100", fin: "2025-12-05 13:30:00 +0100", workflow_state: "nouveau", adherent_id: adhérent_attainville.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# # outils: [camionnette_benne, projecteur]
# AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i32.id)

# i33 = Intervention.create(description: "Maintenance éclairage public - quartier nord", début: "2025-12-08 09:00:00 +0100", fin: "2025-12-08 12:30:00 +0100", workflow_state: "nouveau", adherent_id: adhérent_bouffémont.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_tech_marie.id, intervention_id: i33.id)

# i34 = Intervention.create(description: "Aide logistique centre vaccination", début: "2025-12-10 07:00:00 +0100", fin: "2025-12-10 18:00:00 +0100", temps_de_pause: 1.0, workflow_state: "validé", adherent_id: adhérent_andilly.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_secretaire_véronique.id, intervention_id: i34.id)
# AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i34.id)

# i35 = Intervention.create(description: "Intervention informatique : remise à plat messagerie", début: "2025-12-12 09:00:00 +0100", fin: "2025-12-12 12:00:00 +0100", workflow_state: "pointage activé", adherent_id: adhérent_montmorency.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_info_clara.id, intervention_id: i35.id)

# i36 = Intervention.create(description: "Réparations voirie mineures - signalétique", début: "2025-12-15 08:00:00 +0100", fin: "2025-12-15 11:30:00 +0100", workflow_state: "nouveau", adherent_id: adhérent_attainville.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i36.id)

# i37 = Intervention.create(description: "Nettoyage salles municipales - fin d'année", début: "2025-12-18 07:30:00 +0100", fin: "2025-12-18 10:30:00 +0100", workflow_state: "nouveau", adherent_id: adhérent_andilly.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i37.id)

# i38 = Intervention.create(description: "Livraison sapins officiels - place centrale", début: "2025-12-20 06:30:00 +0100", fin: "2025-12-20 09:00:00 +0100", workflow_state: "nouveau", adherent_id: adhérent_bouffémont.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# # outils: [camionnette_benne]
# AgentIntervention.create!(agent_id: agent_tech_marie.id, intervention_id: i38.id)

# i39 = Intervention.create(description: "Événement : accueil jeunes - atelier numérique", début: "2025-12-22 14:00:00 +0100", fin: "2025-12-22 16:30:00 +0100", workflow_state: "nouveau", adherent_id: adhérent_montmorency.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_info_clara.id, intervention_id: i39.id)
# AgentIntervention.create!(agent_id: agent_periscolaire_pierre.id, intervention_id: i39.id)

# i40 = Intervention.create(description: "Intervention déneigement préventif (simulation)", début: "2026-01-05 06:30:00 +0100", fin: "2026-01-05 10:00:00 +0100", workflow_state: "nouveau", adherent_id: adhérent_attainville.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# # outils: [camionnette_benne, groupe_electrogene]
# AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i40.id)
# AgentIntervention.create!(agent_id: team_espaces_verts.id, intervention_id: i40.id)

# i41 = Intervention.create(description: "Révision installations sportives - inventaire", début: "2026-01-08 09:00:00 +0100", fin: "2026-01-08 12:00:00 +0100", workflow_state: "nouveau", adherent_id: adhérent_andilly.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: team_entretien_batiment.id, intervention_id: i41.id)

# i42 = Intervention.create(description: "Contrôle périodique extincteurs bâtiments publics", début: "2026-01-12 08:30:00 +0100", fin: "2026-01-12 12:00:00 +0100", workflow_state: "nouveau", adherent_id: adhérent_bouffémont.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_tech_marie.id, intervention_id: i42.id)

# i43 = Intervention.create(description: "Atelier périscolaire - sport en salle", début: "2026-01-15 16:00:00 +0100", fin: "2026-01-15 18:00:00 +0100", workflow_state: "nouveau", adherent_id: adhérent_montmorency.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_periscolaire_pierre.id, intervention_id: i43.id)

# i44 = Intervention.create(description: "Audit éclairage LED - ville", début: "2026-01-18 09:00:00 +0100", fin: "2026-01-18 17:00:00 +0100", workflow_state: "nouveau", adherent_id: adhérent_attainville.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i44.id)
# AgentIntervention.create!(agent_id: agent_info_clara.id, intervention_id: i44.id)

# i45 = Intervention.create(description: "Nettoyage ponctuel après manifestation", début: "2026-01-21 06:00:00 +0100", fin: "2026-01-21 09:30:00 +0100", workflow_state: "nouveau", adherent_id: adhérent_andilly.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# # outils: [balayeuse, camionnette_benne]
# AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i45.id)

# i46 = Intervention.create(description: "Contrôle consommables informatiques", début: "2026-01-24 10:00:00 +0100", fin: "2026-01-24 12:00:00 +0100", workflow_state: "nouveau", adherent_id: adhérent_bouffémont.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_info_clara.id, intervention_id: i46.id)

# i47 = Intervention.create(description: "Préparation archives 2025 - transfert", début: "2026-01-27 09:00:00 +0100", fin: "2026-01-27 13:00:00 +0100", workflow_state: "nouveau", adherent_id: adhérent_montmorency.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_compta_sophie.id, intervention_id: i47.id)

# i48 = Intervention.create(description: "Contrôle hygiène cuisine scolaire", début: "2025-10-02 08:00:00 +0200", fin: "2025-10-02 10:00:00 +0200", temps_de_pause: 0.5, workflow_state: "terminé", adherent_id: adhérent_andilly.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_secretaire_véronique.id, intervention_id: i48.id)

# i49 = Intervention.create(description: "Ménage hebdomadaire mairie (répétitif)", repeter: true, workflow_state: "nouveau", adherent_id: adhérent_andilly.id, organisation_id: organisation.id, slug: SecureRandom.uuid, created_at: "2025-09-01 08:00:00.000000000 +0200")
# AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i49.id)
# # -> Exemple d'utilisation pour générer les interventions filles (comme tu l'avais montré) :
# # (i49.created_at.to_date..Date.today).each do |date|
# #   next if date.saturday? || date.sunday?
# #   hour = 8
# #   minute = rand(0..30)
# #   debut = Time.zone.local(date.year, date.month, date.day, hour, minute, rand(0..59))
# #   duree = 60.minutes
# #   fin = debut + duree
# #   intervention_fille = Intervention.create(description: i49.description, workflow_state: "validé", adherent_id: i49.adherent_id, template_slug: i49.slug, début: debut, fin: fin, organisation_id: i49.organisation_id, slug: SecureRandom.uuid)
# #   i49.agent_interventions.each do |agent_intervention|
# #     intervention_fille.agent_interventions.create(agent: agent_intervention.agent)
# #   end
# # end

# # Quelques interventions additionnelles pour atteindre ~50 (variations & réutilisation d'agents)

# i50 = Intervention.create(description: "Nettoyage d'urgence - déversement huile route", début: "2025-09-21 07:30:00 +0200", fin: "2025-09-21 10:00:00 +0200", temps_de_pause: 0.5, workflow_state: "terminé", adherent_id: adhérent_attainville.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# # outils: [camionnette_benne, groupe_electrogene]
# AgentIntervention.create!(agent_id: agent_tech_jean.id, intervention_id: i50.id)

# i51 = Intervention.create(description: "Contrôle périodique éclairage salle omnisports", début: "2025-11-30 09:00:00 +0100", fin: "2025-11-30 12:00:00 +0100", workflow_state: "validé", adherent_id: adhérent_bouffémont.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_tech_marie.id, intervention_id: i51.id)

# i52 = Intervention.create(description: "Atelier parentalité - logistique et installation", début: "2025-10-17 14:00:00 +0200", fin: "2025-10-17 17:00:00 +0200", workflow_state: "terminé", adherent_id: adhérent_andilly.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_secretaire_véronique.id, intervention_id: i52.id)
# AgentIntervention.create!(agent_id: agent_periscolaire_pierre.id, intervention_id: i52.id)

# i53 = Intervention.create(description: "Inspection toiture - école", début: "2025-09-30 09:00:00 +0200", fin: "2025-09-30 11:30:00 +0200", temps_de_pause: 0.5, workflow_state: "terminé", adherent_id: adhérent_montmorency.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# # outils: [echelle_4m]
# AgentIntervention.create!(agent_id: agent_tech_marie.id, intervention_id: i53.id)

# i54 = Intervention.create(description: "Inventaire matériel ménage", début: "2026-01-30 09:00:00 +0100", fin: "2026-01-30 12:00:00 +0100", workflow_state: "nouveau", adherent_id: adhérent_andilly.id, organisation_id: organisation.id, slug: SecureRandom.uuid)
# AgentIntervention.create!(agent_id: agent_menage_nicole.id, intervention_id: i54.id)



Intervention.where.not(début: nil).each do |intervention|
  intervention.tools.each do |tool|
    Mouvement.create(tool_id: tool.id, intervention_id: intervention.id, état: 3, date: intervention.début)
  end
end
# Créer les états IN
Intervention.where.not(fin: nil).each do |intervention|
  intervention.tools.each do |tool|
    Mouvement.create(tool_id: tool.id, intervention_id: intervention.id, état: 2, date: intervention.fin)
  end
end

# Check disponibilité agents / update champ temps_total
Intervention.all.each do |i|
  i.temps_total = i.calc_temps_total
  i.save
end

Intervention.where(workflow_state: ["terminé", "validé", "refusé", "archivé"]).each do |i|
  i.co2 = case i.adherent_id
  when adhérent_bouffémont.id
    3.15 + rand(-0.30..0.30).round(2)
  when adhérent_montmorency.id
    0.41 + rand(-0.30..0.30).round(2)
  when adhérent_attainville.id
    3.75 + rand(-0.30..0.30).round(2)
  when adhérent_andilly.id
    1.35 + rand(-0.30..0.30).round(2)
  end
  i.save
end

Intervention.where(workflow_state: ["validé", "refusé", "archivé"]).each do |i|
  i.note = case i.workflow_state
  when "validé", "archivé"
    rand(4..5)
  when "refusé"
    rand(1..3)
  end
  i.save
end

i1.update!(team_id: team_entretien_batiment.id)
i2.update!(team_id: team_eclairage.id)
i3.update!(team_id: team_menage.id)
i4.update!(team_id: team_informatique.id)
i6.update!(team_id: team_compta.id)
i7.update!(team_id: team_plomberie.id)
i8.update!(team_id: team_peinture.id)
i9.update!(team_id: team_entretien_batiment.id)
i10.update!(team_id: team_entretien_batiment.id)
i11.update!(team_id: team_metal.id)
i12.update!(team_id: team_peinture.id)
i13.update!(team_id: team_securite.id)
i14.update!(team_id: team_menage.id)
i15.update!(team_id: team_entretien_batiment.id)
i16.update!(team_id: team_entretien_batiment.id)
i17.update!(team_id: team_informatique.id)
i18.update!(team_id: team_menage.id)
i19.update!(team_id: team_entretien_batiment.id)
i20.update!(team_id: team_metal.id)
i26.update!(team_id: team_peinture.id) 
i27.update!(team_id: team_technique.id)      
i28.update!(team_id: team_menage.id)    
i29.update!(team_id: team_technique.id)      
i30.update!(team_id: team_peinture.id) 
i31.update!(team_id: team_securite.id)  
i32.update!(team_id: team_menage.id)    
i33.update!(team_id: team_technique.id)      
i34.update!(team_id: team_peinture.id) 
i35.update!(team_id: team_securite.id)  
i36.update!(team_id: team_espaces_verts.id) 
i37.update!(team_id: team_menage.id)    
i38.update!(team_id: team_technique.id)      
i39.update!(team_id: team_peinture.id) 
i40.update!(team_id: team_securite.id)  
i41.update!(team_id: team_espaces_verts.id) 
i42.update!(team_id: team_menage.id)    
i43.update!(team_id: team_technique.id)      
i44.update!(team_id: team_peinture.id) 
i45.update!(team_id: team_securite.id)  
i46.update!(team_id: team_menage.id)    
i47.update!(team_id: team_technique.id)      
i48.update!(team_id: team_peinture.id) 
i49.update!(team_id: team_securite.id)  
i50.update!(team_id: team_espaces_verts.id)
i51.update!(team_id: team_menage.id)
i52.update!(team_id: team_technique.id)
i53.update!(team_id: team_peinture.id)
i54.update!(team_id: team_securite.id)
i55.update!(team_id: team_espaces_verts.id)
i56.update!(team_id: team_menage.id)
i57.update!(team_id: team_plomberie.id)
i58.update!(team_id: team_peinture.id)
i59.update!(team_id: team_securite.id)
i60.update!(team_id: team_menage.id)
i61.update!(team_id: team_technique.id)
i62.update!(team_id: team_peinture.id)
i63.update!(team_id: team_securite.id)
i64.update!(team_id: team_menage.id)
i65.update!(team_id: team_menage.id)
i66.update!(team_id: team_eclairage.id)
i67.update!(team_id: team_peinture.id)
i68.update!(team_id: team_securite.id)
i69.update!(team_id: team_menage.id)
i70.update!(team_id: team_technique.id)
i71.update!(team_id: team_peinture.id)
i72.update!(team_id: team_menage.id)
i73.update!(team_id: team_securite.id)
i74.update!(team_id: team_peinture.id)
i75.update!(team_id: team_menage.id)
i76.update!(team_id: team_technique.id)
i77.update!(team_id: team_peinture.id)
i78.update!(team_id: team_menage.id)
i79.update!(team_id: team_securite.id)
i80.update!(team_id: team_peinture.id)
i81.update!(team_id: team_menage.id)
i82.update!(team_id: team_technique.id)
i83.update!(team_id: team_peinture.id)
i84.update!(team_id: team_menage.id)
i85.update!(team_id: team_securite.id)

# Interventions : météo, tags
# Images User
# Images Tools
# ENVOYER LISTE EMAILS 
# Document
# Wiki_page
# Intervention récurrente
# ? MailLog
# ? Audit
# ? modification d'interventions