# Notes — Phase 5 : Observabilité & sécurité

Récap technique des galères et décisions prises pendant cette phase.

## 2FA sur Proxmox
TOTP activé sur le compte `root@pam` (application d'authentification + QR code), codes de récupération sauvegardés en lieu sûr. Referme un trou de sécurité identifié plus tôt dans le projet : l'accès web à Proxmox (shell intégré compris) équivaut à un accès root complet à l'hôte, jusque-là protégé par le seul mot de passe.

## cert-manager et CA interne
Installé via manifeste officiel (namespace `cert-manager`, 3 pods : `cert-manager`, `webhook`, `cainjector`). Une CA auto-signée a été mise en place (`selfsigned-issuer` → certificat `internal-ca` → `internal-ca-issuer`), adaptée à un usage interne (`.home`).

Distinction actée avec Let's Encrypt : les deux ne sont pas redondants, Let's Encrypt sera utilisé plus tard pour les services destinés à une exposition publique (site perso, serveur de jeu), la CA interne reste pour tout ce qui ne sort jamais du réseau local.

Testé et validé sur `auto-gw-report` : Ingress modifié avec un `host` et une section `tls`, certificat généré automatiquement par cert-manager, CA installée manuellement dans le magasin de confiance Windows → cadenas vert obtenu dans le navigateur.

## Prometheus + Grafana
Installés via Helm (`prometheus-community/kube-prometheus-stack`, namespace `monitoring`) — premier vrai usage de Helm sur ce projet, l'occasion de comprendre le fonctionnement des repos et des charts. Exposé en NodePort, mot de passe admin récupéré depuis le Secret Kubernetes généré automatiquement à l'installation. Dashboards préconfigurés explorés, notamment un exemple de suivi SLO/Error Budget.

## Loki + Promtail
Installés via Helm (`grafana/loki-stack`, même namespace `monitoring`). Trois problèmes rencontrés et résolus dans l'ordre :

1. **Incompatibilité de version** entre la version récente de Grafana et l'image Loki par défaut du chart — une erreur de parsing apparaissait sur le healthcheck (`unexpected IDENTIFIER`). Corrigé en forçant explicitement `loki.image.tag=2.9.11`.
2. **Résolution DNS obsolète** : après réinstallation de Loki, Promtail continuait de pointer vers l'ancien Service (IP interne désormais invalide). Résolu en redémarrant les pods Promtail.
3. **Logs manquants malgré le réseau réparé** : le namespace `default` restait absent des logs même après le fix réseau. Cause identifiée : le fichier de suivi de position de lecture de Promtail (`positions.yaml`) considérait les anciennes lignes (en échec d'envoi) comme déjà traitées, et n'attendait que des lignes nouvelles. Résolu en générant du trafic sur l'application pour produire de nouveaux logs.

Connecté à Grafana comme datasource, testé avec succès depuis l'interface Explore.

## Vault
Installé via Helm (`hashicorp/vault`), en mode non-dev (persistant, contrairement au mode dev qui perd tout au redémarrage).

**Blocages rencontrés, dans l'ordre :**
1. Pod bloqué en `Pending` — absence totale de StorageClass sur le cluster (voir [ADR 0004](decisions/0004-vault-storage-troubleshooting.md)).
2. Après résolution du stockage, `Pending` persistant toujours — cause différente cette fois : le nœud `twilight-town` était en `DiskPressure`, son volume logique LVM n'utilisant que 15 Go sur 30 Go disponibles côté groupe de volumes. Corrigé avec `lvextend` puis `resize2fs`.

**Initialisation** : tentée une première fois sans sauvegarder les clés de déverrouillage par erreur — PVC et pod supprimés puis recréés proprement (aucune perte réelle, le coffre n'avait jamais été déverrouillé donc ne contenait encore aucun secret). Réinitialisé une seconde fois, cette fois avec les clés et le root token correctement sauvegardés.

Déverrouillé selon le schéma de Shamir (seuil de 3 clés sur 5 nécessaires). Moteur de secrets KV v2 activé sous le chemin `homelab/`.

**Secrets centralisés** : `homelab/dockerhub-pull`, `homelab/dockerhub-ci`, `homelab/pihole`.

**Rotation de sécurité effectuée** : les tokens Docker Hub d'origine ont été régénérés (nouveaux tokens séparés en lecture seule et lecture/écriture), et propagés au secret Kubernetes `regcred` ainsi qu'à la variable `DOCKERHUB_TOKEN` de Gitea Actions.

## Network Policies (Calico)
Comportement par défaut testé avant toute restriction : n'importe quel pod du cluster (testé avec un pod `busybox` quelconque) pouvait joindre directement le Service `auto-gw-report-service`, en contournant complètement l'Ingress.

Une `NetworkPolicy` a été appliquée sur `auto-gw-report` pour n'autoriser que le trafic entrant depuis le namespace `ingress-nginx` (port 8000). Revalidé après application : l'accès direct pod-à-pod est désormais bloqué (timeout), tandis que l'accès via l'Ingress reste pleinement fonctionnel.

## Dette technique identifiée pendant cette phase
- Prometheus et Loki tournent actuellement **sans stockage persistant** (pas de PVC) — tout l'historique de métriques/logs est perdu à chaque redémarrage de pod. À corriger maintenant que `local-path-provisioner` est disponible.
- Statut du disque LVM de `radiant-garden` non vérifié — le même souci que `twilight-town` (DiskPressure) pourrait s'y trouver aussi.
- Le token de registration du runner Gitea n'a jamais été centralisé dans Vault — jugé non nécessaire, il s'agit d'un token à usage unique déjà consommé, sans secret actif à faire tourner.