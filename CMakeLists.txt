cmake_minimum_required(VERSION 3.10)
project(WeekendsWay LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt5 5.12 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2)

# Android extras are only needed on Android (for Intents)
if(ANDROID)
  find_package(Qt5 5.12 REQUIRED COMPONENTS AndroidExtras)
endif()

add_executable(${PROJECT_NAME}
  src/main.cpp
  src/Navigator.h
  src/Navigator.cpp
  src/Storage.h
  src/Storage.cpp
  qml/qml.qrc
)

target_link_libraries(${PROJECT_NAME}
  Qt5::Core
  Qt5::Gui
  Qt5::Qml
  Qt5::Quick
  Qt5::QuickControls2
)

if(ANDROID)
  target_link_libraries(${PROJECT_NAME} Qt5::AndroidExtras)
endif()

# On Android, Qt Creator / androiddeployqt can generate a package automatically.
# If you later add a custom Android manifest/resources, set:
# set_property(TARGET ${PROJECT_NAME} PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_SOURCE_DIR}/android)
