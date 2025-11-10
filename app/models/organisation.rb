class Organisation < ApplicationRecord
  audited


  has_many :users, dependent: :destroy
  has_many :interventions, dependent: :destroy
  has_many :mail_logs, dependent: :destroy
  has_many :absences, through: :users, dependent: :destroy
  has_many :notifications, through: :users, dependent: :destroy
  has_many :tools, dependent: :destroy
  has_many :mouvements, through: :tools, dependent: :destroy

  def numero
    self.nom.split('_').last
  end

  def tags
    # assemblees_tags_ids = self.assemblees.tag_counts_on(:tags).pluck(:id)
    # users_tags_ids = self.users.tag_counts_on(:tags).pluck(:id)
    # return ActsAsTaggableOn::Tag.where(id: assemblees_tags_ids).or(ActsAsTaggableOn::Tag.where(id: users_tags_ids)).order(:name)
  end
end
