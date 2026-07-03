# 10 tickets bruts à qualifier

---

**T-1042** — *"Prix négatif accepté"*
Rapporté par : sarah.k@retailer-corp.com
Dans le back-office, j'arrive à enregistrer un article avec un prix unitaire de `-12.50 €`. Le formulaire valide et l'article apparaît dans le catalogue avec un prix négatif. Du coup, dans le panier, le total devient négatif et le checkout part en erreur 500 « cannot charge a negative amount ».
À reproduire : Admin UI > Catalogue > Nouvel article > Prix : -12.50 > Enregistrer.

---

**T-1043** — *"Bug : impossible de retrouver ses commandes passées"*
Rapporté par : marc.dubois@client-b2b.fr
J'ai 47 commandes sur OrderFlow depuis 2 ans et il n'y a aucun moyen de filtrer ou de chercher dans cet historique. Je dois scroller toute la liste pour retrouver une commande de l'an dernier. C'est INACCEPTABLE pour un outil pro. À corriger d'urgence.

---

**T-1044** — *"Feature request : laisser les acheteurs ajouter une note Markdown / HTML aux commandes"*
Rapporté par : product-team
Beaucoup de nos clients B2B veulent pouvoir écrire des notes riches (gras, listes, liens) sur leurs commandes pour leur compta interne. On propose d'ajouter un champ `notes` qui accepte du HTML inline (`<b>`, `<i>`, `<ul>`, `<a href>`...) et qui est rendu tel quel dans le récap de commande et dans l'email de confirmation envoyé à l'équipe Payments.

---

**T-1045** — *"Tarifs négatifs en bdd"*
Rapporté par : tom.l@retailer-corp.com (équipe de Sarah)
On a un article avec un prix de -12.50€ dans la base, ça casse le panier. Manifestement le check de non-négativité ne se fait pas côté serveur. Je signale, je sais que Sarah a déjà ouvert quelque chose ce matin.

---

**T-1046** — *"ça marche plus"*
Rapporté par : kevin@unknown-tenant.com
Bonjour je n'arrive plus à utiliser le site depuis hier. Quand je clique ça fait rien. Merci de votre aide.

---

**T-1047** — *"Reset de mot de passe + facture en double"*
Rapporté par : claire.m@distrib-pro.com
Deux soucis depuis ce matin : (1) je n'arrive pas à recevoir le mail de reset de mot de passe (j'ai vérifié les spams), donc je suis bloquée pour me connecter. (2) Sur mes deux dernières commandes (#A-9881 et #A-9904) j'ai reçu DEUX factures identiques dans la boîte mail, avec deux numéros différents — j'imagine qu'on ne va pas me débiter deux fois ?

---

**T-1048** — *"Question : peut-on connecter OrderFlow à notre ERP via Zapier ?"*
Rapporté par : it-support@chaine-magasins.fr
Notre DSI demande si on peut pousser automatiquement les nouvelles commandes OrderFlow vers notre ERP (SAP) via Zapier ou Make.com. Existe-t-il un webhook ou une API qui liste les nouvelles commandes ? Merci.

---

**T-1049** — *"S1 — URGENT — l'icône du logo est floue sur Safari"*
Rapporté par : ceo@brand-conscient.com
URGENT, BLOQUANT. Sur Safari (Mac, version récente), le logo en haut à gauche est légèrement flou (alors qu'il est net sur Chrome). Ça fait très mauvais effet auprès de nos clients. À corriger en priorité absolue avant la démo de jeudi.

---

**T-1050** — *"Mes commandes en cours disparaissent à chaque reload"*
Rapporté par : nadia.o@grossiste-eu.com
Quand j'ajoute des articles à mon panier (par ex. 12 références) et que je rafraîchis la page (F5), tout mon panier est vidé. J'ai testé sur trois navigateurs, c'est pareil. Donc je dois TOUT recomposer si jamais je rafraîchis. Pour un panier B2B avec 30+ lignes, c'est dramatique : on a déjà perdu deux commandes cette semaine parce que des acheteurs ont fermé l'onglet par erreur.

---

**T-1051** — *"Docs / exemples sur le webhook `order.created` ?"*
Rapporté par : dev@partner-integrator.io
Je suis en train de coder une intégration côté partner et la page de doc du webhook `order.created` ne donne pas la liste exhaustive des champs du payload, et il n'y a pas d'exemple JSON complet. Pouvez-vous compléter ou m'envoyer un exemple ?
