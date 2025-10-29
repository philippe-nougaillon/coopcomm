class AddOtpMethodToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :otp_method, :integer
  end
end
