// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";

import "trix";
import "@rails/actiontext";

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
