import { Controller } from "@hotwired/stimulus"

const options = {
    enableHighAccuracy: true,
    maximumAge: 0
};

export default class extends Controller {
    static values = { url: String }

    connect() {
        this.getLocation()
    }

    getLocation() {
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                this.updateLocation.bind(this),
                this.handleError
            )
        }
    }

    updateLocation(position) {
        const data = {
            latitude: position.coords.latitude,
            longitude: position.coords.longitude
        }

        fetch("update_location", {
            method: 'PATCH',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
            },
            body: JSON.stringify(data)
        })
        .then(response => {
            if (response.ok) console.log("Localisation mise à jour")
        })
    }

    handleError(error) {
        console.warn(`Erreur géo (${error.code}): ${error.message}`)
    }
}