cmake_minimum_required(VERSION 3.10)
project(WeekendsWay LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt5 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2)

add_executable(${PROJECT_NAME}
  src/main.cpp
  src/Navigator.h
  src/Navigator.cpp
  src/Storage.h
  src/Storage.cpp
  qml/qml.qrc
)

target_link_libraries(${PROJECT_NAME} PRIVATE
  Qt5::Core
  Qt5::Gui
  Qt5::Qml
  Qt5::Quick
  Qt5::QuickControls2
)

# Android extras are only needed on Android (for Intents)
if(ANDROID)
  find_package(Qt5 REQUIRED COMPONENTS AndroidExtras)
  target_link_libraries(${PROJECT_NAME} PRIVATE Qt5::AndroidExtras)
endif()
