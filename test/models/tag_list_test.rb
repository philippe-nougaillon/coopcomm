# frozen_string_literal: true

require 'test_helper'

# Comportement de `tag_list` (acts-as-taggable-on), partagé par Intervention et User.
# Aucun initializer ne configure la gem : ce fichier fige la configuration par défaut
# dont dépendent la saisie des mots clés, les filtres et l'historique d'audit.
class TagListTest < ActiveSupport::TestCase
  setup do
    @intervention = interventions(:tonte_locaux)
  end

  # === Normalisation à l'écriture ==========================================

  test 'une chaîne virgulée devient une liste' do
    @intervention.update!(tag_list: 'urgence, plomberie')

    assert_equal %w[urgence plomberie], @intervention.reload.tag_list
  end

  test 'les espaces autour des mots clés sont rognés' do
    @intervention.update!(tag_list: '  urgence  ,   plomberie ')

    assert_equal %w[urgence plomberie], @intervention.reload.tag_list
  end

  test 'les doublons sont fusionnés sans tenir compte de la casse' do
    @intervention.update!(tag_list: 'doublon, Doublon, DOUBLON')

    assert_equal ['doublon'], @intervention.reload.tag_list
  end

  test 'les valeurs vides et nulles d un tableau sont ignorées' do
    @intervention.update!(tag_list: ['', 'urgence', nil])

    assert_equal ['urgence'], @intervention.reload.tag_list
  end

  test 'une chaîne vide retire tous les mots clés' do
    @intervention.update!(tag_list: 'urgence')

    @intervention.update!(tag_list: '')

    assert_empty @intervention.reload.tag_list
  end

  test 'nil retire tous les mots clés' do
    @intervention.update!(tag_list: 'urgence')

    @intervention.update!(tag_list: nil)

    assert_empty @intervention.reload.tag_list
  end

  test 'vider les mots clés détruit les lignes de liaison' do
    @intervention.update!(tag_list: 'urgence, plomberie')
    assert_equal 2, @intervention.taggings.count, 'garde : les liaisons doivent exister avant'

    @intervention.update!(tag_list: '')

    assert_equal 0, @intervention.reload.taggings.count
  end

  test 'un enregistrement neuf a une liste vide, jamais nil' do
    assert_equal [], Intervention.new.tag_list
    assert_equal [], User.new.tag_list
  end

  # ÉPINGLAGE : la virgule reste un séparateur À L'INTÉRIEUR d'un élément de tableau.
  # Le champ manager est `addable`, un mot clé libre contenant une virgule se coupe donc
  # en deux. À inverser si la saisie doit accepter les virgules littérales.
  test 'une virgule dans un élément de tableau scinde le mot clé en deux' do
    @intervention.update!(tag_list: ['espace vert, tonte'])

    assert_equal ['espace vert', 'tonte'], @intervention.reload.tag_list
  end

  # === Casse ===============================================================

  test 'un mot clé existant impose sa casse à la nouvelle saisie' do
    @intervention.update!(tag_list: 'urgence')
    autre = interventions(:nouvelle_intervention)

    autre.update!(tag_list: 'Urgence')

    assert_equal ['urgence'], autre.reload.tag_list
    assert_equal 1, ActsAsTaggableOn::Tag.where('name ILIKE ?', 'urgence').count
  end

  test 'un mot clé inédit conserve la casse saisie' do
    @intervention.update!(tag_list: 'Élagage')

    assert_equal ['Élagage'], @intervention.reload.tag_list
  end

  # === Unicode et bornes ===================================================

  test 'les accents sont conservés et retrouvés quelle que soit la casse' do
    @intervention.update!(tag_list: 'Élagage')

    assert_includes Intervention.tagged_with('élagage'), @intervention
  end

  # ÉPINGLAGE : au-delà de la longueur admise par la table `tags`, la sauvegarde est
  # refusée avec un message qui ne parle pas du mot clé trop long
  # (« Tag doit exister, Tag doit être rempli(e) »). À inverser si le message est corrigé.
  test 'un mot clé démesurément long est refusé' do
    @intervention.update!(tag_list: 'urgence')

    erreur = assert_raises(ActiveRecord::RecordInvalid) do
      @intervention.update!(tag_list: 'x' * 300)
    end

    assert_equal ['urgence'], @intervention.reload.tag_list
    assert_match(/Tag/, erreur.message)
  end

  # === Portée : la table des mots clés est commune ==========================

  test 'un même mot clé sert aux interventions et aux utilisateurs' do
    @intervention.update!(tag_list: 'partagé')
    users(:bond).update!(tag_list: 'partagé')

    assert_equal 1, ActsAsTaggableOn::Tag.where(name: 'partagé').count
  end

  # === Persistance à travers le workflow ====================================

  test 'les mots clés survivent à une transition de workflow' do
    intervention = interventions(:intervention_terminée)
    intervention.update!(tag_list: 'urgence, plomberie')

    intervention.valider!

    assert_equal %w[urgence plomberie], intervention.reload.tag_list
  end
end
