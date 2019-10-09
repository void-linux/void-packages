#find_package(catch REQUIRED)
set(catch_INCLUDE /usr/include/catch)

file(GLOB LIST_TESTS_PY gyp/tests/list_tests.py)
file(GLOB TESTS_LIST_TXT gyp/tests/tests_list.txt)

add_executable(tests_algorithm
	SourceFiles/base/algorithm_tests.cpp
	SourceFiles/base/tests_main.cpp
)

add_executable(tests_flags
	SourceFiles/base/flags_tests.cpp
	SourceFiles/base/tests_main.cpp
)

add_executable(tests_flat_map
	SourceFiles/base/flat_map_tests.cpp
	SourceFiles/base/tests_main.cpp
)

add_executable(tests_flat_set
	SourceFiles/base/flat_set_tests.cpp
	SourceFiles/base/tests_main.cpp
)

add_executable(tests_rpl
	SourceFiles/rpl/operators_tests.cpp
	SourceFiles/rpl/producer_tests.cpp
	SourceFiles/rpl/variable_tests.cpp
	SourceFiles/base/tests_main.cpp
)

target_link_libraries(tests_algorithm Qt5::Core)
target_link_libraries(tests_flags Qt5::Core)
target_link_libraries(tests_flat_map Qt5::Core)
target_link_libraries(tests_flat_set Qt5::Core)
target_link_libraries(tests_rpl Qt5::Core)

target_include_directories(tests_algorithm PUBLIC
	${catch_INCLUDE}
)
target_include_directories(tests_flags PUBLIC
	${catch_INCLUDE}
)
target_include_directories(tests_flat_map PUBLIC
	${catch_INCLUDE}
	${THIRD_PARTY_DIR}/GSL/include
	${THIRD_PARTY_DIR}/variant/include
)
target_include_directories(tests_flat_set PUBLIC
	${catch_INCLUDE}
)
target_include_directories(tests_rpl PUBLIC
	${catch_INCLUDE}
	${THIRD_PARTY_DIR}/GSL/include
	${THIRD_PARTY_DIR}/variant/include
)

enable_testing()
add_test(tests python ${LIST_TESTS_PY} --input ${TESTS_LIST_TXT})
