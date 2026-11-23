# frozen_string_literal: true

require 'test_helper'

class AibboOutilPersonnesTest < ActiveSupport::TestCase
  setup do
    @manager = users(:hidalgo)
  end

  # ==================== TESTS CRITIQUES ====================
  # Une personne n'est décrite que par ce que l'utilisateur lit déjà en suivant ses liens : sa fiche pour un manager
  # ou un administrateur, son nom dans la messagerie pour les autres ; rien de ce qui sert à se connecter n'est jamais rendu.
  test 'un manager ne reçoit que les comptes de ses services (critique)' do
    resultat = Aibbo::OutilPersonnes.new(users(:manager_marseille)).call

    assert_equal users(:adherent_marseille, :adherent_nom_long, :adherent_marseille_avec_adresse_et_memo, :agent_marseille, :manager_marseille,
                       :nettoyeur_marseille).map { |u| nom(u) }.sort,
                 resultat[:personnes].pluck(:nom).sort
  end

  test 'le nom d’une personne hors du périmètre n’est pas reconnu (critique)' do
    resultat = Aibbo::OutilPersonnes.new(users(:manager_marseille)).call(nom: 'bond')

    assert_match(/introuvable parmi les personnes/, resultat[:erreur])
    assert_nil resultat[:personnes]
  end

  test 'un agent ne reçoit des autres personnes de ses services que leur nom, comme dans la messagerie (critique)' do
    resultat = Aibbo::OutilPersonnes.new(users(:bond)).call
    autres = resultat[:personnes].reject { |personne| personne[:nom] == nom(users(:bond)) }

    assert_equal users(:administrateur_paris, :berthout, :hidalgo, :martin_technique_paris, :patrick_adherent_paris, :nettoyage, :électricité, :weil)
                   .map { |u| nom(u) }.sort, autres.pluck(:nom).sort
    assert_equal [[:nom]], autres.map(&:keys).uniq
    assert_not_includes resultat.to_json, users(:weil).téléphone
  end

  test 'un adhérent ne reçoit des autres personnes de ses services que leur nom (critique)' do
    resultat = Aibbo::OutilPersonnes.new(users(:weil)).call
    autres = resultat[:personnes].reject { |personne| personne[:nom] == nom(users(:weil)) }

    assert_includes autres.pluck(:nom), nom(users(:bond))
    assert_not_includes autres.pluck(:nom), nom(users(:manager_marseille))
    assert_equal [[:nom]], autres.map(&:keys).uniq
    assert_not_includes resultat.to_json, users(:bond).email
  end

  test 'un agent ne peut chercher les personnes ni par service ni par rôle, que la messagerie ne montre pas (critique)' do
    agent = Aibbo::OutilPersonnes.new(users(:bond))

    assert_match(/ni leur service, ni leur rôle/, agent.call(service: 'technique')[:erreur])
    assert_match(/ni leur service, ni leur rôle/, agent.call(role: 'agent')[:erreur])
  end

  test 'aucun résultat ne porte le haché d’un mot de passe (critique)' do
    haches = User.visible_to(@manager).pluck(:encrypted_password).compact_blank
    resultat = Aibbo::OutilPersonnes.new(@manager).call.to_json

    assert_not_empty haches
    haches.each { |hache| assert_not_includes resultat, hache }
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'un manager reçoit le mail et le téléphone d’un compte de ses services' do
    weil = Aibbo::OutilPersonnes.new(@manager).call(nom: 'weil')[:personnes].first

    assert_equal users(:weil).email, weil[:mail]
    assert_equal users(:weil).téléphone, weil[:téléphone]
  end

  test 'le filtre par rôle et par service ne garde que les personnes de ce rôle dans ce service' do
    resultat = Aibbo::OutilPersonnes.new(@manager).call(role: 'agent', service: 'technique')

    assert_equal users(:nettoyage, :électricité, :bond, :martin_technique_paris).map { |u| nom(u) }.sort, resultat[:personnes].pluck(:nom).sort
    assert_equal 4, resultat[:total]
  end

  test 'les effectifs par rôle comptent chaque rôle parmi les personnes retenues' do
    resultat = Aibbo::OutilPersonnes.new(@manager).call

    assert_equal User.visible_to(@manager).agent.count, resultat[:par_rôle]['agent']
    assert_equal User.visible_to(@manager).adhérent.count, resultat[:par_rôle]['adhérent']
  end

  test 'les effectifs par service comptent les membres de chaque service encadré' do
    resultat = Aibbo::OutilPersonnes.new(@manager).call

    assert_equal services(:technique).users.count, resultat[:par_service][services(:technique).nom]
    assert_not resultat[:par_service].key?(services(:secretariat).nom)
  end

  test 'un nom partiel rend toutes les personnes qui le portent' do
    resultat = Aibbo::OutilPersonnes.new(@manager).call(nom: 'team')

    assert_equal users(:nettoyage, :électricité).map { |u| nom(u) }.sort, resultat[:personnes].pluck(:nom).sort
  end

  test 'les services d’une personne sont tous ceux que sa fiche montre, même ceux que l’utilisateur n’encadre pas' do
    resultat = Aibbo::OutilPersonnes.new(@manager).call(nom: nom(users(:manager_paris)))

    assert_equal services(:secretariat, :service_paris).map(&:nom).sort, resultat[:personnes].first[:services]
  end

  test 'un manager reçoit l’adresse, le mémo et les étiquettes d’un adhérent, comme sur sa fiche' do
    commune = users(:adherent_marseille_avec_adresse_et_memo)
    commune.update!(tag_list: 'prioritaire')

    fiche = Aibbo::OutilPersonnes.new(users(:manager_marseille)).call(nom: commune.nom)[:personnes].first

    assert_equal commune.address, fiche[:adresse]
    assert_equal commune.memo, fiche[:mémo]
    assert_equal ['prioritaire'], fiche[:étiquettes]
  end

  test 'un manager reçoit l’évaluation d’un agent, comme sur sa fiche' do
    bond = users(:bond)

    fiche = Aibbo::OutilPersonnes.new(@manager).call(nom: 'james bond')[:personnes].first

    assert bond.rated_interventions.any?
    assert_equal({ moyenne: bond.moyenne.round(2), notes: bond.total_rating }, fiche[:évaluation])
  end

  test 'un agent reçoit sa propre fiche : mail et services, sans mémo ni évaluation' do
    fiche = Aibbo::OutilPersonnes.new(users(:bond)).call(nom: 'james bond')[:personnes].first

    assert_equal users(:bond).email, fiche[:mail]
    assert_equal [services(:technique).nom], fiche[:services]
    assert_nil fiche[:évaluation]
  end

  private

  def nom(utilisateur)
    utilisateur.nom_prénom.strip
  end
end
