# frozen_string_literal: true

# Expressions de tri partagées par plusieurs modèles, appelées depuis leurs
# `triable_par` : les tableaux qui affichent la même chose se trient de la même
# façon (les trois documents devis/commande/facture, l'utilisateur, le service).
module ColonnesTri
  # Sous-requête scalaire plutôt que jointure : aucune ligne dupliquée, aucune
  # interférence avec les `includes` et la pagination déjà en place.
  def self.utilisateur(colonne_clé)
    "(SELECT #{TriTextuel.expression('users.nom')} FROM users WHERE users.id = #{colonne_clé})"
  end

  def self.service(colonne_clé)
    "(SELECT #{TriTextuel.expression('services.nom')} FROM services WHERE services.id = #{colonne_clé})"
  end

  def self.document(table)
    {
      "#{table}.ref" => :texte,
      "#{table}.workflow_state" => :texte,
      "#{table}.adherent" => utilisateur("#{table}.adherent_id"),
      "#{table}.service" => service("#{table}.service_id"),
      "#{table}.intitulé" => :texte,
      "#{table}.date_livraison_souhaitée" => :brut,
      "#{table}.total_ht" => :brut
    }
  end

  def self.mail_logs
    {
      'mail_logs.created_at' => :brut,
      'mail_logs.channel' => :brut,
      'mail_logs.user' => utilisateur('mail_logs.user_id'),
      'mail_logs.to' => :texte,
      'mail_logs.subject' => :texte,
      'mail_logs.statut' => :brut,
      'mail_logs.etat' => :brut
    }
  end

  def self.audits
    {
      'audits.created_at' => :brut,
      'audits.action' => :texte,
      'audits.auditable_type' => :texte,
      'audits.user' => utilisateur('audits.user_id')
    }
  end
end
