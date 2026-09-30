# Notes — Terraform (provisioning automatisé)

## VM control node : gummi-ship
Création d'une VM dédiée (192.168.1.207, 2 Go RAM / 2 cœurs / 20 Go) pour piloter Ansible et Terraform vers le reste du homelab — pattern classique en DevOps (une machine centrale plutôt que son PC perso). Ansible ne tourne pas nativement sur Windows, d'où cette VM plutôt que WSL.

## Outils installés
Ansible (via le PPA officiel, plus à jour que les dépôts Ubuntu standards) et Terraform (dépôt officiel HashiCorp, avec vérification de clé GPG) installés sur `gummi-ship`.

## Authentification Proxmox
Un API Token dédié créé dans Proxmox (`root@pam!terraform`, Privilege Separation désactivée pour simplicité en usage perso). Stocké pour l'instant dans les fichiers Terraform — migration vers Vault prévue plus tard, cohérent avec la gestion des secrets déjà en place pour Docker Hub/Pi-hole.

## Template cloud-init Ubuntu — le prérequis clé
Sans template cloud-init, Terraform ne peut pas automatiser une installation Ubuntu classique (l'installateur interactif reste manuel). Le template permet de cloner une VM déjà "prête", configurée automatiquement au premier boot (IP, utilisateur, clé SSH) — aucune intervention manuelle après clonage.

Construit à partir de l'image cloud officielle Ubuntu 24.04 (pas une ISO classique), importée et configurée sur Proxmox comme template réutilisable.

**Bug rencontré** : la première tentative d'attachement du disque n'a pas fonctionné correctement (resté non attaché plutôt que sur le bon contrôleur) — chaque VM clonée héritait du même défaut (impossible de démarrer). Diagnostiqué en inspectant la config de la VM, corrigé en réappliquant la configuration disque/boot directement sur le template, puis en recréant les clones.

## Organisation des fichiers Terraform
Un dossier séparé par groupe de VMs indépendant (chaque dossier garde son propre état Terraform — un `destroy` dans un dossier n'affecte pas les VMs des autres dossiers), plutôt que tout centraliser dans un seul fichier partagé, sauf si les VMs sont réellement liées entre elles.

## Résultat validé
Première VM clonée automatiquement : IP fixe et clé SSH publique injectées automatiquement par cloud-init, connexion immédiate sans mot de passe. Temps de création de quelques secondes, contre 15-20 minutes pour une installation manuelle via ISO (comme fait pour les VMs précédentes du homelab).
