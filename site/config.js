// Replaced at deploy time (scripts/deploy-site.sh) and at container start (docker/40-orrery-config.sh).
// An empty apiUrl turns the live quiz stats off, so the page also works with no backend.
window.ORRERY_CONFIG = { apiUrl: "" };
