class Organisation < ApplicationRecord
  audited

  has_many :users
  has_many :interventions
  has_many :mail_logs
  has_many :absences, through: :users
  has_many :notifications, through: :users

  def numero
    self.nom.split('_').last
  end

  def tags
    # assemblees_tags_ids = self.assemblees.tag_counts_on(:tags).pluck(:id)
    # users_tags_ids = self.users.tag_counts_on(:tags).pluck(:id)
    # return ActsAsTaggableOn::Tag.where(id: assemblees_tags_ids).or(ActsAsTaggableOn::Tag.where(id: users_tags_ids)).order(:name)
  end
end
