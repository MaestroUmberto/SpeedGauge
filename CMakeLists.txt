cmake_minimum_required(VERSION 3.14)

project(ConsoleTest LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

#find_package(QT NAMES Qt6 Qt5 COMPONENTS Core REQUIRED)
#find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Core REQUIRED)

find_package(QT NAMES Qt6 Qt5 COMPONENTS Core Quick REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Core Quick REQUIRED)
find_package(Qt6 COMPONENTS Core5Compat REQUIRED)

add_executable(SpeedGauge
  main.cpp
  qconsolelistener.cpp
  qconsolelistener.h
  qml.qrc
)
#target_link_libraries(ConsoleTest Qt${QT_VERSION_MAJOR}::Core)


target_compile_definitions(SpeedGauge
  PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>)
target_link_libraries(SpeedGauge
  PRIVATE Qt${QT_VERSION_MAJOR}::Core Qt${QT_VERSION_MAJOR}::Quick)
target_link_libraries(SpeedGauge PUBLIC Qt6::Core5Compat)

if(QT_VERSION_MAJOR EQUAL 6)
    qt_import_qml_plugins(SpeedGauge)
    qt_finalize_executable(SpeedGauge)
endif()
