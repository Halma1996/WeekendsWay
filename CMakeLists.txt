cmake_minimum_required(VERSION 3.16)
project(WeekendsWay LANGUAGES CXX)

set(WEEKENDSWAY_VERSION_CODE "1000001" CACHE STRING "Android update version code")
set(WEEKENDSWAY_VERSION_NAME "1.1.0" CACHE STRING "Android display version")

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
    src/MapLinks.h
    src/MapLinks.cpp
    src/Storage.h
    src/Storage.cpp
    src/Contacts.h
    src/Contacts.cpp
    qml/qml.qrc
)

qt_add_executable(WeekendsWay
    ${APP_SOURCES}
)

if(ANDROID)
    if(NOT WEEKENDSWAY_VERSION_CODE MATCHES "^[1-9][0-9]*$")
        message(FATAL_ERROR "WEEKENDSWAY_VERSION_CODE must be a positive integer")
    endif()
    set_target_properties(WeekendsWay PROPERTIES
        QT_ANDROID_VERSION_CODE "${WEEKENDSWAY_VERSION_CODE}"
        QT_ANDROID_VERSION_NAME "${WEEKENDSWAY_VERSION_NAME}"
        QT_ANDROID_TARGET_SDK_VERSION 35
        QT_ANDROID_SDK_BUILD_TOOLS_REVISION 35.0.0
        QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android"
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
