package com.pawcare.rest.api

import groovy.sql.Sql

import java.sql.DriverManager

class Database {

    private static final String DRIVER = 'com.mysql.cj.jdbc.Driver'

    static Sql open() {
        Class.forName(DRIVER)

        String url = System.getenv('PAWCARE_DB_URL') ?:
                'jdbc:mysql://127.0.0.1:3306/pawcare?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Ho_Chi_Minh'

        String user = System.getenv('PAWCARE_DB_USER') ?: 'root'
        String password = System.getenv('PAWCARE_DB_PASSWORD') ?: ''

        return new Sql(DriverManager.getConnection(url, user, password))
    }

    static Object withSql(Closure action) {
        Sql sql = open()
        try {
            return action.call(sql)
        } finally {
            sql.close()
        }
    }
}