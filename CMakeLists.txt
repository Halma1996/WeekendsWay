cmake_minimum_required(VERSION 3.16)
project(WeekendsWay LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2)

set(APP_SOURCES
    src/main.cpp
    src/Navigator.h
    src/Navigator.cpp
    src/Storage.h
    src/Storage.cpp
    qml/qml.qrc
    icons/home.svg
)

qt_add_executable(WeekendsWay
    ${APP_SOURCES}
)

if(ANDROID)
    set_target_properties(WeekendsWay PROPERTIES
        QT_ANDROID_TARGET_SDK_VERSION 35
    )
endif()

target_link_libraries(WeekendsWay PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
)

if(ANDROID)
    target_link_libraries(WeekendsWay PRIVATE
        z
        log
        android
        GLESv2
        EGL
    )
endif()