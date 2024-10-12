#!/usr/bin/env bash

# load header helper functions
. "$JAVIS_OPERATIONS/javis_utils/scripts/header.sh"
. "$JAVIS_OPERATIONS/javis_utils/scripts/formatters.sh"

docker_list=("javis_common" "javis_autonomy" "javis_drivers" "javis_estimation" "javis_sim")     

echo ${JAVIS_PATH}

if [ "$JAVIS_SYSTEM_TYPE" == "basestation" ]; then
    arch="x86"
    wget -O ${JAVIS_PATH}/ros-data-types-x86.zip "https://javis.blob.core.windows.net/docker/dds/ros-data-types-x86.zip?sp=r&st=2022-06-23T02:20:46Z&se=2025-06-23T10:20:46Z&sv=2021-06-08&sr=b&sig=XHTxgF6GtXD7seC%2BNAUWD%2FIlm9c3Y5An0O6Fu3PvpIw%3D"
    # echo "Yay!!"
else
    arch="arm"
    wget -O ${JAVIS_PATH}/ros-data-types-arm.zip "https://javis.blob.core.windows.net/docker/dds/ros-data-types-arm.zip?sp=r&st=2022-06-23T02:19:43Z&se=2025-06-23T10:19:43Z&sv=2021-06-08&sr=b&sig=8%2FFD%2FNbf5QiQAuaF9JdNrck%2FEz0aLfIdc2TchiCCAR0%3D"
    # echo "Nay!!"
fi

unzip -qo ${JAVIS_PATH}/ros-data-types-${arch}.zip -d ${JAVIS_PATH}/


for cont in ${docker_list[@]}; do
    text "Working on"
    docker start ${cont}
    docker exec -it ${cont} rm -rf /home/developer/dds_install/ros-data-types-x86
    sudo docker cp ${JAVIS_PATH}/ros-data-types-${arch} ${cont}:/home/developer/dds_install/
done

for cont in ${docker_list[@]}; do
    text "Killing"
    docker kill ${cont}
done

rm -rf ${JAVIS_PATH}/ros-data-types-${arch}.zip ${JAVIS_PATH}/ros-data-types-${arch}


exit_success