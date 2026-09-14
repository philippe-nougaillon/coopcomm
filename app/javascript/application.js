// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";

import "trix";
import "@rails/actiontext";
import "@rails/activestorage";

// Limite les fichiers acceptés par Trix aux mêmes types que ceux validés
// côté serveur (PieceJointeValidable::DOCUMENTS). Ceci est un simple confort
// visuel — la vraie barrière de sécurité est la validation Ruby.

const TAILLE_MAX_TRIX = 110 * 1024 * 1024; // 110 Mo (100 Mo + marge)

document.addEventListener("trix-initialize", (event) => {
  const input = event.target.querySelector("input[type=file]");
  if (input) {
    input.setAttribute(
      "accept",
      ".pdf,.doc,.docx,.xls,.xlsx,.odt,.ods,.txt,.csv,.png,.jpg,.jpeg,.gif,.webp,.avif,.heic,.heif,.mp4,.webm,.ogg,.mov"
    );
  }
});

const autoInjectSlimSelect = () => {
  // On ajoute les IDs spécifiques à notre recherche
  const query =
    "select.slim-select, #intervention_tags, #intervention_tags_manager, #user_tag_list";
  const selects = document.querySelectorAll(query);

  selects.forEach((select) => {
    // Si le contrôleur n'est pas encore présent, on l'ajoute
    if (
      !select.hasAttribute("data-controller") ||
      !select.getAttribute("data-controller").includes("slim-select")
    ) {
      const existingControllers = select.getAttribute("data-controller") || "";
      select.setAttribute(
        "data-controller",
        `${existingControllers} slim-select`.trim(),
      );
    }
  });
};

document.addEventListener("turbo:load", autoInjectSlimSelect);
document.addEventListener("turbo:render", autoInjectSlimSelect);
document.addEventListener("turbo:frame-load", autoInjectSlimSelect);

// htmx câble ses attributs hx-* au chargement initial du DOM, mais ne re-traite pas
// le contenu que Turbo injecte lors d'un échange de <body> (navigation, retour
// navigateur). On relance htmx.process à chaque rendu Turbo pour recâbler les
// éléments hx-* (ex. la recherche de contact dans la messagerie).
const reprocessHtmx = () => {
  if (window.htmx) window.htmx.process(document.body);
};

document.addEventListener("turbo:load", reprocessHtmx);
document.addEventListener("turbo:render", reprocessHtmx);
document.addEventListener("turbo:frame-load", reprocessHtmx);

// Turbo guarda una "foto" del DOM antes de navegar, para poder restaurarla
// al volver atrás. Si un <dialog> quedó abierto en esa foto, se restaura
// abierto y bloquea la página. Lo cerramos justo antes de que Turbo tome esa foto.
document.addEventListener("turbo:before-cache", () => {
  document.querySelectorAll("dialog[open]").forEach((dialog) => dialog.close())
})