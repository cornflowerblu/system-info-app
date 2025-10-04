cmake_minimum_required(VERSION 3.15)
project(SystemAPI)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# Source files
set(SOURCES
    src/systemapi.cpp
)

# Header files
set(HEADERS
    include/systemapi.h
)

# Create shared library
add_library(systemapi SHARED ${SOURCES} ${HEADERS})

# Include directories
target_include_directories(systemapi PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

# Platform-specific settings
if(WIN32)
    # Windows-specific settings
    target_compile_definitions(systemapi PRIVATE SYSTEMAPI_EXPORTS)

    # Export all symbols (alternative to .def file)
    set_target_properties(systemapi PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS ON)
elseif(APPLE)
    # macOS-specific settings
    set_target_properties(systemapi PROPERTIES
        MACOSX_RPATH ON
        INSTALL_RPATH "@loader_path"
    )
elseif(UNIX)
    # Linux-specific settings
    set_target_properties(systemapi PROPERTIES
        INSTALL_RPATH "$ORIGIN"
    )
endif()

# Set version
set_target_properties(systemapi PROPERTIES
    VERSION 1.0.0
    SOVERSION 1
)
