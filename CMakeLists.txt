# This script will add all the cpp and h files under src and include folders.
cmake_minimum_required( VERSION 3.21 )
project( MyThirdOgre )

# Enable folder and virtual filter support in Visual Studio globally
set_property(GLOBAL PROPERTY USE_FOLDERS ON)
set_property(GLOBAL PROPERTY PREDEFINED_TARGETS_FOLDER "CMakePredefinedTargets")

include( CMake/Bootstrap.cmake )
include( CMake/Dependencies/OGRE.cmake )

setupOgre( OGRE_SOURCE, OGRE_BINARIES, OGRE_LIBRARIES, FALSE )

# Setup our application
if( MSVC )
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /MP")
	if( NOT PLATFORM_X64 )
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /arch:SSE2")
	endif()
	add_definitions( -DUNICODE -D_UNICODE )
endif()

if( APPLE )
	macro( add_recursive dir retVal )
		file( GLOB_RECURSE ${retVal} ${dir}/*.h ${dir}/*.cpp ${dir}/*.c ${dir}/*.mm ${dir}/*.m )
	endmacro()
else()
	macro( add_recursive dir retVal )
		file( GLOB_RECURSE ${retVal} ${dir}/*.h ${dir}/*.cpp ${dir}/*.c ${dir}/*.hlsl ${dir}/*.json ${dir}/*.compositor ${dir}/*.material )
	endmacro()
endif()

include_directories( "./include" )

add_recursive( ./src SOURCES )
foreach( SOURCE ${SOURCES} )
	if( SOURCE MATCHES "(MainLoop(Multi|Single)Threaded|UnitTesting)\\.cpp$" )
		list( REMOVE_ITEM SOURCES "${SOURCE}" )
	endif()
endforeach()
add_recursive( ./include HEADERS )

# MAGIC STEP: Force CMake to mirror the physical directory tree for headers and sources
source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}" FILES ${SOURCES} ${HEADERS})

if( APPLE )
	file( GLOB_RECURSE RESOURCES ./src/*.storyboard )
	set( RESOURCES ${RESOURCES} ./Data/Resources.cfg ./out/Data )
endif()

add_executable( ${PROJECT_NAME} WIN32 MACOSX_BUNDLE ${SOURCES} ${HEADERS} ${RESOURCES} )
set_target_properties( ${PROJECT_NAME} PROPERTIES
	CXX_STANDARD 17
	CXX_STANDARD_REQUIRED ON
)
target_include_directories( ${PROJECT_NAME} PRIVATE
	"${CMAKE_CURRENT_SOURCE_DIR}/include/Leap"
	"${CMAKE_CURRENT_SOURCE_DIR}/include/Headers"
)

set( LEAP_SDK "" CACHE PATH "Path to the Leap SDK" )
set( LEAP_SDK_INCLUDE_DIR "" CACHE PATH "Path to the Leap SDK include directory" )
if( NOT LEAP_SDK AND DEFINED ENV{LEAP_SDK} )
	set( LEAP_SDK "$ENV{LEAP_SDK}" )
endif()
if( NOT LEAP_SDK_INCLUDE_DIR AND DEFINED ENV{LEAP_SDK_INCLUDE_DIR} )
	set( LEAP_SDK_INCLUDE_DIR "$ENV{LEAP_SDK_INCLUDE_DIR}" )
elseif( NOT LEAP_SDK_INCLUDE_DIR AND LEAP_SDK )
	set( LEAP_SDK_INCLUDE_DIR "${LEAP_SDK}/include" )
endif()
if( LEAP_SDK_INCLUDE_DIR )
	target_include_directories( ${PROJECT_NAME} PRIVATE "${LEAP_SDK_INCLUDE_DIR}" )
endif()
if( WIN32 AND LEAP_SDK )
	target_link_directories( ${PROJECT_NAME} PRIVATE "${LEAP_SDK}/lib/x64" )
	target_link_libraries( ${PROJECT_NAME} LeapC )
endif()
target_link_libraries( ${PROJECT_NAME} ${OGRE_LIBRARIES} )

if( APPLE )
	set_target_properties( ${PROJECT_NAME} PROPERTIES XCODE_ATTRIBUTE_ENABLE_BITCODE "NO" )
	set_target_properties( ${PROJECT_NAME} PROPERTIES RESOURCE "${RESOURCES}" )
	set_target_properties( ${PROJECT_NAME} PROPERTIES MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/src/Info.plist )
	set( CMAKE_EXE_LINKER_FLAGS "-framework Foundation -framework CoreGraphics -framework QuartzCore -framework UIKit -framework Metal -framework MetalKit -framework ModelIO" )
endif()

if(MSVC)
  set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT ${PROJECT_NAME})
endif()

# 1. Instruct CMake to find the SDL2 package using your preset paths
find_package(SDL2 REQUIRED)

# 2. Force your executable target to link the library definitions
target_link_libraries(${PROJECT_NAME} ${SDL2_LIBRARIES})

if(MSVC)
    # Target the exact folder holding OgreMain_d.dll and the RenderSystems
    set(_debugger_runtime_path "${OGRE_BINARIES}/bin/$<CONFIG>")
    
    if(SDL2_LIBRARY)
        get_filename_component(_sdl2_runtime_dir "${SDL2_LIBRARY}" DIRECTORY)
        string(APPEND _debugger_runtime_path "$<SEMICOLON>${_sdl2_runtime_dir}")
    endif()
    if(LEAP_SDK)
        string(APPEND _debugger_runtime_path "$<SEMICOLON>${LEAP_SDK}/lib/x64")
    endif()

    set_target_properties(${PROJECT_NAME} PROPERTIES
		# Point the working directory directly to where your updated files are generated
		VS_DEBUGGER_WORKING_DIRECTORY "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
		VS_DEBUGGER_ENVIRONMENT "PATH=${_debugger_runtime_path}$<SEMICOLON>%PATH%"
	)
endif()

# This automatically bakes your active OGRE_BINARIES path directly into the config file
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/bin/Data/resources2.cfg.in"
    "${CMAKE_CURRENT_SOURCE_DIR}/resources2.cfg"
)

# Automate copying configuration files
 add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${OGRE_BINARIES}/bin/$<CONFIG>/plugins$<$<CONFIG:Debug>:_d>.cfg"
    "${CMAKE_SOURCE_DIR}/bin/Data/resources2.cfg"
    "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
    COMMENT "Copying Ogre rendering and resource config files..."
)

# Automatically copy SDL2.dll to the output folder where your executable lives
if(TARGET SDL2::SDL2)
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "C:/Program Files (x86)/SDL2/lib/x64/SDL2.dll"
        $<TARGET_FILE_DIR:${PROJECT_NAME}>
    )
endif()

# Tell the compiler exactly where OgreNext stores its header-only RapidJSON dependency
target_include_directories(${PROJECT_NAME} PRIVATE "${OGRE_NEXT_DEPS_RAPIDJSON}")
