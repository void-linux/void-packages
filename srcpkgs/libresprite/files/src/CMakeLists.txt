add_definitions(-DHAVE_CONFIG_H)

include_directories(. .. ../third_party)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wno-switch -std=gnu++11")

set(OBSERVABLE_TESTS OFF CACHE BOOL "Compile observable tests")
add_subdirectory(observable)
include_directories(observable)

add_subdirectory(base)

include_directories(${BASE_INCLUDE_DIR})

add_subdirectory(gen)
