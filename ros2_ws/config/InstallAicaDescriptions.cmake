macro(install_aica_descriptions BASE_FOLDER OUT_FOLDER)
    message("Validating and installing descriptions")
    file(GLOB DESC
        ${BASE_FOLDER}/*.json
        ${BASE_FOLDER}/*.yaml
        ${BASE_FOLDER}/*.yml
    )
    foreach(FILE ${DESC})
        execute_process(COMMAND validate_interface ${FILE}
                        OUTPUT_VARIABLE VALIDATION_OUTPUT
                        RESULT_VARIABLE VALIDATION_RESULT)
        if(NOT VALIDATION_RESULT EQUAL 0)
            message(FATAL_ERROR "Failed to validate file ${FILE}:\n${VALIDATION_OUTPUT}")
        endif()
        install(FILES ${FILE} DESTINATION ${OUT_FOLDER})
    endforeach()
endmacro()