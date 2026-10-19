# ADR 0001 — Proxmox VE plutôt que k8s bare-metal

**Statut** : accepté
**Date** : 2026-08-04

## Contexte

Une seule machine physique disponible (i5-9600KF, 16-32 Go RAM). Objectif : apprendre Kubernetes dans des conditions proches d'un vrai environnement distribué, pas juste un cluster single-node.

## Options considérées

- **Bare-metal** (k8s installé directement sur Ubuntu Server) : zéro overhead RAM/CPU, plus simple, mais un seul nœud "physique" — perd l'aspect distribué du cluster.
- **Proxmox VE + VMs** : permet de créer plusieurs VMs = plusieurs nœuds k8s indépendants (master + workers), simule un vrai cluster distribué. Coût : overhead RAM par VM.

## Décision

Proxmox VE, avec 2 VMs pour commencer (1 master + 1 worker), extensible à 3 si upgrade RAM à 32 Go.

## Conséquences

- RAM devient la ressource limitante du projet → upgrade à 32 Go recommandé.
- Gain en compétence virtualisation, très recherchée en entreprise en plus de Kubernetes.
- Snapshots Proxmox facilitent l'expérimentation sans risque (rollback rapide en cas de casse).
