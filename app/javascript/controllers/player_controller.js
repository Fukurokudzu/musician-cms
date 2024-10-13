import { Controller } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'

export default class extends Controller {
    static targets = ["audio", "playPause", "seekSlider", "volumeSlider", "currentTime", "duration", "artistTitle", "trackTitle", "mute", "releaseLink", "progress"];
    isUpdatingTrack = false;
    isFetchingTrackData = false; // Flag to prevent multiple API calls
    releaseTracks = [];
    eventListenersAdded = false; // Flag to check if event listeners are added

    connect() {
        document.addEventListener('turbo:load', this.initializeEventListeners.bind(this));
        this.initializeEventListeners();
    }

    initializeEventListeners() {
        this.removeEventListeners(); // Ensure previous listeners are removed

        this.trackLinks = document.querySelectorAll('.play-track');
        this.trackLinks.forEach(link => {
            link.addEventListener('click', this.playTrack.bind(this));
        });

        this.nextTrackButton = document.querySelector('#next-track');
        if (this.nextTrackButton) {
            this.nextTrackButton.addEventListener('click', this.nextTrack.bind(this));
        }

        this.previousTrackButton = document.querySelector('#previous-track');
        if (this.previousTrackButton) {
            this.previousTrackButton.addEventListener('click', this.previousTrack.bind(this));
        }

        if (this.hasAudioTarget) {
            this.audioTarget.addEventListener("timeupdate", this.updateTime.bind(this));
            this.audioTarget.addEventListener("loadedmetadata", this.updateDuration.bind(this));
        }

        this.eventListenersAdded = true; // Set the flag to true after adding event listeners
    }

    removeEventListeners() {
        if (!this.eventListenersAdded) return;

        this.trackLinks.forEach(link => {
            link.removeEventListener('click', this.playTrack.bind(this));
        });

        if (this.nextTrackButton) {
            this.nextTrackButton.removeEventListener('click', this.nextTrack.bind(this));
        }

        if (this.previousTrackButton) {
            this.previousTrackButton.removeEventListener('click', this.previousTrack.bind(this));
        }

        if (this.hasAudioTarget) {
            this.audioTarget.removeEventListener("timeupdate", this.updateTime.bind(this));
            this.audioTarget.removeEventListener("loadedmetadata", this.updateDuration.bind(this));
        }

        this.eventListenersAdded = false; // Reset the flag
    }

    async playTrack(event) {
        event.preventDefault();
        const link = event.currentTarget;
        const trackId = link.getAttribute('data-track-id');

        await this.loadTrackData(trackId);
    }

    async loadTrackData(trackId) {
        if (this.isFetchingTrackData) return; // Prevent multiple calls
        this.isFetchingTrackData = true;

        try {
            const data = await this.fetchTrackData(trackId);
            const { track, release_tracks } = data;

            this.releaseTracks = [];
            this.releaseTracks = release_tracks;
            console.log("Release tracks:", this.releaseTracks);
            this.updateAudioSource(track.data_src, track.artist, track.title);
            await this.updateTrackDisplay(track.id);
        } catch (error) {
            console.error('Error loading track data:', error);
        } finally {
            this.isFetchingTrackData = false; // Reset the flag
        }
    }

    async fetchTrackData(trackId) {
        const response = await fetch(`/tracks/${trackId}`);
        return await response.json();
    }

    async updateTrackDisplay(trackId) {
        if (this.isUpdatingTrack) return;
        this.isUpdatingTrack = true;

        const csrfTokenElement = document.querySelector('meta[name="csrf-token"]');
        if (!csrfTokenElement) {
            console.error("CSRF token not found.");
            this.isUpdatingTrack = false;
            return;
        }
        const csrfToken = csrfTokenElement.getAttribute('content');
        if (!csrfToken) {
            console.error("CSRF token content not found.");
            this.isUpdatingTrack = false;
            return;
        }

        try {
            const data = await this.updateTrack(trackId, csrfToken);
            if (data.release_url) {
                this.releaseLinkTarget.setAttribute('data-release-url', data.release_url);
            } else {
                console.error("Failed to update track display.");
            }
        } catch (error) {
            console.error("Error:", error);
        } finally {
            this.isUpdatingTrack = false;
        }
    }

    async updateTrack(trackId, csrfToken) {
        const response = await fetch(`/player/update_track`, {
            method: "PATCH",
            headers: {
                "Accept": "application/json",
                "Content-Type": "application/json",
                "X-CSRF-Token": csrfToken
            },
            body: JSON.stringify({ id: trackId })
        });
        return await response.json();
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

    async changeTrack(direction) {
        if (this.isChangingTrack) return; // Prevent multiple calls
        this.isChangingTrack = true;

        const trackInfoDiv = document.querySelector('.track-info');
        const currentTrackId = parseInt(trackInfoDiv.getAttribute('data-track-id'));

        let currentIndex = this.releaseTracks.findIndex(track => track.id === currentTrackId);

        if (currentIndex === -1) {
            console.error("Current track not found in release tracks.");
            await this.loadTrackData(currentTrackId); // Fetch updated release tracks

            currentIndex = this.releaseTracks.findIndex(track => track.id === currentTrackId);

            if (currentIndex === -1) {
                console.error("Current track still not found after fetching.");
                this.isChangingTrack = false;
                return;
            }
        }

        if (this.releaseTracks.length === 0) {
            console.error("No tracks available.");
            this.isChangingTrack = false;
            return;
        }

        let nextIndex = currentIndex + direction;
        console.log("Current index:", currentIndex);
        console.log("Next index:", nextIndex);

        if (nextIndex >= this.releaseTracks.length) {
            nextIndex = 0; // Wrap around to the first track
        } else if (nextIndex < 0) {
            nextIndex = this.releaseTracks.length - 1; // Wrap around to the last track
        }

        const nextTrack = this.releaseTracks[nextIndex];

        if (!nextTrack) {
            console.error("Next track not found.");
            this.isChangingTrack = false;
            return;
        }

        this.audioTarget.addEventListener('loadeddata', () => {
            this.isChangingTrack = false; // Reset the flag once the new track is loaded
        }, { once: true });

        this.updateAudioSource(nextTrack.data_src, nextTrack.artist, nextTrack.title);
        await this.updateTrackDisplay(nextTrack.id);
        trackInfoDiv.setAttribute('data-track-id', nextTrack.id);
    }

    updateAudioSource(newSrc, artist, track) {
        this.audioTarget.src = newSrc;
        this.audioTarget.play();
        this.playPauseTarget.innerHTML = '<i class="fas fa-pause"></i>'; // Pause icon
        this.artistTitleTarget.textContent = artist.title;
        this.trackTitleTarget.textContent = track;
    }
}