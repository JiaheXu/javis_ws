# JAVIS Start Services

The JAVIS payload has setup that all the javis launches happen on startup.

The user can disable or enable any of the startup services.

# Create a Startup Script

1. Create your startup script

        vim ~/javis_ws/src/javis_utils/scripts/[service-name].sh

    - see as example: `~/javis_ws/src/javis_utils/services/scripts/myservice_example.sh`

2. Change permissions of script

        sudo chmod +x ~/javis_ws/src/javis_utils/scripts/[service-name].sh

3. Create asystemd service file:

    - see as example: `~/javis_ws/src/javis_utils/services/myservice_example.service`

4. Copy over service file:

        # Copy over service file
        sudo cp ~/javis_ws/src/javis_utils/services/[service-name].service /etc/systemd/system/

        # Change permissions
        sudo chmod 644 /etc/systemd/system/[service-name].service

5. Enable Service:

        # enable service to start on boot
        sudo systemctl enable [service-name]

# Remove Startup Script

1. Stop Service

        sudo systemctl stop [service-name]

2. Disable Service

        sudo systemctl disable [service-name]

3. Remove service file

        sudo rm /etc/systemd/system/[service-name].service

4. Restart your system
