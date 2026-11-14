#!/usr/bin/env bash
set -u

declare -A SERVICES=(
    ["Grafana"]="https://grafana.home"
    ["ArgoCD"]="https://argocd.home"
    ["PoMassistant"]="https://pom.home"
    ["SonarQube"]="http://192.168.1.205:9000/api/system/status"
    ["Pi-Hole"]="http://gummi-workshop.home/admin/"
    # ["Test failure"]="http://testfailure.home"

)

failed=0

for nom in "${!SERVICES[@]}"; do
    url="${SERVICES[$nom]}"
    echo "Checking ${url}..."
    code=$(curl -k -s -o /dev/null -w "%{http_code}" "${url}" --max-time 5)
    if [ "$code" -ge 200 ] && [ "$code" -lt 400 ]; then
        echo "${nom} OK - HTTP : ${code}"
    else
        echo "${nom} Off - HTTP : ${code}"
        failed=$((failed + 1))
    fi
done

echo "Nombre de fail : $failed"
exit $failed
