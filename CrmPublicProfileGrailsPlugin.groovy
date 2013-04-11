class CrmPublicProfileGrailsPlugin {
    // Dependency group
    def groupId = "grails.crm"
    // the plugin version
    def version = "0.2"
    // the version or versions of Grails the plugin is designed for
    def grailsVersion = "2.0 > *"
    // the other plugins this plugin depends on
    def dependsOn = [:]
    def loadAfter = ['crmContact']
    // resources that are excluded from plugin packaging
    def pluginExcludes = [
            "grails-app/views/error.gsp"
    ]

    def title = "Crm Public Profile Plugin" // Headline display name of the plugin
    def author = "Goran Ehrsson"
    def authorEmail = "goran@technipelago.se"
    def description = '''\
Provide a "members" area on your Grails CRM powered site where users can login
and manage their contact information and a simple photo gallery.
'''

    def documentation = "https://github.com/goeh/grails-crm-public-profile"
    def license = "APACHE"
    def organization = [name: "Technipelago AB", url: "http://www.technipelago.se/"]
    def issueManagement = [system: "github", url: "https://github.com/goeh/grails-crm-public-profile/issues"]
    def scm = [url: "https://github.com/goeh/grails-crm-public-profile"]
}
