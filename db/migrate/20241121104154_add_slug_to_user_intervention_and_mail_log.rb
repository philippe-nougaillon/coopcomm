class AddSlugToUserInterventionAndMailLog < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :slug, :string
    add_column :interventions, :slug, :string
    add_column :mail_logs, :slug, :string

    User.all.each do |user|
      user.update!(slug: SecureRandom.uuid)
    end

    Intervention.all.each do |intervention|
      intervention.update!(slug: SecureRandom.uuid)
    end

    MailLog.all.each do |mail_log|
      mail_log.update!(slug: SecureRandom.uuid)
    end
  end
end
