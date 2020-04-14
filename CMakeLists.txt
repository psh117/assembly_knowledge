cmake_minimum_required(VERSION 3.4)
project(assembly_knowledge)

find_package(catkin REQUIRED)
catkin_package(CATKIN_DEPENDS xacro)

install(DIRECTORY furniture_info models
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}
)