#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
# 
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

set(MY_NAME "PhysX")
set(TARGET_WITH_NAMESPACE "3rdParty::${MY_NAME}")
if (TARGET ${TARGET_WITH_NAMESPACE})
    return()
endif()

set(_PACKAGE_DIR ${CMAKE_CURRENT_LIST_DIR}/PhysX/physx)

set(${MY_NAME}_INCLUDE_DIR
    ${_PACKAGE_DIR}/include
    ${_PACKAGE_DIR}/include/foundation
    ${_PACKAGE_DIR}/include/geometry
)

set(${MY_NAME}_COMPILE_DEFINITIONS $<$<BOOL:${LY_MONOLITHIC_GAME}>:PX_PHYSX_STATIC_LIB>)

# LY_PHYSX_PROFILE_USE_CHECKED_LIBS allows to override what PhysX configuration to use on O3DE profile.
set(LY_PHYSX_PROFILE_USE_CHECKED_LIBS OFF CACHE BOOL "When ON it uses PhysX SDK checked libraries on O3DE profile configuration")
if(LY_PHYSX_PROFILE_USE_CHECKED_LIBS)
    set(PHYSX_PROFILE_CONFIG "checked")
else()
    set(PHYSX_PROFILE_CONFIG "profile")
endif()

set(PATH_TO_LIBS ${_PACKAGE_DIR}/bin/$<IF:$<BOOL:${LY_MONOLITHIC_GAME}>,static,shared>/$<IF:$<CONFIG:profile>,${PHYSX_PROFILE_CONFIG},$<CONFIG>>)
set(PATH_TO_SHARED_LIBS ${_PACKAGE_DIR}/bin/shared/$<IF:$<CONFIG:profile>,${PHYSX_PROFILE_CONFIG},$<CONFIG>>)

if(DEFINED CMAKE_IMPORT_LIBRARY_SUFFIX)
    set(import_lib_prefix ${CMAKE_IMPORT_LIBRARY_PREFIX})
    set(import_lib_suffix ${CMAKE_IMPORT_LIBRARY_SUFFIX})
else()
    set(import_lib_prefix ${CMAKE_SHARED_LIBRARY_PREFIX})
    set(import_lib_suffix ${CMAKE_SHARED_LIBRARY_SUFFIX})
endif()

set(${MY_NAME}_LIBRARIES
    ${PATH_TO_LIBS}/${CMAKE_STATIC_LIBRARY_PREFIX}PhysXCharacterKinematic_static_64${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${PATH_TO_LIBS}/${CMAKE_STATIC_LIBRARY_PREFIX}PhysXVehicle_static_64${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${PATH_TO_LIBS}/${CMAKE_STATIC_LIBRARY_PREFIX}PhysXExtensions_static_64${CMAKE_STATIC_LIBRARY_SUFFIX}
    ${PATH_TO_LIBS}/${CMAKE_STATIC_LIBRARY_PREFIX}PhysXPvdSDK_static_64${CMAKE_STATIC_LIBRARY_SUFFIX}
)

set(extra_static_libs ${EXTRA_STATIC_LIBS_NON_MONOLITHIC})
set(extra_shared_libs ${EXTRA_SHARED_LIBS})

if(LY_MONOLITHIC_GAME)
    if(LY_PHYSX_PROFILE_USE_CHECKED_LIBS)
        set(MONO_PATH_TO_STATIC_LIBS ${CMAKE_CURRENT_LIST_DIR}/PhysX/physx/bin/static/checked)
    else()
        set(MONO_PATH_TO_STATIC_LIBS ${CMAKE_CURRENT_LIST_DIR}/PhysX/physx/bin/static/profile)
    endif()
    # The order of PhysX 5.x static libraries is important for monolithic targets.
    set(IMPORTED_PHYSICS_LIBS
        PhysX_static_64
        PhysXPvdSDK_static_64
        PhysXVehicle_static_64
        PhysXCharacterKinematic_static_64
        PhysXExtensions_static_64
        PhysXCooking_static_64
        PhysXCommon_static_64
        PhysXFoundation_static_64
    )
    foreach(PHYSICS_LIB ${IMPORTED_PHYSICS_LIBS})
        add_library(${PHYSICS_LIB}::imported STATIC IMPORTED GLOBAL)
        set(${PHYSICS_LIB}_PATH ${MONO_PATH_TO_STATIC_LIBS}/${CMAKE_STATIC_LIBRARY_PREFIX}${PHYSICS_LIB}${CMAKE_STATIC_LIBRARY_SUFFIX})
        set_target_properties(${PHYSICS_LIB}::imported
            PROPERTIES
                IMPORTED_LOCATION_DEBUG   ${${PHYSICS_LIB}_PATH}
                IMPORTED_LOCATION_PROFILE ${${PHYSICS_LIB}_PATH}
                IMPORTED_LOCATION_RELEASE ${${PHYSICS_LIB}_PATH}
        )
        target_link_libraries(${PHYSICS_LIB}::imported INTERFACE 
            ${PREVIOUS_PHYSICS_LIB}
            ${MONO_PATH_TO_STATIC_LIBS}/${CMAKE_STATIC_LIBRARY_PREFIX}${PHYSICS_LIB}${CMAKE_STATIC_LIBRARY_SUFFIX}
        )
        set (PREVIOUS_PHYSICS_LIB ${PHYSICS_LIB}::imported)
    endforeach()

    add_library(Physx5_STATIC_LIBS_FOR_MONOLITHIC::imported INTERFACE IMPORTED GLOBAL)
        target_link_libraries(Physx5_STATIC_LIBS_FOR_MONOLITHIC::imported INTERFACE
        PhysXFoundation_static_64::imported
    )

    if(extra_shared_libs)
        set(${MY_NAME}_RUNTIME_DEPENDENCIES
            ${extra_shared_libs}
        )
    endif()
else()
    list(APPEND ${MY_NAME}_LIBRARIES
        ${PATH_TO_LIBS}/${import_lib_prefix}PhysX_64${import_lib_suffix}
        ${PATH_TO_LIBS}/${import_lib_prefix}PhysXCooking_64${import_lib_suffix}
        ${PATH_TO_LIBS}/${import_lib_prefix}PhysXFoundation_64${import_lib_suffix}
        ${PATH_TO_LIBS}/${import_lib_prefix}PhysXCommon_64${import_lib_suffix}
        ${extra_static_libs}
    )
    set(${MY_NAME}_RUNTIME_DEPENDENCIES
        ${PATH_TO_LIBS}/${CMAKE_SHARED_LIBRARY_PREFIX}PhysX_64${CMAKE_SHARED_LIBRARY_SUFFIX}
        ${PATH_TO_LIBS}/${CMAKE_SHARED_LIBRARY_PREFIX}PhysXCooking_64${CMAKE_SHARED_LIBRARY_SUFFIX}
        ${PATH_TO_LIBS}/${CMAKE_SHARED_LIBRARY_PREFIX}PhysXFoundation_64${CMAKE_SHARED_LIBRARY_SUFFIX}
        ${PATH_TO_LIBS}/${CMAKE_SHARED_LIBRARY_PREFIX}PhysXCommon_64${CMAKE_SHARED_LIBRARY_SUFFIX}
        ${extra_shared_libs}
    )
endif()

add_library(${TARGET_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL)
ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${${MY_NAME}_INCLUDE_DIR})
if(LY_MONOLITHIC_GAME)
    target_link_libraries(${TARGET_WITH_NAMESPACE} INTERFACE Physx5_STATIC_LIBS_FOR_MONOLITHIC::imported)
else()
    target_link_libraries(${TARGET_WITH_NAMESPACE} INTERFACE ${${MY_NAME}_LIBRARIES})
endif()
target_compile_definitions(${TARGET_WITH_NAMESPACE} INTERFACE ${${MY_NAME}_COMPILE_DEFINITIONS})
if(DEFINED ${MY_NAME}_RUNTIME_DEPENDENCIES)
    ly_add_target_files(TARGETS ${TARGET_WITH_NAMESPACE} FILES ${${MY_NAME}_RUNTIME_DEPENDENCIES})
endif()

set(${MY_NAME}_FOUND True)
