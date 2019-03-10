set(TELEGRAM_GENERATED_SOURCES)

set(IMPORT_EXECUTABLES "native/ImportExecutables.cmake" CACHE FILEPATH "POINT")
INCLUDE(${IMPORT_EXECUTABLES})

add_custom_command(
	OUTPUT
		${GENERATED_DIR}/scheme.h
		${GENERATED_DIR}/scheme.cpp
	COMMAND python ${TELEGRAM_SOURCES_DIR}/codegen/scheme/codegen_scheme.py -o${GENERATED_DIR} ${TELEGRAM_RESOURCES_DIR}/scheme.tl
	DEPENDS ${TELEGRAM_RESOURCES_DIR}/scheme.tl
	COMMENT "Codegen scheme.tl"
)
list(APPEND TELEGRAM_GENERATED_SOURCES
	${GENERATED_DIR}/scheme.h
	${GENERATED_DIR}/scheme.cpp
)

file(GLOB_RECURSE STYLES
	${TELEGRAM_RESOURCES_DIR}/*.palette
	${TELEGRAM_RESOURCES_DIR}/*.style
	${TELEGRAM_SOURCES_DIR}/*.style
)
set(GENERATED_STYLES)
foreach(STYLE ${STYLES})
	get_filename_component(STYLE_FILENAME ${STYLE} NAME)
	get_filename_component(STYLE_NAME ${STYLE} NAME_WE)
	if (${STYLE} MATCHES \\.palette$)
		set(THIS_GENERATED_STYLES
			${GENERATED_DIR}/styles/palette.h
			${GENERATED_DIR}/styles/palette.cpp
		)
	else()
		set(THIS_GENERATED_STYLES
			${GENERATED_DIR}/styles/style_${STYLE_NAME}.h
			${GENERATED_DIR}/styles/style_${STYLE_NAME}.cpp
		)
	endif()

	# style generator does not like '-' in file path, so let's use relative paths...
	add_custom_command(
		OUTPUT ${THIS_GENERATED_STYLES}
		COMMAND codegen_style -IResources -ISourceFiles -o${GENERATED_DIR}/styles ${STYLE}
		WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
		DEPENDS codegen_style ${STYLE}
		COMMENT "Codegen style ${STYLE_FILENAME}"
	)
	set(GENERATED_STYLES ${GENERATED_STYLES} ${THIS_GENERATED_STYLES})
endforeach()
list(APPEND TELEGRAM_GENERATED_SOURCES ${GENERATED_STYLES})

add_custom_command(
	OUTPUT
		${GENERATED_DIR}/emoji.h
		${GENERATED_DIR}/emoji.cpp
		${GENERATED_DIR}/emoji_suggestions_data.h
		${GENERATED_DIR}/emoji_suggestions_data.cpp
	COMMAND codegen_emoji -o${GENERATED_DIR} ${TELEGRAM_RESOURCES_DIR}/emoji_autocomplete.json
	DEPENDS codegen_emoji
	COMMENT "Codegen emoji"
)

list(APPEND TELEGRAM_GENERATED_SOURCES
	${GENERATED_DIR}/emoji.h
	${GENERATED_DIR}/emoji.cpp
	${GENERATED_DIR}/emoji_suggestions_data.h
	${GENERATED_DIR}/emoji_suggestions_data.cpp
)

add_custom_command(
	OUTPUT
		${GENERATED_DIR}/lang_auto.h
		${GENERATED_DIR}/lang_auto.cpp
	COMMAND codegen_lang -o${GENERATED_DIR} ${TELEGRAM_RESOURCES_DIR}/langs/lang.strings
	DEPENDS codegen_lang
	COMMENT "Codegen lang"
)
list(APPEND TELEGRAM_GENERATED_SOURCES
	${GENERATED_DIR}/lang_auto.h
	${GENERATED_DIR}/lang_auto.cpp
)

add_custom_command(
	OUTPUT
		${GENERATED_DIR}/numbers.h
		${GENERATED_DIR}/numbers.cpp
	COMMAND codegen_numbers -o${GENERATED_DIR} ${TELEGRAM_RESOURCES_DIR}/numbers.txt
	DEPENDS codegen_numbers
	COMMENT "Codegen numbers"
)
list(APPEND TELEGRAM_GENERATED_SOURCES
	${GENERATED_DIR}/numbers.h
	${GENERATED_DIR}/numbers.cpp
)

add_custom_target(telegram_codegen DEPENDS ${TELEGRAM_GENERATED_SOURCES})
