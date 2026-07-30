# frozen_string_literal: true

require 'test_helper'

class MailLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @mail_log = mail_logs(:mail_log)
    sign_in users(:hidalgo)
  end

  test 'should get index' do
    get mail_logs_url
    assert_response :success
  end

  # test "should get new" do
  #   get new_mail_log_url
  #   assert_response :success
  # end

  # test "should create mail_log" do
  #   assert_difference("MailLog.count") do
  #     post mail_logs_url, params: { mail_log: { message_id: @mail_log.message_id, organisation_id: @mail_log.organisation_id, subject: @mail_log.subject, to: @mail_log.to } }
  #   end

  #   assert_redirected_to mail_log_url(MailLog.last)
  # end

  test 'should show mail_log' do
    get mail_log_url(@mail_log)
    assert_response :success
  end

  # test "should get edit" do
  #   get edit_mail_log_url(@mail_log)
  #   assert_response :success
  # end

  # test "should update mail_log" do
  #   patch mail_log_url(@mail_log), params: { mail_log: { message_id: @mail_log.message_id, organisation_id: @mail_log.organisation_id, subject: @mail_log.subject, to: @mail_log.to } }
  #   assert_redirected_to mail_log_url(@mail_log)
  # end

  # test "should destroy mail_log" do
  #   assert_difference("MailLog.count", -1) do
  #     delete mail_log_url(@mail_log)
  #   end

  #   assert_redirected_to mail_logs_url
  # end

  test 'should refresh mail_log' do
    ENV['MAILGUN_API_KEY'] = 'abcd1234'
    ENV['MAILGUN_DOMAIN'] = 'example.com'

    get notifications_url
    assert_response :success
  end

  # --- Filtres de l'index (slim-select multiple) ---

  test 'le filtre destinataire accepte une sélection multiple' do
    autre = MailLog.create!(to: 'ailleurs@example.com', subject: 'Autre sujet', message_id: '999',
                            organisation: organisations(:mairie_paris), channel: 0, user_id: users(:bond).id)

    get mail_logs_url(search: [@mail_log.to, ''])

    assert_response :success
    assert_includes assigns(:mail_logs), @mail_log
    assert_not_includes assigns(:mail_logs), autre
  end

  test 'le filtre destinataire est insensible à la casse' do
    get mail_logs_url(search: [@mail_log.to.upcase])

    assert_response :success
    assert_includes assigns(:mail_logs), @mail_log
  end

  test 'un filtre destinataire entièrement vide est ignoré' do
    get mail_logs_url(search: [''])

    assert_response :success
    assert_includes assigns(:mail_logs), @mail_log
  end

  test 'le filtre sujet restreint la liste' do
    get mail_logs_url(search_subject: [@mail_log.subject])

    assert_response :success
    assert_includes assigns(:mail_logs), @mail_log
  end

  test 'un filtre sujet vide est ignoré' do
    get mail_logs_url(search_subject: [''])

    assert_response :success
    assert_includes assigns(:mail_logs), @mail_log
  end

  test 'le filtre ko ne garde que les envois en échec' do
    en_echec = MailLog.create!(to: 'echec@example.com', subject: 'Échec', message_id: '888', statut: false,
                               organisation: organisations(:mairie_paris), channel: 0, user_id: users(:bond).id)

    get mail_logs_url(ko: '1')

    assert_response :success
    assert_includes assigns(:mail_logs), en_echec
    assert_not_includes assigns(:mail_logs), @mail_log
  end

  # --- refresh / slug introuvable ---

  test 'refresh interroge les deux fournisseurs et revient aux notifications' do
    FetchMailgunInfos.stub :call, nil do
      FetchTwilioInfos.stub :call, nil do
        get refresh_mail_logs_url
      end
    end

    assert_redirected_to notifications_path
    assert_match(/Actualisation réussie/i, flash[:notice].to_s)
  end

  test 'un slug de notification inconnu redirige au lieu de planter' do
    get mail_log_url('slug-inexistant')

    assert_redirected_to root_path
    assert_match(/introuvable/i, flash[:alert].to_s)
  end
end
