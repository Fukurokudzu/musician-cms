import { Controller } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'

export default class extends Controller {
    static targets = ["audio", "playPause", "seekSlider", "volumeSlider", "currentTime", "duration", "artistTitle", "trackTitle", "mute",  "releaseLink", "progress"];
    isUpdatingTrack = false; // Add a flag to prevent multiple requests

    connect() {
        this.trackLinks = document.querySelectorAll('.play-track');
        this.trackLinks.forEach(link => {
            link.addEventListener('click', (event) => this.playTrack(event));
        });

        this.nextTrackButton = document.querySelector('#next-track');
        if (this.nextTrackButton) {
            this.nextTrackButton.removeEventListener('click', this.nextTrack.bind(this));
            this.nextTrackButton.addEventListener('click', this.nextTrack.bind(this));
        }

        this.previousTrackButton = document.querySelector('#previous-track');
        if (this.previousTrackButton) {
            this.previousTrackButton.removeEventListener('click', this.previousTrack.bind(this));
            this.previousTrackButton.addEventListener('click', this.previousTrack.bind(this));
        }

        if (this.audioTarget) {
            this.audioTarget.addEventListener("timeupdate", () => this.updateTime());
            this.audioTarget.addEventListener("loadedmetadata", () => this.updateDuration());
        }
    }

    playTrack(event) {
        event.preventDefault();
        const link = event.currentTarget;
        const newSrc = link.getAttribute('data-src');
        const trackId = link.getAttribute('data-track-id');

        if (!newSrc) {
            console.error("No valid source found for the audio element.");
            return;
        }

        if (this.audioTarget.src !== newSrc) {
            this.updateAudioSource(newSrc, link.dataset.artist, link.dataset.track);
            this.updateTrackInfo(trackId);
        } else {
            this.togglePlayPause();
        }
    }

    togglePlayPause() {
        if (this.audioTarget.paused) {
            this.audioTarget.play();
            this.playPauseTarget.innerHTML = '<i class="fas fa-pause"></i>'; // Pause icon
        } else {
            this.audioTarget.pause();
            this.playPauseTarget.innerHTML = '<i class="fas fa-play"></i>'; // Play icon
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
        if (this.audioTarget.muted) {
            this.muteTarget.innerHTML = '<i class="fas fa-volume-mute"></i>'; // Mute icon
        } else {
            this.muteTarget.innerHTML = '<i class="fas fa-volume-up"></i>'; // Unmute icon
        }
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

    nextTrack() {
        this.changeTrack(1);
    }

    previousTrack() {
        this.changeTrack(-1);
    }

    changeTrack(direction) {
        const trackInfoDiv = document.querySelector('.track-info');
        const currentTrackId = trackInfoDiv.getAttribute('data-track-id');
        const trackElements = document.querySelectorAll('.play-track');

        let currentIndex = -1;

        for (let i = 0; i < trackElements.length; i++) {
            if (trackElements[i].getAttribute('data-track-id') === currentTrackId) {
                currentIndex = i;
                break;
            }
        }

        const nextIndex = (currentIndex + direction + trackElements.length) % trackElements.length;
        const nextElement = trackElements[nextIndex];
        const newSrc = nextElement.getAttribute('data-src');
        if (!newSrc) {
            console.error("No valid source found for the audio element.");
            return;
        }

        this.updateAudioSource(newSrc, nextElement.dataset.artist, nextElement.dataset.track);
        this.updateTrackInfo(nextElement.getAttribute('data-track-id'));
    }

    updateAudioSource(newSrc, artist, track) {
        this.audioTarget.src = newSrc;
        this.audioTarget.play();
        this.playPauseTarget.innerHTML = '<i class="fas fa-pause"></i>'; // Pause icon
        this.artistTitleTarget.textContent = artist;
        this.trackTitleTarget.textContent = track;
    }

    updateTrackInfo(trackId) {
        if (this.isUpdatingTrack) return; // Prevent multiple requests
        this.isUpdatingTrack = true;

        const csrfTokenElement = document.querySelector('meta[name="csrf-token"]');
        if (!csrfTokenElement) {
            console.error("CSRF token not found.");
            this.isUpdatingTrack = false;
            return;
        }
        const csrfToken = csrfTokenElement.getAttribute('content');

        fetch(`/player/update_track`, {
            method: "PATCH",
            headers: {
                "Accept": "application/json",
                "Content-Type": "application/json",
                "X-CSRF-Token": csrfToken
            },
            body: JSON.stringify({ id: trackId })
        }).then(response => response.json())
            .then(data => {
                if (data.release_url) {
                    this.releaseLinkTarget.setAttribute('data-release-url', data.release_url);
                } else {
                    console.error("Failed to update track info.");
                }
                this.isUpdatingTrack = false;
            }).catch(error => {
            console.error("Error:", error);
            this.isUpdatingTrack = false;
        });
    }
}