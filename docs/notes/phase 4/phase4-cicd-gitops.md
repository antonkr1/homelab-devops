# Notes — Phase 4 : CI/CD & GitOps

Récap technique des galères et décisions prises pendant la mise en place du pipeline CI/CD.

## Gitea — configuration réseau
Port SSH de Gitea décalé sur `2222` plutôt que le `22` par défaut, pour ne pas entrer en conflit avec le port SSH natif de la VM `gummi-workshop` déjà utilisé pour l'administration système.

## Pipeline CI — ce qu'il fait et ce qu'il ne fait pas
Le pipeline (Gitea Actions) build l'image Docker et la pousse sur Docker Hub à chaque push sur `main`. **Il n'exécute pas de tests applicatifs** (`pytest` ou équivalent) — le build agit comme un garde-fou implicite (une image qui ne compile pas n'est jamais poussée), mais ne détecte aucun bug fonctionnel dans le code. Identifié comme amélioration à faire, pas encore traitée.

Optimisation ajoutée en fin de session : un filtre sur les chemins surveillés (`app.py`, `requirements.txt`, `Dockerfile`) pour que le pipeline ne se déclenche que sur un vrai changement de code, pas sur une modification des manifestes Kubernetes versionnés dans le même repo.

## Authentification — deux tokens Docker Hub distincts
Un token **Read & Write** est utilisé côté CI (Gitea Actions) pour pousser les images. Un token **lecture seule** est utilisé côté cluster Kubernetes pour tirer (pull) les images — séparation volontaire des permissions selon le principe du moindre privilège.

## ArgoCD — authentification au dépôt Gitea
Connexion au repo via un **token d'accès personnel Gitea** (portée `repo: Read`), pas le mot de passe du compte — évite d'exposer les identifiants complets du compte pour un accès qui n'a besoin que de lire le dépôt.

## Piège rencontré : manifestes non versionnés
Les fichiers `deployment.yaml` et `ingress.yaml` de la Phase 3 avaient été créés directement sur la VM master via un éditeur en ligne de commande, sans jamais être commités nulle part. Il a fallu les rapatrier manuellement (VM master → PC → `docker-host`) avant de pouvoir les ajouter au repo Gitea et laisser ArgoCD s'en servir comme source de vérité — bon rappel que "ça tourne sur le cluster" ne veut pas dire "c'est versionné".

## Test de validation du flux GitOps complet
Un changement simple (`replicas: 1 → 2`) poussé sur Gitea a été repris automatiquement par ArgoCD et appliqué sur le cluster, confirmant que la chaîne complète fonctionne de bout en bout. Point notable : la synchronisation n'est pas instantanée par défaut — ArgoCD fonctionne par polling (vérification périodique du dépôt, environ toutes les 3 minutes), une vraie réactivité immédiate nécessiterait de configurer un webhook Gitea → ArgoCD (non fait à ce stade).

## Dette technique identifiée à ce stade
- Pas de tests applicatifs dans le pipeline CI
- Pas de webhook Gitea → ArgoCD (sync par polling uniquement)
- Tokens (Gitea, Docker Hub) ayant transité en clair pendant la configuration — à révoquer/régénérer par précaution
- Pas de `host:` défini sur la ressource Ingress (wildcard actuel) — fonctionne tant qu'une seule app est exposée, à corriger dès qu'une deuxième application sera déployée
- Pas de stockage persistant Kubernetes (StorageClass) configuré — c'est ce qui a motivé le choix d'héberger Gitea hors cluster plutôt que dessus