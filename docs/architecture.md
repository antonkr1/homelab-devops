# Architecture

## Vue d'ensemble

```
┌─────────────────────────────────────────────┐
│              Serveur physique                │
│         i5-9600KF · 32 Go RAM · SSD 1To      │
└──────────────────────┬────────────────────────┘
                        │
                 ┌──────▼──────┐
                 │  Proxmox VE  │  (hyperviseur)
                 └──────┬──────┘
          ┌─────────────┼─────────────┐
          │             │             │
    ┌─────▼─────┐ ┌─────▼─────┐ ┌─────▼─────┐
    │  VM master │ │ VM worker1│ │ VM worker2│
    │  Ubuntu +  │ │ Ubuntu +  │ │ Ubuntu +  │
    │    k3s     │ │    k3s    │ │    k3s    │
    └────────────┘ └───────────┘ └───────────┘
```

## Couches applicatives sur le cluster k3s

- **Ingress** : Traefik (fourni avec k3s par défaut)
- **CI/CD** : Gitea (dépôt Git self-hosted) + runner CI + ArgoCD (GitOps)
- **Observabilité** : Prometheus (métriques) + Grafana (dashboards) + Loki (logs)
- **Sécurité** : Vault (secrets), cert-manager (TLS auto)
- **Apps hébergées** : à définir (Nextcloud, Pi-hole, Jellyfin, blog perso...)

## Réseau

- IP fixe réservée sur le routeur (réservation DHCP par adresse MAC)
- Accès SSH par clé uniquement, pas de mot de passe

## Décisions

Voir [decisions/](decisions/) pour le détail argumenté de chaque choix technique.
