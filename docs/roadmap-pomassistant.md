# Roadmap - PoMAssistant : CI/CD, sécurité et exploitation

Dernière mise à jour : 18 novembre 2026.

Objectif : héberger l'application **PoMAssistant** (Vue 3 / Vite / Supabase, écrite par un ami) sur le homelab, avec une chaîne CI/CD de bout en bout, sécurisée et supervisée. Mon rôle est d'héberger et d'industrialiser son cycle de vie, pas de la développer. Projet démarré le 19 octobre 2026.

La roadmap de l'infrastructure (Proxmox, Kubernetes, DNS, etc.) est dans [ROADMAP.md](../ROADMAP.md).

Légende : `[x]` fait, `[~]` en cours ou partiel, `[ ]` prévu.

## Chaîne actuelle

```
Pull request vers main ou dev
   → scan du code (Trivy), tests (Vitest), construction de l'image sans publication, scan de l'image
   → analyse de sécurité du code (CodeQL)
   → vers dev uniquement : analyse SonarQube, Quality Gate bloquant

Push sur main ou dev
   → construction de l'image (sans publication), scan Trivy de l'image
   → publication sur GHCR seulement si le scan est vert (tag immuable AAAAMMJJ-HHMM-<sha court>)
   → commit GitOps dans homelab-devops (nouveau tag)
   → ArgoCD : mise à jour progressive, 2 réplicas, sans coupure
```

Le déploiement automatique ne concerne que l'environnement `dev` pour l'instant. La protection complète (`tests`, `image`, `analyze (javascript-typescript)`, `sonarqube`) est en place sur `dev` et sur `main`. SonarQube ne s'exécute pour l'instant que sur les PR vers `dev` : la condition du job est en cours d'élargissement aux PR vers `main` (voir Mois 1).

## État initial et cible

| Domaine | Avant | Cible | Outils |
|---|---|---|---|
| Hébergement | Plateforme Netlify | Cluster Kubernetes du homelab, application sur 2 réplicas | Kubernetes, Docker |
| Déploiement | Via Netlify, sans contrôle | CI/CD continue et automatique, chaque version reliée à son commit | GitHub Actions, ArgoCD (GitOps) |
| Environnements | Chez un hébergeur externe | Environnements de test (`dev`) et de production séparés | Environnements GitHub, Kubernetes |
| Tests | Aucun test automatisé | Tests unitaires lancés à chaque modification | Vitest dans le pipeline |
| Sécurité | Aucune analyse automatique (mesuré : 7 vulnérabilités de production, 0 secret) | Analyses de sécurité avant la mise en ligne | Détection de secrets, scan des dépendances et des images (Trivy), analyse statique du code (SonarQube, CodeQL), mise à jour automatique des dépendances (Renovate), Vault |
| Supervision | Pas de supervision propre | Métriques, logs, tableaux de bord | Prometheus, Grafana, Loki |
| Authentification | Utilisateurs créés à la main dans la base | Création d'utilisateurs, sessions sécurisées | Supabase Auth |
| Base de données | Supabase | Supabase, une base pour le test et une autre pour la production | Supabase, PostgreSQL |
| Haute disponibilité | Non | Application répliquée en production | PodDisruptionBudget |

L'état initial mesuré est détaillé dans `etat-initial-pomassistant.md`.

## Mois 1 - tests, analyses de sécurité, déploiement automatique

- [x] Déploiement automatique par tag immuable (la CI modifie le dépôt d'infrastructure, ArgoCD déploie)
- [x] État initial figé et mesuré (scan Trivy du dépôt non modifié)
- [x] Correction des dépendances (`npm audit fix`) ; 8 alertes MODERATE restantes acceptées et documentées
- [x] Scan du code et scan de l'image, bloquants sur CRITICAL
- [x] Action tierce épinglée sur le hash de son commit
- [x] Image durcie : utilisateur non root, capacités retirées, seccomp, limites de ressources, sondes
- [x] Contrôles sur pull request (scans, tests, construction sans publication)
- [x] Premiers tests unitaires (Vitest), job `tests` aux droits minimaux, exécuté avant la construction de l'image
- [x] Protection de branche sur `dev` : PR obligatoire, contrôles `tests`, `image`, `sonarqube` et `analyze (javascript-typescript)` obligatoires, sans contournement (blocage du bouton de fusion vérifié sur une vraie PR)
- [x] Protection de `main` : PR obligatoire, contrôles `tests`, `image`, `analyze (javascript-typescript)` et `sonarqube`, branche à jour avant fusion, sans contournement ; blocage du bouton de fusion vérifié sur une PR `dev` vers `main` (18 novembre)
- [~] Corriger la condition du job `sonarqube` : il était sauté sur les PR vers `main` (un contrôle sauté compte comme réussi, l'obligation ne vérifiait donc rien) ; correction en cours sur `dev`, puis vérification sur la PR `dev` vers `main`
- [x] Tests des composables `useSyncPairFilters`, `useSyncPairOrder`, `useMonthlyOrder` et `useMonthly`
- [~] Étendre les tests : compte à rebours (`useCountdown`) après extraction du calcul dans une fonction pure
- [x] SonarQube (Community Build) installé sur `gummi-workshop` (Docker Compose, PostgreSQL) ; premier scan manuel : 5 remarques d'accessibilité, aucune vulnérabilité
- [x] SonarQube dans la CI : job `sonarqube` sur les pull requests vers `dev`, Quality Gate bloquant ; accès au serveur privé par Tailscale (identité fédérée OIDC, nœud éphémère, accès limité au seul port de SonarQube)
- [x] CodeQL (analyse de sécurité du code JS/TS) en complément de SonarQube : workflow versionné `.github/workflows/codeql.yml`, sur push et PR vers `main` et `dev` plus une analyse hebdomadaire, contrôle obligatoire sur `dev` ; aucune alerte à ce jour
- [x] Sauvegarde de SonarQube planifiée chaque nuit (`cron`) et restauration testée (16 novembre)
- [x] Étape `curl` de diagnostic retirée du job `sonarqube`
- [ ] Contrôles adaptés à la nature de la modification : filtres de chemins, `CODEOWNERS` sur les zones sensibles
- [x] Scan de l'image **avant** sa publication : le job `image` construit sans publier (`load: true`), scanne avec Trivy, puis ne publie qu'ensuite (push uniquement) ; une image vulnérable n'atteint plus GHCR, vérifié de bout en bout sur `dev`
- [x] Mises à jour automatiques : Renovate (en remplacement de Dependabot), configuré sur la branche `dev` ; première PR fusionnée (épinglage des dépendances, #18) ; choix expliqué dans [renovate.md](docs\decisions\renovate-vs-dependabot.md)
- [] Tester les mises à jour de Renovate sur les actions GitHub (`checkout@v4`, Node 20 en fin de support)
- [ ] Rapport de scan initial et documentation dans `docs/`

## Mois 2 - supervision, alertes, production en haute disponibilité

- [~] Stockage persistant pour la supervision (Prometheus, Loki)
- [ ] Alertes (Alertmanager) et tableaux de bord applicatifs : disponibilité, erreurs, temps de réponse
- [ ] Environnement `prod` : second projet Supabase, variables dédiées, mise à jour depuis `main`
- [ ] Application répliquée avec budget d'interruption (PodDisruptionBudget)
- [ ] Webhook pour une synchronisation immédiate (au lieu du polling toutes les 3 minutes)

## Mois 3 - évolutions, test de bout en bout, documentation

- [ ] Évolutions proposées à l'auteur par pull request (corrections repérées, ancien système de mots de passe à retirer)
- [ ] Test de bout en bout de la chaîne, du commit au pod
- [ ] Documentation finale et démonstration

## Suivi et points de vigilance

- GitHub rapproche les contrôles obligatoires par nom et par commit, pas par événement : un contrôle sauté compte comme réussi. Vérifier qu'un contrôle obligatoire s'exécute vraiment sur chaque type de PR.
- Vérifier régulièrement que les pods tournent avec le dernier tag et que les runs sur `dev` sont verts.

