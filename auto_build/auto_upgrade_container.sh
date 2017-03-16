#!/bin/bash

# Récupère le dossier du script
if [ "${0:0:1}" == "/" ]; then script_dir="$(dirname "$0")"; else script_dir="$(echo $PWD/$(dirname "$0" | cut -d '.' -f2) | sed 's@/$@@')"; fi

type=$1

# Vérifie que le CI ne tourne pas
timeout=7200	# Durée d'attente maximale
inittime=$(date +%s)	# Enregistre l'heure de début d'attente
while test -e "$script_dir/../CI.lock"; do	# Vérifie la présence du lock de du CI
	sleep 60	# Attend la fin de l'exécution du CI.
	if [ $(( $(date +%s) - $inittime )) -ge $timeout ]	# Vérifie la durée d'attente
	then	# Si la durée dépasse le timeout fixé, force l'arrêt.
		inittime=0	# Indique l'arrêt forcé du script
		echo "Temps d'attente maximal dépassé, la mise à jour est annulée."
		break
	fi
done

touch "$script_dir/../CI.lock"	# Replace le lock le temps de la mise à jour.

# Change le snapshot du conteneur avant de procéder à l'upgrade
sudo "$script_dir/switch_container.sh" $type >> "$script_dir/../package_check/upgrade.log" 2>&1

# Démarre la mise à jour du conteneur.
sudo "$script_dir/../package_check/sub_scripts/auto_upgrade.sh" >> "$script_dir/../package_check/upgrade.log" 2>&1

rm "$script_dir/../CI.lock"
