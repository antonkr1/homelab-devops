#!/usr/bin/env bash

# Tourne sur la même VM que SonarQube (gummi-workshop) et sauvegarde la base de données PostgreSQL de SonarQube dans un zip avec la date et l'heure. Supprime les anciennes sauvegardes en gardant les 7 dernières.
set -euo pipefail

BACKUP_DIR="$HOME/backups/sonarqube"
COMPOSE_DIR="$HOME/sonarqube"
KEEP_LAST=7
FICHIER="$BACKUP_DIR/sonarqube_$(date +%Y%m%d_%H%M%S).sql.gz"

mkdir -p "$BACKUP_DIR" && chmod 700 "$BACKUP_DIR"
if ! docker compose -f "$COMPOSE_DIR/docker-compose.yml" exec -T db pg_dump -U sonar sonar |gzip > "$FICHIER"; then
    rm -f "$FICHIER"
    echo "Erreur lors de la sauvegarde de la base de données SonarQube" >&2
    exit 1 
fi

find "$BACKUP_DIR" -name "sonarqube_*.sql.gz" -type f | sort | head -n "-$KEEP_LAST" | xargs -r rm
echo "Sauvegarde de la base de données SonarQube terminée avec succès. Fichier : $FICHIER"