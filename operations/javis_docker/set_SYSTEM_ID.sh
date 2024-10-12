JAVIS_IP="$(ifconfig | grep 10.3.1 | grep "inet " | awk '{print $2}') "

VAR1="Linuxize"
VAR2="Linuxize"
echo $JAVIS_IP

if [[ "$JAVIS_IP" == *"10.3.1.69"* ]]
then
  export JAVIS_SYSTEM_IP=mt000_test
fi

# if [ "$JAVIS_IP" = "10.3.1.9" ]; then
#     echo "Strings are equal."
# else
#     echo "Strings are not equal."
# fi
# mt000 = "10.3.1.69"

# if [["$JAVIS_IP" == "10.3.1.69" ]] 
# then
#   export JAVIS_SYSTEM_ID="mt000_test"
  
# elif( "$JAVIS_IP" = "10.3.1.9")
# then
#   export JAVIS_SYSTEM_ID="mt001"

# elif( "$JAVIS_IP" = "10.3.1.10")
# then
#   export JAVIS_SYSTEM_ID="mt002"
# fi  
