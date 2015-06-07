package grails.plugins.crm.profile

import grails.converters.JSON
import grails.converters.XML
import grails.plugins.crm.contact.CrmAddressType
import grails.plugins.crm.contact.CrmContact
import grails.plugins.crm.contact.CrmContactAddress
import grails.plugins.crm.contact.CrmContactCategory
import grails.plugins.crm.contact.CrmContactCategoryType
import grails.plugins.crm.content.CrmResourceRef
import grails.plugins.crm.core.TenantUtils
import grails.plugins.crm.core.WebUtils
import grails.transaction.Transactional
import org.springframework.dao.DataIntegrityViolationException

import java.util.concurrent.TimeoutException

/**
 * Created by goran on 15-05-17.
 */
class AdminProfileController {

    def crmContactService
    def crmContentService
    def crmSecurityService
    def selectionService
    def recentDomainService
    def crmTagService

    def index() {
        // If any query parameters are specified in the URL, let them override the last query stored in session.
        def cmd = new CrmContactQueryCommand()
        def query = params.getSelectionQuery()
        bindData(cmd, query ?: WebUtils.getTenantData(request, 'crmContactQuery'))
        [cmd: cmd]
    }

    def list() {
        def baseURI = new URI('bean://crmContactService/list')
        def query = params.getSelectionQuery()
        def uri

        switch (request.method) {
            case 'GET':
                uri = params.getSelectionURI() ?: selectionService.addQuery(baseURI, query)
                break
            case 'POST':
                uri = selectionService.addQuery(baseURI, query)
                WebUtils.setTenantData(request, 'crmContactQuery', query)
                break
        }

        params.max = Math.min(params.max ? params.int('max') : 10, 100)

        def result
        try {
            result = selectionService.select(uri, params)
            if (result.totalCount == 1 && params.view != 'list') {
                // If we only got one record, show the record immediately.
                redirect action: "show", params: selectionService.createSelectionParameters(uri) + [id: result.head().ident()]
            } else {
                [crmContactList: result, crmContactTotal: result.totalCount, selection: uri]
            }
        } catch (Exception e) {
            flash.error = e.message
            [crmContactList: [], crmContactTotal: 0, selection: uri]
        }
    }

    def clearQuery() {
        WebUtils.setTenantData(request, 'crmContactQuery', null)
        redirect(action: 'index')
    }

    private List<CrmAddressType> getAddressTypes(Long tenant) {
        CrmAddressType.createCriteria().list([sort: 'orderIndex', order: 'desc']) {
            eq('tenantId', tenant)
            eq('enabled', true)
            inList('param', ['visit', 'postal'])
        }
    }

    @Transactional
    def create() {
        def tenant = TenantUtils.tenant
        def crmContact = new CrmContact()
        def user = crmSecurityService.getUserInfo(params.username) ?: crmSecurityService.getCurrentUser()
        def addressTypes = getAddressTypes(tenant)
        params.username = user?.username
        bindData(crmContact, params)
        crmContact.tenantId = tenant

        switch (request.method) {
            case 'GET':
                return [user: user, crmContact: crmContact, addressTypes: addressTypes, referer: params.referer]
            case 'POST':
                bindCategories(crmContact, params.list('category').findAll { it.trim() })
                bindAddresses(crmContact, params)

                if (crmContact.save()) {
                    // TODO hack!
                    if (!params.text) {
                        params.text = "<h2>${crmContact}</h2>\n<p>${crmContact.description ?: ''}</p>\n"
                    }
                    if (params.text) {
                        crmContentService.createResource(params.text, 'presentation.html', crmContact, [contentType: 'text/html', status: CrmResourceRef.STATUS_SHARED])
                    }
                } else {
                    render(view: 'create', model: [user: user, crmContact: crmContact,
                                                   addressTypes: addressTypes, referer: params.referer])
                    return
                }
                flash.success = message(code: 'default.created.message', args: [message(code: 'crmContact.label', default: 'Company'), crmContact.toString()])
                if (params.referer) {
                    redirect(uri: params.referer - request.contextPath)
                } else {
                    redirect(action: "show", id: crmContact.id)
                }
                break
        }
    }

    def show(Long id, String guid) {
        def crmContact = guid ? crmContactService.findByGuid(guid) : crmContactService.getContact(id)
        if (!crmContact) {
            flash.error = message(code: 'default.not.found.message', args: [message(code: 'crmContact.label', default: 'Contact'), guid ?: id])
            redirect(action: "index")
            return
        }

        withFormat {
            html {
                def externalLink = [:]
                def targetContact
                if (crmContact.company) {
                    def externalInfoLink = grailsApplication.config.crm.company.external.info.link
                    if (externalInfoLink) {
                        def externalInfoLabel = grailsApplication.config.crm.company.external.info.label ?: 'crmContact.external.info.label'
                        externalLink.label = message(code: externalInfoLabel, default: "External Information")
                        if (externalInfoLink instanceof Closure) {
                            externalLink.link = externalInfoLink.call(crmContact)
                        } else {
                            externalLink.link = externalInfoLink.toString()
                        }
                    }
                    targetContact = recentDomainService.getHistory(request, CrmContact, 'changeParent')?.find { it }
                }

                return [crmContact: crmContact, externalLink: externalLink, targetContact: targetContact,
                        selection : params.getSelectionURI()]
            }
            json {
                render crmContact.dao as JSON
            }
            xml {
                render crmContact.dao as XML
            }
        }
    }

    @Transactional
    def edit(Long id) {
        def tenant = TenantUtils.tenant
        def user = crmSecurityService.getUserInfo(params.username) ?: crmSecurityService.getCurrentUser()
        params.username = user?.username

        def crmContact = crmContactService.getContact(id)
        if (!crmContact) {
            flash.error = message(code: 'default.not.found.message', args: [message(code: 'crmContact.label', default: 'Contact'), id])
            redirect(action: "index")
            return
        }

        def addressTypes = getAddressTypes(tenant)
        def html = crmContentService.findResourcesByReference(crmContact, [name: "*.html", status: CrmResourceRef.STATUS_SHARED])?.find {
            it
        }

        switch (request.method) {
            case "GET":
                return [user: user, crmContact: crmContact, addressTypes: addressTypes, referer: params.referer, htmlContent: html]
            case "POST":
                if (params.version) {
                    def version = params.version.toLong()
                    if (crmContact.version > version) {
                        crmContact.errors.rejectValue("version", "default.optimistic.locking.failure",
                                [message(code: 'crmContact.label', default: 'Contact')] as Object[],
                                "Another user has updated this contact while you were editing")
                        return [user: user, crmContact: crmContact, addressTypes: addressTypes, referer: params.referer, htmlContent: html]
                    }
                }
                bindData(crmContact, params)
                bindCategories(crmContact, params.list('category').findAll { it.trim() })
                bindAddresses(crmContact, params)

                if (crmContact.save()) {
                    // TODO hack!
                    if (!params.text) {
                        params.text = "<h2>${crmContact}</h2>\n<p>${crmContact.description ?: ''}</p>\n"
                    }
                    if (html) {
                        if (params.text) {
                            def inputStream = new ByteArrayInputStream(params.text.getBytes('UTF-8'))
                            crmContentService.updateResource(html, inputStream, 'text/html')
                        } else {
                            crmContentService.deleteReference(html)
                        }
                    } else if (params.text) {
                        crmContentService.createResource(params.text, 'presentation.html', crmContact, [contentType: 'text/html', status: CrmResourceRef.STATUS_SHARED])
                    }
                } else {
                    return [user: user, crmContact: crmContact, addressTypes: addressTypes, referer: params.referer, htmlContent: html]
                }

                flash.success = message(code: 'default.updated.message', args: [message(code: 'crmContact.label', default: 'Contact'), crmContact.toString()])
                redirect(action: "show", id: crmContact.id)
                break
        }
    }

    private void bindAddresses(CrmContact crmContact, Map params) {
        // This is a workaround for Grails 2.4.4 data binding that does not insert a new CrmContactAddress when 'id' is null.
        // I consider this to be a bug in Grails 2.4.4 but I'm not sure how it's supposed to work with Set.
        // This workaround was not needed in Grails 2.2.4.
        for (i in 0..10) {
            def a = params["addresses[$i]".toString()]
            if (a && !a.id) {
                def ca = new CrmContactAddress(contact: crmContact)
                bindData(ca, a)
                if (!ca.isEmpty()) {
                    if (ca.validate()) {
                        crmContact.addToAddresses(ca)
                    } else {
                        crmContact.errors.addAllErrors(ca.errors)
                    }
                }
            }
        }

        // Remove existing addresses were all properties are blank.
        for (a in crmContact.addresses.findAll { it?.empty }) {
            crmContact.removeFromAddresses(a)
            if (a.id) {
                a.delete()
            }
        }
    }

    private void bindCategories(CrmContact crmContact, List<String> cats) {
        final Collection<CrmContactCategory> existing = crmContact.categories ?: []
        final List<CrmContactCategoryType> add = []
        final List<CrmContactCategory> remove = []
        for (String c in cats) {
            if (!existing.find { it.toString() == c }) {
                CrmContactCategoryType t = crmContactService.createCategoryType([name: c], true)
                if (t.hasErrors()) {
                    return
                } else {
                    add << t
                }
            }
        }
        for (CrmContactCategory c in existing) {
            if (!cats.find { c.toString() == it }) {
                remove << c
            }
        }
        for (CrmContactCategory c in remove) {
            crmContact.removeFromCategories(c)
            c.delete()
        }
        for (CrmContactCategoryType t in add) {
            crmContact.addToCategories(category: t)
        }
    }

    @Transactional
    def delete(Long id) {
        def crmContact = crmContactService.getContact(id)
        if (!crmContact) {
            flash.error = message(code: 'default.not.found.message', args: [message(code: 'crmContact.label', default: 'Contact'), id])
            redirect(action: "index")
            return
        }

        try {
            def tombStone = crmContactService.deleteContact(crmContact)
            flash.warning = message(code: 'default.deleted.message', args: [message(code: 'crmContact.label', default: 'Contact'), tombStone])
            redirect(action: "index")
        }
        catch (DataIntegrityViolationException e) {
            flash.error = message(code: 'default.not.deleted.message', args: [message(code: 'crmContact.label', default: 'Contact'), crmContact])
            redirect(action: "edit", id: id)
        }
    }

    def autocompleteTags() {
        params.offset = params.offset ? params.int('offset') : 0
        if (params.limit && !params.max) params.max = params.limit
        params.max = Math.min(params.max ? params.int('max') : 25, 100)
        def result = crmTagService.listDistinctValue(CrmContact.name, params.remove('q'), params)
        WebUtils.defaultCache(response)
        render result as JSON
    }

    def autocompleteCategoryType() {
        def result = crmContactService.listCategoryType(params.remove('q'), params).collect { it.toString() }
        WebUtils.defaultCache(response)
        render result as JSON
    }

    def export() {
        def user = crmSecurityService.getUserInfo()
        def namespace = params.namespace ?: 'crmContact'
        if (request.post) {
            def filename = message(code: 'crmContact.label', default: 'Contact')
            try {
                def topic = params.topic ?: 'export'
                def result = event(for: namespace, topic: topic,
                        data: params + [user: user, tenant: TenantUtils.tenant, locale: request.locale, filename: filename]).waitFor(60000)?.value
                if (result?.file) {
                    try {
                        WebUtils.inlineHeaders(response, result.contentType, result.filename ?: namespace)
                        WebUtils.renderFile(response, result.file)
                    } finally {
                        result.file.delete()
                    }
                    return null // Success
                } else {
                    flash.warning = message(code: 'crmContact.export.nothing.message', default: 'Nothing was exported')
                }
            } catch (TimeoutException te) {
                flash.error = message(code: 'crmContact.export.timeout.message', default: 'Export did not complete')
            } catch (Exception e) {
                log.error("Export event throwed an exception", e)
                flash.error = message(code: 'crmContact.export.error.message', default: 'Export failed due to an error', args: [e.message])
            }
            redirect(action: "index")
        } else {
            def uri = params.getSelectionURI()
            def layouts = event(for: namespace, topic: (params.topic ?: 'exportLayout'),
                    data: [tenant: TenantUtils.tenant, username: user.username, uri: uri]).waitFor(10000)?.values?.flatten()
            [layouts: layouts, selection: uri]
        }
    }
}
