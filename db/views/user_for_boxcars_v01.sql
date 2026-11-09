-- Paramètre de session posé par FetchBoxcarsInfos ; absent ou vidé par RESET (''), la vue ne rend aucune ligne.
-- L'organisation d'un utilisateur dérive de ses services (cf. User#organisation) : EXISTS évite les doublons
-- quand il appartient à plusieurs services de la même organisation.
SELECT users.id,
       users.nom,
       users."prénom",
       users.email,
       users."téléphone",
       users."rôle",
       users.address,
       users.memo,
       users.created_at,
       users.updated_at
FROM users
WHERE users.discarded_at IS NULL
  AND EXISTS (
    SELECT 1
    FROM user_services
    JOIN services ON services.id = user_services.service_id
    WHERE user_services.user_id = users.id
      AND services.organisation_id = NULLIF(current_setting('app.organisation_id', true), '')::bigint
  )
