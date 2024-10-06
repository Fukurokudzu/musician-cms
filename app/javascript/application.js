// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

document.addEventListener('turbo:load', function() {
    const player = document.getElementById('music-player');
    const trackLinks = document.querySelectorAll('.play-track');
    // TODO: Implement hiding player when src is empty
    // const playerContainer = document.getElementById('player');

    trackLinks.forEach(link => {
        link.addEventListener('click', function(event) {
            event.preventDefault();
            player.src = this.getAttribute('data-src');
            player.play();
            // playerContainer.classList.remove('hidden');
        });
    });
});
