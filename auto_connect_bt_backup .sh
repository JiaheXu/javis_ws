#!/bin/bash
# Delay to allow Bluetooth stack to come up
sleep 6

# Your adapter and device addresses
ADAPTER="CC:47:40:6F:C6:AE"
DEVICE="EC:83:50:80:4E:B9"

# Ensure the adapter is up
bluetoothctl <<EOF
select $ADAPTER
power on
connect $DEVICE
exit
EOF
