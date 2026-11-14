# Roadmap — PoMAssistant : CI/CD, sécurité et exploitation


Objectif : héberger l'application **PoMAssistant** (Vue 3 / Vite / Supabase, écrite par un ami) sur le homelab, avec une chaîne CI/CD de bout en bout, sécurisée et supervisée. Mon rôle est d'héberger et d'industrialiser son cycle de vie, pas de la développer. Projet démarré le 19 octobre 2026, sur 6 mois dont 3 de travail effectif.

La roadmap de l'infrastructure (Proxmox, Kubernetes, DNS, etc.) est dans [ROADMAP.md](../ROADMAP.md).

Légende : `[x]` fait, `[~]` en cours ou partiel, `[ ]` prévu.

## Chaîne actuelle

```
Pull request vers main ou dev
   → scan du code (Trivy), tests (Vitest), construction de l'image sans publication, scan de l'image
   → vers dev uniquement : analyse SonarQube, Quality Gate bloquant

Push sur main ou dev
   → construction + publication sur GHCR (tag immuable AAAAMMJJ-HHMM-<sha court>)
   → commit GitOps dans homelab-devops (nouveau tag)
   → ArgoCD : mise à jour progressive, 2 réplicas, sans coupure
```

Le déploiement automatique ne concerne que l'environnement `dev` pour l'instant. L'analyse SonarQube et la protection complète (`tests`, `image`, `sonarqube`) sont en place sur `dev` ; `main` suivra.

## État initial et cible

| Domaine | Avant | Cible |
|---|---|---|
| Hébergement | Plateforme Netlify | Cluster Kubernetes du homelab, application sur 2 réplicas |
| Déploiement | Via Netlify, sans contrôle | CI/CD continue et automatique, chaque version reliée à son commit |
| Environnements | Chez un hébergeur externe | Environnements de test (`dev`) et de production séparés |
| Tests | Aucun test automatisé | Tests unitaires lancés à chaque modification |
| Sécurité | Aucune analyse automatique (mesuré : 7 vulnérabilités de production, 0 secret) | Analyses de sécurité avant la mise en ligne |
| Supervision | Pas de supervision propre | Métriques, logs, tableaux de bord |
| Authentification | Utilisateurs créés à la main dans la base | Création d'utilisateurs, sessions sécurisées |
| Base de données | Supabase | Supabase, une base pour le test et une autre pour la production |
| Haute disponibilité | Non | Application répliquée en production |

L'état initial mesuré est détaillé dans `etat-initial-pomassistant.md`.

## Phase 1 — tests, analyses de sécurité, déploiement automatique

- [x] Déploiement automatique par tag immuable (la CI modifie le dépôt d'infrastructure, ArgoCD déploie)
- [x] État initial figé et mesuré (scan Trivy du dépôt non modifié)
- [x] Correction des dépendances (`npm audit fix`) ; 8 alertes MODERATE restantes acceptées et documentées
- [x] Scan du code et scan de l'image, bloquants sur CRITICAL
- [x] Action tierce épinglée sur le hash de son commit
- [x] Image durcie : utilisateur non root, capacités retirées, seccomp, limites de ressources, sondes
- [x] Contrôles sur pull request (scans, tests, construction sans publication)
- [x] Premiers tests unitaires (Vitest), job `tests` aux droits minimaux, exécuté avant la construction de l'image
- [x] Protection de branche sur `dev` : PR obligatoire, contrôles `tests`, `image` et `sonarqube` obligatoires, sans contournement (blocage du bouton de fusion vérifié sur une vraie PR)
- [ ] Étendre la même protection à `main`, une fois la chaîne stabilisée sur `dev`
- [x] Tests des composables `useSyncPairFilters` et `useSyncPairOrder`
- [~] Étendre les tests : compte à rebours (`useCountdown`) après extraction du calcul dans une fonction pure
- [x] SonarQube (Community Build) installé sur `gummi-workshop` (Docker Compose, PostgreSQL) ; premier scan manuel : 5 remarques d'accessibilité, aucune vulnérabilité
- [x] SonarQube dans la CI : job `sonarqube` sur les pull requests vers `dev`, Quality Gate bloquant ; accès au serveur privé par Tailscale (identité fédérée OIDC, nœud éphémère, accès limité au seul port de SonarQube)
- [ ] Décider du rôle de CodeQL à côté de SonarQube
- [ ] Scan de l'image **avant** sa publication
- [ ] Dependabot (dépendances et actions GitHub)
- [ ] Rapport de scan initial et documentation dans `docs/`

## Phase 2 — supervision, alertes, production en haute disponibilité

- [ ] Alertes (Alertmanager) et tableaux de bord applicatifs : disponibilité, erreurs, temps de réponse
- [ ] Environnement `prod` : second projet Supabase, variables dédiées, mise à jour depuis `main`
- [ ] Application répliquée avec budget d'interruption (PodDisruptionBudget)
- [ ] Webhook pour une synchronisation immédiate (au lieu du polling toutes les 3 minutes)

## Phase 3 — évolutions, test de bout en bout, documentation

- [ ] Évolutions proposées à l'auteur par pull request (corrections repérées, ancien système de mots de passe à retirer)
- [ ] Test de bout en bout de la chaîne, du commit au pod
- [ ] Documentation finale et démonstration

## Suivi et points de vigilance

- Jetons `GITOPS_TOKEN` (limité au dépôt d'infrastructure) et `SONAR_TOKEN` (jeton d'analyse de projet), tous deux valables 90 jours : noter leur date de création et les renouveler à temps, sinon la CI ne pourra plus déployer ni analyser.
- Vérifier régulièrement que les pods tournent avec le dernier tag et que les runs sur `dev` sont verts.
