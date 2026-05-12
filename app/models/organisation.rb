class Organisation < ApplicationRecord
  audited

  has_many :mail_logs, dependent: :destroy
  has_many :absences, through: :users, dependent: :destroy
  has_many :tools, dependent: :destroy
  has_many :mouvements, through: :tools, dependent: :destroy
  has_many :services, dependent: :destroy
  has_many :export_logs, dependent: :destroy
  has_many :warehouses, dependent: :destroy
  has_many :users, -> { distinct }, through: :services
  has_many :messages, -> { distinct }, through: :users
  has_many :interventions, through: :services

  def numero
    self.nom.split('_').last
  end

  def tags
    # assemblees_tags_ids = self.assemblees.tag_counts_on(:tags).pluck(:id)
    # users_tags_ids = self.users.tag_counts_on(:tags).pluck(:id)
    # return ActsAsTaggableOn::Tag.where(id: assemblees_tags_ids).or(ActsAsTaggableOn::Tag.where(id: users_tags_ids)).order(:name)
  end
end
