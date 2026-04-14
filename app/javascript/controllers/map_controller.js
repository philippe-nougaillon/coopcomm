import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    depart: Object,
    arrivee: Object,
    polyline: String
  }

  async connect() {
    await this.ensureGoogleMapsLoaded();
    this.initMap();
  }

  async ensureGoogleMapsLoaded() {
    return new Promise((resolve) => {
      if (typeof google !== "undefined" && google.maps && google.maps.importLibrary) {
        resolve();
        return;
      }

      if (document.querySelector('script[data-google-maps]')) {
        const interval = setInterval(() => {
          if (typeof google !== "undefined" && google.maps && google.maps.importLibrary) {
            clearInterval(interval);
            resolve();
          }
        }, 100);
        return;
      }

      const script = document.createElement("script");
      script.setAttribute("data-google-maps", "true");
      const metaTag = document.querySelector("meta[name='google-maps-api-key']");
      const apiKey = metaTag ? metaTag.content : "";

      window.initMapCallback = () => resolve();

      script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}&libraries=places,geometry&loading=async&callback=initMapCallback`;
      script.async = true;
      script.defer = true;
      document.head.appendChild(script);
    });
  }

  async initMap() {
    const { Map } = await google.maps.importLibrary("maps");
    const { AdvancedMarkerElement } = await google.maps.importLibrary("marker");
    const { encoding } = await google.maps.importLibrary("geometry");

    // 💡 SÉCURITÉ : On force la conversion en nombres pour éviter l'erreur "not a number"
    const departCoords = {
      lat: parseFloat(this.departValue.lat),
      lng: parseFloat(this.departValue.lng)
    };

    const arriveeCoords = {
      lat: parseFloat(this.arriveeValue.lat),
      lng: parseFloat(this.arriveeValue.lng)
    };

    const bounds = new google.maps.LatLngBounds();

    // Initialisation de la map
    const map = new Map(this.element, {
      center: departCoords,
      zoom: 11,
      mapId: "549c4681c953f814fa1cd142",
    });

    // Ajout du marker d'arrivée
    new AdvancedMarkerElement({
      map: map,
      position: arriveeCoords, // Maintenant garanti d'être des nombres
      title: "Intervention",
    });

    // Centrage de la map
    bounds.extend(departCoords);
    bounds.extend(arriveeCoords);
    map.fitBounds(bounds);

    // Ajout de la route
    if (this.polylineValue && this.polylineValue !== "") {
      const decodedPath = encoding.decodePath(this.polylineValue);
      new google.maps.Polyline({
        path: decodedPath,
        geodesic: true,
        strokeColor: "#0f53ff",
        strokeOpacity: 0.6,
        strokeWeight: 6,
        map: map
      });
    }

    const trafficLayer = new google.maps.TrafficLayer();
    trafficLayer.setMap(map);
  }
}