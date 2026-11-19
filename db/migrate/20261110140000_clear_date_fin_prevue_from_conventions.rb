# frozen_string_literal: true

class ClearDateFinPrevueFromConventions < ActiveRecord::Migration[8.1]
  def up
    Convention.where.not(date_fin_prévue: nil).find_each do |convention|
      next if Convention.exists?(['user_id = ? AND service_id = ? AND date_début > ?',
                                  convention.user_id, convention.service_id, convention.date_début])

      convention.update_attribute(:date_fin_prévue, nil)
    end
  end
end
