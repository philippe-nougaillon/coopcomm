# frozen_string_literal: true

require 'test_helper'

class MouvementTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  # --- Notification des réservations futures à la déclaration d'une panne ---
  # 

  setup do
    @tool       = tools(:rateau)
    @declarant  = users(:bond)
    @reserviste = users(:weil)
  end

  test "déclarer une panne enqueue NotifPanneJob pour la réservation future d'un autre utilisateur" do
    réservation = Mouvement.create!(tool: @tool, user: @reserviste, état: :réservé, date: 2.days.from_now)

    panne = nil
    assert_enqueued_jobs 1, only: NotifPanneJob do
      panne = Mouvement.create!(tool: @tool, user: @declarant, état: :panne, date: Time.current)
    end

    # Le job reçoit des ids bruts (pas de GlobalID) : (mouvement_panne_id, réservation_id).
    assert_enqueued_with(job: NotifPanneJob, args: [panne.id, réservation.id])
  end

  test 'déclarer une panne enqueue un NotifPanneJob par réservation future' do
    résa_1 = Mouvement.create!(tool: @tool, user: @reserviste, état: :réservé, date: 2.days.from_now)
    résa_2 = Mouvement.create!(tool: @tool, user: users(:patrick_adherent_paris), état: :réservé, date: 3.days.from_now)

    panne = nil
    assert_enqueued_jobs 2, only: NotifPanneJob do
      panne = Mouvement.create!(tool: @tool, user: @declarant, état: :panne, date: Time.current)
    end

    couples = enqueued_jobs.select { |j| j[:job] == NotifPanneJob }.map { |j| j[:args] }
    assert_equal [[panne.id, résa_1.id], [panne.id, résa_2.id]].sort, couples.sort
  end

  test 'les réservations futures du déclarant lui-même ne sont pas notifiées' do
    Mouvement.create!(tool: @tool, user: @declarant, état: :réservé, date: 2.days.from_now)

    assert_no_enqueued_jobs only: NotifPanneJob do
      Mouvement.create!(tool: @tool, user: @declarant, état: :panne, date: Time.current)
    end
  end

  test 'les réservations passées ne sont pas notifiées' do
    Mouvement.create!(tool: @tool, user: @reserviste, état: :réservé, date: 2.days.ago)

    assert_no_enqueued_jobs only: NotifPanneJob do
      Mouvement.create!(tool: @tool, user: @declarant, état: :panne, date: Time.current)
    end
  end

  test "la réservation future d'un utilisateur supprimé (discard) n'est pas notifiée" do
    # Le default_scope :kept de User s'applique à l'association : réservation.user
    # renvoie nil pour un réserviste soft-deleted, la garde `user.present?` l'exclut.
    Mouvement.create!(tool: @tool, user: @reserviste, état: :réservé, date: 2.days.from_now)
    @reserviste.discard

    assert_no_enqueued_jobs only: NotifPanneJob do
      Mouvement.create!(tool: @tool, user: @declarant, état: :panne, date: Time.current)
    end
  end

  test "créer un mouvement qui n'est pas une panne ne notifie personne" do
    Mouvement.create!(tool: @tool, user: @reserviste, état: :réservé, date: 3.days.from_now)

    assert_no_enqueued_jobs only: NotifPanneJob do
      Mouvement.create!(tool: @tool, user: @declarant, état: :réservé, date: 2.days.from_now)
    end
  end
end
