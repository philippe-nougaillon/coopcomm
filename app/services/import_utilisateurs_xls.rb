# frozen_string_literal: true

require 'spreadsheet'

# Import des agents depuis un classeur Excel 97-2003.
# Rien n'est écrit tant que `appliquer` est faux (mode simulation du formulaire).
class ImportUtilisateursXls < ApplicationService
  # Une ligne du bilan. `numéro` est le numéro de ligne dans le classeur.
  Ligne = Struct.new(:numéro, :type, :nom, :email, :service, :changements, :messages, keyword_init: true)

  # `succès` et `erreurs` sont dans l'ordre du fichier.
  Rapport = Struct.new(:succès, :erreurs, :illisible, :structure_invalide, :appliqué, keyword_init: true) do
    def illisible? = illisible.present?
    def structure_invalide? = structure_invalide.present?
    def interrompu? = illisible? || structure_invalide?
    def message_interruption = illisible || structure_invalide
    def importés = succès.size
    def en_erreur = erreurs.size
    def total = importés + en_erreur
  end

  COLONNES_OBLIGATOIRES = %i[nom prénom email service].freeze

  ENTETES = {
    nom: %w[nom],
    prénom: %w[prénom prenom],
    email: %w[email],
    service: %w[service],
    téléphone: %w[téléphone telephone],
    memo: %w[mémo memo]
  }.freeze

  FICHIER_ILLISIBLE = 'Fichier illisible : le format attendu est Excel 97-2003 (.xls).'
  STRUCTURE_INVALIDE = 'Structure du fichier invalide. Les colonnes obligatoires ' \
                       '(Nom, Prénom, Email, Service) sont introuvables.'

  def initialize(fichier:, importateur:, organisation:, appliquer: false)
    @fichier = fichier
    @importateur = importateur
    @organisation = organisation
    @appliquer = appliquer
    @succès = []
    @erreurs = []
  end

  def call
    feuille = ouvrir_feuille
    return rapport(illisible: FICHIER_ILLISIBLE) if feuille.nil?
    return rapport(structure_invalide: STRUCTURE_INVALIDE) unless mapper_colonnes(feuille)

    feuille.each(1) { |ligne| traiter_ligne(ligne) }

    rapport
  end

  private

  attr_reader :importateur, :organisation, :colonnes

  def appliquer? = @appliquer

  def rapport(illisible: nil, structure_invalide: nil)
    Rapport.new(succès: @succès, erreurs: @erreurs, illisible: illisible,
                structure_invalide: structure_invalide, appliqué: appliquer?)
  end

  # Un fichier qui n'est pas un XLS 97-2003 est un cas nominal, pas une panne.
  def ouvrir_feuille
    Spreadsheet.client_encoding = 'UTF-8'
    Spreadsheet.open(chemin).worksheet(0)
  rescue StandardError
    nil
  end

  def chemin
    @fichier.respond_to?(:tempfile) ? @fichier.tempfile.path : @fichier.to_s
  end

  def mapper_colonnes(feuille)
    entêtes = Array(feuille.row(0)).map { |cellule| cellule.to_s.strip.downcase }

    @colonnes = ENTETES.transform_values do |préfixes|
      entêtes.index { |entête| préfixes.any? { |préfixe| entête.start_with?(préfixe) } }
    end

    COLONNES_OBLIGATOIRES.none? { |clé| colonnes[clé].nil? }
  end

  def cellule(ligne, clé)
    index = colonnes[clé]
    return nil if index.nil?

    ligne[index]&.to_s&.strip
  end

  def traiter_ligne(ligne)
    numéro = ligne.idx + 1
    return if ENTETES.keys.all? { |clé| cellule(ligne, clé).blank? }

    identité = { nom: [cellule(ligne, :nom), cellule(ligne, :prénom)].compact_blank.join(' '),
                 email: cellule(ligne, :email)&.downcase,
                 service: cellule(ligne, :service) }

    return erreur(numéro, **identité, messages: ['Nom manquant']) if cellule(ligne, :nom).blank?
    return erreur(numéro, **identité, messages: ['Email manquant']) if identité[:email].blank?

    utilisateur, refus = chercher_utilisateur(identité[:email])
    return erreur(numéro, **identité, messages: [refus]) if refus

    enregistrer(utilisateur, ligne, numéro, identité)
  end

  # Rend [utilisateur, motif_de_refus] ; hors `default_scope :kept`, sans quoi un
  # compte désactivé échouerait sur l'unicité de l'email au lieu d'être nommé.
  def chercher_utilisateur(email)
    existant = User.unscoped.where('lower(email) = ?', email).first

    return [nouvel_utilisateur(email), nil] if existant.nil?
    return [nil, 'ce compte est désactivé : réactivez-le depuis la liste des utilisateurs désactivés'] if
      existant.discarded?
    return [nil, 'cet email appartient à un compte d’une autre organisation'] if existant.organisation != organisation
    return [nil, "ce compte est un #{existant.rôle} : modifiez-le depuis sa fiche"] unless existant.agent?

    [existant, nil]
  end

  def nouvel_utilisateur(email)
    User.new(email: email, rôle: 'agent', password: User.generate_random_password)
  end

  def renseigner(utilisateur, ligne)
    utilisateur.nom = cellule(ligne, :nom)
    utilisateur.prénom = cellule(ligne, :prénom)
    utilisateur.email = cellule(ligne, :email)&.downcase

    # Colonne absente : on ne touche à rien. Colonne présente et vide : effacement.
    utilisateur.téléphone = cellule(ligne, :téléphone) if colonnes[:téléphone]
    utilisateur.memo = cellule(ligne, :memo) if colonnes[:memo]

    rattacher_service(utilisateur, cellule(ligne, :service))
  end

  # Le service du fichier remplace celui de l'agent. Rend le motif d'erreur, que
  # l'appelant pose après `valid?` — qui vide les erreurs.
  def rattacher_service(utilisateur, nom_service)
    service = trouver_service(nom_service)
    return "introuvable dans votre organisation (Valeur lue: '#{nom_service.presence || 'VIDE'}')" if service.nil?

    déjà_rattaché = utilisateur.user_services.any? do |rattachement|
      rattachement.service_id == service.id && !rattachement.marked_for_destruction?
    end

    utilisateur.user_services.each do |rattachement|
      rattachement.mark_for_destruction if rattachement.service_id != service.id
    end
    utilisateur.user_services.build(service: service) unless déjà_rattaché

    nil
  end

  def trouver_service(nom_service)
    return nil if nom_service.blank? || organisation.nil?

    organisation.services.find_by(nom: Service.normalize_value_for(:nom, nom_service))
  end

  def enregistrer(utilisateur, ligne, numéro, identité)
    nouveau = utilisateur.new_record?
    motif_service = renseigner(utilisateur, ligne)
    changements = résumer_changements(utilisateur)

    utilisateur.valid?
    if motif_service
      # Sans service retenu, `must_have_at_least_one_service` a déjà protesté :
      # son message générique doublerait le motif réel.
      utilisateur.errors.delete(:services)
      utilisateur.errors.add(:services, motif_service)
    end

    return erreur(numéro, **identité, messages: utilisateur.errors.full_messages) if utilisateur.errors.any?
    return succès(numéro, utilisateur, nouveau, changements) unless appliquer?

    if sauvegarder(utilisateur, nouveau)
      succès(numéro, utilisateur, nouveau, changements)
    else
      erreur(numéro, **identité, messages: utilisateur.errors.full_messages.presence || ['Enregistrement refusé'])
    end
  end

  # `mark_for_destruction` n'est pas honoré par `save` (l'association n'est pas
  # en autosave) : les rattachements retirés sont détruits explicitement, dans
  # la même transaction que l'enregistrement.
  def sauvegarder(utilisateur, nouveau)
    User.transaction do
      utilisateur.user_services.select { |r| r.marked_for_destruction? && r.persisted? }.each(&:destroy)
      raise ActiveRecord::Rollback unless utilisateur.save

      utilisateur.invite!(importateur) if nouveau
      true
    end.present?
  rescue ActiveRecord::ActiveRecordError => e
    utilisateur.errors.add(:base, e.message)
    false
  end

  def résumer_changements(utilisateur)
    changements = utilisateur.changes.except('encrypted_password', 'password', 'slug', 'invitation_token')
    changements = changements.transform_values(&:last) if utilisateur.new_record?

    avant = noms_de_services(utilisateur.user_services.select(&:persisted?))
    après = noms_de_services(utilisateur.user_services.reject(&:marked_for_destruction?))

    if utilisateur.new_record?
      changements['service'] = après
    elsif avant != après
      changements['service'] = [avant, après]
    end

    changements
  end

  def noms_de_services(rattachements)
    rattachements.filter_map { |rattachement| rattachement.service&.nom }.sort.join(', ').presence || 'Aucun'
  end

  def succès(numéro, utilisateur, nouveau, changements)
    @succès << Ligne.new(numéro: numéro,
                         type: nouveau ? 'Nouveau' : 'Mise à jour',
                         nom: "#{utilisateur.nom} #{utilisateur.prénom}".strip,
                         email: utilisateur.email,
                         service: noms_de_services(utilisateur.user_services.reject(&:marked_for_destruction?)),
                         changements: changements,
                         messages: [])
  end

  def erreur(numéro, nom:, email:, service:, messages:)
    @erreurs << Ligne.new(numéro: numéro, type: 'Erreur', nom: nom, email: email,
                          service: service, changements: {}, messages: messages)
  end
end
