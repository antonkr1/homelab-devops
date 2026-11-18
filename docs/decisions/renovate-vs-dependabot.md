# Renovate plutôt que Dependabot

Date : 18 novembre 2026.

## Contexte

Les dépendances du projet (paquets npm, actions GitHub) doivent être mises à jour régulièrement, et les actions de la CI sont épinglées sur le hash de leur commit : l'outil choisi doit savoir maintenir ces épinglages.

## Décision

Renovate remplace Dependabot, configuré sur la branche `dev`. Première PR fusionnée le 18 novembre (#18, épinglage des dépendances).

## Raisons

- **Épinglage des actions** : les actions tierces de la CI sont épinglées sur le hash de leur commit. Renovate a un préréglage dédié (`helpers:pinGitHubActionDigests`) qui les épingle puis maintient ce hash à jour.
- **Plus flexible** : regroupement des mises à jour par règles (`packageRules`), plus de gestionnaires de paquets, et mise à jour des versions écrites dans n'importe quel fichier (Dockerfile, manifests).

## Contrepartie

Outil tiers à autoriser sur le dépôt, avec plus de réglages à maintenir que Dependabot, qui est intégré à GitHub.

## Sources

