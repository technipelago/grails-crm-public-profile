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

import grails.plugins.crm.content.CrmResourceRef

import javax.servlet.http.HttpServletResponse
import grails.converters.JSON
import grails.plugins.crm.contact.CrmContact
import grails.plugins.crm.security.CrmUser
import grails.plugins.crm.core.TenantUtils
import grails.plugins.crm.content.CrmResourceFolder

class PublicProfileController {

    static allowedMethods = [index : "GET", edit: ["GET", "POST"], createFromUser: "POST", createFromContact: "POST",
                             upload: "POST", updateImageCaption: "POST", deleteImage: "POST", updateDescription: "POST"]

    private static final String PUBLIC_FOLDER = "partner"

    def crmSecurityService
    def crmContactService
    def crmContentService

    def index(Long id) {
        def (crmContact, user) = findContactAndUser(id)

        if (!crmContact) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND)
            return
        }

        if (!user) {
            user = [:]
        }
        def photos
        def webFolder = crmContentService.getFolder(PUBLIC_FOLDER + '/' + crmContact.number, crmContact.tenantId)
        if (webFolder) {
            photos = webFolder.getFiles(extension: ['png', 'jpg', 'gif'])
        } else {
            webFolder = crmContact
            def jpgs = crmContentService.findResourcesByReference(webFolder, [name: "*.jpg", status: CrmResourceRef.STATUS_SHARED])
            def pngs = crmContentService.findResourcesByReference(webFolder, [name: "*.png", status: CrmResourceRef.STATUS_SHARED])
            photos = (jpgs + pngs) //.findAll { !it.isTagged('bilder') }
        }
        [user: user, crmContact: crmContact, address: crmContact.address, webFolder: webFolder, photos: photos]
    }

    private List findContactAndUser(Long id) {
        def crmContact
        def user

        if (id) {
            crmContact = CrmContact.get(id)
            if (crmContact?.guid) {
                user = CrmUser.findByGuid(crmContact.guid)
            }
        } else {
            user = crmSecurityService.currentUser
            if (!user) {
                throw new RuntimeException("Not authorized")
            }
            crmContact = CrmContact.findByGuid(user.guid)
        }

        return [crmContact, user]
    }

    def createFromUser(String username) {
        def user = crmSecurityService.getUser(username)
        if (!user) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND)
            return
        }

        def crmContact = CrmContact.findByGuid(user.guid)
        if (!crmContact) {
            crmContact = crmContactService.save(guid: user.guid, name: user.name, telephone: user.telephone, email: user.email,
                    address: [address1  : user.address1, address2: user.address2, address3: user.address3,
                              postalCode: user.postalCode, city: user.city, region: user.region, country: user.countryCode])
        }

        def folder = crmContentService.getFolder(PUBLIC_FOLDER + '/' + crmContact.number, crmContant.tenantId)
        if (!folder) {
            TenantUtils.withTenant(crmContact.tenantId) {
                def root = PUBLIC_FOLDER ? crmContentService.getFolder(PUBLIC_FOLDER, crmContact.tenantId) : null
                crmContentService.createFolder(root, crmContact.number, crmContact.name, null, "")
            }
        }

        flash.success = message(code: "publicProfile.created.message", default: "Public Profile created", args: [crmContact.toString()])

        if (params.referer) {
            redirect(uri: params.referer - request.contextPath)
        } else {
            redirect(controller: "crmContact", action: "show", id: crmContact.id)
        }
    }

    def createFromContact(String id) {
        def crmContact = CrmContact.get(id)
        if (!crmContact) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND)
            return
        }
        TenantUtils.withTenant(crmContact.tenantId) {
            def root = PUBLIC_FOLDER ? crmContentService.getFolder(PUBLIC_FOLDER, crmContact.tenantId) : null
            crmContentService.createFolder(root, crmContact.number, crmContact.name, null, "")
        }

        flash.success = message(code: "publicProfile.created.message", default: "Public Profile created", args: [crmContact.toString()])

        if (params.referer) {
            redirect(uri: params.referer - request.contextPath)
        } else {
            redirect(controller: "crmContact", action: "show", id: id)
        }
    }

    def edit(Long id) {
        def (crmContact, user) = findContactAndUser(id)
        if (!crmContact) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND)
            return
        }
        def cmd = new ProfileEditCommand()
        switch (request.method) {
            case "GET":
                if (user) {
                    bindData(cmd, user.properties, [include: ['username']])
                }
                bindData(cmd, crmContact.properties, [include: ['name', 'telephone', 'mobile', 'email', 'url']])
                bindData(cmd, crmContact.address.properties)
                println "cmd=${cmd.toMap()}"
                break
            case "POST":
                bindData(cmd, params)
                cmd.username = user?.username
                if (crmContact.email) {
                    cmd.email = crmContact.email // Not allowed to update email
                }
                if (cmd.validate()) {
                    def values = cmd.toMap()
                    bindData(crmContact, values)
                    bindData(crmContact.address, values)
                    crmContact.save(flush: true)
                    if (cmd.username) {
                        def tmpUser = crmSecurityService.getUser(cmd.username)
                        if (tmpUser) {
                            crmSecurityService.updateUser(tmpUser, values)
                        }
                    }
                    updateFacts(crmContact, params)
                    flash.success = message(code: "publicProfile.updated.message", default: "Profile updated", args: [cmd.name, cmd.username, cmd.email])
                    if (crmContact?.guid == crmSecurityService.currentUser?.guid) {
                        id = null
                    }
                    redirect action: "index", id: id
                    return
                }
                break
        }
        [cmd: cmd, crmContact: crmContact]
    }

    // TODO How do we make the facts dynamic/configurable???
    private void updateFacts(crmContact, params) {
        TenantUtils.withTenant(crmContact.tenantId) {
            crmContact.setTagValue("brukare", params.brukare)
            crmContact.setTagValue("djurslag", params.djurslag)
            crmContact.setTagValue("nöt-antal", params.antal)
            crmContact.setTagValue("nöt-raser", params.raser)
        }
    }

    def upload(Long folder) {
        def webFolder = CrmResourceFolder.get(folder)
        if (!webFolder) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND)
            return
        }

        def fileItem = request.getFile("file")
        if (fileItem && !fileItem.isEmpty()) {
            try {
                def ref
                TenantUtils.withTenant(webFolder.tenantId) {
                    ref = crmContentService.createResource(fileItem.inputStream, fileItem.originalFilename, fileItem.size, fileItem.contentType, webFolder)
                }
                flash.success = message(code: "crmContent.upload.success", args: [ref.toString()], default: "Resource [{0}] uploaded")
            } catch (Exception e) {
                log.error("Failed to upload file: ${fileItem.originalFilename}", e)
                flash.error = message(code: "crmContent.upload.error", args: [fileItem.originalFilename], default: "Failed to upload file {0}")
            }
        }

        def crmContact = CrmContact.findByNumberAndTenantId(webFolder.name, webFolder.tenantId)
        def id = (crmContact?.guid == crmSecurityService.currentUser?.guid) ? null : crmContact.id

        redirect(action: 'index', id: id)
    }

    def updateImageCaption(Long id, String caption) {
        // TODO security alert! Logged in users can update *any* image caption!
        def ref = crmContentService.getResourceRef(id)
        if (!ref) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND)
            return
        }
        ref.title = caption
        ref.save()
        render ref.dao as JSON
    }

    def deleteImage(Long id) {
        // TODO security alert! Logged in users can delete *any* image!
        def ref = crmContentService.getResourceRef(id)
        if (!ref) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND)
            return
        }
        crmContentService.deleteReference(ref)
        render "DELETED"
    }

    def updateDescription(String id, String description) {
        // TODO security alert! Logged in users can update *any* description!
        def webFolder = CrmResourceFolder.get(id)
        if (webFolder) {
            webFolder.description = description
            webFolder.save()
            render webFolder.description
        } else {
            response.sendError(HttpServletResponse.SC_NOT_FOUND)
        }
    }
}
