class AddTemplateSlugFieldToIntervention < ActiveRecord::Migration[7.1]
  def change
    add_column :interventions, :template_slug, :string
  end
end
