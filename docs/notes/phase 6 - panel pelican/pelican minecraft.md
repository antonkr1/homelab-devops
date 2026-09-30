# Notes — Pelican Panel, serveur Minecraft, exposition externe

## Tentative Kubernetes abandonnée
Un déploiement de Pelican Panel avait été tenté sur le cluster K8s, mais le déploiement Docker/conteneurisé du projet Pelican est encore instable et officiellement "work in progress" à ce stade. Décision : abandon de cette piste, retour à un docker-compose classique sur une VM dédiée (`hundred-acre-wood`), qui a fonctionné du premier coup.

## Panel Pelican — configuration réseau
Déployé avec `network_mode: host` (nécessaire : en réseau Docker isolé, le container ne pouvait pas joindre Wings sur l'IP de son propre hôte). Conséquence : Caddy ne pouvait plus bind sur le port 80 (`permission denied`) — corrigé avec `cap_add: NET_BIND_SERVICE`.

## Wings
Installé en binaire natif (pas en container), service systemd dédié. FQDN configuré en IP brute (`.home` refusé par la validation du formulaire), SSL désactivé en conséquence — à revoir avec un vrai nom de domaine.

Piège rencontré : un test `wings --debug` interrompu au `Ctrl+C` a laissé un processus fantôme bloquant le port pour le vrai service systemd — identifié via `ss -tulpn`, tué manuellement.

## Serveur Minecraft
Créé via l'Egg Paper : 2048 Mo RAM, 10 Go disque, port 25565. Whitelist activée par défaut, gérée depuis la console.

## Domaine et exposition externe
Domaine `traverse-town.com` acheté (Cloudflare). Enregistrement A (`direct.traverse-town.com`) séparé du nom public utilisé pour se connecter. Enregistrement SRV pour la connexion sans port — piège rencontré : le SRV doit correspondre exactement au sous-domaine tapé par le joueur (`mc`), pas au nom de l'enregistrement A cible.

Redirection de port sur la Freebox : externe 49565 → 192.168.1.206:25565 (la Freebox impose des ports externes > 49152).

**Statut final : connexion externe sans port validée et fonctionnelle.**

## Dette technique restante
- Pelican Panel et Wings tournent en HTTP simple, sans certificat — accès géré via Tailscale uniquement, pas d'exposition publique prévue pour le Panel.