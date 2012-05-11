/*
 * Copyright 2012 Goran Ehrsson.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package grails.plugins.crm.profile

import javax.servlet.http.HttpServletResponse
import grails.converters.JSON

class PublicProfileController {

    static allowedMethods = [index: "GET", edit: ["GET", "POST"], upload:"POST", updateImageCaption:"POST", deleteImage:"POST", updateDescription:"POST"]

    def crmSecurityService
    def shiroCrmSecurityService
    def crmContactService
    def crmContentLibraryService
    def crmContentService
    def crmTagService

    def index() {
        crmTagService.createTag(name: "brukare")
        crmTagService.createTag(name: "djurslag")
        crmTagService.createTag(name: "nöt-antal")
        crmTagService.createTag(name: "nöt-raser")
        def user = crmSecurityService.currentUser
        def crmContact = findContact(user)
        def webFolder = crmContentLibraryService.getFolder(crmContact.number)
        def photos = webFolder ? webFolder.getFiles(extension: ['png', 'jpg', 'gif']) : []
        [user: user, crmContact: crmContact, address: crmContact.address, photos: photos]
    }

    private Object findContact(user) {
        def crmContact = crmContactService.list([guid: user.guid], [sort: 'id', order: 'asc']).find {it}
        if (!crmContact) {
            crmContact = crmContactService.save(guid: user.guid, name: user.name, telephone: user.telephone, email: user.email,
                    address: [address1: user.address1, address2: user.address2, address3: user.address3,
                            postalCode: user.postalCode, city: user.city, region: user.region, country: user.countryCode])
        }
        return crmContact
    }

    def edit() {
        def user = crmSecurityService.currentUser
        def crmContact = findContact(user)
        def cmd = new ProfileEditCommand()
        switch (request.method) {
            case "GET":
                bindData(cmd, user)
                bindData(cmd, [url: crmContact.url])
                break
            case "POST":
                bindData(cmd, params)
                cmd.username = user.username
                cmd.email = user.email
                if (cmd.validate()) {
                    crmContact = updateProfile(cmd)
                    updateFacts(crmContact, params)
                    flash.success = message(code: "publicProfile.updated.message", default: "Profile updated", args: [cmd.name, cmd.username, cmd.email])
                    redirect action: "index"
                    return
                }
                break
        }
        [cmd: cmd, crmContact: crmContact]
    }

    private Object updateProfile(ProfileEditCommand cmd) {
        def values = cmd.toMap()
        // Update user.
        def user = shiroCrmSecurityService.updateUser(values)

        // Update user's CrmContact instance.
        def crmContact = findContact(user)
        if (crmContact) {
            bindData(crmContact, values)
            bindData(crmContact.address, values)
            return crmContact.save(flush: true)
        }

        log.error("No CrmContact found for profile [${user.username}]")

        return null
    }

    private void updateFacts(crmContact, params) {
        crmContact.setTagValue("brukare", params.brukare)
        crmContact.setTagValue("djurslag", params.djurslag)
        crmContact.setTagValue("nöt-antal", params.antal)
        crmContact.setTagValue("nöt-raser", params.raser)
    }

    def upload() {

        def fileItem = request.getFile("file")
        if (fileItem && !fileItem.isEmpty()) {
            def user = crmSecurityService.currentUser
            def crmContact = findContact(user)
            def webFolder = crmContentLibraryService.getFolder(crmContact.number)
            if (webFolder) {
                try {
                    def ref = crmContentService.createResource(fileItem, webFolder)
                    flash.success = message(code: "crmContent.upload.success", args: [ref.toString()], default: "Resource [{0}] uploaded")
                } catch (Exception e) {
                    log.error("Failed to upload file: ${fileItem.originalFilename}", e)
                    flash.error = message(code: "crmContent.upload.error", args: [fileItem.originalFilename], default: "Failed to upload file {0}")
                }
            }
        }
        redirect(action: 'index')
    }

    def updateImageCaption(Long id, String caption) {
        def ref = crmContentService.getResourceRef(id)
        if (!ref) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND)
            return
        }
        ref.name = caption
        ref.save()
        render ref.dao as JSON
    }

    def deleteImage(Long id) {
        def ref = crmContentService.getResourceRef(id)
        if (!ref) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND)
            return
        }
        crmContentService.deleteReference(ref)
        render "DELETED"
    }

    def updateDescription(String description) {
        def user = crmSecurityService.currentUser
        def crmContact = findContact(user)
        if (!crmContact) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND)
            return
        }
        crmContact.description = description
        crmContact.save()
        render description
    }
}
