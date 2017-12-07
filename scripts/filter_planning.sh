#!/usr/bin/env bash

###############################################################################
# Copyright 2017 The Apollo Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################

function print_help() {
   echo "Example: filter_planning.sh -[pc|np|wp] [-d|--dir] bag1 bag2 bag3 ..."
   echo "-d|--dir the target storage directory"
   echo "This script works in three modes:"
   echo "  -pc filter for perfect control, produces *.pc.bag"
   echo "  -np filter for planning dependencies, produces *.np.bag"
   echo "  -wp filter for planning and its dependencies, produces *.wp.bag"
}

perfect_control_topic="topic == '/apollo/prediction' \
   or topic == '/apollo/routing_response' \
   or topic == '/apollo/perception/obstacle' \
   or topic == '/apollo/perception/traffic_light'"

planning_deps="$perfect_control_topic \
    or topic == '/apollo/canbus/chassis' \
    or topic == '/apollo/localization/pose'"

planning_all="topic == '/apollo/planning' \
    or topic == '/apollo/drive_event' \
    or $planning_deps"


#Three different filter mode
#create perfect control mode bag
is_perfect_control=false
#create a rosbag with planning and its dependencies
is_with_planning=false
#create a rosbag only with planning's dependencies
is_no_planning=false
work_mode_num=0

#argument parsing code from https://stackoverflow.com/a/14203146
POSITIONAL=()
target_dir="."
while [[ $# -gt 0 ]]; do
key="$1"
case $key in
    -pc|--perfectcontrol)
    is_perfect_control=true
    work_mode_num=$((work_mode_num+1))
    shift # past argument
    ;;
    -np|--noplanning)
    is_no_planning=true
    work_mode_num=$((work_mode_num+1))
    shift # past argument
    ;;
    -wp|--lib)
    is_with_planning=true
    work_mode_num=$((work_mode_num+1))
    shift # past value
    ;;
    -d|--dir)
    target_dir="$2"
    shift # past argument
    shift # past value
    ;;
    -h|--help)
    print_help
    exit 0
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done

if [[ $work_mode_num -eq 0 ]]; then
   print_help
   exit 0
fi

set -- "${POSITIONAL[@]}" # restore positional parameters

function filter() {
    if $is_perfect_control; then
        target="${name%.*}.pc.bag"
        rosbag filter $1 "$target_dir/$target" "$perfect_control_topic"
    fi

    if $is_no_planning; then
        target="${name%.*}.np.bag"
        rosbag filter $1 "$target_dir/$target" "$planning_deps"
    fi

    if $is_with_planning; then
        target="${name%.*}.wp.bag"
        rosbag filter $1 "$target_dir/$target" "$planning_all"
    fi
}

for bag in $@; do
    name=$(basename $bag)
    echo "filtering ${bag}"
    filter $bag
done
