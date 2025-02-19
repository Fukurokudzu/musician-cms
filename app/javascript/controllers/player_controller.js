import { Controller } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'

export default class extends Controller {
    static targets = ["audio", "playPause", "seekSlider", "volumeSlider", "currentTime", "duration", "artistTitle", "trackTitle", "mute", "releaseLink", "progress"];
    isUpdatingTrack = false;

    initializeEventListeners() {
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
            this.isFetchingTrackData = false;
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

    async nextTrack(csrfToken) {
        const response = await fetch(`/player/next_track`, {
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

    previousTrack() {
        this.previousTrack();
    }

    updateAudioSource(newSrc, artist, track) {
        this.audioTarget.src = newSrc;
        this.audioTarget.play();
        this.playPauseTarget.innerHTML = '<i class="fas fa-pause"></i>';
        this.artistTitleTarget.textContent = artist.title;
        this.trackTitleTarget.textContent = track;
    }
}