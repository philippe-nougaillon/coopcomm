# frozen_string_literal: true

require 'test_helper'

class OrganisationTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionDispatch::TestProcess::FixtureFile

  setup do
    @organisation = organisations(:mairie_paris)
  end

  test 'un logo PNG est accepté' do
    @organisation.logo = fixture_file_upload('logo_organisation.png', 'image/png')

    assert_predicate @organisation, :valid?
  end

  test 'un logo JPEG est accepté' do
    @organisation.logo = fixture_file_upload('logo_organisation.jpg', 'image/jpeg')

    assert_predicate @organisation, :valid?
  end

  test 'un logo ajouté sans autre modification produit un audit qui le mentionne' do
    assert_difference -> { @organisation.audits.count }, 1 do
      @organisation.update!(logo: fixture_file_upload('logo_organisation.png', 'image/png'))
    end

    assert_match(/logo ajouté/i, @organisation.audits.last.comment)
  end

  test 'un logo que le serveur ne sait pas convertir est refusé' do
    @organisation.logo = { io: File.open(Rails.root.join('test/fixtures/files/exemple.png')),
                           filename: 'logo.webp', content_type: 'image/webp' }

    assert_not @organisation.valid?
    assert_includes @organisation.errors[:logo], 'illisible : enregistrez-le en PNG ou en JPEG'
  end

  test 'un logo WebP lisible est accepté' do
    @organisation.logo = fixture_file_upload('logo_organisation.webp', 'image/webp')

    assert_predicate @organisation, :valid?
  end

  test 'un logo est refusé quand libvips manque au serveur' do
    @organisation.logo = fixture_file_upload('logo_organisation.png', 'image/png')

    ActiveStorage.stub(:variant_transformer, nil) { assert_not @organisation.valid? }
    assert_includes @organisation.errors[:logo], 'illisible : enregistrez-le en PNG ou en JPEG'
  end

  test 'retirer le logo n’est pas soumis au contrôle de lecture' do
    @organisation.update!(logo: fixture_file_upload('logo_organisation.png', 'image/png'))
    @organisation.logo = nil

    assert_predicate @organisation, :valid?
  end

  # ==================== TESTS CRITIQUES ====================
  # Supprimer une organisation emporte ses services, racine du rattachement de ses
  # utilisateurs, et tout ce qui s'y accroche ; une autre organisation n'y perd rien.

  test 'la suppression d’une organisation emporte ses services et ses utilisateurs, désactivés compris (critique)' do
    administrateur = users(:administrateur_paris)
    désactivé = users(:agent_discarded_paris)

    @organisation.destroy!

    assert_empty Service.where(organisation_id: @organisation.id)
    assert_nil User.with_discarded.find_by(id: administrateur.id)
    assert_nil User.with_discarded.find_by(id: désactivé.id)
  end

  test 'la suppression d’une organisation emporte ses interventions, y compris une demande née sans service (critique)' do
    intervention = interventions(:tonte_locaux)
    demande_sans_service = interventions(:demande_par_mail)

    @organisation.destroy!

    assert_nil Intervention.find_by(id: intervention.id)
    assert_nil Intervention.find_by(id: demande_sans_service.id)
  end

  test 'la suppression d’une organisation emporte ses devis, commandes, factures, conventions et prestations (critique)' do
    cotation = cotations(:cotation_paris)
    commande = commandes(:commande_paris)
    facture = factures(:facture_paris)
    convention = conventions(:convention_paris)
    prestation = prestations(:nettoyage_bureaux)

    @organisation.destroy!

    assert_nil Cotation.find_by(id: cotation.id)
    assert_nil Commande.find_by(id: commande.id)
    assert_nil Facture.find_by(id: facture.id)
    assert_nil Convention.find_by(id: convention.id)
    assert_nil Prestation.find_by(id: prestation.id)
  end

  test 'la suppression d’une organisation laisse intacte une autre organisation (critique)' do
    audit_sans_acteur = Audited::Audit.create!(auditable: interventions(:nettoyage_port), action: 'update',
                                               audited_changes: { 'commentaires' => [nil, 'par un job'] })

    @organisation.destroy!

    assert Service.exists?(services(:service_marseille).id)
    assert User.exists?(users(:agent_marseille).id)
    assert Intervention.exists?(interventions(:nettoyage_port).id)
    assert Intervention.exists?(interventions(:demande_par_mail_marseille).id)
    assert Tool.exists?(tools(:camion).id)
    assert Cotation.exists?(cotations(:cotation_marseille).id)
    assert Audited::Audit.exists?(audit_sans_acteur.id)
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'la suppression d’une organisation emporte son matériel, ses mouvements et ses documents' do
    outil = tools(:tondeuse)
    mouvement = mouvements(:mouvement_tondeuse)
    document = documents(:carte_grise)

    @organisation.destroy!

    assert_nil Tool.find_by(id: outil.id)
    assert_nil Mouvement.find_by(id: mouvement.id)
    assert_nil Document.find_by(id: document.id)
  end

  test 'la suppression d’une organisation emporte ses sites, ses journaux de mails et ses journaux d’exports' do
    site = warehouses(:entrepot_paris)
    mail_log = mail_logs(:mail_log)
    export_log = export_logs(:one)

    @organisation.destroy!

    assert_nil Warehouse.find_by(id: site.id)
    assert_nil MailLog.find_by(id: mail_log.id)
    assert_nil ExportLog.find_by(id: export_log.id)
  end

  test 'la suppression d’une organisation purge les audits de ses utilisateurs, ceux de la suppression compris' do
    ids_utilisateurs = @organisation.users.with_discarded.ids

    Audited.audit_class.as_user(users(:administrateur_paris)) { @organisation.destroy! }

    assert_empty Audited::Audit.where(user_id: ids_utilisateurs)
  end

  test 'la suppression d’une organisation purge les audits sans acteur de ses enregistrements, ceux de la cascade compris' do
    intervention = interventions(:tonte_locaux)
    intervention.update!(commentaires: 'modifiée par un job')
    ids_services = @organisation.services.ids

    @organisation.destroy!

    assert_empty Audited::Audit.where(auditable_type: 'Intervention', auditable_id: intervention.id)
    assert_empty Audited::Audit.where(auditable_type: 'Service', auditable_id: ids_services)
  end

  test 'la suppression d’une organisation purge les audits laissés par ses utilisateurs sur un enregistrement supprimé avant elle' do
    intervention = interventions(:nouvelle_intervention)
    Audited.audit_class.as_user(users(:weil)) { intervention.destroy! }

    @organisation.destroy!

    assert_empty Audited::Audit.where(auditable_type: 'Intervention', auditable_id: intervention.id)
  end

  test 'la suppression d’une organisation rend au store d’audited le request_uuid qu’elle y avait posé' do
    @organisation.destroy!

    assert_nil Audited.store[:current_request_uuid]
  end

  test 'la suppression d’une organisation ne rafraîchit le tableau de bord qu’une seule fois' do
    base = Minitest::Mock.new
    ActualiserDashboard::VUES.each { |vue| base.expect(:refresh_materialized_view, nil, [vue], concurrently: true) }

    Scenic.stub(:database, base) { @organisation.destroy! }

    assert_mock base
  end

  test 'la suppression d’une organisation purge son logo' do
    @organisation.logo.attach(fixture_file_upload('logo_organisation.png', 'image/png'))
    blob = @organisation.logo.blob

    assert_enqueued_with(job: ActiveStorage::PurgeJob, args: [blob]) { @organisation.destroy! }
  end

  test 'les dimensions d’un logo sont connues dès son enregistrement' do
    @organisation.update!(logo: fixture_file_upload('logo_tres_large.png', 'image/png'))

    assert_equal [1220, 100], @organisation.reload.logo.metadata.values_at(:width, :height)
  end
end
