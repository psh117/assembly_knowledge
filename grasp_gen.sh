#!/bin/bash

rosrun fgpg fgpg config/grasp_options.yaml models/meshes/ikea_stefan_bottom.stl
rosrun fgpg fgpg config/grasp_options.yaml models/meshes/ikea_stefan_long.stl
rosrun fgpg fgpg config/grasp_options_middle.yaml models/meshes/ikea_stefan_middle.stl
rosrun fgpg fgpg config/grasp_options.yaml models/meshes/ikea_stefan_short.stl
rosrun fgpg fgpg config/grasp_options.yaml models/meshes/ikea_stefan_side_left.stl
rosrun fgpg fgpg config/grasp_options.yaml models/meshes/ikea_stefan_side_right.stl

rm models/grasps/*
mv models/meshes/*_grasp.yaml models/grasps/

