#!/bin/ash
IFS=$'\n'
while true; do
#  echo "cycle"
  for LINE in $(iwinfo wlan0 assoclist | grep SNR); do
    MAC=$(echo "$LINE" | awk '{ print $1 }')
    SIGNAL=$(echo "$LINE" | awk '{ print $2 }')
    MAC_PREFIX=$(echo "$MAC" | sed -e 's/://g' | cut -c1-6)
#    echo "$MAC $SIGNAL"

    if [ "$SIGNAL" -lt "-80" ]; then
#      echo "$MAC $SIGNAL"
      if ! find /tmp | grep "angry_wifi_client_$MAC" > /dev/null; then
        date ; logger -s -t angry_wifi "Low signal client $MAC ($SIGNAL) disconnect."
	ubus call hostapd.wlan0 del_client "{'addr':'$MAC', 'reason':5, 'deauth':false, 'ban_time':0}"

	# Add to do-not-disconnect list                                                                                                                                           
        touch "/tmp/angry_wifi_client_${MAC}_$(date +%s)"
      fi
    fi
  done
  # Remove from the do-not-disconnect list
  CURDATE=$(date +%s)
  for FILE in $(find /tmp | grep angry_wifi_client); do
    TIME=$(echo "$FILE" | cut -d'_' -f 5)
    TIME_SINCE=$((CURDATE - TIME))
    MAC=$(echo "$FILE" | cut -d'_' -f 4)

    if [ "$TIME_SINCE" -gt "120" ]; then
      date ; logger -s -t angry_wifi "Low signal client $MAC removed from do-not-disconnect."
      rm "$FILE"
    fi
  done
  sleep 5
done
