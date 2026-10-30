#!/usr/bin/env bash

set -u

# This script can be started from any directory.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="${WORKSPACE:-$(cd -- "${SCRIPT_DIR}/../.." && pwd)}"
SESSION="${SESSION:-robot}"
CONDA_SH="${CONDA_SH:-$HOME/miniconda3/etc/profile.d/conda.sh}"
CONDA_ENV="${CONDA_ENV:-detection}"
LOG_DIR="${LOG_DIR:-$HOME/diff_driver_log}"

echo "Script directory: ${SCRIPT_DIR}"
echo "ROS workspace:    ${WORKSPACE}"
echo "Current directory: $(pwd)"

HTTP_BRIDGE_SCRIPT="${WORKSPACE}/src/moma-patrol-system/ros_http_bridge/ros_http_bridge/http_bridge_node.py"
DETECT_SCRIPT="${WORKSPACE}/src/moma-patrol-system/detect/detect/detect.py"
PATROL_SCRIPT="${WORKSPACE}/src/moma-patrol-system/patrol/patrol/patrol.py"

for script in "${HTTP_BRIDGE_SCRIPT}" "${DETECT_SCRIPT}" "${PATROL_SCRIPT}"; do
  if [[ ! -f "${script}" ]]; then
    echo "Python script not found: ${script}"
    exit 1
  fi
  chmod +x "${script}"
  echo "Executable permission granted: ${script}"
done

if [[ ! -f "${WORKSPACE}/devel/setup.bash" ]]; then
  echo "ROS workspace is not built: ${WORKSPACE}/devel/setup.bash"
  echo "Build it first with: catkin_make --cmake-args -DROS_EDITION=ROS1"
  exit 1
fi

if tmux has-session -t "${SESSION}" 2>/dev/null; then
  echo "tmux session '${SESSION}' already exists."
  echo "Attach with: tmux attach -t ${SESSION}"
  exit 0
fi

mkdir -p "${LOG_DIR}"

ROS_SETUP="source '${WORKSPACE}/devel/setup.bash'"
CONDA_SETUP="source '${CONDA_SH}' && conda activate '${CONDA_ENV}'"

tmux new-session -d -s "${SESSION}" -n sensors

# Window 0: sensors and robot driver
tmux send-keys -t "${SESSION}:0.0" \
  "${ROS_SETUP} && roslaunch realsense2_camera rs_camera.launch" C-m

sleep 4
tmux split-window -h -t "${SESSION}:0"
sleep 2
tmux send-keys -t "${SESSION}:0.1" \
  "${ROS_SETUP} && roslaunch livox_ros_driver2 msg_MID360.launch" C-m

sleep 4
tmux split-window -v -t "${SESSION}:0.1"
sleep 2
tmux send-keys -t "${SESSION}:0.2" \
  "${ROS_SETUP} && LOG='${LOG_DIR}/diff_driver_\$(date +%Y%m%d_%H%M%S).log' && unbuffer roslaunch robot_driver diff_driver.launch --screen 2>&1 | tee /dev/tty | while IFS= read -r line; do clean_line=\$(echo \"\$line\" | perl -pe 's/\\x1B\\[[0-9;]*m//g'); printf '%s %s\\n' \"\$(date '+%F %T')\" \"\$clean_line\"; done > \"\$LOG\"" C-m

tmux select-layout -t "${SESSION}:0" tiled

# Window 1: localization, navigation, and robot bringup
tmux new-window -t "${SESSION}" -n test_ws
tmux send-keys -t "${SESSION}:1.0" \
  "${ROS_SETUP} && export LD_LIBRARY_PATH='${WORKSPACE}/devel/lib:/opt/ros/noetic/lib:/opt/ros/noetic/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/opt/MVS/lib/64:/opt/MVS/lib/32:/usr/local/cuda/lib64' && roslaunch lm_bringup moma_localize.launch" C-m

sleep 0.5
tmux split-window -h -t "${SESSION}:1"
sleep 0.5
tmux send-keys -t "${SESSION}:1.1" \
  "${ROS_SETUP} && roslaunch moma_nav sentry_movebase.launch" C-m

sleep 3
tmux split-window -v -t "${SESSION}:1.1"
sleep 0.5
tmux send-keys -t "${SESSION}:1.2" \
  "${ROS_SETUP} && roslaunch dobot_v4_bringup bringup_v4.launch" C-m

tmux select-layout -t "${SESSION}:1" tiled

# Window 2: application nodes
tmux new-window -t "${SESSION}" -n moma_ws
tmux split-window -h -t "${SESSION}:2"
tmux split-window -v -t "${SESSION}:2.0"

tmux send-keys -t "${SESSION}:2.0" \
  "${ROS_SETUP} && ${CONDA_SETUP} && cd '${WORKSPACE}' && rosrun ros_http_bridge http_bridge_node.py" C-m

sleep 0.5
tmux send-keys -t "${SESSION}:2.1" \
  "${ROS_SETUP} && ${CONDA_SETUP} && cd '${WORKSPACE}' && rosrun detect detect.py" C-m

sleep 0.5
tmux send-keys -t "${SESSION}:2.2" \
  "${ROS_SETUP} && ${CONDA_SETUP} && cd '${WORKSPACE}' && roslaunch patrol patrol.launch" C-m

tmux select-layout -t "${SESSION}:2" tiled

# Window 3: industrial camera
tmux new-window -t "${SESSION}" -n camera
tmux send-keys -t "${SESSION}:3.0" \
  "${ROS_SETUP} && rosrun mvs camera_stream" C-m

tmux select-window -t "${SESSION}:0"
echo "Started tmux session '${SESSION}'."
echo "Attach with: tmux attach -t ${SESSION}"
