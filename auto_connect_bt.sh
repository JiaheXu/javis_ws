#!/usr/bin/env bash

DEVICE="C5:23:67:15:F6:25"
#ADAPTER="CC:47:40:6F:C6:AE"

while true; do
    CONNECTED=$(bluetoothctl info $DEVICE | grep "Connected: yes")

    if [ -z "$CONNECTED" ]; then
        echo "[BT] reconnecting..."
        bluetoothctl connect $DEVICE
    fi

    sleep 20
done

