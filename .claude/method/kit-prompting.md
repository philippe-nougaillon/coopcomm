# Kit prompting — Thésaurus + Boîte à tokens images + 13 Templates + Checklist

> Extrait « léger » de `generation-ia-synthese-approfondie.md` (synthèse de la newsletter « Génération IA », Flint Media — corpus arrêté au 2026-05-10). À charger en conversation de travail.
> Régime visé : Claude Max + agents (Claude Code / Cowork / MCP / Skills / CLAUDE.md). Domaine des exemples : tech / produit / dev.
> Pour le « pourquoi » (comment pense un LLM, archéologie, steelman, angles morts), voir le document complet. Pour l'évaluation des modèles/agents et la sécurité « agent en prod », voir `methode-evaluation-et-securite-agents.md`. Aucun secret dans ce fichier ; tout est local.

---

# 13. THÉSAURUS DU PROMPTING (≥ 37 entrées)

> **Mode d'emploi** : remplace le **terme plat** par la **graine sémantique**, qui *active* un comportement plus précis du modèle. Colonne « adapté à ton domaine (tech/produit/dev) » : exemple de prompt prêt à coller dans ton contexte. Source : techniques recensées dans le corpus (réf. de fiches entre crochets dans les notes ci‑dessous).

| # | Terme plat | Graine sémantique | Ce que ça active | Exemple de prompt (tech / produit / dev) |
|---|---|---|---|---|
| 1 | « résume ce document » | **« fais-moi une *extraction* détaillée »** | Tire les éléments porteurs d'info, préserve chiffres/exemples/formulations exactes ; ne lisse pas. | `Voici la doc de notre API : <document>…</document>. Fais-moi une extraction détaillée : tous les endpoints, paramètres, codes d'erreur, exemples de payload, limites de rate. Ne résume pas, n'omets rien.` |
| 2 | « analyse cette archi » | **« *subsume* l'analyse »** / *subsumer* | Synthèse qui *préserve la logique interne et la hiérarchie* de la source au lieu de tout aplatir. | `Explorons les ADR (Architecture Decision Records) de ce repo. Subsume l'analyse : restitue la logique de chaque décision et leur hiérarchie, pas une liste plate.` |
| 3 | « donne-moi une vue d'ensemble » | **« propose une vision *Gestalt* de ce code/dépôt »** | Vue de la *forme d'ensemble* : motifs récurrents, dépendances cachées, incohérences, dette structurelle. | `Voici l'arbre des modules et les imports. Propose une vision Gestalt : quel est le schéma invisible de couplage ? Où la structure contredit-elle l'intention déclarée dans le README ?` |
| 4 | « argumente le contraire » | **« *steelman* cet argument »** / *steelmanner* | Construit la version la *plus solide* d'une position (pas l'épouvantail). | `"Il faut migrer vers les microservices maintenant." Steelman cet argument : la version qu'en défendrait son meilleur avocat, avec ses prémisses les plus fortes. Puis fais le steelman de la position inverse.` |
| 5 | « prends de la hauteur » | **« fais une *anabasis* conceptuelle »** / *anabase* | Remonte des faits bruts vers les principes qui les gouvernent. | `À partir de ces 12 tickets de bug, fais une anabasis conceptuelle : remonte aux 2-3 causes structurelles dont ils sont les symptômes.` |
| 6 | « traite X comme un acteur » | **« *hypostasie* X et décris-le comme un agent autonome »** / *hypostasier* | Traite une abstraction comme un agent avec intentions et contraintes propres → révèle les forces qui la gouvernent. | `Hypostasie "notre dette technique" : décris-la comme un agent autonome — quelles seraient ses intentions, ses contraintes, son intérêt à survivre ?` |
| 7 | « réfléchis avant de répondre » | **« applique le *Chain of Thought* : commence par "Raisonnement:" en gras, en italique, avant chaque action »** | Force la décomposition en sous‑étapes → exploite l'auto‑régression → meilleures réponses. | `Avant de proposer le schéma de base de données, applique le Chain of Thought : "Raisonnement:" (en gras, en italique) — liste les entités, les relations, les contraintes, puis seulement le DDL.` |
| 8 | « recule, prends du recul » | **« *philosophe* d'abord : pose la question d'abstraction supérieure (*step-back*) »** | Niveau d'abstraction supérieur avant la réponse concrète. | `Avant de me dire comment scaler ce service, fais un step-back : quelle est la question générale de scalabilité dont ce cas est une instance ? Réponds à cette question d'abord, puis applique-la.` |
| 9 | « donne-moi un exemple » | **« voici N exemples (*few-shot*) : entrée → sortie »** | Cadre un format ou un style par paires. *(À éviter sur les modèles de raisonnement.)* | `Génère des messages de commit selon ces exemples : <ex>fix(auth): handle expired refresh token → ...</ex> <ex>...</ex>. Voici le diff : …` |
| 10 | « agis comme un expert » | **« *persona pattern* : Agis comme un [rôle] — PhD en…, X années sur…, reconnu pour…, [résultats chiffrés]. Ta mission est de… Utilise la méthode suivante : … »** | Active un registre, une rigueur, une méthode. *(Allège-le sur les modèles récents ; ne fige pas la méthode.)* | `Agis comme un staff engineer spécialisé en systèmes distribués (15 ans, a conçu des pipelines à 10⁶ req/s). Ta mission : auditer ce design doc. Méthode : (1) hypothèses implicites, (2) modes de défaillance, (3) alternatives, (4) recommandation.` |
| 11 | « dis-moi si tu ne sais pas » | **« *porte de sortie* : si tu n'as pas l'info, écris "Informations insuffisantes" et ne déduis pas »** | Réduit drastiquement l'hallucination. | `Réponds uniquement à partir du <document> fourni. Si la réponse n'y est pas, écris "Informations insuffisantes" — ne devine pas, ne déduis pas.` |
| 12 | « cite tes sources » | **« pour chaque info, donne l'extrait + le n° de ligne/page : {"extrait"} {ligne} ; n'utilise pas "le doc dit…" »** | Vérifiabilité ; coupe l'invention. | `Pour chaque affirmation sur le comportement de ce module, cite l'extrait du code source et le numéro de ligne au format {"extrait"} {fichier:ligne}. Pas de "le code fait…".` |
| 13 | « ne sois pas générique » | **« génère les 20 clichés du sujet, puis écris un texte qui n'en utilise aucun »** | Pousse hors de la « moyenne statistique ». | `Génère les 20 formulations clichés des annonces de release notes ("nous sommes ravis…", "amélioration de l'expérience…"). Puis rédige nos release notes sans aucune d'elles, uniquement des faits concrets.` |
| 14 | « évite les tics de langage » | **« interdis ces expressions : "dans un monde", "crucial", "captivant"… ; cherche les termes les moins utilisés »** | Style « inimitable » ; sort du RLHF moyen. | `Rédige cette doc technique en interdisant : "il est important de noter que", "n'hésitez pas à", "tout simplement", "crucial". Phrases courtes, voix active, impératif.` |
| 15 | « pas de "ce n'est pas X c'est Y" » | **« évite les constructions antithétiques ; affirmation positive directe »** | Coupe un tic rhétorique du RLHF. | `Dans cette explication d'archi, évite les tournures "ce n'est pas Y, c'est Z" et "pas X, mais Z". Affirme directement.` |
| 16 | « corrige/raccourcis ce texte » | **« *méthode ECS* : couper plutôt que réécrire ; réduis ~40 % ; conserve idées, chiffres, transitions, style ; valide étape par étape »** | Réduction fidèle, pas réécriture imposée. | `Voici notre RFC (8 pages). Réduis-la d'~40 % avec la règle stricte "couper plutôt que réécrire" : garde les décisions, les chiffres, les transitions. Montre-moi d'abord l'intro réduite, attends ma validation.` |
| 17 | « réduis l'emphase » | **« *réducteur d'emphase* : ce texte a un score d'exagération 90/100, ramène-le à 10 »** | Dégonfle le hype. | `Cet article sur "la révolution des agents IA" a un score d'exagération de 85/100. Réécris-le à 15 : faits, ordres de grandeur, incertitudes assumées.` |
| 18 | « note ce texte » | **« *technique du curseur* : note 1-10 sur [dimension], puis génère une variante par niveau »** | Rend la variation pilotable ; l'humain choisit. | `Sur une échelle 1-10 (1 = très verbeux, 10 = très laconique), à combien évalues-tu ce message d'erreur ? Puis réécris-le pour chaque niveau de 1 à 10.` |
| 19 | « parle simplement » | **« explique comme à un *profane éduqué*, sans perdre en précision, ne laisse aucune zone d'ombre, exemples concrets, ≤ 1000 signes »** | Vulgarisation rigoureuse, pas simpliste. | `Explique-moi le fonctionnement de notre système de cache distribué comme à un profane éduqué : clair, précis, exemples concrets, aucune zone d'ombre, ≤ 1500 signes.` |
| 20 | « structure narrative » | **« *Concept Engineering* : applique la structure Kabob/WSJ — Anecdote (zoom in) → Nut Graf (zoom out) → Corps (preuves) → Kicker (chute) »** | Lie l'intime (cas concret) et l'universel (info). | `Rédige le post d'annonce de notre nouvelle feature avec la structure WSJ : un cas client concret en ouverture, le nut graf qui dit pourquoi ça change la donne, les preuves, une chute qui revient au client.` |
| 21 | « fais une bonne accroche » | **« *Open Loop* : un hook irrésistible plutôt qu'un titre ; ouvre une boucle au § 1, ne la ferme qu'au § 10 »** | Joue sur l'effet Zeigarnik ; tient le lecteur. | `Réécris l'intro de ce post de blog technique : ouvre une boucle ("voici comment on a divisé par 10 notre temps de build — mais d'abord, pourquoi c'était cassé") qu'on ne referme qu'à la fin.` |
| 22 | « demande-moi des précisions » | **« pose-moi N questions avant d'exécuter (par blocs de 3-4, attends mes réponses), puis propose plusieurs approches »** | Cadre la tâche ; évite le one‑shot raté. | `Je veux ajouter de l'observabilité à ce service. D'abord, lis le code. Ensuite pose-moi 10 questions par blocs de 4 (périmètre, contraintes, outils existants, SLO). Puis propose 3 approches avant de coder.` |
| 23 | « convoque un expert » | **« choisis N penseurs/experts dont tu maîtrises les cadres en profondeur ; privilégie les auteurs *abondamment documentés* ; subsume l'analyse à travers chaque grille »** | Mobilise des grilles conceptuelles solides, pas le consensus mou. | `Choisis 6 penseurs fondamentaux (ingénierie, économie, sociologie, philosophie) pour analyser notre dette technique. Privilégie les auteurs abondamment documentés. Pour chacun : subsume l'analyse à travers sa grille.` |
| 24 | « donne-moi ton avis » | **« convoque les plus grands experts en [domaines] et propose une *revue critique* de [X] à travers leurs prismes »** | Avis = synthèse d'expertises identifiées, pas opinion floue. | `Convoque les plus grands experts en sécurité applicative, en SRE et en architecture. Propose une revue critique de notre design doc à travers leurs prismes — où chacun tiquerait.` |
| 25 | « apprends de cet exemple » | **« *reverse engineering* : lis ces [exemples], quelle est leur structure et *pourquoi* sont-ils efficaces ? identifie les principes sous-jacents »** | Extrait un patron transférable. | `Lis ces 3 PR descriptions exemplaires de projets open source réputés. Quelle est leur structure et pourquoi sont-elles efficaces ? Identifie les principes, puis applique-les à ma PR : <diff>…</diff>.` |
| 26 | « critique ta réponse » | **« *anti-flagornerie* : propose une analyse critique de ta réponse ; instruction système "pas de flagornerie, esprit critique" »** | Coupe la complaisance. | `Configure-toi : pas de flagornerie, esprit critique systématique. [tâche…] — puis, à chaque réponse, ajoute une section "analyse critique de ma réponse".` |
| 27 | « défends le contraire » | **« *devil's advocate* : défends maintenant la position inverse, avec ses meilleurs arguments »** | L'IA défend trop facilement n'importe quoi → tester le contraire. | `Tu viens de recommander d'adopter Kubernetes. Défends maintenant la position inverse ("garder notre PaaS actuel") avec ses meilleurs arguments. Puis dis-moi laquelle des deux est la plus solide et pourquoi.` |
| 28 | « réfléchis mieux » | **« *auto-réflexion* : 1) plan 2) comment l'améliorer 3) applique 4) réponse 5) comment l'améliorer 6) réponse améliorée »** | Itération interne sans intervention de l'utilisateur. | `Conçois la migration de ce schéma en 6 temps : (1) plan, (2) comment l'améliorer, (3) applique, (4) réponse, (5) comment l'améliorer encore, (6) réponse améliorée. Montre les 6 étapes.` |
| 29 | « parle-moi de cette conversation » | **« *phase 4 de Polya* : réflexion métacognitive — qu'avons-nous appris dans cet échange, qu'est-ce qui resterait à creuser ? »** | Clôture réflexive ; capitalise. | `Utilisons la phase 4 de Polya pour clôturer cette session de debug : qu'avons-nous appris sur le système, quelles hypothèses restent à valider, que faut-il documenter ?` |
| 30 | « retiens ça pour la prochaine fois » | **« crée/mets à jour un fichier `CLAUDE.md` à la racine qui explique l'état du projet et à quoi sert ce dossier »** | Mémoire persistante entre sessions (l'agent repart de zéro sinon). | `Crée un CLAUDE.md à la racine : conventions de code, commandes (build/test/lint), architecture en 5 lignes, ce qui est en cours, ce qu'il ne faut pas toucher. Mets-le à jour à chaque fin de session.` |
| 31 | « on continue dans cette conversation » | **« *anti context rot* : fais-moi une synthèse de notre travail dans un fichier, puis je relance une conversation propre »** | Évite la dégradation des réponses sur les longs contextes. | `Cette conversation devient longue. Fais-moi une synthèse de 20 lignes (décisions prises, état du code, prochaines étapes) dans `journal-session.md`. Je relancerai une nouvelle conversation à partir de ce fichier.` |
| 32 | « génère une image (liste de mots-clés) » | **« décris l'image *comme un cinéaste raconterait une scène* — contexte, histoire, émotion, lumière, focus, position des personnages ; ≤ 80 mots »** | Sort du « award-winning, 4k, 8k » ; image avec intention. | `Pour le diagramme d'archi de notre doc : décris-le comme une scène — un service au premier plan, net ; les dépendances en arrière-plan, floues ; flux de données en lignes lumineuses ; style blueprint technique, fond bleu nuit. ≤ 60 mots.` |
| 33 | « décris-moi un style d'image » | **« *JSON prompting* : décompose le style photographique en JSON (composition, lighting, color_tone, subject, mood, technical) — non genré, indépendant des caractéristiques physiques »** | Style encodé, réutilisable, modifiable. | `Décompose en JSON le style visuel de notre identité de marque (à partir de ce moodboard) : composition, lighting, color_palette, mood, technique. Puis applique ce JSON pour générer 3 illustrations de couverture d'article.` |
| 34 | « réfléchis comme un photographe » | **« pose-toi 3 questions que se poserait [Annie Leibovitz / un grand photographe], réponds-y, puis génère le prompt/JSON »** | Délégation cognitive cadrée par une expertise. | `Avant de générer l'illustration de cet article, pose-toi 3 questions que se poserait un grand directeur artistique éditorial (le sujet ? l'émotion ? le détail qui accroche l'œil ?). Réponds, puis génère le prompt.` |
| 35 | « structure tes données » | **« réponds en *JSON* / convertis en *Markdown* / structure en YAML »** | Permet aux automatisations (et aux agents) de décomposer et réutiliser. | `Renvoie l'analyse de ces logs en JSON : [{timestamp, level, service, error_type, count, sample_message}]. Pas de texte libre autour.` |
| 36 | « explique simplement / ne saute aucune zone d'ombre » | **« explique de façon claire et fluide, *sans perdre en précision*, exemples concrets, *ne laisse aucune zone d'ombre* »** | Bride la tendance à survoler. | `Explique-moi ce bug de concurrence : clair, fluide, sans perdre en précision, avec un exemple concret de timeline d'exécution, et ne laisse aucune zone d'ombre sur le verrou manquant.` |
| 37 | « décompose le problème » | **« *segmente* : 7 étapes — définir / lister / cartographier les causes-effets / … / sélectionner 2-3 segments offrant une progression logique »** | Découpage explicite plutôt qu'imitation d'un style d'expert. | `Pour rédiger le post-mortem, segmente : (1) faits, (2) timeline, (3) cartographie causes→effets, (4) facteurs contributifs, (5) sélectionne les 3 causes racines qui offrent une progression logique, (6) actions, (7) ce qu'on a appris.` |

---


---

# 14. BOÎTE À TOKENS — génération d'images

> Catalogue de « mots‑graines » par catégorie, tiré du corpus (prompts Midjourney/Dall‑E/Flux verbatim). À assembler en « mille‑feuilles » : *charpente → détails essentiels → couches de style*. Penser en couches empilées (« boîboîtes ») : `[type d'image] + [sujet/personnage] + [détails] + [décor] + [lumière] + [pose] + [pellicule/appareil] + [style/mouvement] + [palette]`.

**1. Type / nature de l'image** : `documentary photo`, `fine art photography`, `editorial fashion shot`, `photojournalistic portrait`, `contemporary Japanese street photography`, `candid street photography`, `studio photo close portrait`, `illustration`, `oil painting`, `watercolor painting`, `cartoon`, `drawing`, `vector`, `render`, `blueprint`, `surreal realism`, `1920s black and white documentary feel`, `Instagram story-style photo`, `cinematic moment`.

**2. Cadrage / composition** : `close-up portrait`, `intimate framing`, `closely cropped`, `three-quarter shot with environmental context`, `shallow depth of field`, `subtle bokeh`, `slightly off-axis framing`, `slightly low angle perspective`, `slightly elevated angle`, `leading lines converging towards the subject`, `asymmetrical balance`, `negative space`, `subject in the foreground / man slightly behind, creating a sense of depth`, `the friend on the left / in the middle / on the right`, `at the foreground / in the background`, `dynamic framing adding a sense of spontaneous movement`, `minimalist composition`.

**3. Lumière / ambiance lumineuse** : `soft natural lighting`, `gentle skin tones`, `golden hour / late afternoon sun / tungsten glow`, `morning light / pale morning light`, `key light entering from a side window`, `soft diffused light`, `ethereal haze`, `backlighting`, `overexposure`, `dramatic high-contrast / moody lighting (film noir)`, `deep blacks, high contrast and prominent grain`, `fluorescent store light`, `warm tones of dark beige and light amber`, `intimate vibe`, `melancholic blue of early morning`, `expressive shadows`.

**4. Pellicule / appareil photo** : `Kodak Portra 400 / 160`, `Kodak Tri-X 400 (black and white)`, `Kodak Gold 400`, `Kodak Ektar 400`, `Kodak Ektachrome E100 (slide)`, `Cinestill 50D (50 ISO)`, `Cinestill 800T (800 ISO)`, `Ilford HP5 Plus 400 (B&W)`, `Ilford Delta 3200 (B&W)`, `Fujifilm Superia X-TRA 400`, `Fujifilm Velvia 50 (slide)`, `Fujifilm Provia 100F (slide)`, `Lomography Color Negative 100`, `Lomography Potsdam Kino B&W 100`, `Rollei Retro 400S`, `pushed film`, `medium format photography` ; appareils : `Hasselblad X1D`, `Sigma sd Quattro H`, `Canon AE-1`, `Leica D-Lux 8`, `shot on smartphone (with smartphone reflection in the eyes)`.

**5. Style / mouvement / artiste** *(avec mise en garde : emprunter un style d'artiste ≠ image qui te ressemble ; et Dall‑E refuse les artistes < 100 ans)* : `in the classic Black and White Film Noir style`, `shot by Annie Leibovitz`, `shot by David Lachapelle`, `in the style of Rinko Kawauchi`, `bohemian chic editorial with cinematic depth`, `contemporary Japanese street photography`, `inspired by photojournalistic portraits`, `evokes a deep emotional narrative through grayscale nuances`, `reminiscent of a poignant documentary moment`, `Broken Rules`, `--style raw`, `--profile [code moodboard perso]`.

**6. Émotion / « punctum » (le détail qui « perce »)** : `bittersweet expression, staring pensively into the camera`, `face etched by life experiences`, `pensively melancholic, distant gaze, aura of wisdom beyond her years`, `vulnerable strength illuminating the scene`, `quiet power and dignity`, `unfiltered joy / wide and sparkling eyes / subtle smile`, `mix of regret and defiance`, `eyes filled with regret meeting his, hurt brown ones` ; détails‑punctum : `a crumpled handwritten letter`, `a small symbolic exchanged object`, `glasses still half-full from the night's revelries`, `a star-shaped birthmark near her left eye`, `a surprised cat with sleek black fur, bright yellow eyes`, `bad teeth of a child` (William Klein), `nails that are anything but clean` (Tzara, via Barthes).

**7. Palette / couleurs** : `Colors: shades of grey`, `rich black and white tones, high contrast`, `soft whites, pearl grey, pale gold`, `muted colors of blue and gray`, `melancholic blue of early morning`, `warm tones of dark beige and light amber`, `ruby red, teal, orange, and black color palette`, `warm earthy browns, ochre, terracotta / secondary: muted teal, burgundy, cream`, `vibrant with luminous colors`, `monochrome / black and white to capture the timeless cinematic feel of the 1940s and 1950s`.

**8. Défauts / réalisme** : `film grain, dust and scratches`, `subtle vintage lens aberrations`, `slight imperfections in skin texture and lighting`, `visible skin imperfections and details like wrinkles and scars`, `a slight wrinkle on the forehead`, `slightly disheveled hair`, `tear-streaked makeup`, `subtle motion blur`, `slightly out of focus / sharply in focus` (jeu de mise au point), `print slightly faded and worn, suggesting the passage of time`, `authentic details`, `print-like / film-like treatment, emphasis on texture and warmth`.

**9. Paramètres Midjourney (en fin de prompt)** : `--ar 16:9 / 4:3 / 21:29` (ratio) · `--style raw` (rendu photo) · `--stylize 0 … 1000` / `--s` (force du style MJ ; 0 = adhérence max au prompt) · `--chaos 0…100` (variété) · `--no [élément]` (négatif) · `--q 0.25/0.5/1` (qualité/temps) · `--seed [0…4294967295]` (reproductibilité de variations) · `--weird 0…3000` / `--w` · `--sref [URL] --sw 0…1000` (style d'une image) · `--cref [URL] --cw 0…100` (personnage ; 0 = visage seul) · `--iw 0…3` (poids d'une image guide) · `--tile` (motif répétable) · `--niji 5/6` (anime) · `--v 6` (version) · `--relax / --fast / --turbo` · `--r 1…40` (relance) · `--stop 10…100` (arrêter la diffusion — paréidolie) · commandes `/imagine`, `/describe`, `/blend`, `/profile`.

**Exemples verbatim (à imiter/adapter)** :
- *Portrait éditorial expressif* : `Uplifting portrait of an authentically smiling woman in a male-dominated environment. Her vulnerable strength illuminating the scene, genuine grin contrasting with reserved masculine expressions, convergent gazes expressing curiosity and respect, central feminine presence federating the group, soft warm tones emanating from the subject. Fine Art photography. Broken Rules. Gentle diffused light creating an atmosphere of understanding and benevolence, harmonious composition celebrating the power of embraced femininity. Shot by Annie Leibovitz with Hasselblad X1D. Colors: shades of grey.`
- *Photo « réelle » Dall‑E 3* : `A documentary photo captures a woman in the middle of a crowded supermarket, concentrating on her shopping list. … Natural light filters through the large windows … The photo has a slight grain, reminiscent of Kodak Portra 400 film, and captures authentic details such as a slight wrinkle on the forehead, emphasizing the realism of the moment. The dynamic framing adds a sense of spontaneous movement.`
- *Scène cinématographique Midjourney 6* : `Viewed from the side of the bed are a man and a woman. On the left side of the frame in the middle ground is a man, black, laying on his back and smoking as he looks with side-eye at the woman. … warm tones of dark beige and light amber creating an intimate vibe. The woman is in the foreground and the man is slightly behind her, creating a sense of depth. A cinematic moment captured on cinestill 50d film --ar 16:9 --style raw --v 6`
- *Bloc JSON de style* : voir l'Annexe, fiche #14 (deux blocs JSON complets : « portrait noir et blanc high‑contrast » et « bohemian‑inspired cinematic »).

---


---

# CHECKLIST OPÉRATIONNELLE


### (a) Toute conversation avec une IA générative

- [ ] **Cadrage 30 s** : objectif, contexte, livrable, format. Sinon, je clarifie (ou je laisse l'IA me poser des questions et je valide le plan avant qu'elle n'exécute).
- [ ] **Un seul sujet par conversation.** Au‑delà de ~20 échanges (ou quand les réponses se dégradent : *context rot*), je demande une synthèse écrite dans un fichier et je relance une conversation propre.
- [ ] **Fournir le contexte / les documents** : pour les faits, je m'appuie sur ma bibliothèque (notes, sources, transcripts), pas sur la « connaissance » du modèle. Documents entre balises `<document>…</document>` ou `"""…"""`.
- [ ] **Convoquer des concepts, des penseurs, un vocabulaire précis** (cf. THÉSAURUS, §11) : les « graines sémantiques » déverrouillent des architectures de pensée que le modèle ne produit pas spontanément. Viser l'**élévation** (qualité/originalité), pas le **baratin** (volume).
- [ ] **Faire poser des questions avant d'exécuter** + valider le plan. Pour une tâche complexe : « D'abord, lis mes fichiers. Ensuite, pose-moi des questions. Puis propose plusieurs approches. »
- [ ] **Vérifier à CHAQUE étape**, pas seulement à la fin. Si c'est trop long pour être vérifié, c'est trop long → découper en 10 petites itérations plutôt qu'une grosse génération.
- [ ] **Moins d'étapes IA.** La solution n'est presque jamais « une meilleure IA » mais « moins d'étapes » et « plus de vérification » (les erreurs se propagent en cascade ; biais du milieu sur les longs textes).
- [ ] **Distinguer Fait / Déduction / Opinion** dans ce que je lis ET dans ce que je demande. Demander au modèle de le faire explicitement (mais de façon fluide).
- [ ] **Anti‑flagornerie + devil's advocate** : « Propose une analyse critique de ta réponse » ; « Défends maintenant la position inverse » ; instruction système « pas de flagornerie, esprit critique ».
- [ ] **Données sensibles** : ne rien coller que je ne mettrais pas sur une carte postale. Anonymiser ; éviter les modèles en ligne non‑RGPD ; vérifier qui stocke quoi (et si la pub entre dans le modèle économique, mes données suivent).
- [ ] **Relire la sortie.** Ne jamais accepter sans relecture. L'apparente perfection est un piège (« s'endormir au volant » : plus l'IA paraît puissante, moins on est vigilant, plus le taux d'erreur monte).
- [ ] **Zones de danger connues** : citations/références scientifiques, dates, chiffres précis, personnes/faits peu connus, événements postérieurs à la date d'entraînement, lecture d'URL, lecture de graphiques/tableaux dans des PDF, calculs, raisonnement multi‑sources, documents longs.
- [ ] **Clôture** : angles morts, prochaines étapes, questions ouvertes.

### (b) Spécifique au code / à Claude Code (et agents équivalents)

- [ ] **Explorer l'existant AVANT d'écrire** : « Peux-tu explorer mes fichiers et me dire ce que tu y trouves ? »
- [ ] **Mini‑plan validé** avant le moindre code. Refuser de « foncer ».
- [ ] **`CLAUDE.md` à jour ou créé** : un fichier à la racine (et un par sous‑dossier de travail) qui explique l'état du projet et à quoi sert le dossier. « Mets à jour ta mémoire / le `CLAUDE.md` » en fin de session — c'est la mémoire persistante entre conversations (l'agent « repart de zéro » sinon).
- [ ] **Tout en Markdown.** Éviter PDF/Word ; convertir en `.md` (l'agent scanne les `.md` plus vite ; le code/Markdown structuré ne tolère pas l'à‑peu‑près).
- [ ] **Conversations courtes + « jardinage »** : refactorer/nettoyer régulièrement les dossiers (« Fais une revue de ce dossier et propose-moi des améliorations pour le nettoyer et l'organiser »).
- [ ] **Périmètre d'accès minimal** : ne pas donner accès à tout l'ordinateur (l'agent supprime *vraiment* les fichiers). Attention au **« lethal trifecta »** (Simon Willison) : agent + accès à des données privées + exposition à du contenu non fiable + capacité de communiquer vers l'extérieur = risque d'injection de prompt / exfiltration. L'extension navigateur est l'outil le plus exposé.
- [ ] **Vérifier les failles des skills/fichiers importés** : « Quand tu importes un fichier, surtout une skill, demande toujours à Claude d'analyser les failles » (instructions cachées possibles).
- [ ] **Coût** : « Claude Code consomme beaucoup de tokens. » Pro pour explorer, Max pour l'usage pro quotidien.
- [ ] **Devil's advocate sur les décisions d'archi** : « Demandons-lui de défendre le contraire. »
- [ ] **Construire progressivement** : un modèle, un ou deux outils, trois étapes max ; vérifier chaque sortie avant d'augmenter la complexité ; placer le *human‑in‑the‑loop* là où le risque est le plus grand.


---

# 16. TEMPLATES DE PROMPTS prêts à l'emploi

> Adaptés au domaine *tech / produit / dev*. Remplace `[…]`. Chaque template combine plusieurs « graines » du THÉSAURUS.

### T1 — Analyse de document (extraction + Gestalt + steelman)
```
Voici un document : <document>
[COLLE ICI : design doc / RFC / spec / rapport]
</document>

1. Fais-moi une EXTRACTION détaillée : tous les éléments porteurs d'information (décisions, chiffres, contraintes, hypothèses, dépendances, exemples) — préserve les formulations exactes, ne lisse pas.
2. Propose une vision GESTALT du document : le schéma d'ensemble, les motifs récurrents, les tensions internes, ce qui est dit vs ce qui est tu ("Le texte ne précise pas…").
3. Choisis 5 penseurs/experts dont tu maîtrises les cadres en profondeur (privilégie les auteurs abondamment documentés). Pour chacun : SUBSUME l'analyse à travers sa grille.
4. STEELMAN la thèse centrale du document, puis STEELMAN la position inverse. Dis laquelle est la plus solide et pourquoi.
5. Termine par : angles morts / ce qui manque, et 3 questions ouvertes pour moi.
Pas de flagornerie. Distingue toujours fait / déduction / opinion, de manière fluide.
```

### T2 — Dialogue engineering : faire de l'IA un partenaire de réflexion
```
On va travailler par strates (dialogue engineering) : d'abord je cartographie le terrain, ensuite je poserai ma vraie question.

Sujet : [SUJET].

Étape 1 — Avant tout : il y a certainement des auteurs/experts qui ont pensé la manière d'aborder ce type de problème. Cite-m'en 5, avec leurs cadres. Cite au moins deux références scientifiques, philosophiques ou littéraires.
Étape 2 — Comment [PENSEUR A] / [PENSEUR B] aborderaient-ils cette question ? Subsume.
Étape 3 — Ma vraie question : [QUESTION]. Réponds, puis propose une analyse critique de ta réponse (anti-flagornerie). Propose une alternative radicale.
Étape 4 — Utilisons la phase 4 de Polya : qu'avons-nous appris dans cet échange, qu'est-ce qui resterait à creuser ?
Règles : pas de flagornerie, esprit critique systématique. Un seul sujet. Si la conversation s'allonge, propose une synthèse écrite de 20 lignes.
```

**Exemple Rails (instanciation)** :
```
Sujet : "Quand introduire des Service Objects dans un codebase Rails — et quand ne pas le faire ?"

Étape 1 — Avant tout : il y a certainement des auteurs/experts qui ont pensé cette question (design objet en Ruby/Rails, "Anemic Domain Model", concerns vs services, "Tell Don't Ask", "fat model / skinny controller"). Cite-m'en 5, avec leurs cadres. Cite au moins deux références scientifiques, philosophiques ou littéraires (pas seulement des billets de blog).
Étape 2 — Comment Sandi Metz (POODR — "Practical Object-Oriented Design") et Martin Fowler ("Refactoring", concept "Anemic Domain Model") aborderaient-ils cette question ? Subsume l'analyse à travers chaque grille.
Étape 3 — Ma vraie question : "Dans notre codebase Rails 7 de ~80 modèles, je veux extraire la logique de checkout (paiement + stock + facturation + notification) qui s'est accumulée dans `Order#process!` (220 lignes, méthode d'instance, dépendances tentaculaires). Faut-il créer un Service Object `CheckoutProcessor` (PORO `call`-able), un `ActiveSupport::Concern` mixé dans `Order`, un module Ruby pur dans `lib/checkout/`, ou rester dans le modèle et n'extraire que des objets-valeur ?" Réponds, puis propose une analyse critique de ta réponse (anti-flagornerie). Propose une alternative radicale (par ex. : on garde `Order#process!`, on extrait seulement les invariants en `Value Objects` immuables, et on n'introduit aucune nouvelle couche).
Étape 4 — Utilisons la phase 4 de Polya : qu'avons-nous appris dans cet échange, qu'est-ce qui resterait à creuser (transactions, rollback, idempotence, retry, tests d'intégration vs unitaires des services) ?
Règles : pas de flagornerie, esprit critique systématique. Un seul sujet. Si la conversation s'allonge, propose une synthèse écrite de 20 lignes dans `journal-session.md`.
```

### T3 — Écriture sans clichés (annonce / doc / article technique)
```
Rédige [TYPE DE TEXTE : release notes / post de blog / annonce / doc] sur : [SUJET / NOTES].

Hiérarchie : Fond → Structure → Style (non négociable).
Structure (Concept Engineering — WSJ/Kabob) : Anecdote/cas concret (zoom in) → Nut Graf (zoom out : pourquoi ça compte) → Corps (preuves, chiffres) → Kicker (chute qui revient au cas du début ou ouvre sur la suite).
Ingénierie de l'attention : un hook irrésistible plutôt qu'un titre ; ouvre une boucle au § 1 que tu ne refermes qu'à la fin (Open Loop).
Contraintes anti-lissage :
- Génère d'abord les 20 clichés les plus courants sur ce sujet, puis n'en utilise AUCUN.
- Interdis : "dans un monde", "à l'ère de", "crucial", "captivant", "il est essentiel/impératif", "n'hésitez pas à", "en conclusion".
- Évite les constructions antithétiques "ce n'est pas X – c'est Y".
- Remplace systématiquement les tirets quadratins par un point ou une virgule.
- Concret brutal (Orwell) : aucune métaphore qu'on a l'habitude de voir imprimée ; coupe tout mot inutile ; préfère le mot court.
- Distingue fait / déduction de manière fluide.
Commence par le premier paragraphe (3 phrases max), attends ma validation, puis déroule.
```

**Exemple Rails (instanciation)** :
```
Rédige les **release notes internes** (public : devs + ops) pour : on migre nos jobs async de **Sidekiq** vers **Solid Queue** (Rails 8).

Notes brutes (à structurer, pas à recopier en l'état) : on supprime Redis comme dépendance dédiée aux jobs ; un seul Postgres pour les données et les jobs ; intégration native Rails 8. Risques : Solid Queue est plus jeune que Sidekiq ; on perd `batches` et le rate limiting de Sidekiq Pro ; les jobs critiques (envoi de factures, débit, notifications transactionnelles) migrés en dernier après 30 jours de monitoring sur les jobs non critiques. Métriques actuelles : ~12 M de jobs/mois, p99 de latence Sidekiq = 1,8 s, 4 workers Sidekiq, 2 instances Redis (1 cache + 1 jobs). Plan de rollback : feature flag par queue, retour Sidekiq possible en 30 min via redeploy. Date de bascule (queues non critiques) prévue : début du sprint S+3. Incident contextuel : 14 janvier, perte Redis 22 min → tous les jobs bloqués, 4800 mails de confirmation décalés.

Hiérarchie : Fond → Structure → Style (non négociable).
Structure (Concept Engineering — WSJ/Kabob) : ouvre sur l'incident Redis du 14 janvier (Anecdote/zoom in) → Nut Graf (pourquoi on bouge maintenant, en quoi c'est plus large que l'incident) → Corps (étapes, métriques, risques, plan de rollback, feature flags) → Kicker (où va le temps gagné, ou un point ouvert pour les feedbacks de l'équipe).
Ingénierie de l'attention : un hook irrésistible plutôt qu'un titre ; Open Loop au § 1 fermée seulement au § final.
Contraintes anti-lissage :
- Génère d'abord les 20 clichés typiques d'une release note dev ("nous sommes ravis d'annoncer", "expérience utilisateur fluide", "passage à l'échelle", "améliorée pour vous offrir", "stack moderne"…), puis n'en utilise AUCUN.
- Interdis : "il est crucial / important de noter", "n'hésitez pas à", "tout simplement", "à l'ère de", "en conclusion".
- Évite "ce n'est pas X – c'est Y" et les hyperboles de révélation.
- Remplace systématiquement les tirets quadratins (« — ») par un point ou une virgule.
- Concret brutal (Orwell) : aucune métaphore qu'on a déjà lue dix fois ; coupe tout mot inutile ; préfère le mot court.
- Distingue **fait** (mesuré : "p99 = 1,8 s", "12 M jobs/mois") / **déduction** ("on s'attend à une baisse d'environ 30 % de la latence p99 — à vérifier") / **opinion** ("je trouve l'API plus claire") de manière fluide.
Commence par le premier paragraphe (3 phrases max), attends ma validation, puis déroule.
```

### T4 — Recherche approfondie (agent de recherche)
```
Rôle : agent de recherche et d'analyse approfondie.
1. Présente-toi brièvement et liste les sources auxquelles tu as réellement accès (web, mes documents, ta connaissance — avec sa date limite).
2. Avant chaque action, applique le Chain of Thought : commence par "Raisonnement:" (en gras), texte du raisonnement en italique.
3. Identifie les informations clés nécessaires pour comprendre en profondeur : [SUJET].
4. Formule 4 questions de recherche, dont les réponses doivent permettre de recueillir des informations CONTRADICTOIRES pour équilibrer le résultat. Ajoute systématiquement une 5e question pour aller chercher des infos pouvant contredire les précédentes. Demande-moi de valider chaque question.
5. Recherche question par question ; si les résultats ne sont pas satisfaisants, reformule. Privilégie les sources fiables et les infos récentes.
6. Synthétise par question, avec les URL des sources. Présente un récapitulatif dense.
Porte de sortie : si une donnée n'existe pas, dis-le explicitement — ne la déduis pas. Pour les listes factuelles simples, demande-les-moi avant de chercher. À la fin : ce qui reste incertain + ce qu'il faudrait vérifier humainement.
```

### T5 — Critique steelman (revue de décision)
```
Décision/proposition à examiner : [DÉCISION — ex. "migrer vers les microservices" / "adopter [techno X]" / "réécrire le module Y"].
Contexte : [CONTEXTE — équipe, échelle, contraintes].

1. STEELMAN cette décision : la version la plus solide, telle que la défendrait son meilleur avocat (prémisses les plus fortes, pas l'épouvantail).
2. STEELMAN la décision INVERSE (statu quo / alternative), avec la même rigueur.
3. Convoque les plus grands experts en [domaines pertinents : architecture, SRE, sécurité, produit] : à travers leurs prismes, propose une revue critique des deux options — où chacun tiquerait.
4. Liste les hypothèses implicites, les modes de défaillance, les "unknown unknowns".
5. Recommandation argumentée + conditions sous lesquelles elle s'inverserait.
Pas de flagornerie. Devil's advocate obligatoire à l'étape 2.
```

**Exemple Rails (instanciation)** :
```
Décision/proposition à examiner : "Migrer notre back-office admin de la stack actuelle (Next.js séparé + API Rails) vers **Hotwire (Turbo + Stimulus) dans le monolithe Rails**."

Contexte : équipe de 5 devs, ratio 60 % Rails / 40 % React. Admin utilisé par ~200 utilisateurs internes (jamais de pic, jamais de besoin temps réel), ~40 écrans CRUD + 5 dashboards (graphiques Chart.js). La maintenance du frontend Next.js (build, types, SSR, déploiement séparé, drift de versions npm, double système de routes) prend ~30 % du temps de l'équipe pour ~10 % de la valeur livrée mesurée. Le back-office API expose ~120 endpoints dont 90 % ne servent qu'au back-office. Rails 7.1 (Hotwire natif), Postgres, Sidekiq. Pas de besoin offline. Bande passante des utilisateurs : très bonne (intranet). 3 devs juniors arrivés il y a 6 mois, formés React mais pas Rails.

1. STEELMAN cette décision : la version la plus solide, telle que la défendrait son meilleur avocat — la productivité de l'équipe est le KPI prioritaire ; Hotwire couvre 95 % des besoins d'un back-office CRUD ; supprimer la duplication API/UI ; redéploiement unique ; le recrutement et la formation se simplifient ("Ruby full stack" est un seul rôle).
2. STEELMAN la décision INVERSE (garder Next.js + API) : couplage faible (l'API peut servir un futur "admin client externe"), l'équipe a déjà l'expertise React, écosystème de composants UI plus riche, les 3 juniors viennent du JS, le coût de migration peut excéder le coût de maintenance actuel.
3. Convoque les plus grands experts en architecture web, productivité d'équipe, et UX admin (DHH sur les "majestic monoliths" ; Martin Fowler sur les "modular monoliths" ; les retours publics de Basecamp, GitHub, Shopify sur Hotwire dans leur back-office ; Adam Wathan / TailwindCSS sur la productivité front) : à travers leurs prismes, propose une revue critique des deux options — où chacun tiquerait.
4. Liste les hypothèses implicites (la productivité ressentie reflète la productivité réelle ? le coût de la migration est-il chiffré en jours-homme par écran ? que devient l'usage de Chart.js / des libs React tierces côté Stimulus ? a-t-on un futur "admin externe client" dans le pipeline produit ?), les modes de défaillance (rétrocompatibilité des bookmarks d'URL admin, formation des 3 juniors, dépendances React qui n'ont pas d'équivalent Stimulus, perte de SSR si on rebascule un jour), les "unknown unknowns".
5. Recommandation argumentée + conditions sous lesquelles elle s'inverserait (ex. : si un projet "admin externe client" se profile dans les 12 mois, recommandation inversée ; si la migration estimée > 6 mois calendaires, recommandation inversée ou découpée par écran).
Pas de flagornerie. Devil's advocate obligatoire à l'étape 2.
```

### T6 — Génération d'image (intention + JSON de style)
```
Je veux une illustration pour [USAGE : couverture d'article / diagramme / hero image].
Idée : [IDÉE].

Avant de générer le prompt :
1. Pose-toi 3 questions que se poserait un grand directeur artistique éditorial : Quel est le cœur du message / l'émotion ? Quel détail "punctum" pourrait accrocher l'œil de manière inattendue ? Quel rendu (lumière, médium, palette) servirait le sens ?
2. Réponds à ces questions.
3. Décompose le style en JSON (composition, lighting, color_palette, mood, technical) — non genré, indépendant des caractéristiques physiques.
4. Rédige le prompt final en anglais (≤ 80 mots), comme un cinéaste décrivant une scène : sujet/personnages, position dans le cadre, détail-punctum, type d'image, lumière, pellicule/appareil, palette. Termine par "--ar 16:9 --style raw --v 6" si Midjourney.
Ne génère pas l'image, donne-moi juste le JSON et le prompt.
```

### T7 — Refacto / feature code (avec Claude Code)
```
NE COMMENCE PAS À CODER.

Objectif : [FEATURE / REFACTO].
1. Explore le repo : dis-moi ce que tu y trouves (structure, conventions, points sensibles, tests existants).
2. Pose-moi 10 questions par blocs de 4 (périmètre, contraintes, compat, perf/SLO, stratégie de test, risques de régression). Attends mes réponses.
3. Propose 2-3 approches avec leurs trade-offs. Pour l'approche que tu recommandes : fais le devil's advocate (défends l'approche inverse).
4. Une fois l'approche validée par moi : écris/mets à jour le CLAUDE.md (conventions, commandes build/test/lint, ce qui est en cours, ce qu'il ne faut pas toucher), PUIS un mini-plan en étapes vérifiables.
5. Implémente UNE étape à la fois ; après chaque étape, montre le diff et les tests, attends ma validation.
Rappels : tout en Markdown ; conversations courtes (si ça s'allonge, synthèse dans journal-session.md) ; ne touche pas aux fichiers hors périmètre.
```

### T8 — Démarrage / reprise de session d'agent (anti context rot, mémoire persistante)
```
[DÉMARRAGE] Crée un fichier CLAUDE.md à la racine : à quoi sert ce dossier, l'état actuel du projet, les conventions, les commandes utiles, ce qui est en cours, ce qu'il ne faut pas toucher. Puis crée (si besoin) une arborescence Notes / Projets / Publications, tout en .md. Pour chaque sous-dossier, un CLAUDE.md qui dit à quoi il sert.

[REPRISE] Reprenons notre travail sur [DOSSIER]. Lis le CLAUDE.md et journal-session.md. Résume où on en est, ce qu'on a appris, ce qu'il reste à faire. Puis on continue : [TÂCHE].

[CLÔTURE] Fais-moi une synthèse de notre travail (20 lignes max : décisions, état du code, prochaines étapes) dans journal-session.md. Mets à jour le CLAUDE.md. Fais une revue de ce dossier et propose des améliorations pour le nettoyer et l'organiser (refactoring = jardinage).
```

### T9 — Revue de Pull Request
```
Tu es un relecteur de code senior, exigeant mais constructif. Pas de flagornerie.

Contexte du projet : [stack, conventions — ou : "lis le CLAUDE.md d'abord"].
Voici la PR : <diff>
[COLLE LE DIFF]
</diff>
Description de la PR : [DESCRIPTION / lien ticket].

1. Résume en 3 lignes ce que fait cette PR (ta compréhension), et signale tout écart avec la description.
2. Revue par couches : (a) correctness / cas limites non gérés / régressions possibles ; (b) sécurité (entrées non validées, secrets, injection, autorisations, lethal trifecta si ça touche un agent) ; (c) tests (couverture des chemins critiques, tests qui manquent) ; (d) lisibilité / nommage / conventions du projet ; (e) perf / complexité si pertinent ; (f) dette ajoutée vs dette résolue.
3. Pour chaque remarque : sévérité (bloquant / important / nit), fichier:ligne, et la correction suggérée (extrait de code si utile).
4. Devil's advocate : y a-t-il une raison légitime de NE PAS faire ces changements ? Le périmètre de la PR est-il trop large ?
5. Verdict : approuver / approuver sous conditions (liste) / demander des changements (liste priorisée).
Distingue fait (le code fait X) / déduction (ça pourrait causer Y) / opinion (je préférerais Z).
```

### T10 — Post-mortem d'incident
```
On va écrire le post-mortem d'un incident. Sans recherche de coupable (blameless).

Faits bruts : [TIMELINE BRUTE / logs / messages — colle tout en vrac, "mode bourré" : ne te censure pas].

Procède en segments (ne saute aucune étape, montre ton raisonnement) :
1. FAITS : reconstitue la chronologie précise (UTC), distingue strictement ce qui est attesté de ce qui est déduit ("le texte ne précise pas…").
2. IMPACT : qui/quoi a été affecté, ampleur, durée (MTTD / MTTR).
3. CARTOGRAPHIE causes → effets : remonte des symptômes aux causes racines (anabasis) ; distingue cause racine, facteurs contributifs, causes latentes.
4. CE QUI A BIEN MARCHÉ : détection, mitigation, communication — ne liste pas que le négatif.
5. ACTIONS : pour chaque cause racine et chaque facteur contributif, une action correctrice (avec : owner suggéré, type — préventif/détectif/réducteur d'impact —, et un critère de "fait").
6. CE QU'ON A APPRIS : 3 enseignements transférables.
7. Devil's advocate : quelle action de cette liste risque de créer un nouveau problème ?
Style : concret brutal, pas de "il est crucial de noter que", pas d'hyperboles, distingue fait/déduction de manière fluide.
```

### T11 — Documentation d'API
```
Rédige la doc de cette API. Public cible : un développeur intégrateur qui découvre l'API ("profane éduqué" du domaine — clair, précis, aucune zone d'ombre).

Source de vérité (n'invente rien hors de ça) : <source>
[COLLE : spec OpenAPI / code des handlers / exemples de requêtes-réponses]
</source>

Pour chaque endpoint : méthode + chemin ; à quoi il sert (1 phrase) ; auth requise ; paramètres (nom, type, requis/optionnel, contraintes, défaut) ; corps de requête (schéma + exemple) ; réponses (codes, schéma, exemple) ; codes d'erreur avec leur signification et la marche à suivre ; limites de rate / pagination / idempotence ; effets de bord notables.
Ajoute : un "Quickstart" en 5 lignes (auth → premier appel → premier résultat) ; les pièges connus ; un changelog vide à remplir.
Porte de sortie : si une info n'est pas dans la source, écris "[à documenter — non spécifié dans la source]" — ne devine pas. Pas de phrases préfabriquées ("n'hésitez pas à", "tout simplement", "il est important de noter que").
À la fin : liste les incohérences ou ambiguïtés que tu as repérées dans la source.
```

### T12 — Tri / qualification de tickets (issues)
```
Tu vas qualifier des tickets. Réponds UNIQUEMENT en JSON (pas de texte autour).

Contexte du projet : [domaine, composants principaux, équipes].
Rubrique de tri : type ∈ {bug, feature, question, tech-debt, security, docs, duplicate, invalid} ; sévérité ∈ {S1-critique, S2-majeur, S3-mineur, S4-trivial} (S1 = sécurité/perte de données/indispo prod) ; priorité ∈ {P0, P1, P2, P3} ; composant probable ∈ [LISTE] ; effort estimé ∈ {S, M, L, XL} ; besoin d'infos ∈ {oui, non}.

Pour chaque ticket, renvoie :
{ "id": "...", "type": "...", "severite": "...", "priorite": "...", "composant": "...", "effort": "...", "besoin_infos": "...", "questions_a_poser": ["..."], "doublon_possible_de": "id ou null", "indices_securite": "oui/non + lesquels", "justification": "1-2 phrases" }

Règles : si tu n'es pas sûr du composant, mets "?" et ajoute une question. Tout indice de faille de sécurité → type=security, sévérité ≥ S2, et signale-le explicitement. Ne ferme rien automatiquement ; "invalid"/"duplicate" sont des suggestions, jamais des décisions.

Tickets : <tickets>
[COLLE LES TICKETS — un par bloc]
</tickets>
```

### T13 — Génération de tests
```
NE MODIFIE PAS LA *LOGIQUE* DE PRODUCTION. Écris des tests. Exception : tu peux ajouter un attribut `data-testid` sur un élément de vue quand c'est le moyen le plus fiable de le cibler — c'est préférable à un sélecteur fragile (CSS/XPath/`title=`/`data-action`) ou à un helper qui contourne un markup non ciblable. But : les tests les plus stables possible. Ces attributs sont inertes (aucun effet sur le comportement) ; signale-les. Toute autre modif de prod (logique, correction de bug) reste signalée sans être appliquée (point 5).

Code à tester : <code>
[COLLE LE MODULE / LA FONCTION]
</code>
Framework de test du projet : [pytest / jest / vitest / JUnit / ... — ou : "lis le CLAUDE.md"]. Conventions : [emplacement des tests, fixtures, mocks, naming].

1. D'abord (Chain of Thought, "Raisonnement:" en gras) : liste le contrat de chaque fonction publique (préconditions, postconditions, invariants), les chemins (happy path, erreurs, cas limites : vide / null / zéro / négatif / très grand / unicode / concurrence / timeout / dépendance qui échoue), et les effets de bord à isoler.
2. Propose la matrice de tests (table : cas → entrée → sortie/effet attendu → priorité). Attends ma validation si la liste est longue ; sinon poursuis.
3. Écris les tests : nommage descriptif, arrange/act/assert clairs, un comportement par test, mocks minimaux et explicites, pas de logique dans les tests, pas de dépendance à l'ordre d'exécution.
4. Signale les cas que tu n'as PAS pu couvrir et pourquoi (ex. "nécessiterait de refactorer pour injecter la dépendance X" — proposition de refacto séparée, à valider, pas appliquée ici).
5. Signale tout bug du code de production découvert en écrivant les tests (sans le corriger) : fichier:ligne + scénario qui le déclenche.
Porte de sortie : si le comportement attendu d'un cas n'est pas spécifié et pas déductible, écris un test marqué `xfail`/`skip` avec un commentaire "comportement à clarifier" — ne devine pas le résultat attendu.
```

> **Plus de templates** : la version « kit » de ces 13 templates (sans le reste de ce document) est dans `./kit-prompting.md`, plus rapide à charger en conversation de travail.

---
