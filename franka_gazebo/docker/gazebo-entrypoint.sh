#!/bin/bash
set -e

# setup ros environment
if [ -e "${DOCKER_ROS_SETUP}" ]; then
    source "${DOCKER_ROS_SETUP}"
else
    source "/gazebo_ws/devel/setup.bash"
fi

MY_IP=${DOCKER_ROS_IP:-$(hostname -i)}

if [ "$ROS_IP" == "" ]; then
    export ROS_IP=${MY_IP}
fi

if [ "${ROS_HOSTNAME}" == "" ]; then
    export ROS_HOSTNAME=${MY_IP}
fi

if [ "${DOCKER_ROS_MASTER_URI}" != "" ]; then
    export ROS_MASTER_URI=${DOCKER_ROS_MASTER_URI}
fi

exec "$@"
