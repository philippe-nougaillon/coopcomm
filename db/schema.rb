# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_06_24_143620) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "absences", force: :cascade do |t|
    t.date "du"
    t.date "au"
    t.string "observation"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "motif", default: 0
    t.boolean "matin", default: false
    t.boolean "après_midi", default: false
    t.index ["user_id"], name: "index_absences_on_user_id"
  end

  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.string "message_id", null: false
    t.string "message_checksum", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "agent_interventions", force: :cascade do |t|
    t.bigint "agent_id", null: false
    t.bigint "intervention_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id", "intervention_id"], name: "index_agent_interventions_on_agent_id_and_intervention_id", unique: true
    t.index ["agent_id"], name: "index_agent_interventions_on_agent_id"
    t.index ["intervention_id"], name: "index_agent_interventions_on_intervention_id"
  end

  create_table "audits", force: :cascade do |t|
    t.integer "auditable_id"
    t.string "auditable_type"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.text "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at"
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "conventions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "service_id", null: false
    t.date "date_début"
    t.date "date_fin_prévue"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "mémo"
    t.index ["service_id"], name: "index_conventions_on_service_id"
    t.index ["user_id", "service_id"], name: "index_conventions_on_user_id_and_service_id", unique: true
    t.index ["user_id"], name: "index_conventions_on_user_id"
  end

  create_table "cotation_lignes", force: :cascade do |t|
    t.bigint "cotation_id", null: false
    t.bigint "prestation_id", null: false
    t.string "intitulé"
    t.integer "qté"
    t.decimal "prix_ht", precision: 8, scale: 2
    t.virtual "total_ht", type: :decimal, precision: 10, scale: 2, as: "(prix_ht * (\"qté\")::numeric)", stored: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cotation_id"], name: "index_cotation_lignes_on_cotation_id"
    t.index ["prestation_id"], name: "index_cotation_lignes_on_prestation_id"
  end

  create_table "cotations", force: :cascade do |t|
    t.bigint "adherent_id", null: false
    t.bigint "service_id", null: false
    t.string "ref"
    t.string "intitulé"
    t.text "mémo"
    t.date "date_livraison_souhaitée"
    t.decimal "total_ht", precision: 10, scale: 2
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.string "workflow_state", default: "créé"
    t.index ["adherent_id"], name: "index_cotations_on_adherent_id"
    t.index ["discarded_at"], name: "index_cotations_on_discarded_at"
    t.index ["service_id"], name: "index_cotations_on_service_id"
    t.index ["slug"], name: "index_cotations_on_slug", unique: true
  end

  create_table "documents", force: :cascade do |t|
    t.string "category"
    t.string "workflow_state"
    t.bigint "tool_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "version", precision: 5, scale: 1
    t.string "slug"
    t.index ["tool_id"], name: "index_documents_on_tool_id"
  end

  create_table "export_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "organisation_id", null: false
    t.string "export_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organisation_id"], name: "index_export_logs_on_organisation_id"
    t.index ["user_id"], name: "index_export_logs_on_user_id"
  end

  create_table "interventions", force: :cascade do |t|
    t.datetime "début"
    t.datetime "fin"
    t.decimal "temps_de_pause"
    t.string "description"
    t.string "workflow_state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "adherent_id"
    t.decimal "temps_total", precision: 8, scale: 2, default: "0.0"
    t.text "commentaires"
    t.integer "note", default: 5
    t.string "avis"
    t.string "slug"
    t.boolean "repeter", default: false
    t.string "template_slug"
    t.datetime "début_prévue"
    t.datetime "fin_prévue"
    t.string "meteo"
    t.decimal "co2", default: "0.0"
    t.string "trajet"
    t.bigint "service_id"
    t.string "localisation"
    t.index ["adherent_id"], name: "index_interventions_on_adherent_id"
    t.index ["service_id"], name: "index_interventions_on_service_id"
  end

  create_table "mail_logs", force: :cascade do |t|
    t.string "to"
    t.string "subject"
    t.string "message_id"
    t.bigint "organisation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.boolean "statut", default: true
    t.boolean "etat", default: false
    t.json "error_message"
    t.string "slug"
    t.integer "channel"
    t.bigint "cotation_id"
    t.index ["cotation_id"], name: "index_mail_logs_on_cotation_id"
    t.index ["organisation_id"], name: "index_mail_logs_on_organisation_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "from_id"
    t.bigint "to_id"
    t.datetime "read_at"
    t.index ["from_id"], name: "index_messages_on_from_id"
    t.index ["to_id"], name: "index_messages_on_to_id"
  end

  create_table "mouvements", force: :cascade do |t|
    t.bigint "tool_id", null: false
    t.integer "état"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "intervention_id"
    t.date "date"
    t.bigint "user_id", null: false
    t.string "commentaires"
    t.index ["date"], name: "index_mouvements_on_date"
    t.index ["intervention_id"], name: "index_mouvements_on_intervention_id"
    t.index ["tool_id"], name: "index_mouvements_on_tool_id"
    t.index ["user_id"], name: "index_mouvements_on_user_id"
  end

  create_table "newsletters", force: :cascade do |t|
    t.string "email"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "organisations", force: :cascade do |t|
    t.string "nom"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "prestations", force: :cascade do |t|
    t.bigint "organisation_id", null: false
    t.string "code"
    t.string "libellé"
    t.string "catégorie"
    t.string "sous_catégorie"
    t.string "description"
    t.string "unité"
    t.decimal "tarif", precision: 8, scale: 2
    t.string "compétence"
    t.string "délai"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.index ["organisation_id", "code"], name: "index_prestations_on_organisation_id_and_code", unique: true
    t.index ["organisation_id"], name: "index_prestations_on_organisation_id"
    t.index ["slug"], name: "index_prestations_on_slug", unique: true
  end

  create_table "services", force: :cascade do |t|
    t.string "nom"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organisation_id", null: false
    t.string "slug"
    t.boolean "calculate_distance", default: false
    t.index ["organisation_id"], name: "index_services_on_organisation_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.binary "payload", null: false
    t.datetime "created_at", null: false
    t.bigint "channel_hash", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "taggings", force: :cascade do |t|
    t.bigint "tag_id"
    t.string "taggable_type"
    t.bigint "taggable_id"
    t.string "tagger_type"
    t.bigint "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at", precision: nil
    t.string "tenant", limit: 128
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "taggings_taggable_context_idx"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable_type_and_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
    t.index ["tagger_type", "tagger_id"], name: "index_taggings_on_tagger_type_and_tagger_id"
    t.index ["tenant"], name: "index_taggings_on_tenant"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "tool_interventions", force: :cascade do |t|
    t.bigint "tool_id", null: false
    t.bigint "intervention_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["intervention_id"], name: "index_tool_interventions_on_intervention_id"
    t.index ["tool_id"], name: "index_tool_interventions_on_tool_id"
  end

  create_table "tools", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.bigint "organisation_id", null: false
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "icon_name"
    t.string "modèle"
    t.string "marque"
    t.index ["organisation_id"], name: "index_tools_on_organisation_id"
  end

  create_table "user_services", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "service_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["service_id"], name: "index_user_services_on_service_id"
    t.index ["user_id"], name: "index_user_services_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "nom"
    t.string "prénom"
    t.integer "rôle", default: 0, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.string "uid"
    t.string "provider"
    t.datetime "messages_last_seen_at", default: "2024-11-07 09:50:54"
    t.string "slug"
    t.string "téléphone"
    t.string "memo"
    t.string "otp_secret"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login"
    t.datetime "discarded_at"
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.string "unlock_token"
    t.integer "otp_method"
    t.string "color"
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.datetime "remember_created_at"
    t.string "address"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.bigint "warehouse_id"
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["warehouse_id"], name: "index_users_on_warehouse_id"
  end

  create_table "warehouses", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organisation_id", null: false
    t.string "slug"
    t.string "address"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.index ["organisation_id"], name: "index_warehouses_on_organisation_id"
  end

  create_table "wiki_pages", force: :cascade do |t|
    t.string "titre"
    t.boolean "publiée", default: false
    t.integer "poids", default: 0
    t.integer "catégorie"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "épinglée"
    t.datetime "discarded_at"
    t.bigint "user_id", null: false
    t.string "sous_titre"
    t.boolean "private", default: true
    t.index ["discarded_at"], name: "index_wiki_pages_on_discarded_at"
    t.index ["slug"], name: "index_wiki_pages_on_slug", unique: true
    t.index ["user_id"], name: "index_wiki_pages_on_user_id"
  end

  add_foreign_key "absences", "users"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "agent_interventions", "interventions"
  add_foreign_key "agent_interventions", "users", column: "agent_id"
  add_foreign_key "conventions", "services"
  add_foreign_key "conventions", "users"
  add_foreign_key "cotation_lignes", "cotations"
  add_foreign_key "cotation_lignes", "prestations"
  add_foreign_key "cotations", "services"
  add_foreign_key "cotations", "users", column: "adherent_id"
  add_foreign_key "documents", "tools"
  add_foreign_key "export_logs", "organisations"
  add_foreign_key "export_logs", "users"
  add_foreign_key "interventions", "services"
  add_foreign_key "mail_logs", "cotations"
  add_foreign_key "mail_logs", "organisations"
  add_foreign_key "mouvements", "interventions"
  add_foreign_key "mouvements", "tools"
  add_foreign_key "mouvements", "users"
  add_foreign_key "prestations", "organisations"
  add_foreign_key "services", "organisations"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "taggings", "tags"
  add_foreign_key "tool_interventions", "interventions"
  add_foreign_key "tool_interventions", "tools"
  add_foreign_key "tools", "organisations"
  add_foreign_key "user_services", "services"
  add_foreign_key "user_services", "users"
  add_foreign_key "users", "warehouses"
  add_foreign_key "warehouses", "organisations"
  add_foreign_key "wiki_pages", "users"
end
