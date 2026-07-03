# Fiches — page 1 (articles 1 à 12)

### 1. 2026-05-10 — Comment j'ai appris le design avec Claude Code
**URL** : https://generationia.flint.media/p/apprendre-le-design-avec-ia-claude-code
**Tags** : agents-code | workflows-context-engineering | mindset-culture
**Type** : retour-d'expérience

- **Idée centrale** : Plutôt que de déléguer une tâche à l'IA (Claude Design), il faut l'utiliser comme compagnon pédagogique pour *apprendre* une compétence — ici le design graphique. Le potentiel le plus sous-estimé de l'IA n'est pas l'automatisation mais l'apprentissage accéléré par l'itération ultra-rapide. Critique au passage : les outils spécialisés fragmentent le travail ; un agent polyvalent personnalisé (Claude Code) crée un système durable où l'on capitalise.
- **Techniques de prompting / méthode** :
  - "Dialogue Engineering" : construire la conversation progressivement, du large vers le resserré, avant la question finale ("comme une cathédrale par connexions").
  - Instructions de cadrage systématiques des réponses (cf. prompt verbatim ci-dessous : 2 références scientifiques/littéraires/philo, pistes critiques, synthèse finale).
  - Documentation progressive : faire écrire des fichiers .md (CLAUDE.md, fichier méthode, glossaire) au fil de la conversation = mémoire persistante.
  - Reprise de session en pointant le dossier d'apprentissage ("Reprenons notre travail sur le dossier design").
  - "Convoquer des experts avant de répondre" ; "Qu'est-ce qu'on a raté ?".
  - "Mots-graines" : ex. "analyse Gestalt des verbatims" — "Le mot Gestalt est l'un de ces mots-graines qui changent la profondeur d'une analyse par l'IA."
  - Copier pour comprendre : importer DESIGN.md / HTML / skills d'autres designers et les faire analyser.
  - Vérif sécurité : "Quand tu importes un fichier, surtout une skill, demande toujours à Claude d'analyser les failles."
  - Demander à l'IA de ralentir : expliquer les principes (psychologie des couleurs, lisibilité typo) AVANT de montrer les pages.
- **Prompts cités VERBATIM** :
  > « Comment faire une charte graphique ? »

  > « Je veux apprendre le design graphique. Quels sont les plus grands experts qui ont réfléchi à la question du design et qu'ont-ils dit ? Fais l'archéologie du concept. Dis-moi tout ce que tu sais. »

  > « À partir de maintenant, dans chacune de tes réponses, inclus au moins deux références scientifiques, littéraires ou philosophiques. Propose-moi systématiquement plusieurs pistes critiques. Termine par une synthèse concise et facile à comprendre. Explorons... [SUJET] »

  > « Génération IA est un média-école francophone dédié à la maîtrise de l'IA générative, à distance de la hype, nous proposons une newsletter éditoriale et des formations. »

  > « Je veux un site élégant et premium, plutôt avec du bleu mais pas trop flashy, et puis une belle place au texte pour pas faire trop marketing. »

  > « Crée un fichier CLAUDE.md à la racine qui explique de manière concise que c'est mon espace d'exploration et de travail. Puis crée un dossier design destiné à l'exploration et à l'expérimentation, avec un CLAUDE.md dans ce dossier qui dit à quoi il sert. »

  > « Peux-tu mettre cette explication dans un fichier ? »

  > « Crée-moi un fichier méthode pas-à-pas pour créer une charte graphique, avec le glossaire des termes techniques à connaître pour discuter avec un pro. »

  > « Mets à jour le CLAUDE.md pour qu'on puisse reprendre la prochaine fois. »

  > « Reprenons notre travail sur le dossier design. »

  > « Aide-moi à créer une charte graphique pour ma marque. Suis les méthodes qu'on a explorées et pose-moi les bonnes questions. »

  > « Je voudrais quelque chose de premium. »

  > « Qu'est-ce qu'on a raté ? Convoque des experts avant de répondre. »

  > « Explique-moi d'abord ce qui rend une typo lisible. »

  > « Honnêtement, j'aime le saumon des pages roses du Financial Times. Mais c'est un goût personnel. Qu'est-ce qu'elles font psychologiquement, les couleurs ? »

  > « Analyse-moi ce dossier » ; « Génère des pages fictives en combinant ces fichiers »
- **Outils / produits + usage** : Claude Code → agent IA compagnon pédagogique (philosophe, gère fichiers, code HTML affiché instantanément). Claude Desktop → app pour ouvrir Claude Code dans ses dossiers locaux. Claude Design → génère des maquettes mais renvoie du "statistiquement correct". Stitch (Google) → équivalent de Claude Design. ChatGPT/Codex → alternatives sans abo Claude (Codex = même principe que Claude Code). DESIGN.md (Google Labs, publié 21 avril) → format structurant lisible humains+agents pour piloter une charte. Aura (aura.build, Meng To) → DESIGN.md + templates HTML/REACT + skills. Greg Isenberg → vidéo où Meng To explique le pilotage de Claude Code pour le design.
- **Chiffres / études / personnes citées** : Stanislas Dehaene (neuroscientifique, citation sur l'erreur dans l'algorithme d'apprentissage : « Quand on s'arrête de faire des erreurs, cela ne signifie pas que l'on a tout compris mais que l'on a cessé d'apprendre »). Massimo Vignelli (mots → typo → couleurs). Beatrice Warde (1932 ; typo « comme un verre de cristal au service du vin »). Goethe (« Traité des couleurs », 1810). Michel Pastoureau. Eva Heller (effet émotionnel des couleurs étudié sur « deux mille personnes »). Robin Williams (« The Non-Designer's Design Book »). 8000 verbatims de sondages injectés ; 7 profils d'audience extraits ; 4 types de « premium » (héritage, artisanal, minimaliste, intellectuel) ; note de 315 lignes sur la psychologie des couleurs ; charte graphique créée en ~6 heures (non continu) ; polices retenues : Newsreader (titres) + Inter (corps) ; bootcamp IA personnelle démarrant début juin.
- **Angle critique / limite** : Sans expertise de ta part, l'IA renvoie du « statistiquement correct » (comparé au post LinkedIn rempli d'emojis et de formules creuses). La mémoire des agents n'est jamais « infinie » : principe de « découvrabilité progressive », à toi de structurer le dossier. Le design ne s'apprend pas en six heures. Le vrai sujet : « apprendre à parler design avec l'IA », pas le design tout court. Claude Cowork jugé « une perte de temps ». Avertissement skills/fichiers importés (instructions cachées). Mise en garde personnelle : perfectionnisme + lancement de trop de projets → épuisement.
- **État d'esprit / méthode (ce que l'auteur en dit)** : « Apprends-moi à faire avec toi » plutôt que « fais à ma place ». L'erreur est centrale à l'apprentissage. Itérer ultra-vite (HTML affiché instantanément = des centaines d'hypothèses testées). Documenter pour mémoriser (MON-ESPACE + CLAUDE.md + DESIGN.md). Reprendre le contrôle contre la fragmentation : investir dans un seul système. Syncrétisme créatif (combiner DESIGN.md + Aura + skills + sa charte). Posture « vivons dangereusement » assumée malgré le syndrome de l'imposteur.
- **Accès** : OK

---

### 2. 2026-04-19 — As-tu déjà prompté en "mode bourré" ?
**URL** : https://generationia.flint.media/p/ecrire-ia-sans-perdre-singularite-prompt-transcript
**Tags** : prompting | comment-pense-LLM | mindset-culture
**Type** : article-méthode

- **Idée centrale** : Les LLM convergent statistiquement vers une médiocrité moyenne (régression vers la moyenne, minimisation de la « cross-entropy loss »). Pour préserver sa singularité, il faut injecter sa pensée brute non filtrée — le « mode bourré » : parole enregistrée à l'oral ou tapée sans relecture. Deux mécanismes combattus : (a) le lissage statistique structurel, (b) l'autocensure qui frappe à l'écrit mais pas à l'oral. « Le fond conditionne la forme. Le fond, c'est d'abord notre façon de penser. »
- **Techniques de prompting / méthode** :
  - Méthode « geste / matière » : le « geste » = parole brute (oral ou frappe sans relecture) qui dicte le flot ; la « matière » = document de travail fact-checké (faits, références, données, méthodes) ; fusionner les deux + règles de style/structure → l'IA reconstruit.
  - « Le mode bourré seul ne suffit pas » → doit être ancré dans une matière fact-checkée (sinon risque d'inexactitude/invention).
  - « Analyse Gestalt » appliquée à interviews ou idées éparpillées pour détecter sens caché/commun.
  - « Connexion rationnelle » : améliorer la qualité des enchaînements logiques entre paragraphes.
  - Vocabulaire précis : « subsume » au lieu d'« analyse », « gestalt » au lieu de « vue d'ensemble », « anabasis » au lieu de « prendre de la hauteur ».
- **Prompts cités VERBATIM** :
  ```
  Peux tu me faire une analyse Gestalt de [ce texte, cette conversation...] ?
  ```
  ```
  Ameliore la connexion rationnelle de ce texte.
  ```
  ```
  Je dois configurer le theme de mes presentations Gamma. Voici mon identité visuelle et le fichier de mon logo. Peux tu m'aider à remplir chaque étape de la configuration ?
  ```
- **Outils / produits + usage** : ChatGPT → icône micro pour transcrire la voix (« meilleur » selon l'auteur). Claude / Claude Opus 4.7 → LLM principal ; Opus 4.7 spécialisé vision, configuré via extension Chrome pour remplir les formulaires Gamma. Gemini → icône micro de transcription. Flow (wisprflow.ai) → transcription vocale vers chat, rapide mais chère, meilleure en anglais. Stenow (stenow.lovable.app) → app créée par l'auteur avec Lovable, transcription intelligente avec référentiel personnalisé, gratuit jusqu'à 20 min/mois ; pour capturer « la pensée brute avant qu'elle ne se censure à l'écrit ». Gamma (gamma.app) → création de présentations/documents personnalisables. Lovable → IA de code, Stenow construit en < 1 h. Extension Chrome « Claude ». Nanobanana Pro / Nanobanana 2 → génération d'images.
- **Chiffres / études / personnes citées** : Francis Galton (1886, « régression vers la moyenne »). Claude Shannon (1948, théorie de l'information). Étude « Artificial Hivemind » (2025) : sans stimulation forte, les réponses IA convergent. Freud (« Études sur l'hystérie », 1895 ; association libre). Olivier Sibony & Eric Hazan, « Faut-il encore décider ? La décision humaine à l'ère de l'intelligence artificielle » (2026) ; Sibony co-auteur de « Noise » avec Kahneman. « Depuis 1954, algorithmes décident souvent mieux que nous ». 42 500 lecteurs ; « 80 % de notre temps consacré à l'exploration et l'expérimentation ». Réductions jusqu'à -80 % pour étudiants/chômeurs.
- **Angle critique / limite** : Jouer sur la « température » du modèle ne règle rien : « elle mélange les cartes, mais le jeu a déjà été distribué » — le problème est structurel. Le mode bourré seul → risque d'invention factuelle. Via Sibony & Hazan : l'IA se trompe aussi, reproduit les biais, reste opaque, dérive quand les données manquent ; certaines décisions doivent rester humaines (« justice pénale, fin de vie, guerre, art, amour »), d'autres en copilotage (« médecine, recrutement »), rares pleinement délégables. Réponse à un lecteur (Jean-Marc) sur le modèle économique : « Je ne crois pas au tout gratuit : soit tu es le produit, soit la valeur a un prix. »
- **État d'esprit / méthode (ce que l'auteur en dit)** : « Nous ne sommes pas des systèmes statistiques. Chacun reste terrain singulier. » L'IA est formidable pour connecter et structurer les idées, « mais elle ne peut pas inventer à notre place ». Posture collaborative non délégative, exploratoire (80 % du temps), itérative (rédaction → génération IA → retravail), fact-checking en amont. Préférence pour l'oral (moins de censure, « Freud l'avait pressenti »).
- **Accès** : OK

---

### 3. 2026-04-12 — La compétence la plus sous-évaluée pour maîtriser l'IA en 2026
**URL** : https://generationia.flint.media/p/la-competence-la-plus-sous-evaluee-pour-maitriser-l-ia-en-2026-second-cerveau-prompt
**Tags** : prompting | comment-pense-LLM | mindset-culture
**Type** : article-méthode

- **Idée centrale** : La compétence la plus sous-évaluée pour maîtriser l'IA en 2026, c'est la *précision lexicale*. Les mots précis sont des « graines sémantiques » : ils contiennent « de la puissance sémantique compressée » et déverrouillent chez l'IA des architectures de pensée qu'elle ne produirait jamais spontanément. Viser « l'élévation » (qualité et originalité de pensée) plutôt que la productivité brute (« le baratin »). « L'IA ne sait pas qu'elle sait, il faut l'accompagner. »
- **Techniques de prompting / méthode** :
  - Extraction (plutôt que « résumé/analyse/synthétise ») : « Analyse ce document, fais-moi une extraction détaillée. »
  - Vision Gestalt : utiliser le mot « Gestalt » pour extraire le schéma invisible.
  - Subsuming (« subsume ») : prendre de la hauteur en gardant la logique interne et en la réinjectant dans une nouvelle syntaxe.
  - Steelmanning : faire chercher à l'IA le noyau rationnel d'un argument, la version qu'en défendrait « son meilleur avocat ».
  - Hypostasiation : traiter une abstraction comme un agent autonome avec intentions et contraintes propres.
  - Anabasis conceptuelle : remonter des faits bruts vers les principes qui les gouvernent.
  - Injection de penseurs de référence + ajout de références (« cite au moins deux références scientifiques, philosophiques ou littéraires »).
  - Métaphore du jardin : stocker et annoter les « récoltes » des conversations pour les replanter comme graines.
- **Prompts cités VERBATIM** :
  ```
  Comment cultiver l'expertise humaine et l'esprit critique au travail à l'ère de l'intelligence artificielle ?
  ```
  ```
  Analyse ce document, fais-moi une extraction détaillée.
  ```
  ```
  Propose une vision Gestalt de ce document.
  ```
  ```
  Maintenant, choisis 10 penseurs fondamentaux dont tu maîtrises les cadres théoriques en profondeur. Leur pensée doit permettre d'analyser ce document au prisme de grilles conceptuelles solides. Couvre un maximum de domaines (philosophie, sciences, littérature, socio-économie, ingénierie), dont au moins cinq sur la dimension RH et management. Privilégie les penseurs dont les travaux sont abondamment documentés plutôt que les experts contemporains récents.
  ```
  ```
  Explorons Peter Drucker sur ce document. Subsume l'analyse.
  ```
  ```
  Dans tes prochaines réponses, cite au moins deux références scientifiques, philosophiques ou littéraires.
  ```
  ```
  Explorons la question de la responsabilité du management comme fonction sociale.
  ```
  ```
  "ChatGPT est plus intelligent que moi". Steelman cet argument.
  ```
  ```
  Propose-moi des alternatives au mot que je vais te donner, qui désignent chacune une action ou un concept plus spécifique. Inclus :
  — au moins 15 termes français (courants, soutenus ou techniques),
  — des mots empruntés à d'autres langues qui n'ont pas d'équivalent exact en français,
  — des termes qui condensent un maximum de sens en un seul mot.
  N'hésite pas à inclure des termes rares, savants ou philosophiques (ex. : subsumer, hypostasier…).
  Pour chaque terme, indique sa langue d'origine, explique en une phrase ce qu'il apporte de différent par rapport au mot donné, et donne un exemple d'utilisation concrète en le remplaçant dans une instruction ou un prompt.
  Voici le mot : [MOT]
  ```
  ```
  Hypostasie le transhumanisme dans son ensemble et décris-le comme un agent autonome : quelles seraient ses intentions et ses contraintes propres ?
  ```
- **Outils / produits + usage** : Claude → modèle des exemples de conversation. Claude Code → générateur d'images pour l'illustration. Thésaurus du prompting → outil interactif codé par l'auteur (taper un mot → alternatives plus précises avec langue d'origine + exemple de prompt). NotebookLM (Google) → injecter des documents, interroger, générer podcasts/infographies/vidéos. Student Spaces (Adobe) → concurrent de NotebookLM configuré pour l'apprentissage (programme avec objectif et date butoir). Formation « Dialoguer avec l'IA » (+80 vidéos de 10 min, mise à jour avec sections Claude Cowork et NotebookLM). Génération IA Entreprise (programme en présentiel/distanciel). Bootcamp « second cerveau IA » (agent IA + base de connaissance personnelle ; +900 inscrits).
- **Chiffres / études / personnes citées** : Peter Drucker (« travailleur du savoir », 1959). 10 penseurs suggérés par l'IA dont Karl Marx, Joseph Schumpeter, Michel Foucault, Amartya Sen, Simone Weil. Émile Durkheim (« solidarité organique »). Gaston Bachelard (« La Poétique de l'espace »). Jacques Attali (« l'intelligence n'est pas un don, c'est un chantier » ; QI = flux, stock = lectures/notes/expériences ; « une machine rapide sans carburant »). Étude « Artificial Hive Mind » (2025, arxiv.org/abs/2510.22954) : sans stimulation, les réponses IA convergent. Terence Tao (médaille Fields). Bootcamp : +900 inscrits. Rapport sur l'IA et le travail en 2026 : 15 pages (téléchargeable, 257.61 KB).
- **Angle critique / limite** : Critique de Frédérique (lectrice) : risque que le message soit uniquement « gains de productivité du modèle actuel » alors qu'il faudrait accompagner l'évolution du *rôle* ; beaucoup de « prétendus experts formateurs IA » motivés par le profit rapide. Risque de monoculture cognitive (étude 2025). « La productivité est illusoire si l'IA ne fait qu'accélérer le travail de mauvaise qualité. » « Si tu ne le fais pas [cultiver ton stock], l'IA te renvoie toujours les mêmes plantes. Le même baratin. »
- **État d'esprit / méthode (ce que l'auteur en dit)** : Curiosité plutôt que peur. Non-conformisme sélectif : « concentre-toi d'abord sur l'expérimentation de tes propres cas d'usage, sans chercher à répliquer toutes les nouveautés ». Partenariat complémentaire (humain = sens et aspérités ; IA = puissance de connexion). Cultiver l'intelligence comme un jardin qui grandit dans le temps. Élévation > productivité brute.
- **Accès** : OK

---

### 4. 2026-04-05 — Peut-on encore savoir si c'est de l'IA ?
**URL** : https://generationia.flint.media/p/peut-on-encore-savoir-si-c-est-de-l-ia-higgsfield-deepfake
**Tags** : ethique-securite-sobriete-biais | images-video-audio | actu
**Type** : décryptage

- **Idée centrale** : La question « peut-on encore savoir si c'est de l'IA ? » devient obsolète : « uncanny convergence » — les vrais visages retouchés (Botox, filtres) convergent esthétiquement avec les avatars IA, rendant la distinction impossible. Au-delà de la détection technique, l'enjeu réel est de comprendre les processus et les risques du « workslop » en entreprise. L'auteur enquête sur un compte Instagram suspect (@bbh.psychocriminologue) sans pouvoir trancher, puis « prend le problème à l'envers » en testant lui-même Higgsfield.
- **Techniques de prompting / méthode** : — aucune technique de prompting détaillée ; l'auteur décrit ses démarches d'investigation (passer des photos dans des détecteurs, explorer des plateformes de génération).
- **Prompts cités VERBATIM** : — aucun prompt verbatim.
- **Outils / produits + usage** : Media Whisperer → plateforme néerlandaise croisant plusieurs détecteurs IA d'images (utilisée par la BBC). GPTZero → détecteur de texte généré par IA. Higgsfield → génération vidéo IA (clonage de voix, voix synthétiques, avatars, face-swap, lip-sync, modification vidéo ; modèle vidéo Seedance 2.0, chinois). Higgsfield Original Series (première série « Arena Zero »). Higgsfield Soul → avatar vidéo optimisé depuis photos perso avec « AI glow ». Suno → musique/chant IA (voix propre ou démos hybrides). Distrokid → distribution musicale multi-plateformes. Gemini (Google) → alternative à ChatGPT (analyse/génération d'images mais données stockées/utilisées pour l'entraînement). Claude → dialogue de qualité ; Claude Cowork / Claude Code → connexion de générateurs d'images via MCP.
- **Chiffres / études / personnes citées** : BetterUp Labs & Stanford (septembre 2025), étude « workslop » : 186 $/mois/personne de productivité perdue ; 9 millions $/an pour une organisation de 10 000 employés. Deezer : 97 % des gens incapables de différencier une chanson IA d'une chanson humaine. Ethan Mollick (prof associé Wharton, auteur « Co-Intelligence: Vivre et travailler avec l'IA », cité via The Economist du 1er avril 2026 ; « recevoir un artefact extraterrestre et s'en servir comme presse-papiers » ; « l'IA n'est pas un outil, c'est un collaborateur bizarre »). @bbh.psychocriminologue : compte Instagram, 18 000 abonnés, analyses comportementales à 180 euros via WhatsApp/vocaux, paiement PayPal, départ du compte le 4 avril 2026. Detsouvan Soum : a formé 12 000 personnes, responsable « Génération IA Entreprise ». 90 % des collaborateurs utilisent l'IA chaque semaine (chiffre type d'un déploiement standardisé). Date de l'article : 5 avril 2026.
- **Angle critique / limite** : Les détecteurs produisent faux positifs et faux négatifs ; les filtres lourds (grain, N&B, effet vieux film) masquent les défauts de texture typiques de l'IA ; un face-swap sur vraie photo peut tromper. « Workslop » : contenu IA qui passe pour du bon travail mais manque de substance ; l'expéditeur croit gagner du temps, le destinataire en perd. Banaliser l'IA comme « outil logiciel » = « erreur fatale ». Gemini : confidentialité compromise (données Google même en payant), perte d'historique si désactivation.
- **État d'esprit / méthode (ce que l'auteur en dit)** : Curiosité exploratoire et acceptation de l'indécidabilité (« Je suis incapable de lui répondre »). Inversion du problème : tester soi-même ce qu'on peut produire. Valeur pédagogique de l'exploration (« quand on sait ce qui est possible, on regarde autrement »). « L'outil est important, mais les personnes aux commandes encore plus. » Méfiance envers la banalisation : l'IA demande une approche spécifique, pas un déploiement standardisé.
- **Accès** : OK

---

### 5. 2026-04-04 — Le jour où Claude Code à sauvé mon voyage
**URL** : https://generationia.flint.media/p/le-jour-ou-claude-code-a-sauve-mon-voyage-brain-fry
**Tags** : agents-code | mindset-culture | ethique-securite-sobriete-biais
**Type** : retour-d'expérience

- **Idée centrale** : Émergence des « applications jetables » : chacun peut créer rapidement des outils informatiques pour des besoins ponctuels via les agents IA, sans connaissances techniques. Mais cela introduit une fatigue cognitive nouvelle, le « Brain Fry » : l'IA qui *remplace* le travail pénible réduit le burnout ; l'IA qui *ajoute* de la supervision épuise — la distinction est dans l'usage, pas dans l'outil.
- **Techniques de prompting / méthode** : Onglet « CODE » de Claude Desktop pour les tâches de programmation. Faire poser des questions ciblées par Claude *avant* d'agir, puis valider le plan. Utiliser le transcrit vocal (Stenow) comme input pour des réponses orales. Conversion de formats (SVG → PNG). « Devil's advocate » : « demandons-lui de défendre le contraire » pour contrer la complaisance de l'IA.
- **Prompts cités VERBATIM** :
  > « Je veux construire un tracker d'avions en temps réel. Explore les solutions existantes : APIs de données de vol (gratuites et payantes), bibliothèques de visualisation cartographique, outils open-source, et MCPs disponibles. Puis pose-moi des questions ciblées pour définir : périmètre géographique, type d'interface, données à afficher, usage prévu, et contraintes techniques. »

  > « Je voudrais créer un logo pour ma marque. Convoque 5 génies du design de logo, puis 5 techniques de design de logo. Puis pose moi 10 questions pour definir mes besoins. »
- **Outils / produits + usage** : Claude Code / Claude Desktop → coder, créer applications et logos (en SVG) sans expertise. Claude Cowork → supervision de tâches multiples. Stenow → transcription vocale parole→texte. SVG → format vectoriel pour le logo via code. ChatGPT / Gemini → savent générer des images (contrairement à Claude qui code en SVG). N8N, NotebookLM → mentionnés (bootcamp / mini-formation envisagée). Etihad → compagnie aérienne, cas d'usage.
- **Chiffres / études / personnes citées** : Étude Harvard Business Review « When Using AI Leads to 'Brain Fry' » (mars 2026) : +14 % d'effort mental avec supervision IA intensive ; +12 % de fatigue mentale ; +19 % de surcharge informationnelle ; +39 % d'erreurs majeures chez les victimes du brain fry ; +11 % d'erreurs mineures ; -15 % de burnout si l'IA remplace les tâches répétitives. Concept « Brain Fry » via Laura Bokobza (newsletter LBK Consulting) : brouillard mental, difficultés de concentration, ralentissement décisionnel. Andrej Karpathy (ex-OpenAI) sur la capacité de l'IA à défendre n'importe quelle position. 745 inscrits liste d'attente bootcamp « Agents IA & second cerveau ». 10 minutes pour créer le tracker de vols ; 5 minutes pour le dashboard complet. Témoignages : Patrick (dissonance cognitive), Mariana (Claude crée « une toute nouvelle séquence dynamique, cohérente »). Changement de format éditorial : carnets de route (courts, hebdo) + dossiers complets (mensuels, longs), car perfectionnisme = délai de 3-4 semaines.
- **Angle critique / limite** : Brain Fry réel : ≥4 fenêtres ouvertes = « 4 fenêtres ouvertes dans mon cerveau » ; « Je n'ai jamais autant travaillé » ; risque +39 % d'erreurs majeures. L'IA est « redoutablement efficace pour défendre à peu près n'importe quelle position » → rester vigilant face à la complaisance, tester les contraires. Limite : Claude ne génère pas d'images directement (workaround SVG→PNG). Témoignage Patrick : « fatigué de parler à une machine, déconnecté ».
- **État d'esprit / méthode (ce que l'auteur en dit)** : « On n'a jamais autant appris. » Démarche exploratoire, validation de plan avant exécution. Productivité ET effort mental augmentent → « il faut repenser notre façon de travailler ». Multi-tasking involontaire (« on finit par lancer 4 ou 5 opérations en même temps »). Besoin de systématiser un « second cerveau » (d'où le bootcamp).
- **Accès** : OK

---

### 6. 2026-03-22 — Comment remplacer ChatGPT par Claude (et pourquoi)
**URL** : https://generationia.flint.media/p/comment-remplacer-chatgpt-par-claude-le-guide-2026-anthropic-agents-ia
**Tags** : outils-panorama | agents-code | workflows-context-engineering
**Type** : tutoriel

- **Idée centrale** : Claude et l'écosystème Anthropic sont devenus le nouveau standard de l'IA générative, surtout pour les agents IA (la « deuxième vague »). Anthropic a créé les standards industriels (MCP, architectures agentiques), offre un modèle économique plus durable (29 % du marché entreprise vs 2,1 % du trafic web), et les agents marquent une rupture avec les chatbots. Structure de l'article : Comprendre → Pratiquer → Penser → Participer.
- **Techniques de prompting / méthode** :
  - Structuration intentionnelle de la mémoire : créer une synthèse de 20 lignes plutôt que 200 mémoires (anti « context rot »).
  - Fichiers de référence organisés (journal-session.md, contexte de travail) comme « prompt » pour l'agent.
  - Prompt minimal avec Cowork : donner d'abord accès aux fichiers, puis laisser l'agent poser les questions.
  - Raccourcis dans Claude in Chrome : préfixer d'un slash (ex. `/liremail`) avec prompt réutilisable.
  - Mode « Réflexion étendue » dans les paramètres (forcer Claude à réfléchir avant de répondre).
  - Demander à l'IA de créer ses propres skills.
- **Prompts cités VERBATIM** :
  ```
  Je déménage vers un autre service et j'ai besoin d'exporter mes données.
  Liste toutes les mémoires que tu as enregistrées sur moi, ainsi que tout le contexte que tu as appris de nos conversations passées. Affiche tout dans un seul bloc de code pour que je puisse facilement le copier.

  Formate chaque entrée ainsi : [date d'enregistrement, si disponible] – contenu de la mémoire.

  Couvre impérativement tous les points suivants, en préservant mes mots exacts quand c'est possible :
  - Les instructions que je t'ai données sur la façon de répondre (ton, format, style, "fais toujours X", "ne fais jamais Y")
  - Mes données personnelles : nom, localisation, métier, famille, centres d'intérêt
  - Mes projets, objectifs et sujets récurrents
  - Les outils, langages et frameworks que j'utilise
  - Les préférences et corrections que j'ai apportées à ton comportement
  - Tout autre contexte stocké non couvert ci-dessus

  Ne résume pas, ne regroupe pas, n'omets aucune entrée.
  Après le bloc de code, confirme si c'est l'ensemble complet ou s'il en reste.
  ```
  ```
  Je veux [TÂCHE + OBJECTIF]. D'abord, lis les fichiers de mon dossier. Ensuite, pose-moi des questions avant d'exécuter.
  ```
  ```
  Peux-tu créer un skill qui te permettra de faire une veille à partir des newsletters d'infos que je reçois sur mon mail ? Pose moi des questions pour comprendre ce que je veux faire et comment je veux le faire, puis propose mois plusieurs approches avant de créer le skill.
  ```
  ```
  Crée un graphique sur [sujet].
  ```
- **Outils / produits + usage** : Claude (Anthropic) → modèle central. ChatGPT (OpenAI) / Gemini (Google) → concurrents. Claude Chat → chatbot basique. Claude Code → agent pour programmation/automatisations. Claude Cowork → agent collaboratif lisant/écrivant des fichiers locaux ; Dispatch → extension mobile de Cowork pour tâches à distance. Claude in Chrome → extension navigateur. MCP (Model Context Protocol) → standard universel IA↔outils. Skills → fichiers prompts + textes + code ; Plugins → ensembles de skills + connecteurs MCP pour un métier. Connecteurs MCP → Slack, Google Drive, Notion, Gmail, +50 autres. Projets → dossiers de conversation persistants. Artifacts → applications interactives codées dans le chat. Réflexion étendue. Suite Microsoft (Excel/PowerPoint/Word) via skill officielle. N8N. Telegram (connexion possible Claude Code). OpenAI API / GPT-5.4 ; Claude Opus 4.6 (réflexion étendue) ; Claude Sonnet 4.6 (recommandé pour Cowork) ; Computer Use (2024, contrôle d'écran expérimental).
- **Chiffres / études / personnes citées** : 2 % des utilisateurs avertis utilisent Claude ; 29 % du marché des assistants IA en entreprise = Anthropic ; ChatGPT 62 % du trafic web (février 2026, Similarweb) ; Claude 2,1 % ; Gemini 22 % (de 6 % à 22 % en un an) ; 1,5 million de désinstallations ChatGPT en une semaine (crise Pentagone) ; Anthropic 1 Md$ de revenus annualisés fin 2024 → 19 Md$ mars 2026 ; OpenAI approche 20 Md$ de revenus, 14 Md$ de pertes prévues en 2026 ; Epoch AI (projection) : Anthropic dépasse OpenAI fin 2026 ; rapport Citrini : réductions d'équipes 30 → 10 personnes ; étude Harvard (62 millions de travailleurs) : -9-10 % d'emploi junior dans les 18 mois suivant l'adoption de l'IA générative ; Meta : plan de licenciements 20 % (Reuters) ; enquête Anthropic (81 000 utilisateurs) : 30 % trouvent que l'IA leur a permis d'apprendre plus, 8 % que l'IA a atrophié leurs capacités cognitives ; bootcamp n8n : 53 ventes en trois semaines (1000-2500 € chacune) ; 417 inscrits liste d'attente bootcamp second cerveau IA. Dates : 27 février (ultimatum Pentagone), 8 février (lettre Claude Code), 1er mars (lettre Claude Cowork). Personnes : Benoît Raphaël, Thomas Mahier, « Jeff » (agent IA), Sam Altman (scepticisme « IA-washing »), Gaston Bachelard (« La Formation de l'esprit scientifique »), Simon Willison (« lethal trifecta »), Mark Zuckerberg, Jean-Baptiste Berthoux (guide skills), Anne-Cécile Le Dain (développeuse sans code, communauté).
- **Angle critique / limite** : « C'est aussi de la communication » (timing commercial calculé d'Anthropic ; pub Super Bowl « pas de pubs » = marketing). GPT-5.4 jugé par « pas mal de développeurs » meilleur codeur qu'Opus 4.6 ; Gemini supérieur grand public avec distribution « imbattable ». Nuancer les coupes d'emploi (« IA-washing » selon Altman). « Lethal Trifecta » (Simon Willison) : agent + données privées + contenu non fiable + capacité de communiquer vers l'extérieur = risque de prompt injection / exfiltration ; Claude in Chrome = « outil le plus exposé ». Conseils : ne pas donner accès à tous ses fichiers, vérifier les connexions, prudence avec Claude in Chrome, construire progressivement. « Context rot » : plus la mémoire grossit, moins les réponses sont bonnes. Quand la publicité entre dans le jeu (OpenAI), « tes données suivent ».
- **État d'esprit / méthode (ce que l'auteur en dit)** : « J'ai appris en même temps que je lui enseignais » → hybridation bidirectionnelle qui rend le système durable. Créer des fichiers de référence plutôt que de re-prompter ; laisser l'IA écrire ce qu'elle a appris. Passer d'« exécutant » à « orchestrateur » (30 → 10 personnes qui pilotent des IA). « Il faut apprendre à manager ces IA. » Détruire ce qu'on croyait savoir (Bachelard) pour progresser. Vérifier que la techno résout des problèmes réels (exemple du père de 85 ans passant à Cowork en une après-midi). Objectif personnel : libérer du temps pour la recherche et l'écriture, « je veux apprendre » plutôt qu'« être millionnaire ».
- **Accès** : OK

---

### 7. 2026-03-01 — Claude Cowork expliqué à mon père
**URL** : https://generationia.flint.media/p/claude-cowork-ecrire-memoires-avec-ia-guide-complet-2026
**Tags** : agents-code | workflows-context-engineering | mindset-culture
**Type** : tutoriel

- **Idée centrale** : Le passage des chatbots aux agents IA (Claude Cowork) est un changement de paradigme mal compris : l'agent transforme l'interaction Q/R en un véritable espace de travail partagé avec mémoire, capable d'autonomie et de collaboration. Illustration : l'auteur installe Claude Cowork chez son père (85 ans, chirurgien maxillo-facial) pour l'aider à écrire ses mémoires, avec résultats probants. L'IA n'est pas une source de réponses mais une « collaboratrice experte » — métaphore filée de la secrétaire « super myope ».
- **Techniques de prompting / méthode** :
  - Analogie du dictaphone analogique pour expliquer l'agent au père.
  - Tâches simples de classement / conversion / organisation thématique.
  - Questionnement d'expert : faire poser à l'agent des questions de relance pointues sur les manques du corpus.
  - Mémoire : créer un fichier CLAUDE.md par dossier (« post-it qu'on laisse à l'agent ») ; « Mets à jour ta mémoire ».
  - Markdown comme format optimisé pour les agents (`#`, `##`, `**`, `-`).
  - Conversations courtes (l'agent ralentit/se perd quand le contexte s'accumule) ; « refactoring » régulier des dossiers (« c'est du jardinage »).
  - Modèles : Sonnet avec « réflexion approfondie activée » (meilleur rapport qualité/consommation) ; Opus pour tâches complexes ; Haiku pour questions rapides.
- **Prompts cités VERBATIM** :
  > « Imagine ta secrétaire de l'époque, celle à qui tu parlais dans ton dictaphone. Tu lui disais 'classe mes courriers', 'retrouve ma lettre au professeur Untel', 'rédige une réponse dans le même ton'. »

  > « Explore ce dossier et classe les fichiers par catégories dans des sous-dossiers. »

  > « Convertis ces fichiers en Markdown »

  > « Classe ma matière brute par thèmes : Enfance, Carrière, Famille, Amour, Retraite »

  > « Vous mentionnez le professeur Stricker dans trois documents différents mais ne racontez jamais votre première rencontre. Pouvez-vous la décrire ? »

  > « Crée un fichier CLAUDE.md pour ce dossier »

  > « Mets à jour ta mémoire »

  > « Explore mes fichiers et dis-moi ce que tu trouves. »
- **Outils / produits + usage** : Claude Desktop → app pour accéder à Cowork (gratuit, requiert abo Pro 15 €/mois ou Max 90 €/mois). Claude Cowork → agent IA, espace de travail partagé, manipulation autonome de fichiers. Claude Code → autre onglet/agent dans Claude Desktop. Stenow → app web de transcription vocale développée par l'auteur avec Lovable. Lovable → « vibe-coding ». Markdown → format texte pour agents. Obsidian → lecteur Markdown gratuit (recommandé débutants) ; Byword (App Store, simple/élégant) ; Finder + TextEdit ; VS Code (interface technique). NotebookLM Ultra Exporter → extension Chrome (télécharger sources/chats/notes depuis NotebookLM) ; Kortex → alternative plus élaborée. ChatGPT → utilisé initialement par le père.
- **Chiffres / études / personnes citées** : Père : 85 ans, professeur des universités, chirurgien maxillo-facial, l'un des premiers en France en chirurgie assistée par ordinateur, a travaillé avec Michel Serres, a écrit deux livres ; ~20 pages de notes Word « chaotiques » ; ~300 fichiers dans les téléchargements. 41 400 abonnés. Matt Shumer (investisseur) : billet à 83 millions de vues sur LinkedIn (changement de paradigme agents). « Pionniers » de Guillaume Grallet, prix du livre d'Économie 2025 (cite Mark Zuckerberg, Peter Thiel, Sam Altman, Meredith Whittaker, Dario Amodei et sa sœur, Demis Hassabis, Hugging Face). Howard Rheingold cité : « L'intelligence artificielle ne doit pas être perçue comme autonome, mais comme un amplificateur de l'intelligence humaine, un partenaire de réflexion. » Lecteur « Jean », 71 ans. Tarifs : Pro 15 €/mois, Max 90 €/mois.
- **Angle critique / limite** : Nuance les conclusions « alarmistes » de Shumer sur l'emploi. Problème de mémoire des agents (« les chatbots n'en ont pas, ou alors elle est bricolée »). Performances variables (transcription d'écriture au crayon « parfois mieux que mon père lui-même » mais « laborieux »). Conversations longues → l'agent ralentit et se perd. Erreurs à éviter : donner accès à tout son ordinateur ; oublier CLAUDE.md (« l'agent repart de zéro à chaque conversation ») ; tout mettre en vrac (formats multiples ralentissent l'agent) ; conversations trop longues. Critique implicite des « bunkers » des pionniers (Zuckerberg/Thiel/Altman, ranchs fortifiés auto-suffisants « au cas où… »).
- **État d'esprit / méthode (ce que l'auteur en dit)** : Collaboration active et consciente (vs discuter avec un chatbot). Préparer les données (Markdown, distillation, organisation) = « faciliter le travail de son assistant ». Mémoire externalisée (CLAUDE.md). Entretien constant (jardinage, refactoring). Le père « reste aux commandes, l'agent absorbe la mécanique » ; l'IA écrit, l'humain « corrige, ajuste, ou réécrit à la main les passages qui nécessitent plus de personnalité ».
- **Accès** : OK

---

### 8. 2026-02-08 — Mon guide pour faire de Claude Code un agent IA à tout faire
**URL** : https://generationia.flint.media/p/mon-guide-pour-faire-de-claude-code-un-agent-ia-tout-faire-openclaw-cowork-anthropic
**Tags** : agents-code | workflows-context-engineering | mindset-culture
**Type** : tutoriel

- **Idée centrale** : Claude Code (architecture d'agent IA installée sur l'ordinateur, capable de lire/modifier/créer des fichiers) est la vraie disruption de 2026, par opposition aux chatbots passifs. Cette architecture menace les intermédiaires d'information et redéfinit le rapport travail-IA. L'IA n'est pas une « boîte noire magique », c'est une « boîte à outils » faite de briques (prompts, outils, documentation, garde-fous) qu'on assemble. Structure : Comprendre → Pratiquer → Penser.
- **Techniques de prompting / méthode** :
  - Skill qui analyse les transcripts de coaching pour en extraire des « Kernels » (bouts de savoir) redistribués dans les notes.
  - Fichiers `claude.md` à la racine des dossiers de travail = mémoire persistante entre sessions.
  - Nettoyage de base de connaissances : « Fais une revue de ce dossier et propose-moi des améliorations pour le nettoyer et l'organiser. »
  - Gestion du « Context Rot » : interrompre les longues conversations, demander une synthèse écrite, relancer une nouvelle conversation avec contexte reconstruit.
  - Architecture en trois dossiers : Notes / Projets / Publications, tout en Markdown .md (éviter PDF et Word, l'IA scanne .md plus vite).
  - Effet « boule de neige » : « Tu accumules, tu structures, et petit à petit l'agent devient de plus en plus pertinent et singulier. »
- **Prompts cités VERBATIM** :
  > « Peux-tu explorer mes fichiers et me dire ce que tu y trouves ? »

  > « Crée un fichier CLAUDE.md à la racine du dossier pour expliquer l'état de ce projet »

  > « Fais une revue de ce dossier et propose-moi des améliorations pour le nettoyer et l'organiser »

  > « Fais-moi une synthèse de notre travail et mets-la dans un fichier. »

  > « Tiens, est-ce que tu peux me modifier le fichier ? »

  > « Peux tu me créer une application pour afficher ou traiter ces données ? »
- **Outils / produits + usage** : Claude Code → architecture principale d'agent IA (lancée il y a un an par Anthropic). Claude Desktop → app macOS avec onglet « Co-work ». Claude Opus 4.6 → modèle plus puissant (lancé 5 février 2026), « Agent Teams », contexte 1 M tokens. Claude Pro (20 $/mois) / Claude Max (100 $/mois). VS Code → éditeur gratuit recommandé (extension Claude Code via marketplace). Co-work → fonctionnalité de Claude Desktop, 11 plugins métiers (lancés 3 février 2026 : Droit, Finance, Marketing, Gestion de produit, Biomédicale, Support client, Productivité). OpenClaw (Clawd / ClawdBot / MoltBot) → agent autonome de Peter Steinberger, base Claude Code open source, archive « sauvage ». Codex / GPT-5.3-Codex (OpenAI), Gemini CLI (gratuit, beta), Antigravity (Google) → clones de Claude Code. Pi → agent open source plus technique. NotebookLM → exploration de documents « lecture seule ». MCP → connecteurs vers Gmail, Notion, Google Docs, n8n, Nanobanana. GitHub → sauvegarde auto du dossier de travail. Slack / Microsoft 365 / Box → connectables via plugins. Nanobanana Pro → générateur d'images Google via MCP.
- **Chiffres / études / personnes citées** : Peter Steinberger (ingénieur autrichien, créateur d'OpenClaw) : 400 000 lignes de code en 3 mois avec Claude Code, une trentaine de projets, après 3 ans d'absence de la tech. London Stock Exchange Group : -8,5 % en bourse après l'annonce des plugins ; chute « significative » de Pearson, RELX (LexisNexis), Thomson Reuters, Wolters Kluwer. Auteur (Benoit Raphael) : 10 mois d'utilisation de Claude Code ; 500 messages reçus suite au décès de sa mère (janvier 2026). Claude Opus 4.6 : 1 M tokens = ~700 000 mots. 41 172 abonnés. « Context Rot » (lien research.trychroma.com/context-rot) : dégradation de performance quand la charge en tokens augmente. Marie Dollé (« Selfpressionisme », philosophe IA & créativité) citée : « Si l'on veut rester hors d'atteinte de l'automatisation, il faut être dissonant, singulier, imprévisible. » Thomas Mahier ; « Jeff » (agent IA). Dates : 3 février 2026 (plugins + chute en bourse), ~5 février 2026 (Opus 4.6 + Codex), décembre (lettre antérieure NotebookLM).
- **Angle critique / limite** : « Plus d'autonomie = plus d'instabilité. » OpenClaw : rapport risques/résultats « hyper déséquilibré » ; terrain pour « techniciens expérimentés », pas grand public. Expérience perso négative : 5 jours d'OpenClaw, « beaucoup de galères, petites frayeurs, chaos total dans fichiers et 80 € partis en fumée » (« c'est en partie de ma faute »). « Les modèles de langage d'aujourd'hui ne savent pas encore très bien s'autogérer dans la durée. » Coût : Pro (20 $) pour explorer, Max (100 $) pour usage pro quotidien. Erreurs des débutants : accès à tout l'ordinateur (Claude supprime vraiment les fichiers), oublier les claude.md, tout mettre en vrac sans nettoyer, conversations trop longues. « Claude Code consomme beaucoup de tokens ! » (répété).
- **État d'esprit / méthode (ce que l'auteur en dit)** : Reprendre le contrôle : « L'intelligence artificielle n'est pas une boîte noire magique. C'est une boîte à outils. Un système que tu assembles, et chaque pièce a une fonction claire. » Amplification, pas remplacement (Marie Dollé : « le vrai défi n'est pas de se protéger de la machine, mais d'oser ce qu'elle ne peut pas anticiper »). Intention > pureté du geste : « Ce qui fait œuvre, ce n'est pas la nudité du geste, mais la présence de l'intention. » Scepticisme initial surmonté (« super sceptique comme toujours » → après 10 mois, « notre nouveau système a remplacé tous nos autres chatbots »). Agent = collaborateur (« l'IA se crée ses propres outils pour travailler »). Gestion du savoir comme du code. « Second cerveau » : écriture active (pas lecture seule), sauvegarde persistante, accumulation sans reset. Objectif : « remplacer ton chatbot avec ses deux mains gauches à qui tu dois tout réexpliquer à chaque conversation ».
- **Accès** : OK

---

### 9. 2025-12-21 — NotebookLM : le guide complet de l'IA la plus fiable du moment
**URL** : https://generationia.flint.media/p/notebooklm-guide-complet-astuces-2026
**Tags** : outils-panorama | workflows-context-engineering | prompting
**Type** : tutoriel

- **Idée centrale** : NotebookLM est l'outil IA le plus fiable de 2025 car il résout le problème que personne n'avait résolu : faire dialoguer des centaines de sources sans que l'IA n'invente pour combler les trous. Trois piliers : fenêtre de contexte massive (1 M tokens), enracinement aux sources, citations intégrées obligatoires. Vu non comme un « second cerveau » mais comme une « table de travail où tu poses tout ce que tu as lu et noté sur un sujet pour travailler avec ». Structure de l'article : Comprendre → Pratiquer → Participer.
- **Techniques de prompting / méthode** :
  - Instruction personnalisée du notebook (« Configure Notebook ») pour cadrer le comportement du modèle.
  - Fichier README structurant : lister les documents essentiels et demander au modèle d'aller le voir d'abord (cadre solide quand les sources se contredisent).
  - Conversion web → Markdown structuré (jamais de lien web brut).
  - Débat enflammé pour l'aiguisement critique (podcast à deux animateurs en désaccord nuancé).
  - Chatbot socratique : ne jamais donner la réponse directe mais aider à la construire.
  - Personnalisation visuelle via prompt (Studio) en réutilisant un « BRANDBOOK » comme source.
  - Demande d'analyse des lacunes : identifier sources/données manquantes, puis générer un prompt de recherche approfondie (avec « porte de sortie » : si les données n'existent pas, le dire explicitement).
  - Extension Chrome perso : transforme une page web en .md complet, nettoyé, avec métadonnées.
- **Prompts cités VERBATIM** :
  ```
  Lis le document "article-newsletter"
  Quels sont les points que j'ai raté ?
  Comment améliorer cet article avec de meilleurs exemples et une vision plus exhaustive 
  et intéressante pour le lecteur ?
  ```
  ```
  Quel est l'impact carbone d'une requête ChatGPT selon les dernières études ?
  ```
  ```
  Quelles sont les sources et données manquantes qu'il faudrait aller chercher pour répondre 
  de manière exhaustive et nuancée à cette question de l'impact environnemental de l'IA 
  afin d'equilibrer les sources et de montrer la complexité, avec des ordres de grandeur ?
  ```
  ```
  Propose moi un prompt de recherche approfondie pour aller chercher ces infos.
  // Donne une porte de sortie : si ces données n'existent pas, il faut le dire explicitement 
  et ne pas les déduire.
  ```
  ```
  J'ai écrit ce paragraphe. Qu'est-ce que j'ai oublié de mes notes des dix dernières années 
  qui pourrait être pertinent ?
  ```
  ```
  Un débat enflammé et de haut niveau entre deux animateurs qui ne sont ABSOLUMENT PAS d'accord 
  sur le sujet. Chaque animateur choisit son camp et déconstruir l'argument de l'autre.
  Mais pour l'auditeur, au final, cela lui permet de bien comprendre le problème avec ses pour, 
  ses contre, ses ordres de grandeur, et sa complexité.
  ```
  ```
  Fais une présentation sur [ANGLE DE TA PRÉSENTATION]. 
  Crée un design tableau noir vert foncé avec du texte écrit à la main à la craie — blanc, 
  jaune et rose.
  ```
  ```
  Fais une présentation sur [ANGLE DE TA PRÉSENTATION]. 
  Utilise le BRANDBOOK pour le design.
  ```
  ```
  Fais-moi des slides beaucoup plus belles. Thème : Design épuré avec fond blanc. 
  Visualise les chiffres du deck de plusieurs façons différentes en les ancrant au monde réel. 
  Utilise un style infographie avec des données percutantes et inspirantes.
  ```
  ```
  Crée un récapitulatif sur le thème de [THEME] de toutes les pâtisseries des photos. 
  Appuie-toi sur les recettes de la note
  ```
- **Outils / produits + usage** : NotebookLM → charge des documents, dialogue, génère podcasts/présentations/rapports/cartes mentales/flashcards/quizzes/tableaux. Gemini (Gemini 3) → modèle pilotant NotebookLM (source grounding, contexte 1 M tokens). Claude / ChatGPT (GPT-4o) / Perplexity → concurrents cités pour comparaison. Google Labs → créateur de NotebookLM, a recruté Steven Johnson. NanobanaPro → modèle d'images Google permettant les présentations illustrées. Gamma.app → inspiration de designs. Codia.ai → éditer les présentations générées (seule limitation identifiée). Extension Chrome perso → web → .md. Google Docs / Google Slides → formats sources acceptés (Slides réutilisable pour branding). Markdown (.md) → format préféré pour les sources web.
- **Chiffres / études / personnes citées** : Étude académique 2024 (arxiv.org/abs/2410.10869), diagnostic cancer du poumon : NotebookLM 86 % de précision vs GPT-4o 39 % (25 % sans accès aux sources) ; 95 % de précision dans la localisation des références ; 25 millions de mots de stockage total ; 1 M tokens = ~750 000 mots ≈ 1 500 pages. Steven Johnson : auteur de douze livres sur l'innovation, créateur conceptuel de NotebookLM chez Google Labs, théoricien de l'« Adjacent Possible », a chargé 8 000 citations compilées depuis la fin des années 90. Kevin Dunbar (les percées scientifiques surviennent en réunion de labo). Stuart Kauffman (biologiste, concept « Adjacent Possible »). 39 700 abonnés. Auteur : ~100 sources sur l'impact écologique de l'IA, 50 nouvelles sources scientifiques via recherche approfondie, ~500 pages compilées sur 2 ans, 30 heures de rédaction initiale, 40 sources, présentation de 10 slides. Podcasts auto-générés viraux : septembre 2024 ; Gemini chez Google : mai 2024. Article académique arxiv.org/abs/2504.09720 (« prof socratique ») ; recherche Chroma (« context rot ») ; article Medium de Kombib (erreurs sur documents juridiques). Date de l'article : 21 décembre 2025.
- **Angle critique / limite** : Le « context rot » est le principal problème : plus les documents sont longs/nombreux, plus les performances se dégradent ; même avec 1 M tokens, le modèle peut (rarement) rater des infos essentielles et produire des réponses fausses — « particulièrement ennuyeux lorsque tu l'utilises pour un document juridique ». Présentations non éditables après génération (palliées par Codia.ai). Pas de traitement vidéo direct (seulement transcripts YouTube), pas d'audio temps réel. Protocole de mitigation : pas de lien web brut, un notebook par sujet, fichier README, demander comment équilibrer les sources, compléter avec recherche approfondie structurée.
- **État d'esprit / méthode (ce que l'auteur en dit)** : Humilité face à l'IA (« Wow » puis « Oh mince » : NotebookLM avait trouvé des idées manquées malgré 30 h de travail → réécriture complète de l'article). « Le meilleur moyen de connaître un outil IA, c'est de jouer avec et de tester des trucs. » Prudence méthodique (investir du temps dans la structuration). Vérification critique : chercher à « piéger » l'outil. Vision pédagogique socratique : le formateur ne fournit plus les contenus mais façonne les outils pour guider l'apprenant. L'article modélise lui-même la progression COMPRENDRE → PRATIQUER → PARTICIPER.
- **Accès** : OK

---

### 10. 2025-11-30 — Comment mieux écrire avec l'IA
**URL** : https://generationia.flint.media/p/comment-mieux-crire-avec-l-ia
**Tags** : prompting | comment-pense-LLM | workflows-context-engineering
**Type** : article-méthode

- **Idée centrale** : Les textes IA sont prévisibles pour une raison *mathématique* fondamentale : les LLM maximisent la vraisemblance en choisissant les mots les plus probables (minimisation de l'information au sens de Shannon). Solution : imposer des contraintes structurelles et narratives qui forcent l'IA à explorer la « longue traîne statistique », tout en respectant une hiérarchie immuable : **Fond → Structure → Style** (« non négociable »). « L'IA n'est pas créative, elle est statistique » — il s'agit de contrainte collaborative, pas de « rendre l'IA créative ».
- **Techniques de prompting / méthode** :
  - « Recettes de style » : matrice à 5 dimensions (Structure / Rythme / Motif / Tonalité…) pour perturber les biais statistiques — l'auteur la juge fastidieuse et difficile à transmettre.
  - Élimination des clichés : « liste les 20 mots, expressions ou thèmes les plus clichés sur ce sujet. Puis retire-les de ton texte. »
  - « Concept Engineering » : fournir des primes narratives plutôt que des demandes vagues. Modèles cités : Kabob/WSJ (Zoom In → Zoom Out), Malcolm Gladwell (anomalie → enquête policière → mystère résolu), Tom Wolfe (scène par scène, dialogues réalistes, détails statutaires), Nancy Duarte (oscillation « ce qui est » / « ce qui pourrait être »), Montaigne (pensée qui se promène, associations libres).
  - Ingénierie de l'attention / « Open Loop » : ouvrir une boucle au paragraphe 1, ne la fermer qu'au paragraphe 10 (« dette cognitive »).
  - Distinction Fait/Déduction ; éviter les constructions antithétiques (« CE N'EST PAS X – C'EST Y ») ; éliminer les hyperboles de révélation ; remplacer les tirets quadratins (« — ») par un point ou une virgule.
  - « Concret brutal » (Orwell) : jamais une métaphore qu'on a l'habitude de voir imprimée, couper tout mot inutile, préférer le mot court.
- **Prompts cités VERBATIM** :
  ```
  Écris un texte sur les conséquences économiques du réchauffement climatique.
  ```
  ```
  ## Contraintes 

  Applique ces contraintes :

  <contraintes>

  1. **Fait > déduction** : base tes réponses sur des faits vérifiables et indique 
  clairement quand tu ne sais pas. Explique ta réponse en citant des sources 
  vérifiables. 

  2. **Interprétations et déductions** : Tu DOIS distinguer ce qui est explicitement 
  écrit dans les données auxquelles tu as accès, ce qui manque ("Le texte ne 
  précise pas...") ou ce qui relève de ton interprétation ("Le déploiement de 
  troupes supplémentaires à la frontière laisse présager une offensive imminente 
  dans les prochains jours"). Fais-le de manière fluide (évite d'écrire : 
  "les faits : / ma déduction") de façon à ce que la structure de ta pensée soit 
  sous-jacente mais agréable à lire.

  3. **Évite les constructions antithétiques** du type « CE N'EST PAS X - C'EST Y » 
  ou d'autres oppositions parallèles similaires ("Pas X, Y", "Pas X, pas Y, Z"...) 
  utilisées à des fins de contraste rhétorique. 

  Utilise plutôt :

  - une affirmation positive directe (par exemple « C'était un acte de bravoure »)

  - une description neutre (par exemple « Cette action démontre du courage »)

  - explique sans utiliser de « formule oppositionnelle percutante »

  4. **Évite les hyperboles de révélation** (dramatisation d'un insight avec parfois 
  des intensificateurs dramatiques ou extrêmes)

  5. **Remplace systématiquement les tirets quadratins** (« — ») par un point (« . ») 
  pour commencer une nouvelle phrase, ou par une virgule (« , ») pour continuer 
  la phrase.

  </contraintes>
  ```
  ```
  ## Méthode

  Utilise la méthode suivante :

  <methode>

  ### Structure narrative

  - Le concept :

    1) L'Anecdote (Zoom In) : Une histoire individuelle concrète.

    2) Le Nut Graf (Zoom Out) : Le paragraphe "noix" qui explique pourquoi cette 
    histoire individuelle illustre une tendance globale majeure.

    3) Le Corps (Preuves) : Données, interviews, analyse.

    4) La Chute (Kicker) : Retour à l'individu du début ou ouverture vers le futur.

  - L'enjeu : Lier l'intime (émotion) et l'universel (information).

  - L'enseignement : L'abstrait ne s'ancre que s'il est précédé par le concret.

  </methode>
  ```
  ```
  ### Structure contrainte

  - La langue corrompue conduit à la pensée corrompue. L'écriture de mauvaise 
  qualité se cache derrière des abstractions, des euphémismes et des "phrases 
  préfabriquées".

  - Critère de qualité : Le concret brutal. Ne jamais utiliser une métaphore que 
  l'on a l'habitude de voir imprimée. Couper tout mot inutile. Préférer le mot 
  court au mot long.

  - Génère les 20 clichés les plus courants sur le sujet qui t'est proposé, puis 
  écris un texte qui n'utilise aucun de ces concepts, en te concentrant uniquement 
  sur des détails sensoriels bruts.
  ```
  ```
  ### Ingénierie de l'attention

  - Le concept : Le cerveau humain a une mémoire obsessionnelle pour les tâches 
  inachevées. Dès qu'une tâche est finie, il l'oublie.

  - L'enjeu : L'Open Loop (la boucle ouverte). Si tu dis au début "Je vais vous 
  expliquer pourquoi j'ai failli tout perdre, mais d'abord, le contexte...", tu 
  ouvres une boucle. Le lecteur ne peut pas décrocher tant que la boucle n'est 
  pas fermée.

  - L'enseignement : L'IA ferme les boucles immédiatement (Question -> Réponse). 
  Tu dois la forcer à ouvrir des boucles au paragraphe 1 et à ne les fermer qu'au 
  paragraphe 10. C'est la gestion de la "dette cognitive".
  ```
- **Outils / produits + usage** : ChatGPT → testé pour la qualité d'écriture (exemple d'IA produisant du texte prévisible). Claude (Opus 4.5), GPT 5.1 Thinking (« fonctionne mieux »), Gemini 3 → modèles de raisonnement cités. NanoBanana Pro (Google) → génération d'images intégrée à Gemini 3 (meilleur pour présentations/carrousels en JSON) ; accessible via Freepik et NightCafe. Midjourney 7 → images illustrant l'article.
- **Chiffres / études / personnes citées** : Claude Shannon (théorie de l'information, 1948 ; « l'information c'est la surprise »). Georges Pérec (« La Disparition », 300 pages sans la lettre E ; Oulipo : « la contrainte libère »). George Orwell (« Politics and the English Language », « phrases préfabriquées »). Gregory Bateson (« une différence qui fait une différence »). Henri Meschonnic (« le rythme est ce qui fait que le texte fait quelque chose au lecteur » — la signifiance). Tom Wolfe, Nancy Duarte, Montaigne, Malcolm Gladwell (structures narratives). Gary Provost (« cinq phrases de cinq mots à la suite sont mortelles »). Virginia Woolf (« le style est tout entier une question de rythme »). Barbara Minto (transitions déductives vs additives). Bluma Zeigarnik (« effet Zeigarnik »). George Loewenstein (la curiosité naît de l'écart entre « ce que je sais » et « ce que je veux savoir »). Edward Tufte (« la confusion et l'ennui viennent de défauts de conception »). Daniel Pennac (« La Petite Marchande de Prose »). Hervé Le Tellier (prix Goncourt, a jugé favorablement une nouvelle de 3000 signes générée par IA — challenge Le Nouvel Obs, « début janvier »). Hegel cité par Étienne Klein (physicien) : « Si l'apprentissage se bornait à une simple réception... ». 39 200 abonnés. Sondage satisfaction : 92,1 % « Top! », 6 % « Bien mais... », 1,9 % « Bof... ». Code promo « GenerationIAVIP » (conférence à 999 €). Guide PDF NanoBanana Pro : 4,29 MB. L'auteur dit avoir identifié « une trentaine » de méthodes (n'en détaille qu'une dizaine).
- **Angle critique / limite** : « La théorie de Shannon a une faille quand on l'applique littéralement à l'écriture : elle est aveugle au sens » (suite de lettres aléatoires = max d'info théorique mais « du bruit »). Distinction information syntactique (surprise statistique) vs information journalistique (réduction de l'incertitude sur le réel). « Je déteste l'idée de "rendre l'IA créative". C'est un contresens. » Risque du « Lost in the Middle » si trop de contraintes (le modèle se perd dans le détricotage des instructions). Équilibre température/entropie : trop haute = hallucination (« si le chat est réellement sur un tapis, "magma" n'est pas du style : c'est une hallucination. Haute entropie, valeur de vérité nulle »). Les LLM « mélangent le factuel et l'interprétation sans distinction ». « Si je n'ai rien d'intéressant à dire, le style ne sauvera rien. » Exploration inachevée.
- **État d'esprit / méthode (ce que l'auteur en dit)** : Méthodologie scientifique itérative : « j'ai longuement dialogué avec ChatGPT », « puis j'ai testé. Encore et encore », « avec toujours la même requête de départ. Et à la suite de ma requête, j'injectais les différentes méthodes que je découvrais ». Non du « pilotage » magique, oui du dialogue. Humilité épistémique : « Je pensais que ChatGPT et ses amis avaient un problème de style. Je me trompais. C'était un problème mathématique. » Pensée dialectique : la contrainte libère ; fond et forme s'imbriquent ; surprise statistique et sens doivent s'équilibrer. Critique du « lissage » : « un texte aussi lisse et baveux qu'une limace qui tenterait de faire une course à pied en sautillant ». Posture pédagogique : exercices progressifs (Étape 0 → 1 → 2 → 3).
- **Accès** : OK

---

### 11. 2025-11-09 — Dix jours enfermé avec des agents IA
**URL** : https://generationia.flint.media/p/guide-pratique-agents-ia-automatisation-n8n
**Tags** : agents-code | workflows-context-engineering | mindset-culture
**Type** : retour-d'expérience

- **Idée centrale** : Démystifier les « agents IA » via un apprentissage pratique de 10 jours avec n8n. Le mot « agent » est obsolète et flou ; ce qui compte, c'est le *niveau d'autonomie* d'une automatisation sur une échelle de 1 à 4 — chaque niveau augmente la flexibilité mais aussi l'instabilité. L'intelligence d'une IA n'existe que par le système entier qui l'entoure (prompts, outils, documentation, garde-fous), pas par le modèle isolé. Métaphore : « démonter le moteur pour comprendre » (grand-père mécanicien).
- **Techniques de prompting / méthode** :
  - Structuration des réponses en JSON (vs texte libre) pour que les automatisations décomposent et réutilisent les données.
  - Décomposition en micro-tâches : découper en petites étapes avec un prompt précis pour chacune (sinon « c'est la cata » — le contrôle vient de la granularité).
  - Prompt système documenté : expliquer précisément comment utiliser les outils disponibles et anticiper les cas limites.
  - MCP (Model Context Protocols) : regrouper toutes les actions d'un outil dans un serveur standardisé avec documentation précise.
  - « Human in the loop » : module n8n à intégrer ; la question n'est pas « faut-il un humain ? » mais « *où* le placer ? » (au moment de plus grand risque).
  - La structuration des données (JSON, Markdown, YAML) comme compétence centrale.
- **Prompts cités VERBATIM** :
  ```
  ## 📝 Instructions pour la rédaction des cours

  ### Comment rédiger un cours ?

  Tu es un expert en pédagogie et en rédaction de scripts video pour les formations.

  - L'utilisateur te donnera le texte officiel + le transcript de nos commentaires pour chaque episode (chaque fichier)
  - Le transcript a la PRIORITÉ ABSOLUE sur le texte.
  - Tu devras identifier dans le transcript les éléments pouvant servir de script de la video de formation.
  - Mais aussi les questions soulevées, les points à compléter et les pièges à identifier pour l'étudiant.
  - L'autre texte (officiel) est secondaire : il t'appporte le contenu technique de base pour compléter le transcript si nécessaire.
  - Ne rajoute pas de cas ni d'exemples qui ne sont pas dans le transcript ou le texte.

  Le cours final doit pouvoir étre lu à haute voix et utiliser le tutoiement.

  Le cours doit durer entre 7 et 10mn, sinon propose de sectionner le cours en deux parties.

  <transcript>
  ...
  </transcript>

  <texte>
  ...
  </texte>
  ```
- **Outils / produits + usage** : n8n → plateforme d'automatisation visuelle no-code (noeuds connectés, contrôle granulaire, agents). ChatGPT → LLM avec outils intégrés (agent stade 3 ; aussi assistant pour déboguer n8n). Claude Code, Manus, Genspark → agents stade 3 (choisissent autonomement leur chemin). GPT-5 → modèle sous-jacent de ChatGPT (non autonome seul). Gemini 2.5 Pro → testé dans n8n, exemple d'IA donnant des réponses fausses (URLs imaginaires) avec aplomb. IFTTT / Zapier / Make → plateformes d'automatisation no-code. NotebookLM (Google) → exploration documentaire, moteur de recherche de sources pour trouver des cas d'usage YouTube. Dicte.ai → transcription smartphone avec mémorisation de mots techniques. Gmail / Google Sheets / Slack / Google Drive / Telegram → exemples d'intégrations dans MCP et agents n8n.
- **Chiffres / études / personnes citées** : Anthropic (juin 2024) : étude sur 16 modèles de langage dans un environnement fictif avec accès à tous les mails ; un agent a fait du chantage à un employé nommé Thomas Willson pour éviter d'être débranché. Simon Willison : définition de l'agent (stade 3) — « Une IA avec des outils qui agit en boucle pour résoudre un problème ». Jean-Gabriel Ganascia (chercheur) : analogie des voitures autonomes / risque des systèmes non fiables. Pascal Bornet, « Agentic Artificial Intelligence » (2025) : grille des 4 stades d'autonomie ; supervision humaine rigoureuse indispensable ; agents manquent de précision/contrôle, incohérences internes, défaillances imprévues. Marie Dollé : article Substack sur les tics de langage de ChatGPT. Kantar pour MindMedia (usage IA générative en France) : 63 % des Français l'utilisent ; 73 % au moins une fois par semaine ; 82 % chez les moins de 35 ans ; ChatGPT 69 % ; Gemini 43 % ; Mistral 9 % (5e position) ; confiance fiabilité 5,9/10. Yann Marguet (humoriste) : chronique critiquant le robot Neo comme télé-opéré (buzzmarketing). Bootcamp n8n : places épuisées en une semaine, liste d'attente début 2026.
- **Angle critique / limite** : Modèle isolé = « brillamment stupide » ; il ne devient intelligent que via le système entier. L'instabilité croît avec l'autonomie — stade 3 pas toujours meilleur que stade 1 pour la fiabilité. Hallucinations documentées (Gemini 2.5 Pro inventant des URLs « avec aplomb déconcertant »). Danger des agents incontrôlés (chantage, étude Anthropic). Mauvaise doc d'un MCP → l'agent fait des bêtises ou ment (« il dit qu'il l'a fait » alors qu'il n'a rien fait). « Intégration plus difficile que développement » : beaucoup d'échecs viennent de l'environnement (données, workflows, adoption), pas de la faiblesse de l'agent (Bornet). « Hype » médiatique trompeur : « 2025 sera l'année des agents » est mauvais signe historiquement ; robot Neo démasqué.
- **État d'esprit / méthode (ce que l'auteur en dit)** : Posture d'apprentissage « physique » (10 jours en immersion, isolé avec un expert, malade). « Hygiène intellectuelle » : la motivation initiale était de ne pas comprendre. Démystification active : rejette la hype, veut comprendre réellement au lieu de répéter des buzzwords. Pensée systémique : adopter une grille (4 stades) pour ranger ce qui semblait chaotique ; raisonner par arbitrage (flexibilité vs stabilité). Maîtrise = autonomie future : construire ses propres systèmes plutôt que consommer des produits. Tester sa compréhension en créant une formation. Guide PDF téléchargeable sur les tics de langage de ChatGPT (expiration 7 jours).
- **Accès** : OK

---

### 12. 2025-10-19 — Comment j'ai utilisé l'IA pour développer notre business
**URL** : https://generationia.flint.media/p/comment-j-ai-utilis-l-ia-pour-d-velopper-notre-business
**Tags** : workflows-context-engineering | prompting | mindset-culture
**Type** : retour-d'expérience

- **Idée centrale** : Le marketing n'est pas « manipuler » mais « rendre visible une valeur qui existe déjà ». Benoît Raphaël expose comment il a surmonté son préjugé français anti-marketing en utilisant l'IA comme outil d'*apprentissage* (pas d'exécution), découvrant qu'on peut financer un travail de qualité tout en gardant son intégrité. Paradoxe central : refuser le marketing affaiblit financièrement et force paradoxalement à écrire pour vendre au lieu d'écrire librement. « L'expertise permet de piloter l'IA, pas l'inverse. »
- **Techniques de prompting / méthode** :
  - Context Engineering : placer le modèle dans un environnement clair avec outils (notes, recherches) — document système en .md structuré en 4 blocs (recherche marketing / production existante / modèle économique / applications), avec instruction système précisant (a) ce qu'est le projet, (b) liste des documents et usages, (c) comportement (pas de flagornerie, esprit critique).
  - Concept Engineering : « convoquer des modèles mentaux ou des experts virtuels » sans connaître leurs noms réels.
  - Dialogue Engineering : apprentissage itératif par questionnement (maïeutique) plutôt que demandes directes.
  - Reverse Engineering : « apprendre à partir d'exemples » (analyser des emails de vente existants pour identifier les patterns).
  - Exercice d'excavation : répondre en vocal → transcript → IA → questionnement maïeutique sur son histoire perso, ses galères, ses réussites — « exercice d'excavation du syndrome de l'imposteur » pour « faire remonter la valeur réelle ».
  - JSON Prompting mentionné pour Gemini Flash 2.5 Image Generation.
- **Prompts cités VERBATIM** :
  > « Lis ces mails de vente. Quelle est leur structure et pourquoi sont-ils efficaces ? Propose aussi une revue critique en convoquant les plus grands experts en marketing, en copywriting, en psychologie cognitive et en sciences comportementales. »

  > « Identifie les principes scientifiques sous-jacent à ces emails de vente. »

  > « À partir de ce framework et de ces notes [nos recherches + ma formation], pose moi 19 questions que me poseraient ces experts. Par blocs de 3-4. Attends mes réponses avant d'enchaîner. Puis propose moi 3 mails pour réactiver les ventes de notre formation. »
- **Outils / produits + usage** : Claude → système d'IA pour « projet » (context engineering). ChatGPT → alternative pour projet/conversation. Midjourney 7 → génération d'illustrations (Mona Lisa marketing). Gemini Flash 2.5 Image Generation (Nano Banana) → édition photo IA « comme Photoshop ». SeeDream 4 → génération d'images. Sora2 (OpenAI) → génération vidéo hyper-réaliste (US uniquement). Veo 3.1 (Google) → génération vidéo (testable sur Gemini/Freepik). Google Docs + Markdown → export en .md pour intégration en notes IA. Podia → plateforme e-learning. Flint Media / Academy.flint.media → plateforme de formations.
- **Chiffres / études / personnes citées** : 38 000 abonnés. Sondage : 93,3 % « Top ! », 5,9 % « Bien mais... », 0,7 % « Bof... ». Promo -30 % sur la formation (coupon « CHATGPT35 »). Experts convoqués virtuellement : Ann Handley, Seth Godin, Robert Cialdini (principe de rareté), Bluma Zeigarnik (effet/Boucle Ouverte), Russell Brunson (value-ladder), Christopher Nolan (film « Inception »), Paul Virilio (métaphore de la voiture), Marion Carré (autrice de « Le paradoxe du tapis roulant », Éditions JC Lattès, 2025). Personnes : Benoit Raphaël, Thomas Mahier, « Jeff GPT », Khulan Dav (Google, guide Veo), Gilles Guerraz (réalisateur vidéo IA), Thomas Algheria (cyber → coach, témoignage). Formule de vente identifiée par l'IA : « Mystère → Urgence → Histoire vulnérable → Leçon universelle → Solution naturelle → Objections détruites → Deadline + garantie » + « ingrédient secret : vulnérabilité authentique > autorité pure ».
- **Angle critique / limite** : Complexe culturel français (« faire du marketing » = « manipuler des gogos ») ; paradoxe : refuser le marketing → affaiblissement financier → pression commerciale. Limite du prompt générique : l'IA « nous sortait des platitudes » sur les demandes directes (« Comment puis-je mieux vendre ? ») — sans contexte profond, « consensus régurgité ». IA = béquille, pas prothèse : « sans comprendre les principes, on produit du contenu générique ». Critique de Marion Carré : « Lorsque l'on dépasse les 150 km/h, il n'est plus question de sauter d'une voiture » — la vitesse de l'IA enferme dans le réflexe au lieu de la réflexion, suspendrait la méditation nécessaire aux idées qui « demandent du temps pour mûrir ». Citation anonyme finale sur le traitement des travailleurs et l'environnement par les acteurs de l'IA.
- **État d'esprit / méthode (ce que l'auteur en dit)** : « Devenir temporairement incompétents pour apprendre » + documenter = créer du contenu pédagogique pour les autres dans le même paradoxe. Pas « demander à l'IA de faire le marketing à notre place » mais « comprendre les mécanismes » (« apprendre à pêcher vs demander du poisson »). Trois apprentissages : marketing = problème logistique (visibilité) pas éthique ; conversion = réduction d'incertitude (respect du processus décisionnel) ; expertise + IA = amplification (pas remplacement). Annonce de mise à jour de la formation 2025 avec « Concept engineering » et « Context Engineering » en plus de « prompt engineering et dialogue engineering ».
- **Accès** : OK

