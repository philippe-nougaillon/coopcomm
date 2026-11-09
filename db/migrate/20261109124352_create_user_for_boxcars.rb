class CreateUserForBoxcars < ActiveRecord::Migration[8.1]
  def change
    create_view :user_for_boxcars
  end
end
