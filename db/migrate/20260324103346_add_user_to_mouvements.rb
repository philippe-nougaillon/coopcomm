# frozen_string_literal: true

class AddUserToMouvements < ActiveRecord::Migration[8.0]
  def change
    add_reference :mouvements, :user, null: true, foreign_key: true

    reversible do |dir|
      dir.up do
        # On rafraîchit le cache du modèle pour qu'il "voie" la nouvelle colonne
        Mouvement.reset_column_information

        Mouvement.find_each do |mouvement|
          target_user_id = nil

          # A. On cherche le premier agent de l'intervention
          target_user_id = mouvement.intervention.agents.first&.id if mouvement.intervention.present?

          # B. S'il n'y a pas d'agent, on cherche le créateur de l'outil via Audited
          if target_user_id.nil? && mouvement.tool.present?
            creation_audit = mouvement.tool.audits.find_by(action: 'create')
            target_user_id = creation_audit&.user_id
          end

          # C. SÉCURITÉ : Il te faut un fallback absolu au cas où l'outil a été créé avant
          # l'installation de Audited ou si la BDD est un peu sale.
          target_user_id ||= User.first&.id

          # On met à jour silencieusement (sans déclencher validations/callbacks/audits)
          mouvement.update_column(:user_id, target_user_id) if target_user_id
        end
      end
    end

    # 3. Maintenant que tout est rempli, on verrouille la colonne
    change_column_null :mouvements, :user_id, false
  end
end
