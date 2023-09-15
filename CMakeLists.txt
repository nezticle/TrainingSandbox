cmake_minimum_required(VERSION 3.16)

project(TrainingSandbox VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.5)

add_subdirectory(ScriptConsole)
add_subdirectory(CodeEditor)

# Get a list of all of the files in the data folder.
file(GLOB_RECURSE BUNDLED_RESOURCES "${CMAKE_CURRENT_SOURCE_DIR}/data/*")
if (APPLE)
    # For iOS and macOS some extra steps are necessary so that the data
    # files are placed into the app bundle in the correct location.

    # Individually set the file's path properties.
    foreach (FILE ${BUNDLED_RESOURCES})
        # Get the relative path from the data-folder to the particular file.
        file(RELATIVE_PATH NEW_FILE "${CMAKE_CURRENT_SOURCE_DIR}/data" ${FILE})

        # Get the relative path to the file.
        get_filename_component(NEW_FILE_PATH ${NEW_FILE} DIRECTORY)

        # Set it's location inside the app package (under Resources).
        # CMake will automatically take care of the differences between iOS and macOS
        set_property(SOURCE ${FILE} PROPERTY MACOSX_PACKAGE_LOCATION "Resources/data/${NEW_FILE_PATH}")

        # Optional: Add the file to the 'Resources' folder group in Xcode.
        #           This also preserves folder structure.
        source_group("Resources/data/${NEW_FILE_PATH}" FILES "${FILE}")
    endforeach ()
else ()
    # for anything that is not macOS/iOS just copy the files to the build folder
    foreach(file ${BUNDLED_RESOURCES})
        # To recreate the same folder structure we first need to read the base folder
        file(RELATIVE_PATH RELATIVE_FILE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/data" ${file})
        get_filename_component(FOLDER ${RELATIVE_FILE_PATH} DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/data")
        file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/data/${FOLDER} )
            message(STATUS "COPY ${file} -> ${CMAKE_CURRENT_BINARY_DIR}/data/${RELATIVE_FILE_PATH}")
            configure_file(${file} "${CMAKE_CURRENT_BINARY_DIR}/data/${RELATIVE_FILE_PATH}" COPYONLY)
    endforeach()
endif()

qt_add_executable(trainingSandbox
    main.cpp
    ${BUNDLED_RESOURCES}
)

qt_add_qml_module(trainingSandbox
    URI TrainingSandbox
    VERSION 1.0
    QML_FILES
        Main.qml
        DynamicItemLoader.qml
        DynamicNodeLoader.qml
        OriginGizmo.qml
    SOURCES
        dynamicfileshelper.h dynamicfileshelper.cpp
    RESOURCES
        dripicons-v2.ttf
        sandbox.jpg
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(trainingSandbox PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER io.qt.TrainingSandbox
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(trainingSandbox
    PRIVATE
        Qt6::Quick
        scriptconsolemodule
        codeeditormodule
)

include(GNUInstallDirs)
install(TARGETS trainingSandbox
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
