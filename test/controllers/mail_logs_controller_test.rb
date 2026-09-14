# frozen_string_literal: true

require 'test_helper'

class MailLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @mail_log = mail_logs(:mail_log)
    sign_in users(:hidalgo)
  end

  test 'index : sans paramètre → la page répond' do
    get mail_logs_url

    assert_response :success
  end

  test 'index : filtre destinataire → seulement les envois à ces adresses' do
    autre = cree_mail_log(to: 'ailleurs@example.com', subject: 'Autre sujet', message_id: '999')

    get mail_logs_url(search: [@mail_log.to, ''])

    assert_includes assigns(:mail_logs), @mail_log
    assert_not_includes assigns(:mail_logs), autre
  end

  test 'index : filtre destinataire insensible à la casse' do
    get mail_logs_url(search: [@mail_log.to.upcase])

    assert_includes assigns(:mail_logs), @mail_log
  end

  test 'index : filtre destinataire entièrement vide → liste non restreinte' do
    get mail_logs_url(search: [''])

    assert_includes assigns(:mail_logs), @mail_log
  end

  test 'index : filtre sujet → seulement les envois de ce sujet' do
    autre = cree_mail_log(to: 'ailleurs@example.com', subject: 'Autre sujet', message_id: '999')

    get mail_logs_url(search_subject: [@mail_log.subject])

    assert_includes assigns(:mail_logs), @mail_log
    assert_not_includes assigns(:mail_logs), autre
  end

  test 'index : filtre sujet vide → liste non restreinte' do
    get mail_logs_url(search_subject: [''])

    assert_includes assigns(:mail_logs), @mail_log
  end

  test 'index : filtre ko → seulement les envois en échec' do
    en_echec = cree_mail_log(to: 'echec@example.com', subject: 'Échec', message_id: '888', statut: false)

    get mail_logs_url(ko: '1')

    assert_includes assigns(:mail_logs), en_echec
    assert_not_includes assigns(:mail_logs), @mail_log
  end

  test 'show : une notification de son organisation → la page répond' do
    get mail_log_url(@mail_log)

    assert_response :success
  end

  test 'refresh : les deux fournisseurs sont interrogés → retour aux notifications' do
    FetchMailgunInfos.stub :call, nil do
      FetchTwilioInfos.stub :call, nil do
        get refresh_mail_logs_url
      end
    end

    assert_redirected_to notifications_path
    assert_match(/Actualisation réussie/i, flash[:notice].to_s)
  end

  test 'set_mail_log : un slug inconnu redirige sans planter' do
    get mail_log_url('slug-inexistant')

    assert_redirected_to root_path
    assert_match(/introuvable/i, flash[:alert].to_s)
  end

  private

  def cree_mail_log(**attributs)
    MailLog.create!({ organisation: organisations(:mairie_paris), channel: 0,
                      user_id: users(:bond).id }.merge(attributs))
  end
end
