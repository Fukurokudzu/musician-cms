import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
    static targets = ["player", "artistTitle", "trackTitle"];

    connect() {
        this.trackLinks = document.querySelectorAll('.play-track');
        this.trackLinks.forEach(link => {
            link.addEventListener('click', this.playTrack.bind(this));
        });
    }

    playTrack(event) {
        event.preventDefault();
        const link = event.currentTarget;
        this.playerTarget.src = link.getAttribute('data-src');
        this.playerTarget.play();
        this.artistTitleTarget.textContent = link.dataset.artist;
        this.trackTitleTarget.textContent = link.dataset.track;
    }
}