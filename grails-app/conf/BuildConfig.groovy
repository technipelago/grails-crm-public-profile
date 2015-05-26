grails.project.class.dir = "target/classes"
grails.project.test.class.dir = "target/test-classes"
grails.project.test.reports.dir = "target/test-reports"
grails.project.target.level = 1.6

grails.project.repos.default = "crm"

grails.project.dependency.resolution = {
    inherits("global") { }
    log "warn"
    repositories {
        grailsCentral()
        mavenRepo "http://labs.technipelago.se/repo/crm-releases-local/"
        mavenRepo "http://labs.technipelago.se/repo/plugins-releases-local/"
    }
    dependencies {
        test "org.spockframework:spock-grails-support:0.7-groovy-2.0"
    }

    plugins {
        build(":tomcat:$grailsVersion",
                ":release:2.2.1",
                ":rest-client-builder:1.0.3") {
            export = false
        }
        test(":hibernate:$grailsVersion") {
            export = false
        }

        test(":spock:0.7") {
            export = false
            exclude "spock-grails-support"
        }

        compile ":markdown:1.1.1"

        compile ":crm-core:2.0.2"
        compile ":crm-security:2.0.3"
        compile ":crm-contact:2.0.2"
        compile ":crm-content:2.0.4"
    }
}
