project(crl)

find_package(Qt5 REQUIRED COMPONENTS Core)

file(GLOB CRL_SOURCE_FILES
	src/crl/common/*.cpp
	src/crl/dispatch/*.cpp
	src/crl/qt/*.cpp
	src/crl/winapi/*.cpp
	src/crl/linux/*.cpp
	src/crl/crl_time.cpp
)

add_library(${PROJECT_NAME} STATIC ${CRL_SOURCE_FILES})

target_include_directories(${PROJECT_NAME} PUBLIC src)
target_link_libraries(${PROJECT_NAME} Qt5::Core)
