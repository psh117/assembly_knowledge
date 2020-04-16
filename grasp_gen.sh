#!/bin/bash

rosrun fgpg fgpg config/grasp_options.yaml models/meshes/stefan_bottom.stl
rosrun fgpg fgpg config/grasp_options.yaml models/meshes/stefan_long_part.stl
rosrun fgpg fgpg config/grasp_options.yaml models/meshes/stefan_middle_part.stl
rosrun fgpg fgpg config/grasp_options.yaml models/meshes/stefan_short_part.stl
rosrun fgpg fgpg config/grasp_options.yaml models/meshes/stefan_side_left_part.stl
rosrun fgpg fgpg config/grasp_options.yaml models/meshes/stefan_side_right_part.stl

rm models/grasps/*
mv models/meshes/*_grasp.yaml models/grasps/

