class AddSlugToConvention < ActiveRecord::Migration[8.0]
  def change
    add_column :conventions, :slug, :string

    Convention.all.each do |c|
      c.save
    end
  end
end
