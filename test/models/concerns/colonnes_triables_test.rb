# frozen_string_literal: true

require 'test_helper'

# Les expressions SQL des colonnes calculées reflètent une méthode Ruby du même
# modèle : ce test échoue si l'une change sans l'autre.
class ColonnesTriablesTest < ActiveSupport::TestCase
  setup do
    @service = services(:technique)
  end

  test 'clé de tri « évaluation » : lecture → la moyenne calculée par le modèle' do
    assert_equal User.all.to_h { |user| [user.id, user.moyenne&.round(4)] },
                 clés_sql(User, 'users.moyenne') { |valeur| valeur&.to_f&.round(4) }
  end

  test 'clé de tri « absent » : lecture → ce que répond le modèle' do
    users(:bond).absences.create!(du: Date.current, au: Date.current, motif: :congés_payés)

    assert_equal User.all.to_h { |user| [user.id, user.absent?] },
                 clés_sql(User, 'users.absent')
  end

  test 'clé de tri « service » : lecture → le premier service de l\'utilisateur' do
    attendu = User.all.to_h do |user|
      [user.id, user.services.map { |service| TriTextuel.clé_de_tri(service.nom) }.min]
    end

    assert_equal attendu, clés_sql(User, 'users.service')
  end

  test 'clé de tri « mots clés » : lecture → la liste des mots clés de l\'utilisateur' do
    users(:bond).update!(tag_list: 'Zonage, entretien, Élagage')

    attendu = User.all.to_h do |user|
      [user.id, user.tag_list.map { |tag| TriTextuel.clé_de_tri(tag) }.sort.join(',').presence]
    end

    assert_equal attendu, clés_sql(User, 'users.tags')
  end

  test 'clé de tri « nombre d\'utilisateurs » : lecture → le compte du service' do
    attendu = Service.all.to_h { |service| [service.id, service.users.count] }

    assert_equal attendu, clés_sql(Service, 'services.users_count', &:to_i)
  end

  test 'clé de tri « dernier mail » : lecture → la date du dernier envoi de la cotation' do
    cotation = cotations(:cotation_paris)
    MailLog.create!(to: 'x@aikku.eu', subject: 'Devis', organisation: cotation.organisation,
                    user_id: users(:hidalgo).id, cotation: cotation)

    attendu = Cotation.all.to_h { |c| [c.id, c.mail_logs.maximum(:created_at)&.round] }

    assert_equal attendu, clés_sql(Cotation, 'cotations.dernier_mail') { |valeur| valeur&.round }
  end

  test 'clé de tri « heures consommées » : lecture → la somme calculée par la convention' do
    convention = conventions(:convention_paris)
    début = Time.zone.parse('2026-03-02 09:00:00')
    Intervention.create!(description: 'Intervention sous convention', adherent_id: convention.user_id,
                         service: convention.service, agents: [users(:hidalgo)], temps_de_pause: 0,
                         début: début, fin: début + 3.hours, slug: SecureRandom.uuid)

    attendu = Convention.all.to_h { |c| [c.id, c.heures_consommees.to_f] }

    assert_equal({ convention.id => 3.0 }, attendu.slice(convention.id))
    assert_equal attendu, clés_sql(Convention, 'conventions.heures_consommees', &:to_f)
  end

  test 'triable_par : toute colonne déclarée → expression exécutable en base' do
    Rails.application.eager_load!

    déclarées = 0
    ApplicationRecord.descendants.reject(&:abstract_class?).each do |modele|
      modele.colonnes_triables.each_key do |colonne|
        déclarées += 1
        clés_sql(modele, colonne)
      rescue StandardError => e
        flunk("#{modele} : la colonne #{colonne} ne s'exécute pas — #{e.message}")
      end
    end

    assert_operator déclarées, :>, 50
  end

  # Exécute l'expression déclarée telle quelle et rend { id => valeur }.
  def clés_sql(modele, colonne, &transformation)
    expression = case modele.colonnes_triables[colonne]
                 when :texte then TriTextuel.expression(colonne)
                 when :brut  then colonne
                 else modele.colonnes_triables[colonne]
                 end

    modele.select("#{modele.quoted_table_name}.#{modele.primary_key} AS identifiant",
                           "#{expression} AS clé")
          .to_h { |ligne| [ligne.identifiant, transformation ? transformation.call(ligne.clé) : ligne.clé] }
  end
end
