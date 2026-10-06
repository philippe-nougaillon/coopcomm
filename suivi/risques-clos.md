# Risques clos — CoopComm

> Risques corrigés ou devenus sans objet, **du plus récent au plus ancien**. Chaque fiche garde son scénario et ses gardes d'origine. Risques surveillés : `risques-surveilles.md`.
>
> **Règle de tenue** : une fiche arrive ici **entière** depuis `risques-surveilles.md`, **en tête de liste**, titre préfixé `✅ CORRIGÉ (AAAA-MM-JJ)` ou `✅ SANS OBJET (AAAA-MM-JJ)`.

---

## ✅ Clos, du plus récent au plus ancien

### R3 — ✅ CORRIGÉ (2026-07-17) — Sous `test:all`, un `sign_in` Devise d'un test d'intégration peut être « volé » par une requête navigateur retardataire → redirection login au lieu du comportement métier (flakiness rare, test uniquement)
- **Signalé le** : 2026-07-16 (2 occurrences le même jour, jamais avant : run agent `test:all` 1359 runs / 1 échec, puis run PE — `SecuriteRegressionsTest#test_impossible_de_lire_une_conversation_avec_un_utilisateur_d'une_autre_organisation`, attendu `redirect_to /messagerie`, obtenu `redirect_to /users/sign_in`). **3e occurrence le 2026-07-17** (run PE : `InterventionsDisponibiliteTest#test_le_réel_est_prioritaire…`, attendu 2XX, obtenu 302 → `/users/sign_in` ; vert en isolation 12/12). **4e occurrence le 2026-07-17** (run agent `test:all` **parallèle 4 workers**, seed 42077 : `InterventionsDisponibiliteTest#test_pas_de_conflit_si_les_dates_réelles_sont_disjointes`, même signature 302 → login — le mode parallèle mélange système + intégration dans chaque worker, donc expose davantage au vol de hook). La fréquence monte (4 en 2 jours) — si ça continue, activer une des pistes ci-dessous.
- **Faits établis** : le test passe en isolation (14/14), passe avec `rack_attack_test` dans le même run (37/37), passe sur 3 seeds de la suite non-système complète (3 × 1276 runs / 0 échec) → ne se manifeste que dans `test:all` (système + intégration dans le même processus). **Hors de cause** : la config rack-attack (inerte en test via `:null_store`, et ne produit que des 429/403, jamais une redirection login).
- **Mécanisme — désormais PROUVÉ par la source de la gem** (2026-07-17, warden 1.2.9, ce n'est plus une déduction) : `sign_in` (Devise::Test::IntegrationHelpers, inclus globalement `test_helper.rb:24`) → `Warden::Test::Helpers#login_as` → `Warden.on_next_request` qui **empile un bloc dans un tableau global au processus** (`warden/test/warden_helpers.rb:25` : `_on_next_request << blk`). Ce tableau est **drainé sans aucun filtrage** par le hook posé par `Warden.test_mode!` (`warden.rb:37-42`) :
  ```ruby
  Warden::Manager.on_request do |proxy|
    unless proxy.asset_request?
      while blk = Warden._on_next_request.shift   # ← LA prochaine requête, quelle qu'elle soit
        blk.call(proxy)
      end
    end
  end
  ```
  Le seul filtre est `asset_request?` — une requête **Turbo/XHR retardataire** du navigateur d'un system test n'en est pas une. Sous `test:all`, le serveur Puma de Capybara vit dans le **même processus** et reste actif entre les classes : sa requête en vol traverse Warden juste après le `sign_in` du test d'intégration suivant, **shift le bloc et pose l'utilisateur sur la session du navigateur** au lieu de celle du test → le `get`/`delete` du test part non authentifié.
- **Signature caractéristique** : test d'intégration/contrôleur qui échoue avec `redirect_to /users/sign_in` là où il attend le comportement métier, uniquement en `test:all`, non reproductible en isolation, la classe précédente (ordre du seed) étant un system test.
- **Occurrences** : 5 en 2 jours (2026-07-16 ×2, 2026-07-17 ×3) — 5e = run PE seed 7911, `InterventionsControllerTest#test_purge_:_impossible_de_supprimer_la_photo_d'une_AUTRE_intervention`, attendu 404, obtenu 302 → login ; vert en relance isolée (1 run / 0 échec). **Aucune n'a jamais touché deux fois le même test** : c'est l'ordre du seed qui décide de la victime.
- **Statut : CORRIGÉ le 2026-07-17** (accord PE). Patch dans `test_helper.rb` + 3 tests de verrouillage dans `test/integration/sign_in_hook_isolation_test.rb` (dont une **garde anti-faux-positif** : une file toujours vide ferait passer les 2 tests R3 tout en cassant l'authentification de toute la suite). **Preuve rouge/verte faite** : correctif désactivé → les 2 tests R3 échouent, garde OK ; réactivé → 3/3 verts. Suite non-système **1279 runs / 0 échec / 2 skips** ; échantillon système 4/4 (le helper `login` n'est pas affecté). **Correctif** : neutraliser le drain hors du thread de test, puisque les requêtes d'intégration sont traitées **inline dans le thread principal** alors que Puma sert les siennes dans **ses propres threads** —
  ```ruby
  module Warden::Test::WardenHelpers
    def _on_next_request
      return [] unless Thread.current == Thread.main # requête navigateur : ne consomme rien
      @_on_next_request ||= []
    end
  end
  ```
  La file reste intacte pour le vrai test. ⚠ Ne PAS « ré-armer » le hook depuis l'intérieur du bloc (réflexe naturel) : le drain est un `while … shift`, un re-`push` serait re-shifté immédiatement → **boucle infinie**. Vérifié au préalable : **aucun system test n'utilise `sign_in`** (ils passent par le helper `login` = vrai formulaire), donc rien ne dépend du hook côté navigateur. **Écartés** : re-tenter la requête si redirigée login (masquerait une vraie régression d'authentification — inacceptable sur cette app) ; remplacer `sign_in` par un POST de connexion réel (immunisé par construction et plus réaliste, mais casse les re-`sign_in` en cours de test — `require_no_authentication` de Devise redirige un utilisateur déjà connecté — et touche 25 fichiers).
