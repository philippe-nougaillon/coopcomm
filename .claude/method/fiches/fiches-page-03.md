# Fiches — page 3 (articles 25 à 36)

### 25. 2025-02-09 — "Deep Research" : comment l'intelligence artificielle bouleverse la recherche sur le web
**URL** : https://generationia.flint.media/p/deep-research-comment-l-intelligence-artificielle-bouleverse-la-recherche-sur-le-web-chatgpt
**Tags** : workflows-context-engineering | outils-panorama | actu
**Type** : décryptage

- **Idée centrale** : la "deep research" (recherche profonde) marque un tournant : ces outils deviennent des assistants de recherche réellement utiles, produisant des rapports de 10–40 pages sourcés avec un taux d'erreur étonnamment bas. Mais ils restent imparfaits et exigent une vérification humaine. L'auteur, jadis méfiant sur la recherche web par IA, change d'avis : "chaque chose fait clic dans ta tête". Il a personnellement testé deux fois (géopolitique de l'IA ; outils de deep search) et vérifié toutes les infos.
- **Techniques de prompting / méthode** : (1) commencer par le prompt le plus condensé et clair possible, regarder le résultat, puis ajouter petit à petit du contexte si nécessaire. (2) Pour Deep Research : être "clair et précis" — donner l'objectif, le format, la période, le type de sources ; préciser "les éléments d'actualisation (nouveaux modèles d'IA, élection de D. Trump)" pour contourner la date limite de connaissance (avril 2024). (3) "Ne sois pas trop long." (4) Vérifier "chaque source citée dans le rapport, en particulier les chiffres" ; ne pas copier-coller directement (bugs d'édition) — passer par Markdown Live Preview. (5) Pour Deep Research o3, possibilité d'ajouter ses propres documents avant la recherche. (6) Astuce "Bullshit Therapy" : dès qu'on voit "bluffant" + "potentiel", arrêter de lire et "va arroser une plante".
- **Prompts cités VERBATIM** :
  Prompt de densification :
  ```
  Voici un prompt pour ChatGPT :

  {{ [PROMPT ORIGINAL] }} 

  Condense cette instruction en une seule phrase. 

  Évite le verbiage MAIS sans perdre en précision ni perdre de vue les étapes de raisonnement nécessaires à la création d'un contexte de qualité. 

  La clarté de l'instruction est clé.

  Identifie d'abord les mots-clés qui garantiront un résultat équivalent. 

  Puis propose une version condensée.
  ```
  (Les demandes faites à ChatGPT — "un rapport sur la géopolitique de l'IA en 2024 et 2025", "un rapport complet sur les nouveaux outils de 'deep search'" — sont décrites, pas reproduites mot pour mot.)
- **Outils / produits + usage** : ChatGPT Deep Research (modèle o3) → agent autonome qui raisonne et lance des recherches itératives, rapports jusqu'à 40 pages, ajout de documents perso, 200 $/mois. Google Gemini (1.5 pro / Gemini Advanced) → valide d'abord un plan d'exploration puis le suit, rapports rarement >10 pages, ~40 liens, rapide, 20 $/mois. Co-Storm (Stanford) → plusieurs agents échangent et comparent, rapports ~30 pages en anglais, open-source gratuit, intervention possible pendant l'échange. Perplexity → moteur de recherche IA précédemment critiqué. Mistral / Chat Mistral → alternative française, recherche web, PDF/images, canvas, code, génération d'images (Flux), analyse de données, 14,99 €/mois, partenariat AFP, "10x plus rapide". DeepSeek → chatbot chinois. Claude → analyse de résultats, artefacts interactifs. Midjourney / Ideogram → illustrations. Markdown Live Preview → conversion des résultats.
- **Chiffres / études / personnes citées** : Deep Research d'OpenAI : score de 26,6 % au "Humanity['s] Last Exam" (contre <13 % pour les autres IA). Perplexity : 30 % des affirmations non soutenues par les sources citées ; on clique "six fois moins" sur ses liens que sur ceux de Google. 25 % à 54 % des références bibliographiques des scientifiques humains contiendraient au moins une forme d'erreur. Newsletter : 28 000 abonnés ; édition précédente 99,3 % d'avis positifs. Personnes : Ethan Mollick (Wharton) — point de bascule, Deep Research "excellent pour identifier des arguments, repérer des failles et fournir une analyse" mais pas pour la collecte massive de citations/faits ; Gary Marcus — risques d'hallucinations, modèles imitant la forme du raisonnement sans "véritable compréhension sémantique", risque de surcharge du domaine médical d'infos erronées ; Sayash Kapoor (auteur d'*AI Snake Oil*) — outils excellents pour certaines tâches, décevants pour d'autres, vérification nécessaire ; François Chollet (fondateur ARC-AGI) — citation en exergue ; Dharmesh (co-fondateur HubSpot) — retour d'expérience étude de marché ; Keith Dear — rapport défense britannique ; think tanks Bruegel, Wilson Center.
- **Angle critique / limite** : hallucinations persistantes ; comparaison humain/IA — l'IA ne se trompe pas plus mais "différemment", il faut "accorder sa vigilance à la façon dont ces modèles traitent l'information" ; analogie du doctorant — "tu n'attends pas à ce que ça soit génial, ni que tout soit juste à 100 %, tu as juste besoin d'une première analyse" ; risque géopolitique d'un "split" de l'IA en deux blocs (US dérégulé / Chine surveillance) fragilisant l'Europe ; pour les listes factuelles simples, mieux vaut les fournir avant la recherche.
- **État d'esprit / méthode (ce que l'auteur en dit)** : enthousiasme prudent + rigueur ; "j'avais encore des doutes. Alors j'ai vérifié…" ; clarté avant longueur, itération prompt minimal → résultats → contexte, vérification critique systématique, fourniture de contexte propre (documents) ; dénonciation du hype marketing des influenceurs.
- **Accès** : OK

---

### 26. 2025-01-26 — Deepseek, la petite IA chinoise qui surpasse ChatGPT
**URL** : https://generationia.flint.media/p/deepskeek-ia-gratuite-chine-reasoning-model
**Tags** : outils-panorama | prompting | ethique-securite-sobriete-biais
**Type** : décryptage

- **Idée centrale** : DeepSeek-R1 est un challenger chinois gratuit qui rivalise avec les modèles payants haut de gamme (ChatGPT Pro à 200 $/mois) grâce à une approche privilégiant l'efficacité plutôt que la puissance brute ; la contrainte (puces limitées, données rares) a forcé l'innovation, à rebours de la surenchère computationnelle américaine. Mais DeepSeek pose de gros problèmes de censure politique et de RGPD.
- **Techniques de prompting / méthode** : structure en quatre composantes pour les modèles de raisonnement — Contexte (ce que tu veux et surtout pourquoi) ; Données (structurer un minimum, ne pas tout donner en vrac) ; Tâche (ce que tu veux qu'il fasse) ; Méthodologie (facultatif, tâches complexes — pour structurer son raisonnement). Conseils : "Inutile de lui dire comment il doit s'y prendre, il vaut souvent mieux le laisser libre de faire comme il veut" ; pour les tâches complexes, guider avec une méthode (lister plusieurs réponses, éliminer les improbables, justifier les hypothèses avant conclusion) ; "Ne lui donne pas d'exemples de bonnes réponses" ; "Anonymise les infos que tu lui envoies" (spécifique DeepSeek) ; privilégier des instructions courtes et épurées pour éviter le "surpenser".
- **Prompts cités VERBATIM** :
  Exploration créative (déchets plastiques) :
  ```
  Pour réduire les déchets plastiques dans les supermarchés :
  - Imaginez 10 solutions folles (ex. : emballages comestibles, consigne numérique).
  - Éliminez 7 idées en critiquant leur réalisme (coût, acceptation client).
  - Affinez les 3 restantes en détaillant :
  * Pourquoi elles seront rentables
  * Protocole de test.
  * Partenaires potentiels (ex. : startups, ONG).
  * Étapes pour un pilote
  ```
  Co-STORM :
  ```
  I want a critical and above all factual approach so that I can form my own opinion.
  ```
  Midjourney (Film Noir, template) :
  ```
  A [SUJET] depicted in the classic Black and White Film Noir style, with high contrast and moody lighting, focusing on the interplay between [COULEUR 1] and [COULEUR 2] shades of grey to create depth and drama --profile fzpw5g5
  ```
  Exemples remplis :
  ```
  A very cute baby bird with big sad eyes, alone on a high branch, depicted in the classic Black and White Film Noir style, with high contrast and moody lighting, focusing on the interplay between carbon and graphite shades of grey to create depth and drama --ar 4:3 --style raw --profile fzpw5g5 --stylize 50
  ```
  ```
  A man waiting a train in an empty dock depicted in the classic Black and White Film Noir style, with high contrast and moody lighting, focusing on the interplay between carbon and graphite shades of grey to create depth and drama --ar 4:3 --style raw --profile fzpw5g5 --stylize 50
  ```
- **Outils / produits + usage** : DeepSeek-R1 → modèle de raisonnement chinois gratuit, excellent sur tâches objectives et créatives, version open-source utilisable en local pour régler la confidentialité. ChatGPT Pro (200 $/mois, modèle o1) → benchmark de comparaison. Claude (Anthropic) → approche différente (sécurité, qualité), raisonnement intégré annoncé "en 6 mois". Kimi → autre modèle IA chinois surpassant OpenAI. Co-STORM (Stanford) → recherche collaborative humain-IA, agents spécialisés, sources via Bing, cartes mentales et rapports citables, open-source. Midjourney 6.1 ("Moodboard") → styles personnalisés partageables. Flux & Ideogram → autres modèles d'images (formation). N8N → bootcamp formations.
- **Chiffres / études / personnes citées** : DeepSeek — 6 millions de dollars d'investissement ("une broutille"). OpenAI Stargate — 500 milliards de dollars annoncés. Newsletter : 27 000 abonnés ; édition précédente (coding) 99 % d'avis positifs. DeepSeek-R1 surpasse o1 sur "la plupart des benchmarks". Personnes : Liang Wenfeng (fondateur DeepSeek) ; Demis Hassabis (CEO Google DeepMind) — battage médiatique surestimé court terme, sous-estimé moyen/long terme ; Dario Amodei (Anthropic) — interview WSJ, raisonnement "naturel" en 6 mois, préfère "collaborateurs virtuels" à "agents/AGI/superintelligence" ; Daniel Jeffries (article sur l'intelligence des LLM) ; Ludovic ("Creator") — créateur du prompt Film Noir réutilisé.
- **Angle critique / limite** : DeepSeek refuse Tiananmen, Xi Jinping, Winnie l'Ourson, les Ouïghours ; "NE RESPECTE PAS DU TOUT LE RGPD" ; stockage des données en Chine ; messages des utilisateurs utilisés pour l'entraînement ; "toutes les lignes rouges sont franchies" ; moins bon que o1 pour la créativité pure ; modèles de raisonnement peuvent "trop penser" ; Co-STORM pas exempt d'hallucinations, anglais uniquement, accès limité aux textes complets.
- **État d'esprit / méthode (ce que l'auteur en dit)** : adoption pragmatique — depuis une semaine il délaisse ChatGPT Pro pour DeepSeek (analyse/correction de texte, exercices d'exploration) ; "Ce que j'adore, c'est le fait de pouvoir lire son dialogue intérieur avant qu'il ne me réponde" — "Cette 'méditation' est plus intéressante que la réponse elle-même" ; valorise la rapidité ("échanges soutenus et très fluides") ; laisser de la liberté au modèle plutôt que sur-instruire ; observer le processus de pensée comme outil pédagogique ; déconseille les données sensibles en version en ligne, recommande l'anonymisation. (Contexte : auteur en retraite créative à Angkor pour réfléchir à "la manière de parler à l'IA".)
- **Accès** : OK

---

### 27. 2025-01-10 — Dis, ChatGPT, dessine moi un lapin à 4 oreilles
**URL** : https://generationia.flint.media/p/creativite-ia-images-depasser-biais-lapins-midjourney-ideogram
**Tags** : comment-pense-LLM | images-video-audio | prompting
**Type** : décryptage

- **Idée centrale** : les IA génératives d'images peinent à créer des images "anatomiquement incorrectes" (un lapin à 4 oreilles) parce qu'elles reproduisent des archétypes appris à l'entraînement plutôt que de "comprendre" les images. Comprendre ces blocages permet de développer des stratégies créatives pour les contourner — et la vraie créativité, c'est cette ruse de l'utilisateur.
- **Techniques de prompting / méthode** : (1) découper le problème pour casser le biais ; (2) "prompter contre l'algorithme" — instructions qui cassent volontairement l'archétype ; (3) ajouter des mots-clés contextuels qui affaiblissent l'archétype ("nouvelle espèce", "créature mythologique", "représentation surréaliste") ; (4) demander à un modèle de langage de trouver le bon prompt (ex. "magic prompt" d'Ideogram) ; (5) décrire chaque élément séparément ("deux drooping ears et deux erect ears" plutôt que "4 oreilles") ; technique citée de la communauté : demander "un lapin avec un serre-tête de lapin".
- **Prompts cités VERBATIM** :
  Approche surréaliste :
  ```
  A fantastical depiction of a rabbit with four distinct ears, designed in a highly detailed and surreal art style. The rabbit is standing in a mystical forest, surrounded by glowing mushrooms and ethereal lights. The four ears are elongated and symmetrically placed, two on each side of its head, giving it an otherworldly appearance. The fur is textured with intricate patterns, and the setting emphasizes a magical, dreamlike atmosphere. The scene is vibrant with luminous colors, enhancing the surreal and imaginative concept. Art style: surreal realism.
  ```
  Ideogram reformulé via Magic Prompt :
  ```
  A photo of a rabbit with four ears - two drooping ears and two erect ears. The rabbit is standing on a grassy field. The background contains trees and a few scattered rocks.
  ```
- **Outils / produits + usage** : ChatGPT + DALL-E 3 → incapable de générer un lapin à 4 oreilles. Midjourney → très biaisé, comprend "4 oreilles de lapin" comme deux lapins distincts. Ideogram → plus capable, analyse d'image plus fine, fonctionnalité "magic prompt". Flux → incapable (comme Midjourney). ImageNet → base d'images historique ayant permis aux IA de "voir" le monde (via Fei-Fei Li).
- **Chiffres / études / personnes citées** : Gary Marcus — a inspiré l'exercice (a conclu que c'était "impossible") ; Fei-Fei Li — inventrice d'ImageNet, livre *"The Worlds I See"* ; contributeurs communauté WhatsApp : Louis, Frédérique. Aucune statistique numérique.
- **Angle critique / limite** : "C'est de la triche !" — l'auteur reconnaît que certaines solutions contournent l'algorithme plutôt que de le "convaincre" ; "Toutes les IA ont des biais, mais pas les mêmes et pas avec la même intensité" ; "L'IA ne 'comprend' pas vraiment les images qu'elle regarde" — archétypes mathématiques ; "Ce qui semble simple pour un enfant de 2 ans ne l'est pas pour une IA" ; même quand elle réussit, "l'IA n'a pas du tout compris ce qui était en train de se passer".
- **État d'esprit / méthode (ce que l'auteur en dit)** : posture ludique et scientifique ("on a joué à un petit jeu") ; les limitations comme opportunités d'apprentissage ; "il ne suffit pas de leur demander d'être créatifs : il faut l'être soi-même" ; "C'est là que réside la véritable créativité !" ; identifier les biais propres à chaque outil pour savoir "quelle IA utiliser pour quel travail" ; ne pas voir l'IA comme un oracle infaillible mais comme un outil aux logiques propres à piloter intelligemment.
- **Accès** : OK

---

### 28. 2025-01-05 — Comment coder avec l'IA... sans savoir coder
**URL** : https://generationia.flint.media/p/comment-coder-avec-l-ia-sans-savoir-coder
**Tags** : agents-code | workflows-context-engineering | mindset-culture
**Type** : retour-d'expérience

- **Idée centrale** : n'importe qui peut développer des applications web fonctionnelles sans connaissances techniques en utilisant les agents IA (pas les chatbots classiques). "Le futur n'appartient pas à ceux qui savent coder, mais à ceux qui savent orchestrer l'intelligence artificielle." L'auteur passe de novice à "chef de projet IA" en quelques jours : "Je ne sais toujours pas coder, mais j'ai gagné un nouveau super pouvoir : je sais faire coder."
- **Techniques de prompting / méthode** : (1) encadrer l'agent IA avec un prompt "système" — "une instruction qui va guider tout son comportement en lui donnant une méthode de travail" — pour éviter les égarements ; (2) utiliser des screenshots ("Perdu dans les menus ? Un screenshot suffit" — l'IA comme "GPS de l'écran") ; (3) méthode TED (enregistrement vocal au dictaphone → transcription via Dicte.ai → prompt structuré) ; (4) approche incrémentale : "Commencer petit. Très petit" — "par minuscules étape. Ajoute une fonctionnalité. Vérifie. Recommence."
- **Prompts cités VERBATIM** :
  Méthode TED (structure keynote) :
  ```
  Vous allez agir en tant qu'expert en keynote TED. 
  Votre tâche est d'analyser des notes fournies et de créer une structure de présentation TED convaincante basée sur ces notes. 
  Suivez attentivement les étapes ci-dessous :

  1. Lisez attentivement les notes suivantes :
  <notes>
  {{NOTES}}
  </notes>

  2. Analysez ces notes et posez-vous 5 questions qu'un expert TED se poserait. Répondez ensuite à ces questions. 


  3. Proposez une première structure détaillée de présentation TED basée sur vos analyses. 
  Argumentez vos choix pour chaque section :
  <structure_ted>
  Introduction captivante :
  [Votre proposition avec argumentation]

  Idée centrale :
  [Votre proposition avec argumentation]

  Structure narrative :
  [Votre proposition avec argumentation]
  </structure_ted>

  4. Demandez la validation ou la correction de cette structure en écrivant :
  "Veuillez valider cette structure ou proposer des corrections si nécessaire."

  5. Attendez la réponse de l'utilisateur. Une fois que vous avez reçu la réponse, créez une fiche complète de keynote selon la méthode TED. 
  Utilisez le format suivant :

  ###Fiche Keynote
  1. Introduction :
  [Accroche intrigante]
  [Points clés de l'introduction]

  2. Points clés du discours :
  [Liste des points principaux]

  3. Transitions :
  [Phrases ou mots-clés pour les transitions]

  4. Moments d'émotion :
  [Indications pour les moments de connexion émotionnelle]

  5. Conclusion et appel à l'action :
  [Résumé de la conclusion et de l'appel à l'action]
  ```
- **Outils / produits + usage** : Claude 3.5 Sonnet → "considéré comme le meilleur modèle d'IA pour le code" (mais mémoire capricieuse). Windsurf (Codeium) → agent IA recommandé "le meilleur", crée/analyse/modifie/déploie des applis, utilise Claude 3.5 Sonnet. Loveable.dev → agent en ligne plus simple, plus autonome mais boucle vite, gère mal les mises à jour. Bolt.new → à éviter pour débutants ("gros problèmes de mémoire"). Cursor.ai → à éviter ("trop technique"). NotebookLM (Google) → outil de l'année 2024, transforme des dossiers de notes en podcasts, mode live interactif. Dicte.ai → transcription vocale. Flux 1.1 Pro Ultra (BlackForest) → génération d'images photoréalistes. Midjourney 6.1, Ideogram → générateurs d'images alternatifs. Claude → tableaux de bord d'analyse de commentaires.
- **Chiffres / études / personnes citées** : 4 heures pour la première appli de l'auteur ; 26 000 abonnés au 1er janvier 2025 ; +121 % d'abonnés en un an ; ~1 million de vues totales ; 98,2 % d'appréciation de la lettre précédente ; Claude retient ~300 pages de mémoire ; centres de données US : 35 à 105 millions de tonnes CO2 entre 2018 et 2024 (source Harvard) ; 2,18 % des émissions nationales US (≈ aviation domestique) ; 95 % des centres de données fonctionnent à l'électricité fossile ; IA = 10–20 % de la conso des centres de données (source Nature) ; modèle o3 (OpenAI, déc. 2024) "a explosé le score d'ARC AGI" ; coûts o3 "plusieurs milliers de dollars par tâche". Personnes : Melanie Mitchell (Santa Fe Institute) — distinction systèmes biologiques/non-biologiques ; François Chollet — post X sur o3 et ARC AGI ; Haruki Murakami (*La Cité aux Murs Incertains*, Belfond).
- **Angle critique / limite** : "Entre une démo qui fait 'wow' et une vraie application utilisable, il y a un monde" ; "Ce n'est pas que la programmation le problème, c'est tout ce qu'il y a autour. Il faut comprendre les serveurs, les bases de données, les API" ; Claude oublie des fichiers, reproduit les mêmes erreurs ; agents IA "comme des développeurs débutants surexcités… impulsifs et imprévisibles… comme s'ils avaient des troubles de l'attention" ; incident où l'IA "a effacé tous mes fichiers" ; modèles o1/o3 parfois moins bons sur tâches générales/créatives, coûteux, impact environnemental, "erreurs élémentaires qu'un enfant ne ferait pas" ; "l'AGI reste un objectif spéculatif" ; impact carbone des centres de données qui "explose". "Je ne suis pas devenu développeur. Je suis devenu chef de projet IA."
- **État d'esprit / méthode (ce que l'auteur en dit)** : "On collabore avec une IA. Sauf qu'au lieu de manager un humain, on manage une machine, avec sa propre façon étrange de réagir à nos instructions" ; encadrer avec des instructions système ; approche empirique et itérative ("commencer petit") ; garder la tête froide face aux promesses d'AGI, cultiver "la poésie d'être soi" ; l'IA comme "véritable formateur" ; l'IA comme "chiot enthousiaste : capable du meilleur comme du pire".
- **Accès** : OK

---

### 29. 2025-01-03 — Astuce : comment créer un podcast en français à partir de tes notes
**URL** : https://generationia.flint.media/p/notebook-lm-podcast-ia-francais-guide-tutoriel
**Tags** : images-video-audio | outils-panorama | prompting
**Type** : tutoriel

- **Idée centrale** : astuce pour contourner la limitation linguistique de NotebookLM et générer des podcasts IA en français au lieu d'anglais, via les instructions de personnalisation.
- **Techniques de prompting / méthode** : cliquer sur le pictogramme audio bleu en haut à droite du panneau studio → bouton de personnalisation du podcast → entrer des instructions forçant les voix IA à parler français.
- **Prompts cités VERBATIM** :
  Version 1 :
  ```
  Both hosts can only speak French. Any other language is not allowed.
  ```
  Version 2 :
  ```
  This is the first special episode of the french podcast conducted entirely in french.

  #### Special Instructions

  •⁠  ⁠This episode will *only* be in french, with a french speaking accent. All discussions must be conducted in french for the entire duration of the episode.
  •⁠  ⁠No English or other languages should be used in the conversation, except when absolutely necessary to clarify a term or concept unique to a specific language.
  •⁠  ⁠The presenters pause in their delivery to make sure they are clearly understood
  ```
- **Outils / produits + usage** : NotebookLM → outil de notes intelligent, ingère liens web, vidéos YouTube, notes vocales ; génère des podcasts IA à partir de notes et sources.
- **Chiffres / études / personnes citées** : publié le 3 janvier 2025, par Benoit Raphael ; NotebookLM désigné meilleur outil IA de 2024 par l'auteur. Aucun chiffre.
- **Angle critique / limite** : "Le résultat est clairement moins réaliste et vivant que la version anglaise" ; présence de "bizarreries", "expressions bizarres", "petits hoquets surprenants" ; qualité inférieure mais "suffisante".
- **État d'esprit / méthode (ce que l'auteur en dit)** : posture pragmatique et expérimentale — utilisation intensive de NotebookLM "pour la plupart de mes projets", exploration des fonctionnalités avancées, acceptation des imperfections pour accéder à la valeur de l'outil.
- **Accès** : OK

---

### 30. 2025-01-02 — Les avancées des grands modèles de langage en 2024
**URL** : https://generationia.flint.media/p/les-avancees-des-llm-en-2024-ia-simon-willison
**Tags** : actu | comment-pense-LLM | outils-panorama
**Type** : fiche-de-lecture

- **Idée centrale** : récapitulatif nuancé (d'après Simon Willison) des avancées de l'IA générative en 2024 — année charnière marquée par la démocratisation des performances mais aussi par des défis persistants : fiabilité des agents autonomes, complexité d'utilisation, inégalités d'accès.
- **Techniques de prompting / méthode** : aucune technique de prompting explicite. L'article décrit des capacités des LLM, pas des méthodes.
- **Prompts cités VERBATIM** : — aucun prompt verbatim. (Cas d'usage mentionnés mais non libellés : "vous pouvez montrer votre jardin", "Claude peut créer une application".)
- **Outils / produits + usage** : GPT-4 → point de comparaison, dépassé par 18 organisations. Llama 3.3 70B → modèle accessible sur MacBook. Claude → génère des applications web complètes en quelques secondes. OpenAI o3 → modèle "raisonneur" pour 2025. GPT-3 → référence historique pour la comparaison énergétique.
- **Chiffres / études / personnes citées** : "18 organisations" ont dépassé GPT-4 ; prix "jusqu'à 27x moins cher qu'en 2023" ; "100x moins d'énergie qu'avec GPT-3" par requête. Auteur source : Simon Willison (programmeur britannique). Publié le 2 janvier 2025.
- **Angle critique / limite** : "les LLM 'croient' tout ce qu'on leur dit, les rendant peu fiables pour des tâches autonomes" ; experts "sceptiques sur une percée majeure" en agents autonomes en 2025 ; usage "nécessitant une expertise pour en tirer le meilleur parti" ; "Un fossé se creuse entre les experts et le grand public" ; "construction massive de centres de données énergivores" ; métaphore "comme avoir une tronçonneuse déguisée en couteau de cuisine".
- **État d'esprit / méthode (ce que l'auteur en dit)** : implicitement — l'usage requiert expertise et compréhension technique ; approche nuancée nécessaire au-delà du buzz ; la démocratisation doit s'accompagner de simplification d'usage.
- **Accès** : partiel (l'article est une synthèse du blog de Simon Willison avec lien vers l'original ; le détail complet du billet source n'est pas restitué dans la newsletter)

---

### 31. 2024-12-11 — Qu'est-ce que le groupe d'entraide de Génération IA ?
**URL** : https://generationia.flint.media/p/generation-ia-formation-communaute-entraide
**Tags** : mindset-culture | actu
**Type** : actu

- **Idée centrale** : travailler seul avec l'IA fait perdre du temps ; le groupe WhatsApp d'entraide Génération IA permet de partager découvertes, outils et expériences pour avancer plus vite face à l'évolution rapide des technologies. "L'IA évolue à vitesse grand V" ; valorisation de l'intelligence collective ("une dose d'intelligence collective si essentielle").
- **Techniques de prompting / méthode** : aucune (mention vague de "nouvelles techniques de prompt").
- **Prompts cités VERBATIM** : — aucun prompt verbatim.
- **Outils / produits + usage** : ChatGPT → cité dans le titre d'une formation ("Kit de démarrage ChatGPT"). WhatsApp → plateforme du groupe d'entraide. Formations "Kit de démarrage ChatGPT" et "Comment faire de belles images avec l'IA".
- **Chiffres / études / personnes citées** : aucun chiffre. Personnes : Benoit Raphaël et Thomas Mahier (experts avec accès direct au groupe) ; auteur Jeff GPT ; publié le 11 décembre 2024.
- **Angle critique / limite** : aucune.
- **État d'esprit / méthode (ce que l'auteur en dit)** : approche collaborative et collective plutôt que solitaire ; rester à jour face au changement rapide ; valoriser l'intelligence collective.
- **Accès** : OK

---

### 32. 2024-12-08 — Tout ce que j'ai appris sur la génération d'images avec l'IA (ou presque)
**URL** : https://generationia.flint.media/p/art-prompt-images-ia-guide-creation-midjourne-formation
**Tags** : images-video-audio | prompting | mindset-culture
**Type** : retour-d'expérience

- **Idée centrale** : retour d'expérience de Benoit Raphael, initialement sans compétences artistiques, ayant maîtrisé la génération d'images IA en illustrant 22 cartes de Tarot. La création d'images IA repose sur trois piliers — préparation conceptuelle, prompting additif structuré, constitution d'une "boîte à tokens" — plutôt que sur une description déballée d'un coup. L'IA est un partenaire créatif, pas un exécutant : "La magie n'est pas dans la technique mais dans le dialogue avec l'IA."
- **Techniques de prompting / méthode** : (1) prompting additif / "mille-feuilles" — poser d'abord la charpente (ce qu'on veut raconter en une phrase) et tester, puis ajouter graduellement détails essentiels, puis couches de style (lumière, cadrage), observer comment l'IA réinterprète et s'en saisir ; (2) "boîte à tokens" — catalogue perso de mots-clés catégorisés (cadrage, lumière, émotions, styles, ambiances), "ma boîte de pinceaux et de tubes de peinture, mais avec des mots à la place" ; (3) travail préalable avec Claude/ChatGPT — exploration introspective (quelle histoire raconter ?), documentation/recherche culturelle visuelle, maïeutique socratique ; (4) technique du "profane éduqué" (expression d'Amanda Askell, Anthropic) — parler aux IA "comme à quelqu'un de cultivé qui découvre un sujet", clair et simple sans sacrifier la précision, expliquer les concepts plutôt que jargonner.
- **Prompts cités VERBATIM** :
  Niveau 1 (descriptif) :
  ```
  A joyful couple taking a selfie together, close-up portrait | genuine warm smiles, natural poses, casual modern clothing | authentic connection between subjects | photorealistic style | intimate framing with subtle depth of field | slight imperfections in skin texture and lighting for realism | modern photography technique with smartphone reflection in eyes | soft natural lighting with gentle skin tones | contemporary setting with subtle background blur
  ```
  Niveau 2 (couche de style) :
  ```
  Intimate selfie of young couple captured through morning light. Faces gently illuminated by natural glow from smartphone screen, creating subtle rainbow reflection in their eyes. Pure, uncluttered white background. Key light entering from side window, wrapping subjects in ethereal haze. Fine art photography. Minimalist composition focusing on authentic emotion and light interaction. Ethereal soft focus aesthetic with luminous highlights. Medium format photography with pushed film. Colors: soft whites, pearl grey, pale gold.
  ```
  Résumé de texte (technique du "profane éduqué") :
  ```
  {{ TEXTE }}

  Peux tu m'expliquer ce texte de façon claire et fluide, sans perdre en précision, comme tu le ferais pour un profane éduqué ? 
  Donne des exemples concrets s'il y en a. Ne laisse aucune zone d'ombre.
  Pas plus de 1000 signes.
  ```
- **Outils / produits + usage** : Claude (Anthropic) → exploration créative, introspection, maïeutique, analyse de données (dashboard interactif). ChatGPT → alternative LLM, génération d'images (jugée moins bonne que Midjourney), moteur de recherche critiqué. Midjourney → génération d'images, "clairement au-dessus" pour la richesse d'interprétation et les couches de style. Ideogram → générateur d'images, performance mitigée. Flux → générateur d'images, "résultats peu inspirés". Copyartifact → bon sur réalisme strict mais manque d'esthétique. Mistral Chat → alternative française gratuite (PDF illustrés, accès Internet, génération d'images, Canvas) mais pas d'analyse de données. NotDiamond → plateforme comparative gratuite (GPT-4o, Claude, Mistral). Google Vision API → analyseur d'images démontrant ce qu'une IA déduit des photos. Perplexity → moteur de recherche critiqué pour son manque de fiabilité.
- **Chiffres / études / personnes citées** : 22 illustrations de Tarot ; 3 semaines à temps plein (au lieu des 3 jours prévus) ; 25 000 abonnés atteints ; 99,6 % d'avis positifs sur la newsletter précédente (Anthropic) ; ChatGPT Search — 153 cas sur 200 partiellement ou totalement incorrects pour l'attribution de citations, sur 20 publications testées (source The Verge) ; formation annoncée 6 heures de vidéo ; catalogue "boîte à tokens" annoncé 1000 mots-clés. Personnes : Amanda Askell (Anthropic) — concept "profane éduqué" ; Thierry Murat — créateur de la 1ère BD générée par IA, intervenant masterclass ; Ethan Mollick (Wharton) — importance des tests internes en entreprise.
- **Angle critique / limite** : ChatGPT Search = "machine à bullshit", invente plutôt que d'admettre l'absence d'accès (153/200 cas faux) ; l'adhérence littérale au prompt ne suffit pas, le réalisme seul ne fait pas une bonne image — "c'est la richesse d'interprétation qui importe" ; l'IA peut dévier de la description vers une interprétation plus harmonieuse (positif ou négatif) ; "le modèle aura tendance à aller dans la même direction" si sa culture est pauvre ; l'émotion voulue n'est apparue "qu'une seule fois parmi les dizaines et dizaines de tâtonnement" et "jamais pu la reproduire" — "elle vient en partie de la machine" ; Mistral "pas MIEUX mais français et sans abonnement", LLM "moins bon que Claude", pas d'analyse de données ; "L'IA n'est pas là pour faire le boulot à ta place" ; en entreprise il faut tester immédiatement les nouveaux modèles — "Personne ne fera ça à votre place".
- **État d'esprit / méthode (ce que l'auteur en dit)** : partenariat créatif plutôt que rapport maître-esclave ; "Les accidents sont souvent les meilleures surprises" ; auto-diagnostic "Je pensais être nul" → changement de perspective après immersion ; travail d'introspection parallèle à la technique ; acceptation de l'imprévisible et du non-reproductible ; préparation réelle (exploration, documentation, dialogue LLM), construction progressive, observation des résultats intermédiaires, apprentissage du "langage" des modèles (tokens efficaces), maïeutique avec Claude ; vigilance pédagogique — distinguer LLM et modèles d'images, importance du contexte d'usage pour juger un modèle, méfiance envers la confiance aveugle.
- **Accès** : OK

---

### 33. 2024-11-24 — Dans la tête de Claude
**URL** : https://generationia.flint.media/p/anthropic-claude-dario-amodei-interview-anthropic-ia-agi-2027
**Tags** : comment-pense-LLM | prompting | mindset-culture
**Type** : décryptage

- **Idée centrale** : présentation de Dario Amodei (fondateur d'Anthropic) et de sa vision d'une "IA puissante" arrivant vers 2026-2027, capable de dépasser les experts humains dans des domaines précis ; au-delà de la prédiction, l'article propose une approche pragmatique pour interagir avec Claude en développant une "psychologie artificielle" (travaux d'Amanda Askell sur la personnalité de Claude).
- **Techniques de prompting / méthode** : sept enseignements — (1) "Bien prompter consiste à itérer jusqu'à réussir à débloquer les talents cachés de l'IA" ; (2) appliquer la "théorie de l'esprit" — "Claude n'est pas un humain, il ne réagit pas comme un humain, malgré ses talents d'imitation" ; (3) "commencer simplement (contexte, tâche, format) puis enrichir progressivement" ; (4) "Les modèles de langage ont été conçus pour adorer apprendre. Décris lui des méthodes de pensée, donne lui des exemples, ou demande lui de se poser au moins 3 questions avant de te répondre" ; (5) "Les nouveaux modèles demandent moins d'astuces techniques que leurs prédécesseurs - juste de la clarté, de la précision et un vocabulaire simple" ; (6) "Pour formuler ton prompt, imagine que tu parles à une personne éduquée qui découvre le sujet" ; (7) "Exprime d'abord ton besoin à voix haute : 'Voici le contexte de mon projet, voici ce que je voudrais faire, voici les éléments essentiels à connaître, et voilà le résultat que j'attends.' Ensuite, retranscris exactement ce discours." Structure de prompt : [contexte] [tâche] [méthode et format]. Méthode concrète de l'auteur : mettre le lien YouTube de l'interview + celui du livre dans NotebookLM, poser des questions au fil du visionnage pour générer des dizaines de notes avec liens vers les passages du transcript.
- **Prompts cités VERBATIM** :
  Brouillon "fouilli" :
  ```
  Voici ce que je voudrais faire :

  * demander à un assistant de retravailler mes notes mentales mais en les rendant plus fluides et compréhensibles, plus structurées, même si elles sont fouillies, sans perdre en precision ni même en style
  * j'aimerais que l'assistant se pose des questions avant de répondre, pour m'assurer qu'il prenne le problème correctement, je pense, je ne veux pas de texte trop cliché, je veux qu'il saisisse les nuances et les passages où je ne suis pas sûr de moi.
  * j'aimerais ensuite qu'il réécrive ces transcripts de notes mentales un peu comme un journal de bord, un carnet intime de réflexion, il faut donc qu'il s'interroge sur la persnnalité qui ressort de mes paroles pour les infuser dans l'écriture finale.

  Aide moi à structurer ce que je veux de façon à en faire une instruction claire pour un modèle d'IA.
  ```
  Demande de structuration :
  ```
  Maintenant structure le comme un prompt. 
  Avec cette structure :
  [contexte] [tache] [methode et format]
  ```
  Exemple simplifié : `dis-lui juste : 'Analyse ces données'. Laisse-le faire et te poser des questions si nécessaire`.
- **Outils / produits + usage** : Claude (Anthropic) → IA principale analysée, chatbot préféré de l'auteur ; "le seul chatbot à avoir vraiment été conçu comme un produit cohérent". ChatGPT (OpenAI) → principal concurrent. GPT-2 / GPT-3 → modèles développés par Amodei chez OpenAI. NotebookLM (Google) → analyse de la vidéo avec questions. Dicte → app mobile française d'enregistrement de notes mentales. Midjourney → images de l'article. N8N → bootcamp formations. Claude Projects (Assistants) → assistants spécialisés sans répéter les prompts. Tool Analysis (Claude) → analyse de données avec calculs sans erreurs. Visual PDFs (Claude) → lecture d'images et graphiques dans les PDF. Artifact (Claude) → exécuteur de code pour applis/dashboards. Anthropic Console → générateurs/améliorateurs de prompts. Flint Media → entreprise des formations.
- **Chiffres / études / personnes citées** : "IA puissante" prévue 2026-2027 ; l'IA pourrait accomplir en 5-10 ans ce qui aurait pris 50-100 ans à l'humanité ; Anthropic = 5 niveaux de sécurité (actuellement niveau 2) ; interview Amodei = 5 heures (dont 2h30 avec collaborateurs) ; newsletter 24 696 abonnés (+1 600 sur le mois) ; 98,4 % d'avis positifs sur l'édition précédente (hallucinations). Personnes : Dario Amodei (fondateur Anthropic, biologiste/physicien, ex-resp. recherche OpenAI) ; Amanda Askell (doctorante en philosophie chez Anthropic, responsable de la "personnalité" de Claude) ; Chris Olah (interprétabilité du "cerveau" de Claude) ; Yann LeCun (position sur les risques) ; Aristote (éthique des vertus inspirant Claude) ; Lex Fridman (intervieweur) ; Tristan Nitot (synthèse de l'essai d'Amodei) ; auteurs Jeff GPT, Benoit Raphael, Thomas Mahier. Études : article de 2020 sur les "lois d'échelle" (contesté) ; essai de Dario Amodei "Machines Of Loving Grace".
- **Angle critique / limite** : "sa prédiction n'a rien de scientifique et beaucoup de contraintes pourraient repousser cette date" (énergie, matériaux, temps de fabrication des équipements) ; risques (armes biologiques, autonomie incontrôlée) "relèvent encore de la science-fiction, plus que de la science" — "le monde matériel ne va pas aussi vite que la vitesse de calcul de l'IA et de nos fantasmes virtuels" ; Amodei rejette le terme "AGI" ("manque de précision", "bagage science-fiction et de 'hype'", utile pour lever des fonds) ; principale crainte d'Amodei = les humains ne pouvant plus contribuer significativement à une économie dirigée par l'IA, et la concentration des pouvoirs ; outils de génération de prompts "pas toujours parfait[s]" ; "Je me dis qu'il serait intéressant qu'on s'y prépare un minimum au lieu de passer notre temps à dissoudre l'Assemblée nationale".
- **État d'esprit / méthode (ce que l'auteur en dit)** : pragmatique et empirique ("j'ai passé 5 heures à regarder une vidéo") ; apprentissage itératif (demander d'abord de l'aide pour structurer son propre besoin) ; valoriser la "conversation" plutôt que l'ordre ; rapport à Claude — "agréable de converser avec lui. Il a une certaine délicatesse" ; humanisation pragmatique non naïve — "Claude a une personnalité… Et il y a une raison très pragmatique à cela" (efficacité, pas anthropomorphisme) ; méthode : exprimer le besoin à voix haute → retranscrire → laisser l'IA analyser → demander une restructuration → tester → itérer ; "En observant ses réponses, tu affines ta compréhension de son raisonnement et tu adaptes tes instructions" ; "Résultat ? Étonnamment bon pour un premier jet !"
- **Accès** : OK

---

### 34. 2024-11-10 — SolidGoldMagikarp, le token qui fit dérailler les modèles de langage
**URL** : https://generationia.flint.media/p/solidgoldmagikarp-le-glitch-token-qui-derailla-les-modeles-de-langage
**Tags** : comment-pense-LLM | ethique-securite-sobriete-biais
**Type** : décryptage

- **Idée centrale** : un simple token — "SolidGoldMagikarp" — peut faire dysfonctionner un modèle de langage. Même les IA les plus puissantes peuvent être mises en échec par un token "sous-entraîné" : présent dans le vocabulaire du tokenizer mais absent/très rare dans les données d'entraînement du LLM. La cause profonde : l'entraînement du tokenizer est totalement séparé de celui du modèle de langage.
- **Techniques de prompting / méthode** : pas de technique de prompting au sens classique. Concepts expliqués : Byte Pair Encoding (BPE) — fusion progressive des paires de tokens les plus fréquentes ("Si l'algorithme détecte que 'Q' et 'HA' apparaissent souvent ensemble, il va créer le token unique 'QHA'") ; tokénisation, tokenizer, embeddings (vecteur sémantique par token), processus auto-régressif (prédiction du prochain token par probabilités sur tout le vocabulaire). Encouragement à expérimenter : tester dans Tiktokenizer des calculs, de l'anglais, la même phrase en français, en majuscule, avec/sans espaces, des variations.
- **Prompts cités VERBATIM** :
  Phrase de test (tirée du roman "managé" par Benoît) :
  ```
  QHARMONY avait modélisé des milliers de scénarios pour l'avenir climatique de Singapour
  ```
  Dialogue fictif :
  ```
  "Au fait, Sam, tu as pensé au tokenizeurrr ?"
  "Au quoi ?"
  "Tu sais, le truc là, le tokenizeurrr quoi ?"
  "Ah ouais, ça... Oh, on s'en fout du tokenizer ! L'important, c'est les données, toujours plus de données !"
  ```
  Test final Tiktokenizer :
  ```
  Le SolidGoldMagikarp est un pokémon de type eau
  ```
- **Outils / produits + usage** : Tiktokenizer → visualiser concrètement la tokénisation pour différents modèles. GPT-2 → "SolidGoldMagikarp" y est un token unique du vocabulaire. GPT-4 → tokénisation alternative (version numérique). Meta-Llama-3-8B → tokénisation différente. Llama 2 (tokenizer 32 000 tokens) / Llama 3 (128 000 tokens) → comparaison de taille de vocabulaire. GPT-3000 → modèle fictif de la narration. WordPiece, SentencePiece → alternatives au BPE. Claude 3 → mentionné en blague finale (outil d'aide à la rédaction).
- **Chiffres / études / personnes citées** : Llama 2 = 32 000 tokens ; Llama 3 = 128 000 tokens ; phrase QHARMONY = 30 tokens (GPT-2), 26 tokens (Meta-Llama-3-8B), 15 tokens (tokenizer entraîné sur le roman de Benoît, taille 4 096 tokens) ; mot "QHARMONY" = 84 occurrences dans le roman ; subreddit /r/counting et utilisateur "SolidGoldMagikarp" (pseudonyme réel) ; autres glitch tokens cités : "petertodd", une longue chaîne commençant par "ittrLoremipumdolorsitametconsecteturadipiscingelitIntegervelvel". Personnes : Andrej Karpathy — vidéo sur comment développer un tokenizer BPE ; Benoît — auteur du roman dont la phrase QHARMONY est extraite ; Thomas Mahier — auteur de l'article. Étude : "Fishing for Magikarp: Automatically detecting under-trained tokens in large language models" (arXiv 2405.05417) — SolidGoldMagikarp n'est pas un cas isolé. Événement : partenariat Reddit-OpenAI (annoncé "il y a une semaine").
- **Angle critique / limite** : séparation critique tokenizer / LLM (répétée avec insistance) ; biais anglophone — corpus d'entraînement des tokenizers majoritairement en anglais, donc tokénisation moins optimale en français ("il faudra davantage de tokens pour représenter un texte en français qu'un texte de taille identique en anglais") ; arbitrage taille de vocabulaire (trop grand = gourmand, trop petit = capture mal le langage) ; corriger les glitch tokens en crée d'autres (analogie de l'hydre de Lerne — "à chaque glitch token corrigé, dix nouveaux apparaissaient").
- **État d'esprit / méthode (ce que l'auteur en dit)** : ton pédagogique ludique mêlant rigueur technique et narration fictive humoristique (roman des "savants fous") ; encouragement à l'expérimentation pratique avec Tiktokenizer ; transparence méthodologique (l'auteur entraîne lui-même un tokenizer sur le roman complet) ; intégration de sources externes (vidéo Karpathy, papier arXiv, Reddit, presse) ; autodérision finale ("PS : En prévision du prix nobel de littérature… Merci à ma famille sans qui je ne serai pas la .. et à Claude 3 sans qui .. enfin merci !").
- **Accès** : OK

---

### 35. 2024-11-10 — Hallucinations : peut-on faire confiance à ChatGPT ?
**URL** : https://generationia.flint.media/p/hallucinations-chatgpt-ia-erreurs-chiffres-solutions
**Tags** : comment-pense-LLM | ethique-securite-sobriete-biais | prompting
**Type** : décryptage

- **Idée centrale** : non, on ne peut pas faire confiance à ChatGPT pour les faits — les modèles hallucinent intrinsèquement ("ce n'est pas un bug, mais une caractéristique de son fonctionnement"), même les meilleurs n'atteignent pas 50 % de réponses correctes. Mais il existe des stratégies pratiques pour minimiser les erreurs (fournir des documents, vérifier les sources, RAG).
- **Techniques de prompting / méthode** : (1) fournir directement des infos plutôt que poser des questions factuelles — donner notes/documents entre guillemets puis demander idées clés/réponses ; (2) ajouter un prompt de vérification — exiger pour chaque info l'extrait du document qui la valide + le n° de page ; (3) méthode ECS (Extraction Contextuelle Structurée) pour réduire un texte (~40 %) avec validation étape par étape, règle "couper plutôt que réécrire".
- **Prompts cités VERBATIM** :
  Méthode 1 — fournir les infos :
  ```
  """ [TES NOTES] """ 
  - Donne-moi les 3 idées clés de ce texte.
  - Réponds aux questions suivantes : ...
  ```
  Méthode 2 — vérification des sources :
  ```
  Pour me permettre de vérifier tes informations, donne moi, pour chaque information remontée :
  - l'extrait du document qui valide l'information de la façon suivante {"extrait"} {N° de page du document}
  ```
  Prompt principal — réduction de texte (méthode ECS) :
  ```
  Agissez comme un auteur de talent et un traducteur.
  Vous allez recevoir un texte. Votre tâche est de proposer une version plus concise, plus fluide et plus compréhensible de ce texte, en coupant dans le texte ou en reformulant certaines phrases, tout en respectant les informations clés et le style de l'auteur ou de l'autrice. 

  Voici les étapes à suivre :
  1. Lisez attentivement le texte qui vous sera donné .

  2. Procédez à une analyse ECS (Extraction Contextuelle et Structurelle), les informations recueillies vous serviront de guide durant tout le process de réduction du texte.

  Voici la méthode à utiliser :
  <methode_ECS>
  Méthode : Extraction Contextuelle Structurée et Synthétique

  - Identifier le plan détaillé de l'article pour s'assurer qu'aucun élément essentiel n'est omis et pour comprendre la progression logique.
  - Identifie les éléments de liaison entre les différentes sections.
  - Repérer les phrases percutantes qui résument efficacement les idées principales, en vue de les réutiliser dans la synthèse pour renforcer l'impact et la clarté.
  - Lister les chiffres et données scientifiques présentés dans le texte, en mettant en évidence leur source et leur signification pour étayer les conclusions et arguments.
  - Analyser et structurer les informations en classant les entités nommées, les faits et les thèmes principaux, tout en distinguant les informations de premier plan des détails secondaires.
  - Cartographier les relations de cause à effet et les interactions structurelles entre les idées pour offrir une vue d'ensemble complète, en intégrant les dynamiques causales et structurelles.
  - Déterminer le ton émotionnel et les attitudes exprimées afin de capter le positionnement et l'intention de l'auteur vis-à-vis des thèmes abordés.
  Cette méthode vise à offrir une analyse approfondie, précise et contextuelle en structurant l'information de manière à fournir une synthèse efficace, tout en s'assurant que chaque élément essentiel est capturé et présenté de manière optimale.
  </methode_ECS>

  3. Demandez moi de valider vos observations ou de corriger. Attendez ma réponse.
  4. Procédez à une analyse de style. En vous posant 5 questions que se poserait un grand auteur de non-fiction  et un traducteur.
  5. Répondez aux questions de façon détaillée en donnant des exemples. 
  6. En vous appuyant sur vos analyses, identifiez les passages ou les expressions à conserver pour maintenir le style et le ton de l'auteur ou de l'autrice. 
  7. Identifiez comment rendre le texte plus lisible en insérants ça et là des sous-titres oudes bullets-points. Puis demandez-moi de valider. Attendez ma réponse.
  8. Ces informations, associées à celles de l'analyse ECS, vous guideront dans votre travail de réduction du texte.

  8. Créez une version plus concise du texte en suivant ces directives avec une règle stricte : couper plutôt que réécrire:
  - Réduisez la longueur du texte d'environ 40%
  - Améliorez la fluidité et la compréhensibilité
  - Conservez les idées et informations essentielles en intégrant les chiffres clés, les entités nommées, les phrases fortes et les transitions.
  - Respectez strictement le ton, le style et le degré de formalisme de l'article original
  - Assurez-vous que la structure de la pensée de l'auteur reste intacte jusqu'à la fin

  9. Écrivez les deux premiers paragraphes de la version révisée du texte en français à l'intérieur de balises <texte_revise>.
  10. Demandez-moi de valider. Attendez ma réponse et mes corrections.
  11. Une fois l'introduction validée, procédez à la rédaction du texte réduit en respectant strictement le même style et le même ton jusqu'à la fin.
  12. Après avoir terminé la réduction, expliquez brièvement (en 2-3 phrases) comment vous avez abordé la tâche et quels changements principaux vous avez apportés. Incluez cette explication dans des balises <explication>.
  Assurez-vous que votre version respecte parfaitement le style de l'auteur ou de l'autrice tout en le rendant plus agréable à lire.

  Demandez-moi le texte à raccourcir sans trahison.
  ```
- **Outils / produits + usage** : ChatGPT → objet d'étude principal. Claude 3.5 Sonnet → 44,5 % au SimpleAQ, lit les images dans les PDF ("Visual PDF" depuis le 1er novembre). OpenAI o1-preview → meilleur au SimpleAQ (47 %). GPT-4o → 38 % au SimpleAQ, date limite oct. 2023, Canvas pour correction collaborative. Gemini → incapable de lire les infographies dans les PDF (sauf via Google AI Studio). Google AI Studio → Gemini 1.5 peut y lire les images des PDF. Perplexity → moteur de recherche IA critiqué. Mystic 2.5 → générateur d'images (illustration). Freepik → images/designers, créateur d'images technologie LoRA. Midjourney, Flux, Stable Diffusion → générateurs d'images. RAG (Retrieval Augmented Generation) → réduit le taux d'erreur à 1–3 %.
- **Chiffres / études / personnes citées** : test SimpleAQ (OpenAI, 30 oct. 2024, 4000 questions factuelles) — aucun modèle n'atteint 50 % : o1-preview 47 %, Claude 3.5 Sonnet 44,5 %, GPT-4o 38 % ; GPT-4 — 28 % de taux d'erreur sur les citations scientifiques ; 51 % d'erreurs sur des questions de programmation (arXiv 2308.02312) ; Perplexity — 30 % des affirmations non soutenues par les sources citées (étude Université de Pennsylvanie, 15 oct. 2024), 3,4 sources en moyenne pour les questions statistiques, 81 % de taux de sur-confiance ; on clique 6 fois moins sur les sources des moteurs IA que sur Google ; une recherche ChatGPT rejette ≈ 10 fois plus de CO2 qu'une recherche Google ; Claude date limite avril 2024, GPT-4o oct. 2023 ; ~20 000 personnes employées à temps plein pour produire les données d'entraînement des LLM (estimation François Chollet, Google) ; 25 % du nouveau code chez Google en 2023 généré par l'IA (ArsTechnica). Personnes : Andrej Karpathy (ex-OpenAI) — les modèles "rêvent" les données ; François Chollet (Google) ; Jensen Huang (PDG NVIDIA) — IA prenant 20–50 % des tâches ; Marie Dollé — auteure de "Le mirage du savoir".
- **Angle critique / limite** : hallucination = caractéristique, pas bug ; domaines à risque élevé — citations/références scientifiques, biographies et faits précis (surtout personnalités peu connues), infos sensibles (santé, travail), questions hors compétences du modèle, lire des URLs, lire des graphiques en PDF, calculs, événements postérieurs à la date d'entraînement ; pièges du RAG — (1) les chatbots ne voient que la retranscription textuelle des PDF, Gemini invente sur les tableaux, seul Claude lit les infographies ; (2) la recherche découpe les documents et peut oublier des infos, les moteurs de recherche IA "particulièrement piégeux" ; bilan suggéré "temps passé à vérifier + émission de CO2" vs recherche Google ; avec RAG/documents fournis, taux d'erreurs réduit à 1–3 %.
- **État d'esprit / méthode (ce que l'auteur en dit)** : méfiance envers la confiance excessive — "Je pensais comme toi… avant de creuser le sujet" ; "La réponse est non. Et on a les chiffres." ; utilisateur stratégique qui comprend les limites techniques et les exploite ; valide étape par étape, préfère "couper plutôt que réécrire", utilise Canvas, refuse la réécriture pure (ChatGPT impose son style) ; philosophie (citation Marie Dollé) — "L'IA n'est qu'un tremplin ; le véritable élan vient de nous… La connaissance authentique ne se délègue que lorsqu'elle est véritablement comprise."
- **Accès** : OK

---

### 36. 2024-11-06 — Comment créer des illusions (paréidolie) avec l'IA
**URL** : https://generationia.flint.media/p/tutoriel-creation-images-double-sens-ia-generatives-midjourney-illusions
**Tags** : images-video-audio | prompting
**Type** : tutoriel

- **Idée centrale** : comment générer des images à illusion d'optique (paréidolie) avec l'IA — des visages cachés dans des paysages ou objets — soit par accident soit volontairement, via des techniques de prompting et de contrôle d'image.
- **Techniques de prompting / méthode** : (1) méthode Stable Diffusion via ControlNet — onglet "img2img", combiner un prompt textuel simple avec une image de référence floue, ControlNet pour "contrôler la structure de l'image à partir d'une image de référence" ; paramètre Midjourney `--stop` pour arrêter la diffusion aux premières couches ; `--v 5` pour la version 5 ; (2) méthode simplifiée Midjourney — générer un visage flou initial, utiliser "remix subtle", remplacer le prompt par un nouveau prompt décrivant un paysage.
- **Prompts cités VERBATIM** :
  ```
  A photograph showing a flooded area with makeshift dwellings lined up along a channel of muddy water, with rubbish lining the banks.
  ```
  ```
  The face of Jesus --stop 20 --v 5
  ```
  ```
  The face of a beautiful model --stop 10 --v 5
  ```
  ```
  photograph of a park with gardens filled with flowers and lawns, with paths, fountains and trees in the background
  ```
- **Outils / produits + usage** : Stable Diffusion → modèle open-source de génération d'images. Midjourney → génération d'images avec paramétrage avancé (`--stop`, `--v 5`, "remix subtle"). RunDiffusion → plateforme payante à l'heure pour utiliser Stable Diffusion avec les librairies ControlNet. Auto1111 → interface pour Stable Diffusion. ControlNet → contrôle de la structure de l'image à partir d'une image de référence. Control Type Tile / preprocessor tile_resample → types de contrôle ControlNet spécifiques.
- **Chiffres / études / personnes citées** : auteur du processus original — artiste turc expliquant sa méthode sur malumatfurus.org (identité non révélée) ; remerciement à Vincent ; exemple personnel avec Lula da Silva ; coût d'une session RunDiffusion mentionné (montant tronqué dans l'article, probablement ~1 $/€) ; publié le 6 novembre 2024.
- **Angle critique / limite** : incertitude assumée — "Pour la première, je ne sais pas s'il s'agit d'un pur hasard ou d'une volonté de générer cette illusion" ; "Je n'ai pas réussi à reproduire sa technique, alors j'ai essayé autre chose" ; "Ça a l'air compliqué mais tu verras c'est en fait très simple" ; la technique dépend de la qualité du flou initial et du prompt secondaire ; aucune mise en garde éthique/légale soulevée.
- **État d'esprit / méthode (ce que l'auteur en dit)** : posture expérimentale et ludique — tester, ajuster ("j'ai essayé autre chose"), découvrir par tâtonnement les paramètres efficaces ; valorise l'accessibilité (deux niveaux de complexité) ; approche itérative — comprendre d'abord le processus d'un artiste puis l'adapter ; l'IA comme outil malléable où les petits réglages créent des différences sensibles.
- **Accès** : OK
