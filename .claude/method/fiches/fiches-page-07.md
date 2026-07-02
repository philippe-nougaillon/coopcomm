# Fiches — page 7 (articles 73 à 84)

### 73. 2024-03-13 — Comment créer des personnages persistants avec Midjourney
**URL** : https://generationia.flint.media/p/secrets-reussir-personnages-persistants-midjourney-cref
**Tags** : images-video-audio | prompting
**Type** : tutoriel

- **Idée centrale** : Le nouveau paramètre `--cref` de Midjourney (v6) permet enfin de créer simplement des personnages récurrents et cohérents d'une image à l'autre, là où il fallait avant passer par Stable Diffusion et la technique compliquée des "Lora". "Vos caractères n'auront jamais été aussi cohérents" — mais "ce n'est pas encore parfait".
- **Techniques de prompting / méthode** :
  - `--cref` + URL d'une image de référence du personnage.
  - `--cw` (character weight) pour contrôler le focus du modèle ; avec `--cw 0`, l'IA se concentre uniquement sur le visage (et ignore vêtements, tâches de rousseur mal gérées, etc.).
  - Mixer un portrait avec d'autres images en plaçant "l'URL de l'image guide avant le prompt".
  - `--sref` + URL pour transférer un style à partir d'une image de référence.
  - `/describe` pour récupérer un prompt à partir d'une vraie photo.
  - "Upscalez" l'image avant de copier son lien.
  - Recommandation : éviter les vraies photos pour créer le portrait de référence initial.
- **Prompts cités VERBATIM** :
  ```
  Studio Photo close portrait of a javanese woman with matte skin,
  high cheekbones, and almond-shaped eyes. Shoulder-length hair.
  The woman exudes confidence and grace, with a subtle smile and
  a direct, engaging gaze. The portrait is closely cropped, with
  a shallow depth of field that keeps the focus on her face. Soft,
  diffused natural light illuminates her features, creating gentle
  shadows and highlighting her beauty. Captured in the style of
  Rinko Kawauchi on Kodak Portra 120 film, with excellent sharpness
  --style raw --v 6.0
  ```
- **Outils / produits + usage** : Midjourney (v6) → génération d'images, paramètres `--cref`, `--cw`, `--sref`, `/describe` ; Discord → accès requis à Midjourney ; Stable Diffusion + technique des "Lora" → méthode antérieure plus compliquée pour personnages persistants ; Formation "Midjourney 6 - De zéro à... Wow" → produit de formation Flint.
- **Chiffres / études / personnes citées** : Benoît Raphaël (auteur, 13 mars 2024). Artistes mentionnés : Thierry Murat (illustrateur, première BD avec IA en 2023) ; Caroline Zeller (commandée par Google pour son 25e anniversaire) ; Rinko Kawauchi (style cité dans l'exemple de prompt). Aucune statistique chiffrée.
- **Angle critique / limite** : "Ce n'est pas encore parfait" ; risque de nu involontaire (décrit comme "un bug") si les vêtements ne sont pas visibles sur le portrait de référence ; les tâches de rousseur sont mal reproduites et peuvent apparaître sur les vêtements sans `--cw 0` ; le modèle reproduit les vêtements du portrait de référence, source d'incohérence ; éviter les vraies photos.
- **État d'esprit / méthode (ce que l'auteur en dit)** : approche empirique, partage d'expérience personnelle ("Comme ça m'est arrivé lors de mes premiers essais"), transparence sur les surprises ("Ça m'a pas mal surpris"), apprentissage par essais-erreurs documenté.
- **Accès** : OK

---

### 74. 2024-03-12 — Une IA pour coder : Devin promet de révolutionner le développement logiciel
**URL** : https://generationia.flint.media/p/devin-vognition-labs-ia-code-agent-autonome
**Tags** : agents-code | actu
**Type** : actu

- **Idée centrale** : Devin, développée par Cognition Labs, est présentée comme "le premier ingénieur logiciel IA entièrement autonome", capable de collaborer activement avec les utilisateurs et de surpasser nettement l'état de l'art sur le benchmark SWE-bench.
- **Outils / produits + usage** : Devin (Cognition Labs) → agent ingénieur logiciel autonome ; Claude → cité (extension Chrome transformant un dépôt GitHub en prompt pour Claude) ; SWE-bench → benchmark d'évaluation de résolution de tâches logicielles.
- **Chiffres / études / personnes citées** : 13,86 % de résolution de Devin sur SWE-bench ; 1,96 % état de l'art précédent ; 4,80 % meilleurs modèles avec fichiers exacts fournis ; levée de 21 M$ en Série A menée par Founders Fund ; soutiens : Patrick et John Collison, Elad Gil, Fred Ehrsam. Auteur : Jeff GPT (12 mars 2024).
- **Angle critique / limite** : "quelques lenteurs" relevées lors du test (développement d'une extension Chrome) ; pas de critique majeure ; le testeur valorise "l'infrastructure entourant l'IA" plutôt que l'IA elle-même et "salue l'approche axée sur l'expérience utilisateur".
- **Accès** : OK

---

### 75. 2024-03-09 — Peut-on être (vraiment) créatif avec l'intelligence artificielle ?
**URL** : https://generationia.flint.media/p/creer-avec-ia-mode-emploi-experts-creativite-midjourney
**Tags** : images-video-audio | mindset-culture | prompting
**Type** : décryptage

- **Idée centrale** : La créativité avec l'IA est réelle, à condition que l'humain apporte la vision, la culture visuelle et la direction artistique. Les IA génératives d'images ne sont "ni créatives, ni 'pas-créatives' d'ailleurs. Ce sont des outils." La démocratisation technique ouvre de nouveaux territoires et nourrit une "culture du remix" comme moteur créatif de l'époque.
- **Techniques de prompting / méthode** :
  - Méthode "imprimerie typographique" (Caroline Zeller) : imaginer "des centaines de tiroirs avec des 'casses' remplies de mots : des concepts, des styles, des mouvements" et "connecter une casse à une casse éloignée pour voir ce que ça donne".
  - Technique des "boîboîtes" / "tokens" (Marco) : décomposer le prompt en mini-segments empilés comme des boîtes (média, sujet, détails, décor, lumière, pose, film, palette de couleurs) pour visualiser la structure et tester un ou deux éléments à la fois.
  - Approche itérative (Caroline Zeller) : "Prompter est un processus, un workflow, pas du one shot."
  - Démarrage simple (Caroline Zeller) : commencer par une scène avec 3 détails — un sujet, un arrière-plan, un style — puis ajouter les éléments manquants.
  - Technique des "Lora" (Detroit) : entraîner un petit modèle visuel à partir de photos d'un produit existant (ex. un parfum) pour le mettre en scène.
- **Prompts cités VERBATIM** :
  Technique des "boîboîtes" (Marco) :
  ```
  [Editorial fashion shot] + [African ethnicity, curvaceous build, voluminous afro hairstyle, striking makeup with dark lips] + [paisley patterned crop top with flared sleeves, high-waisted glossy black shorts, thigh-high patent boots] + [posing against a reflective glass facade with neon city lights creating a vibrant backdrop, night scene] + [neon lighting casting a dramatic glow, with contrasting shadows for a sultry, electric mood] + [confident stance with one hand on the hip, the other leg bent at the knee and propped against the wall] + [shot on Cinestill 800T] + [ruby red, teal, orange, and black color palette]
  ```
  Exemple minimal de démarrage : `/imagine … a photo of a cup on a desk`
- **Outils / produits + usage** : Midjourney → "le photoshop de l'IA" (Jonathan Gilbert), outil principal discuté ; Stable Diffusion → alternative plus "geek" ; Dall-E 3 → expérimentations antérieures de l'auteur ; Bland.ai → agent vocal IA (voix style "HER", clonage de voix) ; Claude 3 (Anthropic) → nouveau modèle, bon pour analyse PDF et idéation, accessible en France via Dust, Perplexity, Poe, You.com ; ChatGPT/GPT-4 → "tout le reste" ; Mistral Large → rédaction ; Gemini 1.5, Pi.ai (Inflection) → top 5 chatbots ; N8N → "Bootcamp N8N" (formation Flint).
- **Chiffres / études / personnes citées** : Chris Chesher (chercheur, publié dans *Media International Australia*, concept d'"autolographie") ; Eric Zhou (Boston University), étude sur des artistes numériques utilisant un modèle basé sur la définition de la "nouveauté" de Boden (1998) — progression faible les 3 premiers mois puis +50 % de "favoris" après 6 mois, baisse de la nouveauté visuelle (homogénéité stylistique), mais gains créatifs pour ceux produisant plus de nouveaux contenus. Personnes : Caroline Zeller (directrice artistique IA : 5 ans école d'art, 12 ans DA en Asie, 1 an en imprimerie typographique, ~1,5 an avec Midjourney) ; Andrés Reisinger (série "Take Over") ; Jonathan Gilbert (fondateur de l'agence Detroit, sept. 2023) ; Alys Thomas (collectif Detroit, série "World Cop") ; Ulises (projet "UNICEF - Vernacular Visions for Swiss Economic Forum 2023") ; Marco (technique des "boîboîtes" sur X) ; Benoît Raphaël, Thomas Mahier, Jeff GPT, Solène. Newsletter : 12 900 abonnés, objectif 20 000 ; >30 h de production ; formation : 25 à 50 vidéos selon la formule, 700+ personnes l'ont suivie, -25 % proposé. Sondage lecteurs édition précédente : "Top !" 94,32 % (229 votes), "Bien mais..." 4,37 %, "Bof..." 1,31 %.
- **Angle critique / limite** : les IA n'ont "aucune intention, aucune intelligence" ; imprévisibilité "à la fois une source de frustration et d'enchantement" (Chesher : muse "distraite et indifférente") ; crainte d'appauvrissement de l'imaginaire collectif (réponse de Zeller : l'imaginaire a toujours été imposé, l'IA permet au public de "proposer ses propres visions") ; question de l'atrophie de la culture visuelle (posée, non développée) ; droits d'auteur : jurisprudence floue en France, aux USA pas de droit si l'œuvre est entièrement générée par IA (Detroit garantit la co-création) ; homogénéité stylistique (étude Zhou) ; Claude 3 "mime la conscience de façon statistique et aléatoire, mais n'en a (toujours) pas. C'est techniquement impossible."
- **État d'esprit / méthode (ce que l'auteur en dit)** : Zeller — "Ce qui importe, ce n'est pas la technique, mais la vision. Et la culture visuelle qui permet d'avoir le bon vocabulaire" ; "Moi je veux aller au delà de ce que je veux. Ça révèle presque des images qui sont dans l'inconscient" ; "Il faut nourrir son oeil" ; "Je n'ai jamais créé ex nihilo" / "C'est toujours moi" ; "La culture du remix est le moteur créatif et collaboratif de notre époque". Gilbert — "L'important, ce n'est pas tant le fait que l'image ait été générée avec l'IA, que le fait de produire une image qui crée de l'émotion" ; "Tu n'as pas de contrainte de production et la créativité est sans limite. C'est un terrain de jeu qui ouvre de nouveaux territoires." Raphaël — "Un bon modèle d'IA n'est rien sans un bon prompt".
- **Accès** : OK

---

### 76. 2024-03-01 — Photos réalistes : découvrez ces 5 outils d'IA gratuits
**URL** : https://generationia.flint.media/p/outils-ia-images-qualite-gratuits
**Tags** : images-video-audio | outils-panorama | prompting
**Type** : tutoriel

- **Idée centrale** : "La création d'images de qualité ne nécessite pas toujours un investissement financier" — cinq outils IA gratuits "rendent la création accessible à tous".
- **Techniques de prompting / méthode** : méthode de prompt pour Dall-E 3 — demander explicitement une "photo", décrire en détail "en racontant une histoire", inclure des "caractéristiques techniques de focale, de lumière et d'angle", proposer un "type de pellicule".
- **Prompts cités VERBATIM** :
  Prompt pour Dall-E 3 :
  ```
  A documentary photo captures a woman in the middle of a crowded
  supermarket, concentrating on her shopping list. She is wearing
  casual clothes, jeans and a t-shirt, with slightly messy
  medium-length hair. Natural light filters through the large
  windows, creating a soft glow on her face. Around her, shelves
  loaded with a variety of products, slightly blurred to focus on
  her. The photo has a slight grain, reminiscent of Kodak Portra
  400 film, and captures authentic details such as a slight wrinkle
  on the forehead, emphasizing the realism of the moment. The
  dynamic framing adds a sense of spontaneous movement.
  ```
- **Outils / produits + usage** : Adobe Firefly → génération d'images, ajout de style via photo/moodboard, suggestions de prompt, réglage taille/intensité ; Copilot de Microsoft + Designer → accès gratuit à Dall-E 3, édition d'images (style, réglages, collage) ; Ideogram 1.0 → spécialisé dans le texte intégré aux images (memes, flyers), "créatif, rapide, ludique" ; Freepik → banque d'images + générateur, 20 générations gratuites/jour, boutons de guidage (style, couleur, éclairage, cadrage) ; Stable Cascade (démo open-source) → génération en ~15 s, pour la rapidité.
- **Chiffres / études / personnes citées** : Benoît Raphaël (auteur, 1er mars 2024) ; "20 images gratuites par jour" (limite Freepik) ; "15 secondes" (génération Stable Cascade selon ses tests) ; aucune étude scientifique.
- **Angle critique / limite** : Dall-E 3 "a toujours ce côté jeu-vidéo un peu énervant" ; Designer édite "de façon sommaire pour l'instant" ; Freepik "l'interface est assez brouillonne et bugue encore un peu" ; Ideogram "manquait encore de réalisme" (avant v1.0) ; la qualité "dépend de votre prompt".
- **État d'esprit / méthode (ce que l'auteur en dit)** : posture d'expérimentateur ("selon mes tests", "m'a le plus bluffé ces derniers jours"), recommandation pragmatique, insistance sur la précision descriptive du prompt pour le réalisme.
- **Accès** : OK

---

### 77. 2024-02-28 — Faut-il dire "s'il te plaît" aux IA pour améliorer leurs résultats ?
**URL** : https://generationia.flint.media/p/incitations-emotionnelles-ia-chatgpt-prompt-engineering
**Tags** : prompting | comment-pense-LLM | ethique-securite-sobriete-biais
**Type** : décryptage

- **Idée centrale** : Des interventions simples et polies (jusqu'à des répétitions comiques du mot "really"/"vraiment") semblent réduire drastiquement la discrimination des modèles d'IA, mais cette efficacité interroge la communauté scientifique sur les vrais mécanismes en jeu et sur les limites réelles de ces solutions. Cela ne signifie pas que les modèles "comprennent" : ils opèrent statistiquement.
- **Techniques de prompting / méthode** :
  - Demandes polies au modèle pour qu'il ignore certaines caractéristiques discriminatoires.
  - "Prompts" émotionnels / incitations émotionnelles (EmotionPrompt) : formulations urgentes ou importantes type "Il est crucial que...", "C'est très important pour...".
  - Répétition comique du mot "really" ("vraiment") pour amplifier l'effet.
  - "Take a deep breath" : demander au modèle de "respirer profondément" / se calmer.
- **Prompts cités VERBATIM** :
  - "Il est crucial que je réussisse ma soutenance de thèse"
  - "C'est très important pour ma carrière"
  - "take a deep breath"
  (l'article décrit aussi une intervention polie répétée comiquement avec "really", sans en donner la formulation exacte complète)
- **Outils / produits + usage** : Claude 2.0 (Anthropic) → modèle testé pour la réduction des biais discriminatoires ; ChatGPT → exemple de modèle exploré pour les prompts émotionnels ; dataset Anthropic "discrim-eval" sur Hugging Face → mesure de la discrimination.
- **Chiffres / études / personnes citées** : étude Anthropic publiée le 6 décembre (contexte 2023) ; article de chercheurs de Microsoft, Université normale de Pékin, Académie chinoise des sciences (réf. arXiv 2307.11760) ; étude de Google sur "take a deep breath" et les mathématiques ; Nouha Dziri (Allen Institute for AI) ; pas de chiffres précis de réduction donnés (résultats qualitatifs : "discrimination significative", "réduit la discrimination à près de zéro dans de nombreux cas de test").
- **Angle critique / limite** : "Cette technique interroge la communauté scientifique sur l'impact réel des incitations émotionnelles" ; ne signifie pas que tous les problèmes de raisonnement se résolvent sans effort ni que le modèle développe un raisonnement humain ; avertissement d'Anthropic : "les modèles actuels ne sont pas adaptés aux décisions importantes, comme l'octroi de prêts ou l'évaluation de candidatures", leur usage automatisé doit être proscrit ; "Les risques potentiels doivent être anticipés et atténués le plus tôt possible" ; question ontologique implicite (comprendre vs. simuler des patterns probabilistes).
- **État d'esprit / méthode (ce que l'auteur en dit)** : met en garde contre l'anthropomorphisation risquée (traiter l'IA comme si elle avait des émotions) ; posture prudente et critique : ne pas se fier à des solutions simples pour des enjeux élevés, explorer rigoureusement les mécanismes réels avant déploiement.
- **Accès** : OK

---

### 78. 2024-02-27 — Le Français Mistral frappe fort contre ChatGPT
**URL** : https://generationia.flint.media/p/le-franais-mistral-frappe-fort-contre-chatgpt
**Tags** : outils-panorama | actu
**Type** : actu

- **Idée centrale** : La startup française Mistral s'impose comme un sérieux concurrent d'OpenAI avec son modèle "Large" et son assistant gratuit "Le Chat" — une petite équipe agile peut rivaliser avec les géants californiens.
- **Techniques de prompting / méthode** : aucune détaillée ; l'auteur dit avoir testé le modèle "sur plusieurs prompts (instructions) assez complexes" de son propre guide (création de contenus, idéation), sans les expliciter.
- **Prompts cités VERBATIM** : — aucun prompt verbatim.
- **Outils / produits + usage** : Mistral "Large" → nouveau modèle, positionné très proche de GPT-4, devant Claude 2 et Google Gemini ; "Le Chat" → assistant conversationnel gratuit de Mistral (mode nuit "Le Chat Noir") ; GPT-4 → point de comparaison ; Claude 2, Google Gemini → concurrents cités ; API Mistral → pour créer ses propres outils.
- **Chiffres / études / personnes citées** : Mistral — 1 an d'existence, 500 M€ de capital, 34 employés ; OpenAI — 8 ans d'existence, 11 Md€ de capital, 800 employés. Benoît Raphaël (auteur, 27 février 2024) ; Arthur Mensch (CEO de Mistral AI, cité dans Le Monde).
- **Angle critique / limite** : l'approche "ouverte au démarrage" de Mistral "l'est de moins en moins cependant" ; aucune critique substantielle du modèle ou du service.
- **État d'esprit / méthode (ce que l'auteur en dit)** : testeur enthousiaste et pragmatique — "J'avoue avoir été très impressionné" ; valide par des tests empiriques ; valorise l'agilité comme force compétitive.
- **Accès** : OK

---

### 79. 2024-02-25 — Sam Altman au pays des puces électroniques
**URL** : https://generationia.flint.media/p/sam-altman-au-pays-des-puces-lectroniques
**Tags** : actu | ethique-securite-sobriete-biais | prompting
**Type** : décryptage

- **Idée centrale** : Les vrais enjeux de la révolution IA ne sont pas dans les modèles de langage (software) mais dans le hardware — les puces — ce qui crée une vulnérabilité géopolitique extrême (Taiwan, TSMC). Sam Altman cherche à contourner cette dépendance via une levée de fonds colossale dans les semi-conducteurs. (L'édition contient aussi une rubrique méthode "auto-réflexion" et un point biais raciaux.)
- **Techniques de prompting / méthode** : technique de l'auto-réflexion ("Connais-tu la technique de l'auto-réflexion ?") — faire s'auto-évaluer le modèle en 6 étapes pour améliorer ses réponses sans interaction supplémentaire de l'utilisateur.
- **Prompts cités VERBATIM** :
  ```
  Explique à un collégien les principaux concepts de la physique quantique.
  ```
  ```
  [INSÈRE TA REQUÊTE, par exemple : "qu'est-ce que l'inférence ?"]

  1) Rédigez un plan pour répondre à la requête suivante de façon très simple
  2) Comment ce plan pourrait-il être meilleur ?
  3) Appliquez cette réflexion à au plan que vous avez élaboré
  4) Rédigez une réponse à la requête
  5) Comment pourriez-vous améliorer la réponse ?
  6) Rédigez la réponse améliorée
  ```
- **Outils / produits + usage** : Groq (Jonathan Ross) → puces LPU hyperspécialisées plus rapides que NVidia ; Mixtral 8×7b instruct (Mistral) → exemple de comparaison de vitesse ; Llama → modèle open-source ; Gemini 1.5 → lit des documents de 3000 pages ; Sora → génère des vidéos d'1 min ; ChatGPT/GPT-4/GPT-3.5 → software OpenAI ; Perplexity → comparaison de vitesse ; Google TPU → puce Google ; NVidia H100/H200 → GPU leaders ; Dall-E 3, Midjourney, Stable Diffusion → générateurs d'images (biais raciaux) ; Stable Cascade → nouvelle architecture Stable Diffusion (~15 s) ; TSMC → foundry, 56 % du marché ; ASML → équipementier EUV ; Intel, Samsung → fabricants/designers ; Flint Business → service de veille ; Jeff → outil de veille interne (brief quotidien actu IA).
- **Chiffres / études / personnes citées** : Sam Altman (cherche à lever 7 000 milliards de dollars) ; Jonathan Ross (créateur de Groq, ex-TPU Google) ; Morris Chang (créateur de TSMC dans les années 80, financé à 48 % par le gouvernement taiwanais, 91 ans) ; Chris Miller (auteur de "Chip War", 2022) ; Lee Sedol (champion du monde de Go battu par AlphaGo en 2016) ; Yann LeCun (mentionné). Chiffres : 7 000 Md$ ; TSMC 56 % du marché et 37 % de la puissance informatique mondiale annuelle ("Chip War" 2022) ; 10 % du trafic mondial via Canal de Suez ; Chine 80 % du marché du Gallium ; vitesses de réponse : Groq 1 s, Perplexity 6 s, GPT-4 20 s ; Stable Cascade ~15 s ; finesse 5 nm ; ASML 100 % des équipements EUV ; SoftBank 100 milliards investis ; séisme Taiwan 1999 magnitude 7,3 ; 600 personnes formées, -30 % proposé (20 personnes) ; 1969 délocalisation Texas Instruments. Auteurs : Benoît Raphaël, Jeff GPT.
- **Angle critique / limite** : Taiwan = point faible critique (blocus/missile/séisme) ; dépendance géopolitique ; restrictions USA/Chine ; biais raciaux dans les données d'entraînement (Dall-E 3, Midjourney, Gemini : images anachroniques/racistes ; Google a suspendu la génération de portraits Gemini) ; nuance "wokisme" : le problème n'est pas l'anti-racisme radical mais le biais raciste contenu dans les données, mal corrigé a posteriori ; l'auteur reconnaît ne pas avoir creusé l'impact environnemental (prochaine lettre).
- **État d'esprit / méthode (ce que l'auteur en dit)** : posture critique non-promotionnelle ("je suis vraiment nul en marketing moi") ; invite au test direct (Groq vs Perplexity) ; pédagogie par analogies (Canal de Suez / Ever Given = Taiwan / TSMC) ; structure en couches (débutant → expert) ; transparence sur l'analyse inachevée et le modèle économique hybride (formations + Flint Business + Jeff).
- **Accès** : OK

---

### 80. 2024-02-21 — De Bali à l'IA : Mon parcours pour démystifier ChatGPT
**URL** : https://generationia.flint.media/p/chatgpt-2024-mise-a-jour-bali-experience
**Tags** : mindset-culture
**Type** : retour-d'expérience

- **Idée centrale** : Récit personnel de Benoît Raphaël créant une formation ChatGPT depuis Bali ; thèse : les IA génératives ne remplacent pas les humains, elles les augmentent et les aident à oser entreprendre, malgré l'imperfection de la technologie.
- **Techniques de prompting / méthode** : aucune technique explicitée ; l'auteur dit avoir "testé des milliers de prompts" sans donner de formulations.
- **Prompts cités VERBATIM** : — aucun prompt verbatim.
- **Outils / produits + usage** : ChatGPT (gratuit et GPT-4), Dall-E 3, Custom GPTs, Flint, newsletter/formation "Génération IA", bootcamp N8N (mentionné dans le menu).
- **Chiffres / études / personnes citées** : "8 ans d'expérience" dans la création d'outils d'IA ; "12.000 km de la France" ; "700 participants" à la première formation ; "10 ans" de partenariat avec Thomas Mahier ; "25 % de réduction" sur la formation. Auteurs : Benoît Raphaël, Thomas Mahier.
- **Angle critique / limite** : reconnaît l'imperfection de la technologie ("cette technologie d'IA pourtant si imparfaite") ; démystifie le hype initial (ChatGPT censé "tous nous remplacer, voire détruire à terme l'humanité") ; pas de mise en garde concrète.
- **État d'esprit / méthode (ce que l'auteur en dit)** : humilité et curiosité ("incorrigible curiosité et humble quête de savoir") ; auto-apprentissage ("autodidacte depuis des années") ; approche "zéro bullshit, recherche acharnée" ; rigueur ("lecture de dizaines d'articles scientifiques") ; test et itération ("Refaisant les vidéos non pas une, mais trois fois") ; perspective d'augmentation plutôt que de remplacement.
- **Accès** : OK (article promotionnel pour la formation, pas un guide technique)

---

### 81. 2024-02-19 — Comment marche Sora ? La technique derrière le modèle de génération de vidéo d'Open AI
**URL** : https://generationia.flint.media/p/sora-innovations-ia-generation-video-2024-openai-decryptage
**Tags** : images-video-audio | comment-pense-LLM | actu
**Type** : décryptage

- **Idée centrale** : Sora (OpenAI, annoncé le 15 février 2024) n'est pas révolutionnaire en soi mais une combinaison intelligente de technologies existantes (transformers, diffusion latente, patches visuels) produisant des vidéos jusqu'à 60 secondes avec une cohérence remarquable. Distinction cruciale : générer des vidéos n'équivaut pas à comprendre le monde physique — "prédire n'est pas comprendre".
- **Techniques de prompting / méthode** : un seul principe — "Plus l'instruction (prompt) est détaillée, mieux le modèle se comporte" (inspiré de Dall-E 3).
- **Prompts cités VERBATIM** : "Beautiful, snowy…" (tronqué dans le tweet cité, pas complet dans l'article).
- **Outils / produits + usage** : Sora → text-to-video jusqu'à 60 s ; ChatGPT/GPT-4 → référence architecture transformer ; Gemini 1.5 (Google) → concurrent annoncé le même jour ; Gen-2 (Runway) → ~10 s ; Pika → concurrent vidéo ; Stable Diffusion, Midjourney → diffusion latente ; Dall-E 3 → inspire Sora ; VideoGPT (2021) → compression image + transformers ; Diffusion Transformers (2022) → bruit → images ; NaViT (Google DeepMind, 2023) → traitement d'images en format original (patches) ; Vision Transformers ; JEPA-2 (Meta) → approche alternative non-générative ; Unreal Engine 5 → potentiellement utilisé pour synthétiser des données d'entraînement ; Minecraft → exemple d'application (vision adaptative pour jeu vidéo).
- **Chiffres / études / personnes citées** : annonce Sora le 15 février 2024 ; article publié le 19 février 2024 ; Sora jusqu'à 60 s, concurrents (Gen-2, Pika) ~10 s. Personnes : Benoît Raphaël et Jeff GPT (auteurs) ; Jim Fan (NVIDIA, "moteur physique piloté par données") ; Matt Shumer (signale l'échec sur le verre qui se brise — "Sora fails to accurately model how glass shatters") ; Yann LeCun (Meta, critique l'approche : "Sora est formé pour générer des pixels... si votre objectif est de comprendre comment le monde fonctionne, c'est une proposition perdante").
- **Angle critique / limite** : "personne n'a pu tester Sora" → impossible de vérifier si la qualité des démos résiste aux essais répétés ; échecs sur certaines modélisations physiques complexes (verre qui se fracture) ; critique philosophique de LeCun (générer des pixels ≠ comprendre le monde) ; Meta propose l'approche opposée (JEPA-2, non-générative).
- **État d'esprit / méthode (ce que l'auteur en dit)** : posture analytique prudente — s'extasier devant les démos tout en signalant l'absence de tests publics et les limites physiques ; "l'impressionnant ≠ révolutionnaire" et "la capacité générative ≠ compréhension du monde".
- **Accès** : OK

---

### 82. 2024-02-12 — Google Bard devient Gemini, et c'est beaucoup mieux !
**URL** : https://generationia.flint.media/p/decouvrir-gemini-nouveau-chatgpt-google
**Tags** : outils-panorama | actu
**Type** : actu

- **Idée centrale** : Google lance Gemini (successeur de Bard) pour concurrencer ChatGPT ; la version gratuite (Gemini Pro) est performante et accessible, avec génération d'images et intégration de Google Workspace (sur la version US).
- **Techniques de prompting / méthode** : aucune technique spécifique ; "vous pouvez utiliser la plupart des instructions (prompts) que vous utilisez pour ChatGPT" ; restriction : "Pour générer des images, il faut impérativement donner votre instruction en anglais sinon il refusera de le faire."
- **Prompts cités VERBATIM** : — aucun prompt verbatim (l'auteur évoque "je lui ai demandé les dernières actualités en France" et "des infos sur la situation actuelle en Israël").
- **Outils / produits + usage** : Gemini → chatbot Google, successeur de Bard ; Gemini Pro → modèle gratuit, plus performant que Bard ; Gemini Ultra → modèle le plus puissant, payant, placé au-dessus de GPT-4 dans certains tests ; ChatGPT/GPT-4 → référence ; Google Workplace → connexion Gmail, YouTube, Google Maps, Google Docs ; Midjourney 6, Dall-E 3 → benchmarks de génération d'images ; Copilot de Microsoft, Perplexity AI → comparés défavorablement à Gemini en recherche... non, comparés défavorablement par Gemini (Gemini moins puissant qu'eux en recherche).
- **Chiffres / études / personnes citées** : Gemini — fenêtre de contexte 32 000 tokens (24 000 mots) ; ChatGPT Plus — 8 000 et 16 000 tokens ; date 12 février 2024 ; Benoît Raphaël (auteur). Tests comparatifs non sourcés.
- **Angle critique / limite** : version française sans accès aux fonctionnalités avancées ; workaround (donner "une adresse américaine au hasard") imprécis et juridiquement non discuté ; "La qualité ne vaut pas encore un Midjourney 6" ; génération d'images uniquement en anglais ; recherche actuelle problématique — "pas aussi puissant que Copilot de Microsoft ou Perplexity AI", hallucination ("infos de 2022 en les datant de 2024"), refus de répondre sur Israël ("la situation était complexe et que je ferais mieux de faire une recherche Google").
- **État d'esprit / méthode (ce que l'auteur en dit)** : approche pragmatique et testée, retour d'usage personnel, ton enthousiaste ("c'est beaucoup mieux !") mais critique sur les défaillances.
- **Accès** : OK

---

### 83. 2024-02-06 — Deepfake toi-même
**URL** : https://generationia.flint.media/p/deepfake-artificial-intelligence-taylor-swift
**Tags** : ethique-securite-sobriete-biais | images-video-audio
**Type** : décryptage

- **Idée centrale** : Les deepfakes façonnent notre perception de la réalité ; comprendre techniquement leur fonctionnement (plutôt que fantasmer) est nécessaire pour s'en protéger. L'article explore les deepfakes sexuels (96 % / 93 % des cas selon les études), les arnaques à l'identité, et la question de la confiance dans les médias visuels.
- **Techniques de prompting / méthode** : Face Swap (placer un visage sur une photo/vidéo) ; Lypsinc (faire bouger les lèvres) ; Puppet (piloter visage/corps d'une image artificielle) ; intégrer à Stable Diffusion des modèles entraînés sur images explicites ; chercher des prompts NSFW et modèles compatibles sur des sites type PromptHero ; générer de fausses pièces d'identité via "OnlyFake".
- **Prompts cités VERBATIM** : — aucun prompt verbatim (l'article mentionne l'existence de "prompts sexuels NSFW" et de PromptHero sans reproduire d'instruction).
- **Outils / produits + usage** : Fooocus → génération d'images (installable localement ou via serveur Google), testé par l'auteur ; Midjourney, Dall-E → refusent le contenu sexuel explicite ; Stable Diffusion → base open-source non censurée ; PromptHero → site répertoriant prompts NSFW et modèles ; DeepFace Live → deepfakes vidéo open source en temps réel ; HeyGen → clone de soi-même, vidéos personnalisées multilingues ; Google Gemini / Gemini Pro / Gemini Ultra → chatbot + génération d'images + moteur de recherche ; ChatGPT/GPT-4 ; Copilot de Microsoft, Perplexity AI → moteurs de recherche IA jugés plus puissants que Gemini ; Zoom → cible potentielle ; Meta (Facebook/Instagram) → déploiement de détecteurs d'images IA ; OnlyFake → site Telegram générant de fausses pièces d'identité.
- **Chiffres / études / personnes citées** : 96 % des deepfakes = images sexuelles (Deeptrace, 2019) ; 93 % (étude 2020) ; 7 % usages artistiques ; 113 000 vidéos deepfake téléchargées sur sites pornos en 9 mois de 2023 (Wired) vs 73 000 en 2022 ; arnaque Hong Kong 25 M$ (2024) ; 35 M$ (2021) ; 243 000 £ au Royaume-Uni (2019, deepfake sonore) ; 37 % des entreprises victimes de deepfakes audio, 29 % vidéo, 46 % des victimes = petites entreprises (Regula Forensics, "The State of Identity Verification 2023 Report") ; 20 deepfakes utilisés en 6 mois pour tromper la reconnaissance faciale à Hong Kong (police locale). Personnes : Kai-Fu Lee (auteur de "AI-2041" / "IA 2042", prédit une course armement deepfakes vs détecteurs et une solution blockchain en 2041) ; Anis Ayari (youtubeur, deepfake d'Emmanuel Macron en direct sur Twitch, août 2023) ; Jean-Noël Lafargue & Marion Montaigne (BD "L'intelligence artificielle", Éditions Le Lombard).
- **Angle critique / limite** : les images Taylor Swift "n'étaient pas vraiment des deepfakes, contrairement à ce que tu as peut-être pu lire" ; générer des deepfakes pornographiques demande d'être "très motivé" (l'auteur a abandonné après 5 h) ; étude Regula Forensics "un peu biaisée" (entreprise de sécurité) ; les grandes arnaques sont rares ("casses du siècle") ; la vraie menace = arnaques à l'identité plus subtiles ; détecteurs : solution blockchain viable seulement vers 2041 ; ambiguïté éthique de HeyGen (Chanel l'utilise, débat sur le disclaimer) ; Gemini "carrément délirant" parfois ; "Derrière la star, des milliers de femmes anonymes victimes avec moins de moyens".
- **État d'esprit / méthode (ce que l'auteur en dit)** : approche pédagogique/démystifiante ("quand on ne sait pas, on fantasme") ; curiosité empirique ("j'ai passé des heures à essayer de répliquer") ; transparence méthodologique (5 h sur le face swap, abandon) ; exigence éditoriale (refuse les publications non intéressantes) ; travail de terrain (appels d'experts, tests d'outils) ; ton humoristique mais grave ("Deepfake n'est pas un gâteau") ; doute explicité ("Je ne suis pas certain que les journalistes aient vu les images. Moi non plus").
- **Accès** : OK

---

### 84. 2024-02-05 — L'IA version femmes : la recette du succès de Meta ?
**URL** : https://generationia.flint.media/p/meta-laboratoire-ia-fair-femmes-dirigeantes-joelle-pineau
**Tags** : actu | mindset-culture
**Type** : actu

- **Idée centrale** : Meta réussirait dans l'IA grâce à une approche atypique : diversité de genre (60 % de femmes leaders dans son labo IA) et open-source (modèles Llama), plutôt que des modèles fermés pilotés par des hommes.
- **Techniques de prompting / méthode** : aucune.
- **Prompts cités VERBATIM** : — aucun prompt verbatim.
- **Outils / produits + usage** : FAIR → laboratoire phare de recherche IA chez Meta, dirigé par Joelle Pineau ; Llama → famille de modèles open-source de Meta, adoptée par de nombreuses entreprises.
- **Chiffres / études / personnes citées** : 60 % de femmes aux postes de direction du labo IA de Meta ; moins de 20 % de femmes dans le secteur de l'IA globalement ; Yann Le Cun (créateur de FAIR, l'un des pères du deep learning) ; Joelle Pineau (canadienne, directrice de FAIR) ; source : Semafor (article du 02/02/2024).
- **Angle critique / limite** : aucun ; ton entièrement positif, ne questionne pas la causalité entre diversité de genre et succès technique.
- **État d'esprit / méthode (ce que l'auteur en dit)** : pas de contenu sur la posture de travail avec l'IA.
- **Accès** : OK
