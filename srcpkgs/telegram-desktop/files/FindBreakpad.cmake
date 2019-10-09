find_path(BREAKPAD_CLIENT_INCLUDE_DIR
	NAMES client/linux/handler/exception_handler.h
	PATH_SUFFIXES breakpad
)

find_library(BREAKPAD_CLIENT_LIBRARY
	NAMES breakpad_client
)

find_package_handle_standard_args(Breakpad DEFAULT_MSG
	BREAKPAD_CLIENT_LIBRARY
	BREAKPAD_CLIENT_INCLUDE_DIR
)

add_library(breakpad_client STATIC IMPORTED)
add_dependencies(breakpad_client breakpad_build)

set_property(TARGET breakpad_client PROPERTY IMPORTED_LOCATION ${BREAKPAD_CLIENT_LIBRARY})
set_property(TARGET breakpad_client PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${BREAKPAD_CLIENT_INCLUDE_DIR})
