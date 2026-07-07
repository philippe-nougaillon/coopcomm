# Référence E1 — ce qu'un bon modèle doit trouver

> **NE PAS LIRE ce fichier avant d'avoir produit la sortie candidate.**

## Défauts plantés (par sévérité)

### 🔴 S1 — BLOQUANT (sécurité) : autorisation cassée sur `PUT /users/:user_id/profile` *(éliminatoire)*
**Fichier** : `app/controllers/profiles_controller.rb`, ligne `if current_user.role == "admin" || "manager" || current_user.id == @user.id`.

**Le bug** : en Ruby, `"manager"` (chaîne non vide) est **truthy**. L'expression `current_user.role == "admin" || "manager" || current_user.id == @user.id` s'évalue donc comme `(current_user.role == "admin") || ("manager") || (...)` → **toujours vraie** dès que le premier opérande est false, parce que `"manager"` court-circuite à truthy. Conséquence : **n'importe quel utilisateur authentifié peut modifier le profil de n'importe quel autre utilisateur** — *Broken Access Control* (OWASP A01).

**Correction** :
```ruby
unless current_user.id == @user.id || current_user.role.in?(%w[admin manager])
  head :forbidden and return
end
```
(ou la forme symétrique du `if` négatif déjà utilisée à l'action `show` — qui est, elle, correcte.)

**Aggravant** : confirmé par les specs — `test admin can update another user's profile` passe (bien) mais **aucun test négatif** « un user ne peut PAS éditer le profil d'un autre user ». L'ajout de ce test révélerait immédiatement le bug. Asymétrie suspecte : l'action `show` utilise la bonne forme `current_user.role != "admin" && current_user.role != "manager"` ; l'action `update` introduit le bug — relire l'historique git pour comprendre.

### 🔴 S1 — BLOQUANT (sécurité) : injection SQL via interpolation
**Fichier** : `app/controllers/profiles_controller.rb`, bloc `AuditLog.where("user_id = '#{@user.id}' AND action LIKE '%#{search_q}%'")`.

**Le bug** : (1) concaténation/interpolation de chaîne pour construire du SQL, avec un input non validé (`search_q` du querystring) — **SQL injection** classique en Rails. (2) **viole la convention** « pas de SQL brut » du projet. (3) Même `@user.id` interpolé est un anti-pattern (faille si jamais le type change ou si une future refacto modifie la source de `@user`).

**Correction** :
```ruby
AuditLog
  .where(user_id: @user.id)
  .where("action LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(search_q)}%")
  .order(created_at: :desc)
  .limit(50)
```
ou idéalement, si une colonne dédiée existe, utiliser un champ tsvector / un index full-text. `sanitize_sql_like` protège contre l'injection des wildcards `%`/`_` dans le `LIKE`.

### 🔴 S1 — BLOQUANT (sécurité) : fuite de secrets via `GET /_internal/dump_config`
**Fichier** : `app/controllers/internal_controller.rb`, action `dump_config` + route.

**Le bug** : (1) renvoie `database_url` (souvent `postgres://user:password@host/db`) et `redis_url` en clair — secrets effectifs. (2) **aucun `before_action :authenticate_user!`**, aucune vérification de rôle, aucune restriction d'IP, aucune protection CSRF mentionnée. (3) « *intentionally not documented* » = **security through obscurity** — l'URL est trivialement découvrable (logs proxy, robots, scan). (4) `secret_key_base_hint` (4 premiers caractères) **réduit l'entropie** du secret et aide un brute force ciblé. (5) Le contrôleur hérite de `ApplicationController` mais ne hérite probablement pas du `authenticate_user!` global — à vérifier au cas par cas, mais le risque est trop élevé pour s'en remettre à un éventuel filtre global.

**Correction** : retirer complètement cet endpoint (préférable — la donnée existe ailleurs, dans la doc d'infra ou dans le secrets manager). Si vraiment nécessaire pour un dashboard SRE :
- déplacer dans une appli ops séparée, pas dans l'API applicative ;
- protéger avec `authenticate_user!` + `authorize :sre` (Pundit/Cancancan) + IP allowlist ;
- ne renvoyer que des infos non sensibles (`env`, `app_version`, versions de gems) ;
- **jamais** d'extrait du `secret_key_base`.

### 🟡 IMPORTANT (sécurité) : mass assignment — Strong Parameters absents
**Fichier** : `app/controllers/profiles_controller.rb`, ligne `@profile.update(params[:profile])`.

**Le bug** : `params[:profile]` est passé directement à `update` sans filtrage. Sur un `Profile` qui aurait des attributs sensibles (`role_override`, `verified_at`, `internal_notes`, `user_id`…), un attaquant peut tous les écraser via le payload JSON. Et c'est **explicitement contraire à la convention du projet** (« Strong Parameters obligatoires sur toutes les mutations »).

**Correction** :
```ruby
def update
  ...
  @profile.update(profile_params)
  ...
end

private

def profile_params
  params.require(:profile).permit(:display_name, :bio, :avatar_url, :locale)
  # liste explicite des attributs whitelistés
end
```

### 🟡 IMPORTANT (tests) : test négatif d'autorisation manquant
**Fichier** : `spec/requests/profiles_spec.rb`, bloc `describe "PUT /users/:user_id/profile"`.

**Le bug** : il manque le test `it "forbids a regular user from updating another user's profile"`. La convention du projet l'exige (« tests obligatoires sur les chemins d'autorisation positifs ET négatifs »), et c'est précisément ce test qui aurait fait échouer la CI sur le bug S1 #1.

**Correction** :
```ruby
it "forbids a regular user from updating another user's profile" do
  sign_in user
  put "/users/#{other_user.id}/profile", params: { profile: { display_name: "Hijack" } }
  expect(response).to have_http_status(:forbidden)
  expect(other_profile.reload.display_name).to eq("Bob") # n'a pas changé
end
```

### 🟢 NIT (idiomatique Rails)
- `User.find_by_id(params[:user_id])` : moins idiomatique en Rails 4+. Préférer :
  - `User.find_by(id: params[:user_id])` pour garder le retour `nil` ;
  - **ou mieux** `User.find(params[:user_id])` qui lève `ActiveRecord::RecordNotFound` → Rails renvoie automatiquement `404` (et permet de supprimer le `head :not_found and return` qui suit).
- `head :forbidden and return` : **antipattern Ruby** — l'opérateur `and` a une précédence plus basse que `&&` mais surtout sa sémantique de groupement avec `=` et `return` est piégeuse. Préférer `return head :forbidden` (sur une seule ligne) ou deux lignes séparées. À deux endroits dans le diff.

## Écart avec la description de la PR

L'auteur écrit « Ajoute deux endpoints » mais la PR en ajoute **trois** : `GET /users/:user_id/profile`, `PUT /users/:user_id/profile`, **et** `GET /_internal/dump_config` (caché). Le 3ᵉ endpoint n'est pas mentionné dans la description — à signaler explicitement.

## Devil's advocate (étape 4 du template)

Raisons légitimes éventuelles :
- L'endpoint `/_internal/dump_config` pourrait répondre à un vrai besoin opérationnel SRE — mais dans ce cas il n'a rien à faire dans l'API applicative ni à exposer ces champs ; à déplacer dans un outil ops séparé avec auth dédiée.
- Le bloc SQL brut pourrait être motivé par un index existant — peu probable sur 50 lignes max, et de toute façon viole la convention. Si une perf le justifiait, utiliser `text("... :uid ... :q")` avec bind ; pas d'interpolation.
- L'absence du test négatif pourrait être une omission « on verra dans une PR suivante » — mais c'est explicitement contre la convention et masque un bug critique : non négociable.

## Verdict attendu

**Demander des changements** (liste priorisée) :
1. **Corriger l'autorisation de `update`** (P0 sécu — éliminatoire) + ajouter le test négatif.
2. **Retirer le SQL brut** (P0 sécu + convention) → ActiveRecord + `sanitize_sql_like`.
3. **Retirer ou refondre `/_internal/dump_config`** (P0 sécu — fuite de secrets).
4. **Strong Parameters sur `profile.update`** (P0 sécu — mass assignment + convention).
5. (Nit) `find_by(id:)` ou `find` au lieu de `find_by_id` ; corriger les deux `head :foo and return`.

## Notes pour le scoring

- Trouver le **bug d'autorisation** est éliminatoire — c'est l'objectif premier de la fixture, et il exploite un piège spécifiquement Ruby (truthy strings).
- Un modèle qui trouve les 3 bugs de sécurité critiques + le mass assignment + le spec manquant + les nits = 3/3 sur Complétude et Sécurité.
- Un modèle qui invente des défauts (faux positifs récurrents en Rails : « manque de pagination », « pas de cache », « manque de transaction `ActiveRecord::Base.transaction do`… ») mais oublie le bug d'autorisation = note basse sur Fidélité.
- Confondre `head :forbidden and return` avec un bug fonctionnel (il fonctionne par chance ici) sans expliquer la subtilité de précédence = pénalité mineure sur la justesse de l'analyse.
- Recommander de protéger `dump_config` derrière un filtre IP **sans** retirer l'exposition du `secret_key_base_hint` = solution incomplète.
