import { Controller } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'

// Seconds from the track start within which "previous" means "previous track";
// past it, "previous" restarts the current one (YouTube / Spotify behavior).
const RESTART_THRESHOLD_SECONDS = 3

export default class extends Controller {
    static targets = ["audio", "playPause", "seekSlider", "volumeSlider", "currentTime", "duration", "artistTitle", "trackTitle", "mute", "releaseLink", "progress"];

    initialize() {
        this.currentTrackId = null;
    }

    updatePlaySign(newTrackId) {
        if (this.currentTrackId) {
            document.querySelectorAll(`.play-sign[data-track-id="${this.currentTrackId}"]`)
                .forEach(sign => sign.classList.remove('active'));
        }

        document.querySelectorAll(`.play-sign[data-track-id="${newTrackId}"]`)
            .forEach(sign => sign.classList.add('active'));
        this.currentTrackId = newTrackId;
    }
    connect() {
        if (!this.hasAudioTarget) return;

        this.audioTarget.addEventListener("timeupdate", this.updateTime.bind(this));
        this.audioTarget.addEventListener("loadedmetadata", this.updateDuration.bind(this));
        this.audioTarget.addEventListener("ended", this.nextTrack.bind(this));

        document.querySelectorAll('.play-track')
            .forEach(button => button.addEventListener('click', this.playTrack.bind(this)));
    }

    async playTrack(event) {
        event.preventDefault();
        const trackId = event.currentTarget.getAttribute('data-track-id');
        if (trackId) await this.loadTrackData(trackId);
    }

    async loadTrackData(trackId) {
        try {
            const response = await fetch(`/player/${trackId}`);
            const data = await response.json();
            if (data.track?.data_src) {
                this.updateAudioSource(data.track);
            }
        } catch (error) {
            console.error('Error loading track data:', error);
        }
    }

    updateAudioSource({ data_src, artist, title, id }) {
        if (!this.hasAudioTarget) return;

        this.audioTarget.src = data_src;
        this.audioTarget.play().catch(error => console.error('Error playing audio:', error));

        if (this.hasSeekSliderTarget) this.seekSliderTarget.value = 0;
        if (this.hasCurrentTimeTarget) this.currentTimeTarget.textContent = '0:00';
        if (this.hasDurationTarget) this.durationTarget.textContent = '0:00';

        if (this.hasPlayPauseTarget) {
            this.playPauseTarget.innerHTML = '<i class="fas fa-pause"></i>';
        }
        if (this.hasArtistTitleTarget) {
            this.artistTitleTargets.forEach(el => el.textContent = artist || '');
        }
        if (this.hasTrackTitleTarget) {
            this.trackTitleTargets.forEach(el => el.textContent = title || '');
        }

        let release_id = null;
        const match = window.location.pathname.match(/\/releases\/(\d+)/);
        if (match) {
            release_id = match[1];
        }
        if (this.hasReleaseLinkTarget && release_id) {
            this.releaseLinkTarget.setAttribute('data-release-url', `/releases/${release_id}`);
        }

        this.updatePlaySign(id);
    }

    async nextTrack(event) {
        if (event) event.preventDefault();

        try {
            const response = await fetch('/player/next_track', {
                method: 'GET',
                headers: {
                    'Accept': 'application/json'
                }
            });
            const data = await response.json();
            if (data.track?.data_src) {
                this.updateAudioSource(data.track);
            }
        } catch (error) {
            console.error('Error fetching next track:', error);
        }
    }

    async previousTrack(event) {
        if (event) event.preventDefault();

        // Standard player behavior: restart the current track first,
        // and only skip to the previous one when already near its start.
        if (this.hasAudioTarget && this.audioTarget.currentTime > RESTART_THRESHOLD_SECONDS) {
            this.audioTarget.currentTime = 0;
            return;
        }

        try {
            const response = await fetch('/player/previous_track', {
                method: 'GET',
                headers: {
                    'Accept': 'application/json'
                }
            });
            const data = await response.json();
            if (data.track?.data_src) {
                this.updateAudioSource(data.track);
            }
        } catch (error) {
            console.error('Error fetching previous track:', error);
        }
    }

    togglePlayPause() {
        if (!this.hasAudioTarget || !this.hasPlayPauseTarget) return;

        if (this.audioTarget.paused) {
            this.audioTarget.play();
            this.playPauseTarget.innerHTML = '<i class="fas fa-pause"></i>';
        } else {
            this.audioTarget.pause();
            this.playPauseTarget.innerHTML = '<i class="fas fa-play"></i>';
        }
    }

    seek() {
        if (this.hasAudioTarget && this.hasSeekSliderTarget) {
            this.audioTarget.currentTime = this.audioTarget.duration * (this.seekSliderTarget.value / 100);
        }
    }

    adjustVolume() {
        if (this.hasAudioTarget && this.hasVolumeSliderTarget) {
            this.audioTarget.volume = this.volumeSliderTarget.value / 100;
        }
    }

    muteUnmute() {
        if (!this.hasAudioTarget || !this.hasMuteTarget || !this.hasVolumeSliderTarget) return;

        this.audioTarget.muted = !this.audioTarget.muted;
        if (this.audioTarget.muted) {
            this.muteTarget.innerHTML = '<i class="fas fa-volume-mute"></i>';
            this.volumeSliderTarget.value = 0;
        } else {
            this.muteTarget.innerHTML = '<i class="fas fa-volume-up"></i>';
            this.volumeSliderTarget.value = this.audioTarget.volume * 100;
        }
    }

    updateTime() {
        if (!this.hasAudioTarget || !this.hasSeekSliderTarget || !this.hasCurrentTimeTarget) return;

        const currentTime = this.audioTarget.currentTime;
        const duration = this.audioTarget.duration;
        // Until the metadata loads duration is NaN; writing NaN into a range
        // input makes the browser snap the thumb back to the middle.
        if (!Number.isFinite(duration) || duration <= 0) {
            this.seekSliderTarget.value = 0;
            this.currentTimeTarget.textContent = this.formatTime(currentTime || 0);
            return;
        }
        this.seekSliderTarget.value = (currentTime / duration) * 100;
        this.currentTimeTarget.textContent = this.formatTime(currentTime);
    }

    updateDuration() {
        if (this.hasDurationTarget) {
            this.durationTarget.textContent = this.formatTime(this.audioTarget.duration);
        }
    }

    formatTime(seconds) {
        const minutes = Math.floor(seconds / 60);
        const secs = Math.floor(seconds % 60);
        return `${minutes}:${secs < 10 ? "0" : ""}${secs}`;
    }

    navigateToRelease(event) {
        const releaseUrl = event.currentTarget.getAttribute('data-release-url');
        if (releaseUrl) Turbo.visit(releaseUrl);
    }
}