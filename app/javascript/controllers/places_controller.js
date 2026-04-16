import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["address", "latitude", "longitude"]

  static values = {
    centerLat: Number,
    centerLng: Number
  }

  async connect() {
    // On attend sagement que Google Maps soit 100% prêt
    await this.ensureGoogleMapsLoaded();
    this.initAutocomplete();
  }

  async ensureGoogleMapsLoaded() {
    return new Promise((resolve) => {
      // Si l'API est déjà chargée (ex: navigation Turbo), on résout direct
      if (typeof google !== "undefined" && google.maps && google.maps.importLibrary) {
        resolve();
        return;
      }

      // Si un autre contrôleur est déjà en train de charger le script
      if (document.querySelector('script[data-google-maps]')) {
        const interval = setInterval(() => {
          if (typeof google !== "undefined" && google.maps && google.maps.importLibrary) {
            clearInterval(interval);
            resolve();
          }
        }, 100);
        return;
      }

      // Sinon, on injecte le script
      const script = document.createElement("script");
      script.setAttribute("data-google-maps", "true");

      const metaTag = document.querySelector("meta[name='google-maps-api-key']");
      if (!metaTag) {
        console.error("Balise meta 'google-maps-api-key' introuvable.");
        return;
      }

      const apiKey = metaTag.content;

      // Le resolve() est appelé uniquement quand Google lance ce callback !
      window.initPlacesCallback = () => resolve();

      script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}&libraries=places,geometry&loading=async&callback=initPlacesCallback`;
      script.async = true;
      script.defer = true;

      // 🚨 On a supprimé le script.onload qui se déclenchait trop tôt !
      document.head.appendChild(script);
    });
  }

  async initAutocomplete() {
    // 💡 IMPORTATION MODERNE : On s'assure de charger les bons modules de l'API
    const { LatLng, LatLngBounds } = await google.maps.importLibrary("core");
    const { Autocomplete } = await google.maps.importLibrary("places");

    // Paris comme position s'il n'y a pas de valeur
    const centerLat = this.hasCenterLatValue ? this.centerLatValue : 48.8566;
    const centerLng = this.hasCenterLngValue ? this.centerLngValue : 2.3522;

    // On utilise les classes que l'on vient d'importer
    const regionalBounds = new LatLngBounds(
      new LatLng(centerLat - 0.5, centerLng - 0.5), // Sud-Ouest
      new LatLng(centerLat + 0.5, centerLng + 0.5)  // Nord-Est
    );

    this.autocomplete = new Autocomplete(this.addressTarget, {
      types: [],
      fields: ['geometry', 'formatted_address', 'name'],
      componentRestrictions: { country: "fr" },
      bounds: regionalBounds,
      strictBounds: false
    });

    this.autocomplete.addListener('place_changed', this.placeSelected.bind(this));

    this.addressTarget.addEventListener('keydown', (event) => {
      if (event.key === "Enter") {
        event.preventDefault();
      }
    });
  }

  placeSelected() {
    const place = this.autocomplete.getPlace();

    if (!place.geometry) {
      console.warn("Aucun détail disponible pour : '" + place.name + "'");
      return;
    }

    // Remplissage des champs cachés
    this.latitudeTarget.value = place.geometry.location.lat();
    this.longitudeTarget.value = place.geometry.location.lng();

    // Si c'est un lieu (ex: Mairie), on peut combiner le nom et l'adresse
    // ou juste garder l'adresse formatée selon ton besoin.
    if (place.name && !place.formatted_address.includes(place.name)) {
      this.addressTarget.value = `${place.name}, ${place.formatted_address}`;
    } else {
      this.addressTarget.value = place.formatted_address;
    }
  }
}