cmake_minimum_required(VERSION 2.4)

set(CMAKE_CXX_STANDARD 11)
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

project(Toolkit)

include_directories(include)

set(SOURCES
        include/getopt.hpp
        include/toolkit.hpp
        include/wonder.hpp
        src/getopt.cpp
        src/wonder.cpp
)
set(TARGET_LIB toolkit)
add_library(${TARGET_LIB} ${SOURCES})
set_target_properties(${TARGET_LIB} PROPERTIES FOLDER "Toolkit Library")
install(TARGETS ${TARGET_LIB} DESTINATION lib)

#====[ TESTING ]============================================
enable_testing()
set(TARGET tester)
add_executable(${TARGET} test/test.cpp)
target_link_libraries(${TARGET} ${TARGET_LIB})
set_target_properties(${TARGET} PROPERTIES FOLDER "Unit Tests")
add_test(NAME toolkit COMMAND tester)
