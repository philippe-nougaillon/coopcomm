require "test_helper"

class CotationTest < ActiveSupport::TestCase
  setup do
    @adherent = users(:weil)
    @service = services(:informatique)
  end

  def build_cotation(attrs = {})
    Cotation.new({ adherent: @adherent, service: @service, intitulé: "Devis" }.merge(attrs))
  end

  test "valide avec un intitulé" do
    assert build_cotation.valid?
  end

  test "invalide sans intitulé" do
    cotation = build_cotation(intitulé: nil)
    refute cotation.valid?
    assert cotation.errors[:intitulé].any?
  end

  # --- Workflow (gem workflow) ---

  test "état initial : créé" do
    assert_equal "créé", build_cotation.workflow_state
    assert build_cotation.créé?
  end

  test "envoyer : créé -> envoyé" do
    cotation = build_cotation
    cotation.save!
    assert cotation.can_envoyer?
    cotation.envoyer!
    assert cotation.envoyé?
  end

  test "depuis envoyé, on peut valider et refuser" do
    cotation = build_cotation
    cotation.save!
    cotation.envoyer!
    assert cotation.can_valider?
    assert cotation.can_refuser?
  end

  test "valider : envoyé -> validé" do
    cotation = build_cotation
    cotation.save!
    cotation.envoyer!
    cotation.valider!
    assert cotation.validé?
  end

  test "refuser : envoyé -> refusé" do
    cotation = build_cotation
    cotation.save!
    cotation.envoyer!
    cotation.refuser!
    assert cotation.refusé?
  end

  test "on ne peut pas valider directement depuis créé" do
    cotation = build_cotation
    cotation.save!
    refute cotation.can_valider?
  end

  # --- Référence / périmètre / discard ---

  test "ref générée à la création au format AAAA-N" do
    cotation = build_cotation
    cotation.save!
    assert_match(/\A#{Date.current.year}-\d+\z/, cotation.ref)
  end

  test "la ref n'est pas modifiée lors d'une mise à jour" do
    cotation = build_cotation
    cotation.save!
    ref = cotation.ref
    cotation.update!(intitulé: "Nouveau titre")
    assert_equal ref, cotation.ref
  end

  test "la ref est incrémentée au sein de l'organisation" do
    premiere = build_cotation
    premiere.save!
    seconde = build_cotation
    seconde.save!
    n1 = premiere.ref.split("-").last.to_i
    n2 = seconde.ref.split("-").last.to_i
    assert_equal n1 + 1, n2
  end

  test "organisation dérivée du service" do
    cotation = build_cotation
    cotation.save!
    assert_equal @service.organisation, cotation.organisation
  end

  test "visible_to un administrateur de la même organisation" do
    cotation = build_cotation
    cotation.save!
    assert_includes Cotation.visible_to(users(:administrateur_paris)), cotation
  end

  test "visible_to un manager possédant le service" do
    cotation = build_cotation
    cotation.save!
    # hidalgo gère le service informatique
    assert_includes Cotation.visible_to(users(:hidalgo)), cotation
  end

  test "non visible pour un manager d'une autre organisation" do
    cotation = build_cotation
    cotation.save!
    refute_includes Cotation.visible_to(users(:manager_marseille)), cotation
  end

  test "aucune cotation visible pour un adhérent" do
    build_cotation.save!
    assert_empty Cotation.visible_to(@adherent)
  end

  test "discard (soft delete)" do
    cotation = build_cotation
    cotation.save!
    cotation.discard
    assert cotation.discarded?
    refute_includes Cotation.kept, cotation
  end
end
