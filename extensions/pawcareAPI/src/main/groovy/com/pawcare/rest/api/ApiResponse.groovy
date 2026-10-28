package com.pawcare.rest.api

import groovy.json.JsonBuilder
import org.bonitasoft.web.extension.rest.RestApiResponse
import org.bonitasoft.web.extension.rest.RestApiResponseBuilder

class ApiResponse {

    static RestApiResponse json(RestApiResponseBuilder responseBuilder,
                                int status,
                                Serializable body) {
        return responseBuilder.with {
            withResponseStatus(status)
            withMediaType('application/json')
            withCharacterSet('UTF-8')
            withResponse(new JsonBuilder(body).toString())
            build()
        }
    }

    static RestApiResponse error(RestApiResponseBuilder responseBuilder,
                                 int status,
                                 String message) {
        return json(responseBuilder, status, [
                status: status,
                error : message
        ] as Serializable)
    }
}

class ApiException extends RuntimeException {
    final int status

    ApiException(int status, String message) {
        super(message)
        this.status = status
    }
}