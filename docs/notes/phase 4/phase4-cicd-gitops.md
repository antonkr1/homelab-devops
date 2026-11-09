> **Archive** : chaîne CI/CD d'origine (Gitea + Gitea Actions + Docker Hub), remplacée depuis par GitHub Actions + GHCR + ArgoCD. Les principes (moindre privilège, source de vérité dans Git, sync par polling) restent valables. Voir la note PoMAssistant pour la chaîne actuelle.

# Notes — Phase 4 : CI/CD & GitOps

Récap technique de la mise en place de la première pipeline CI/CD.

## Gitea — configuration réseau
Port SSH de Gitea décalé sur `2222` plutôt que le `22` par défaut, pour ne pas entrer en conflit avec le port SSH natif de la VM `gummi-workshop` déjà utilisé pour l'administration système.

## Pipeline CI — ce qu'il fait et ce qu'il ne fait pas
Le pipeline (Gitea Actions) build l'image Docker et la pousse sur Docker Hub à chaque push sur `main`. **Il n'exécute pas de tests applicatifs** (`pytest` ou équivalent), le build agit comme un garde-fou implicite (une image qui ne compile pas n'est jamais poussée), mais ne détecte aucun bug fonctionnel dans le code. Identifié comme amélioration à faire, pas encore traitée.

Optimisation ajoutée en fin de session : un filtre sur les chemins surveillés (`app.py`, `requirements.txt`, `Dockerfile`) pour que le pipeline ne se déclenche que sur un vrai changement de code, pas sur une modification des manifestes Kubernetes versionnés dans le même repo.

## Authentification — deux tokens Docker Hub distincts
Un token **Read & Write** est utilisé côté CI (Gitea Actions) pour pousser les images. Un token **lecture seule** est utilisé côté cluster Kubernetes pour tirer (pull) les images. Séparation volontaire des permissions selon le principe du moindre privilège.

## ArgoCD — authentification au dépôt Gitea
Connexion au repo via un **token d'accès personnel Gitea** (portée `repo: Read`), pas le mot de passe du compte, évite d'exposer les identifiants complets du compte pour un accès qui n'a besoin que de lire le dépôt.

## Test de validation du flux GitOps complet
Un changement simple (`replicas: 1 → 2`) poussé sur Gitea a été repris automatiquement par ArgoCD et appliqué sur le cluster, confirmant que la chaîne complète fonctionne de bout en bout. Point notable : la synchronisation n'est pas instantanée par défaut, ArgoCD fonctionne par polling (vérification périodique du dépôt, environ toutes les 3 minutes), une vraie réactivité immédiate nécessiterait de configurer un webhook Gitea → ArgoCD (non fait à ce stade).

## Suites données
- **Tests applicatifs dans la CI** : traité plus tard sur la nouvelle chaîne (tests Vitest et scans Trivy, bloquants sur chaque pull request).
- **Webhook vers ArgoCD** : jamais mis en place, la synchronisation reste par polling (~3 min).
- **Ingress sans `host:`** : a bien posé problème dès qu'une deuxième application a été exposée (il captait les requêtes destinées à d'autres noms). Corrigé en définissant un `host` sur chaque Ingress.
- **Stockage persistant** : `local-path-provisioner` installé depuis (StorageClass par défaut). Gitea a ensuite été abandonné au profit de GitHub.