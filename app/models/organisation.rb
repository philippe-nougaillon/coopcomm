# frozen_string_literal: true

class Organisation < ApplicationRecord
  audited

  has_many :mail_logs, dependent: :destroy
  has_many :absences, through: :users, dependent: :destroy
  has_many :tools, dependent: :destroy
  has_many :mouvements, through: :tools, dependent: :destroy
  has_many :services, dependent: :destroy
  has_many :prestations, dependent: :destroy
  has_many :export_logs, dependent: :destroy
  has_many :warehouses, dependent: :destroy
  has_many :users, -> { distinct }, through: :services
  has_many :messages, -> { distinct }, through: :users
  has_many :interventions, through: :services
end
