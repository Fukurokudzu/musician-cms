import { Controller } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'

export default class extends Controller {
    static targets = ["audio", "playPause", "seekSlider", "volumeSlider", "currentTime", "duration", "artistTitle", "trackTitle", "mute",  "releaseLink"];

    connect() {
        console.log("PlayerController connected"); // Log statement
        this.trackLinks = document.querySelectorAll('.play-track');
        this.trackLinks.forEach(link => {
            link.addEventListener('click', (event) => this.playTrack(event));
        });

        this.audioTarget.addEventListener("timeupdate", () => this.updateTime());
        this.audioTarget.addEventListener("loadedmetadata", () => this.updateDuration());
    }

    playTrack(event) {
        event.preventDefault();
        console.log("playTrack method triggered");
        const link = event.currentTarget;
        const newSrc = link.getAttribute('data-src');
        const trackId = link.getAttribute('data-track-id');

        if (!newSrc) {
            console.error("No valid source found for the audio element.");
            return;
        }

        if (this.audioTarget.src !== newSrc) {
            this.audioTarget.src = newSrc;
            this.audioTarget.play();
            this.artistTitleTarget.textContent = link.dataset.artist;
            this.trackTitleTarget.textContent = link.dataset.track;
            this.playPauseTarget.textContent = "Pause";

            // Get the CSRF token from the meta tag
            const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

            // Send a request to update the track in the controller
            fetch(`/player/update_track`, {
                method: "PATCH",
                headers: {
                    "Accept": "application/json",
                    "Content-Type": "application/json",
                    "X-CSRF-Token": csrfToken // Include the CSRF token in the headers
                },
                body: JSON.stringify({ id: trackId })
            }).then(response => response.json())
                .then(data => {
                    console.log("PATCH request sent");
                    if (data.release_url) {
                        this.releaseLinkTarget.setAttribute('data-release-url', data.release_url);
                    } else {
                        console.error("Failed to update track info.");
                    }
                }).catch(error => {
                console.error("Error:", error);
            });
        } else {
            this.togglePlayPause();
        }
    }

    togglePlayPause() {
        if (this.audioTarget.paused) {
            this.audioTarget.play();
            this.playPauseTarget.textContent = "Pause";
        } else {
            this.audioTarget.pause();
            this.playPauseTarget.textContent = "Play";
        }
    }

    seek() {
        const seekTo = this.audioTarget.duration * (this.seekSliderTarget.value / 100);
        this.audioTarget.currentTime = seekTo;
    }

    adjustVolume() {
        this.audioTarget.volume = this.volumeSliderTarget.value / 100;
    }

    muteUnmute() {
        this.audioTarget.muted = !this.audioTarget.muted;
        this.muteTarget.textContent = this.audioTarget.muted ? "Unmute" : "Mute";
    }

    updateTime() {
        const currentTime = this.audioTarget.currentTime;
        const duration = this.audioTarget.duration;
        this.seekSliderTarget.value = (currentTime / duration) * 100;
        this.currentTimeTarget.textContent = this.formatTime(currentTime);
    }

    updateDuration() {
        this.durationTarget.textContent = this.formatTime(this.audioTarget.duration);
    }

    formatTime(seconds) {
        const minutes = Math.floor(seconds / 60);
        const secs = Math.floor(seconds % 60);
        return `${minutes}:${secs < 10 ? "0" : ""}${secs}`;
    }

    navigateToRelease(event) {
        const releaseUrl = event.currentTarget.getAttribute('data-release-url');
        if (releaseUrl) {
            Turbo.visit(releaseUrl);
        }
    }
}