cmake_minimum_required(VERSION 3.10)
project(WeekendsWay LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt5 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 QuickTemplates2)

# (Можно оставить find_library, но мы линковаем по именам — это надёжнее на Android)
find_library(GLESv2_LIB GLESv2)
find_library(EGL_LIB EGL)
find_library(Z_LIB z)
find_library(LOG_LIB log)
find_library(ANDROID_LIB android)

# Общий список исходников
set(APP_SOURCES
  src/main.cpp
  src/Navigator.h
  src/Navigator.cpp
  src/Storage.h
  src/Storage.cpp
  qml/qml.qrc
  icons/home.svg
)

# На Android приложение собирается как .so (SHARED), на Desktop — как exe
if(ANDROID)
  add_library(${PROJECT_NAME} SHARED ${APP_SOURCES})
  set_target_properties(${PROJECT_NAME} PROPERTIES
    QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_SOURCE_DIR}/android"
  )
else()
  add_executable(${PROJECT_NAME} ${APP_SOURCES})
endif()

target_link_libraries(${PROJECT_NAME} PRIVATE
  Qt5::Core
  Qt5::Gui
  Qt5::Qml
  Qt5::Quick
  Qt5::QuickControls2
  Qt5::QuickTemplates2
)

# Android extras are only needed on Android (for Intents)
if(ANDROID)
  find_package(Qt5 REQUIRED COMPONENTS AndroidExtras)
  target_link_libraries(${PROJECT_NAME} PRIVATE Qt5::AndroidExtras)

  # системные библиотеки Android/NDK (лучше по именам)
  target_link_libraries(${PROJECT_NAME} PRIVATE
    z
    log
    android
    GLESv2
    EGL
  )

  # чтобы `cmake --build --target apk` всегда сначала собирал библиотеку приложения
  if(TARGET apk)
    add_dependencies(apk ${PROJECT_NAME})
  endif()
endif()
