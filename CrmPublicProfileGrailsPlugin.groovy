class CrmPublicProfileGrailsPlugin {
    def groupId = "grails.crm"
    def version = "1.3.0"
    def grailsVersion = "2.2 > *"
    def dependsOn = [:]
    def loadAfter = ['crmContact']
    def pluginExcludes = [
            "grails-app/views/error.gsp"
    ]

    def title = "GR8 CRM Public Profile Plugin"
    def author = "Goran Ehrsson"
    def authorEmail = "goran@technipelago.se"
    def description = '''\
Provide a "members" area on your GR8 CRM powered site where users can login
and manage their contact information and a simple photo gallery.
'''

    def documentation = "https://github.com/goeh/grails-crm-public-profile"
    def license = "APACHE"
    def organization = [name: "Technipelago AB", url: "http://www.technipelago.se/"]
    def issueManagement = [system: "github", url: "https://github.com/goeh/grails-crm-public-profile/issues"]
    def scm = [url: "https://github.com/goeh/grails-crm-public-profile"]
}
