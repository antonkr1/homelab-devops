# Comprendre les modules d'un cluster Kubernetes

Ce document explique les concepts clés rencontrés pendant le montage du cluster (Phase 3), pour garder une trace claire de ce qui se passe sous le capot au-delà des simples commandes exécutées.

## Prérequis système avant kubeadm

Kubernetes, installé "à la main" via kubeadm, impose plusieurs réglages système obligatoires sur **chaque nœud**, pas seulement le master :

- **La mémoire d'échange (swap) doit être désactivée** — kubeadm gère lui-même précisément l'allocation mémoire des pods, et la swap viendrait fausser ce contrôle.
- **Deux modules du noyau Linux doivent être actifs** : l'un gère le système de fichiers en couches utilisé par les conteneurs, l'autre rend le trafic réseau interne aux conteneurs visible par les règles de pare-feu du système — sans ça, la mise en réseau entre pods ne fonctionne pas correctement.
- **Le routage réseau doit être explicitement autorisé** au niveau du système, pour permettre au trafic de circuler entre des pods hébergés sur des nœuds différents.
- **Un outil de suivi des connexions réseau** (`conntrack`) est requis par un composant interne de Kubernetes chargé de la gestion du réseau des services — absent par défaut sur une installation Ubuntu Server minimale.

## Le CIDR (Classless Inter-Domain Routing)

Le CIDR est simplement une **notation pour décrire une plage d'adresses IP** (ex : `10.244.0.0/16` représente toutes les adresses de `10.244.0.0` à `10.244.255.255`). Dans un cluster Kubernetes, le "pod network CIDR" définit la plage d'adresses IP **réservée aux pods** — chaque pod reçoit une IP interne au cluster, distincte des adresses IP des machines physiques/virtuelles elles-mêmes.

**Pourquoi c'est sensible** : cette plage doit être **totalement disjointe** du réseau physique réel (le réseau domestique dans ce cas, `192.168.1.0/24`). Si les deux plages se chevauchent, le système ne sait plus distinguer une adresse de pod d'une adresse d'appareil réel sur le réseau local, ce qui casse le routage. C'est pour cette raison qu'on utilise une plage volontairement différente et standardisée (`10.244.0.0/16` est la valeur attendue par défaut par le CNI Calico).

## Le CNI (Container Network Interface)

Le CNI est le composant qui **donne vie au réseau des pods**. Sans lui :
- Les pods n'ont pas d'adresse IP interne fonctionnelle
- Aucun routage n'est possible entre les pods situés sur des nœuds différents
- Le nœud reste bloqué dans un état "non prêt" (`NotReady`), même si le control plane est par ailleurs sain

Techniquement, un CNI est une **spécification** (une norme) que plusieurs implémentations respectent — Calico, Flannel, Cilium en sont des exemples. Une fois installé, le CNI choisi (ici Calico) déploie un **agent sur chaque nœud du cluster**, chargé de :
- Attribuer une IP à chaque pod créé sur ce nœud, dans la plage définie par le CIDR
- Router le trafic entre les pods, y compris entre des pods hébergés sur des nœuds physiquement différents
- Appliquer les règles de sécurité réseau (network policies) si elles sont configurées

Le passage d'un nœud de l'état `NotReady` à `Ready` juste après l'installation du CNI confirme que le réseau des pods est désormais opérationnel.

## La jointure des workers au cluster (kubeadm join)

Quand le control plane est initialisé sur le master, celui-ci génère un **token temporaire** (valide 24h par défaut) — une sorte de preuve d'identité à usage limité dans le temps.

Le processus de jointure repose sur une confiance mutuelle :
- Le **worker** présente ce token pour prouver qu'il est autorisé à rejoindre ce cluster précis (et pas n'importe quel cluster Kubernetes qui traînerait sur le réseau)
- Le worker vérifie en retour une **empreinte cryptographique du certificat du control plane** — ça lui permet de s'assurer qu'il communique bien avec le vrai master, et pas avec un faux control plane qui usurperait son identité sur le réseau

Une fois la jointure réussie, le worker devient un nœud à part entière du cluster : il reçoit des instructions du control plane (créer, déplacer, supprimer des pods) et exécute les charges de travail qui lui sont assignées.

**Point de logique important** : l'outil de pilotage du cluster (`kubectl`) n'est utile et configuré **que sur le master**. Les workers ne pilotent jamais le cluster eux-mêmes, ils ne font qu'exécuter ce qu'on leur demande — pas besoin d'y configurer `kubectl`.

## L'Ingress

Par défaut, les services d'un cluster Kubernetes ne sont pas directement accessibles depuis l'extérieur du cluster de façon pratique — un **Ingress** est la brique qui gère l'**entrée du trafic externe** vers les bons services internes, un peu comme un standardiste qui redirige les appels entrants vers le bon interlocuteur.

Concrètement, l'Ingress permet de :
- Exposer plusieurs services internes via une seule entrée réseau (au lieu d'un port différent pour chaque service)
- Router le trafic selon le **nom d'hôte** demandé ou le **chemin de l'URL** (ex : `app1.mondomaine.local` va vers un service, `app2.mondomaine.local` vers un autre)
- Gérer le HTTPS/TLS de façon centralisée, plutôt que dans chaque application individuellement

Un Ingress a besoin d'un **contrôleur** pour fonctionner réellement (ici, nginx-ingress) — l'objet "Ingress" décrit les règles de routage souhaitées, le contrôleur les applique concrètement.

**Dans ce homelab**, l'Ingress est exposé via **NodePort** (un port ouvert directement sur chaque nœud du cluster, identique sur les trois), en attendant la mise en place d'un vrai nom de domaine interne via un DNS local. C'est une méthode d'exposition simple, adaptée à un cluster bare-metal comme celui-ci (pas de load balancer cloud disponible comme chez un vrai fournisseur cloud).
