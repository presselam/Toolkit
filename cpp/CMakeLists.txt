cmake_minimum_required(VERSION 2.4)

set(CMAKE_CXX_STANDARD 11)

project(Toolkit)

add_executable(Toolkit src/main.cpp)

#set(SOURCES
#        include/Wonder.hpp
#        src/Wonder.cpp
#)

#set(RELEASE_LIB gdal_raf)
#
#set(DEBUG_BIN RAFDRIVER)
#
#add_library(${RELEASE_LIB} SHARED ${SOURCES})
#set_target_properties(${RELEASE_LIB} PROPERTIES PREFIX "")

# Console Logging : add DEBUG_ERRORLEVEL to enable
# TRACE: function calls/major activities
# WARN: a problem occured that may allow the program to continue, albeit abnormally
# ERROR: a problem occured that may lead to a crash
# PRINTFIELDS: prints all exposed fields, VERY noisy
target_compile_definitions(${DEBUG_BIN} PRIVATE DEBUG_TRACE DEBUG_WARN DEBUG_ERROR)
target_compile_definitions(${RELEASE_LIB} PRIVATE DEBUG_WARN DEBUG_ERROR)

# Windows External Libs
#if (WIN32)
#    include_directories(${CMAKE_SOURCE_DIR}/extlib/gdal_2.1.3/windows/include/xercesc)
#    target_link_libraries(${DEBUG_BIN} ${CMAKE_SOURCE_DIR}/extlib/gdal_2.1.3/windows/lib-x64/xerces-c_3.lib)
#    target_link_libraries(${RELEASE_LIB} ${CMAKE_SOURCE_DIR}/extlib/gdal_2.1.3/windows/lib-x64/xerces-c_3.lib)
#
# Linux External Libs
#else()
#    include_directories(${CMAKE_SOURCE_DIR}/extlib/xerces_3.1.4/deb/)
#    target_link_libraries(${DEBUG_BIN} ${CMAKE_SOURCE_DIR}/extlib/xerces_3.1.4/deb/lib-x64/libxerces-c.so)
#    target_link_libraries(${RELEASE_LIB} ${CMAKE_SOURCE_DIR}/extlib/xerces_3.1.4/deb/lib-x64/libxerces-c.so)
#endif()
#
# Windows External Libs
#if (WIN32)
#    include_directories(${CMAKE_SOURCE_DIR}/extlib/gdal_2.1.3/windows/include/)
#    target_link_libraries(${DEBUG_BIN} ${CMAKE_SOURCE_DIR}/extlib/gdal_2.1.3/windows/lib-x64/gdal_i.lib)
#    target_link_libraries(${RELEASE_LIB} ${CMAKE_SOURCE_DIR}/extlib/gdal_2.1.3/windows/lib-x64/gdal_i.lib)
#
# Linux External Libs
#else()
#    include_directories(${CMAKE_SOURCE_DIR}/extlib/gdal_2.1.3/deb/include/)
#    target_link_libraries(${DEBUG_BIN} ${CMAKE_SOURCE_DIR}/extlib/gdal_2.1.3/deb/lib-x64/libgdal.so)
#    target_link_libraries(${RELEASE_LIB} ${CMAKE_SOURCE_DIR}/extlib/gdal_2.1.3/deb/lib-x64/libgdal.so)
#endif()
#
# Move targets to root directory of project
#install(TARGETS ${RELEASE_LIB}
#        DESTINATION ${CMAKE_SOURCE_DIR}/)
#
#install(TARGETS ${DEBUG_BIN}
#        DESTINATION ${CMAKE_SOURCE_DIR}/)
