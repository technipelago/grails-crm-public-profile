<%@ page import="grails.plugins.crm.contact.CrmContactAddress; grails.plugins.crm.core.TenantUtils; grails.plugins.crm.contact.CrmAddressType" %>
<!DOCTYPE html>
<html>
<head>
    <meta name="layout" content="main">
    <g:set var="entityName" value="${message(code: 'crmContact.label', default: 'Contact')}"/>
    <title><g:message code="crmContact.edit.title" args="[entityName, crmContact]"/></title>
    <r:require modules="googleMaps,autocomplete,select2"/>
    <g:if test="${htmlContent}">
        <ckeditor:resources/>
    </g:if>
    <r:script>
        function addCategoryInput() {
            var $div = $('<div class="row-fluid"/>');
            var $newInput = $('<input type="text" name="category" value="" class="crm-category span11" autocomplete="off"/>');
            $newInput.autocomplete("${createLink(action: 'autocompleteCategoryType', params: [max: 20])}", {
                remoteDataType: 'json',
                useCache: false,
                filter: false,
                preventDefaultReturn: true,
                selectFirst: true
            });
            $div.append($newInput);
            $("#category-container").append($div);
            $newInput.focus();
        }
        $(document).ready(function() {
            <% if (htmlContent) { %>
                var stylesheet = ["${resource(dir: 'less', file: 'bootstrap.less.css', plugin: 'twitter-bootstrap')}",
                "${resource(dir: 'less', file: 'crm-ui-bootstrap.less.css', plugin: 'crm-ui-bootstrap')}",
                "${resource(dir: 'less', file: 'responsive.less.css', plugin: 'twitter-bootstrap')}"];
                <% if (css) { %>
                stylesheet.push("${resource(css)}");
                <% } %>
                CKEDITOR.plugins.addExternal( 'widget', "${ resource(dir: 'js/ckeditor/plugins/widget', file: 'plugin.js', plugin: 'crm-content-ui')}");
                CKEDITOR.plugins.addExternal( 'dialog', "${ resource(dir: 'js/ckeditor/plugins/dialog', file: 'plugin.js', plugin: 'crm-content-ui')}");
                CKEDITOR.plugins.addExternal( 'dialogui', "${ resource(dir: 'js/ckeditor/plugins/dialogui', file: 'plugin.js', plugin: 'crm-content-ui')}");
                CKEDITOR.plugins.addExternal( 'clipboard', "${ resource(dir: 'js/ckeditor/plugins/clipboard', file: 'plugin.js', plugin: 'crm-content-ui')}");
                CKEDITOR.plugins.addExternal( 'lineutils', "${ resource(dir: 'js/ckeditor/plugins/lineutils', file: 'plugin.js', plugin: 'crm-content-ui')}");
                CKEDITOR.plugins.addExternal( 'image2', "${ resource(dir: 'js/ckeditor/plugins/image2', file: 'plugin.js', plugin: 'crm-content-ui')}");
                CKEDITOR.config.extraPlugins = 'widget,dialog,dialogui,clipboard,lineutils,image2';
                var editor = CKEDITOR.replace('content',
                {
                    customConfig: "${resource(dir: 'js', file: 'crm-ckeditor-config.js', plugin: 'crm-content-ui')}",
                    stylesSet: "crm-web-styles:${resource(dir: 'js', file: 'crm-ckeditor-styles.js', plugin: 'crm-content-ui')}",
                    baseHref: '',//"${createLink(controller: 'static')}",
                    contentsCss: stylesheet,
                    filebrowserBrowseUrl: "${createLink(controller: 'crmContent', action: 'browse')}?reference=crmContact@${crmContact.ident()}&status=shared",
                    filebrowserUploadUrl: "${createLink(controller: 'crmContent', action: 'upload')}",
                    filebrowserImageBrowseUrl: "${createLink(controller: 'crmContent', action: 'browse')}?pattern=image&reference=crmContact@${crmContact.ident()}&status=shared",
                    filebrowserImageUploadUrl: "${createLink(controller: 'crmContent', action: 'upload')}"
                });
            <% } %>

            $("input.crm-category").autocomplete("${createLink(action: 'autocompleteCategoryType', params: [max: 20])}", {
                remoteDataType: 'json',
                useCache: false,
                filter: false,
                preventDefaultReturn: true,
                selectFirst: true
            });
            $("#btn-add-category").click(function(ev) {
                ev.preventDefault();
                addCategoryInput();
            });
            $(".show-visible-extra").click(function(event) {
                event.stopPropagation();
                var tab = $(this).closest(".tab-pane");
                $(".visible-extra", tab).slideDown();
                $(".hidden-extra", tab).hide();
                return false;
            });
            $(".hide-visible-extra").click(function(event) {
                event.stopPropagation();
                var tab = $(this).closest(".tab-pane");
                $(".visible-extra", tab).slideUp();
                $(".hidden-extra", tab).show();
                return false;
            });
            // Put focus in first open field after tab change.
            $('a[data-toggle="tab"]').on('shown', function (ev) {
                var tab = $(ev.target.hash);
                $(':input[type="text"]:visible:enabled:first', tab).focus();
            });
        });
    </r:script>
</head>

<body>

<g:hasErrors bean="${crmContact}">
    <crm:alert class="alert-error">
        <ul>
            <g:eachError bean="${crmContact}" var="error">
                <li <g:if test="${error in org.springframework.validation.FieldError}">data-field-id="${error.field}"</g:if>><g:message
                        error="${error}"/></li>
            </g:eachError>
        </ul>
    </crm:alert>
</g:hasErrors>

<header class="page-header clearfix">
    <g:if test="${crmContact.person && crmContact.email}">
        <avatar:gravatar email="${crmContact.email}" size="64" id="avatar" cssClass="avatar pull-right"
                         defaultGravatarUrl="mm"/>
    </g:if>

    <g:if test="${crmContact.company}">
        <img src="${resource(dir: 'images', file: 'company-avatar.png')}" class="avatar pull-right"
             width="64" height="64"/>
    </g:if>

    <h1><g:message code="crmContact.edit.title"
                   args="[entityName, crmContact]"/> <small>${crmContact.primaryContact?.encodeAsHTML()}</small></h1>

</header>


<g:form action="edit">
    <g:hiddenField name="referer" id="hiddenReferer" value="${referer}"/>
    <g:hiddenField name="id" value="${crmContact.id}"/>
    <g:hiddenField name="version" value="${crmContact.version}"/>

    <div class="tabbable">
        <ul class="nav nav-tabs">
            <li class="active"><a href="#main" data-toggle="tab"><g:message code="crmContact.tab.main.label"/></a></li>
            <g:each in="${addressTypes}" var="addressType" status="i">
                <li>
                    <a href="#${addressType.param ?: 'a' + addressType.id}"
                       data-toggle="tab">${addressType.encodeAsHTML()}
                    <g:if test="${crmContact.addresses?.find { it.type == addressType }}">
                        (1)
                    </g:if>
                    </a>
                </li>
            </g:each>
            <g:if test="${htmlContent}">
                <li><a href="#html" data-toggle="tab"><g:message code="crmPublicProfile.tab.html.label" default="Presentation"/>(1)</a></li>
            </g:if>
        </ul>

        <div class="tab-content">
            <div class="tab-pane active" id="main">
                <f:with bean="crmContact">

                    <div class="row-fluid">

                        <div class="span4">
                            <div class="row-fluid">
                                <g:if test="${crmContact.company}">
                                    <f:field property="name" input-autofocus="" required=""
                                             input-class="span12"/>
                                    <f:field property="telephone" input-class="span7"/>
                                    <f:field property="fax" input-class="span7"/>
                                </g:if>
                                <g:else>
                                    <f:field property="firstName" input-autofocus="" required=""
                                             input-class="span11"/>
                                    <f:field property="lastName" input-class="span11"/>
                                    <f:field property="title" input-class="span11"/>
                                </g:else>
                            </div>
                        </div>

                        <div class="span4">
                            <div class="row-fluid">
                                <g:unless test="${crmContact.company}">
                                    <f:field property="telephone" input-class="span8"/>
                                    <f:field property="mobile" input-class="span8"/>
                                </g:unless>
                                <f:field property="email" input-class="span11"/>
                                <f:field property="url" input-class="span11"/>

                                <g:if test="${crmContact.company}">
                                    <div class="control-group">
                                        <label class="control-label"><g:message code="crmContact.category.label"
                                                                                default="Category"/>
                                            <a href="#" id="btn-add-category"><i class="icon-plus-sign"></i></a>
                                        </label>

                                        <div class="controls" id="category-container">
                                            <g:set var="categories"
                                                   value="${crmContact.categories?.sort { it.toString() } ?: []}"/>
                                            <g:if test="${categories}">
                                                <g:each in="${categories}" var="c" status="i">
                                                    <div class="row-fluid">
                                                        <input type="text" name="category" value="${c.toString()}"
                                                               class="crm-category span11" autocomplete="off"/>
                                                    </div>
                                                </g:each>
                                            </g:if>
                                            <g:else>
                                                <div class="row-fluid">
                                                    <input type="text" name="category" value=""
                                                           class="crm-category span11" autocomplete="off"/>
                                                </div>
                                            </g:else>
                                        </div>
                                    </div>
                                </g:if>
                            </div>
                        </div>

                        <div class="span4">
                            <div class="row-fluid">
                                <f:field property="number">
                                    <g:textField name="number" value="${crmContact.number}"
                                                 novalidate="" autocomplete="off" class="input-medium"/>
                                </f:field>
                                <f:field property="number2">
                                    <g:textField name="number2" value="${crmContact.number2}"
                                                 novalidate="" autocomplete="off" class="input-medium"/>
                                </f:field>
                                <f:field property="ssn"
                                         label="${crmContact.company ? 'crmCompany.ssn' : 'crmPerson.ssn'}"
                                         input-class="input-medium"/>
                                <g:if test="${crmContact.company && grailsApplication.config.crm.contact.duns.enabled}">
                                    <f:field property="duns" input-class="input-medium"/>
                                </g:if>
                            </div>
                        </div>

                    </div>

                    <div class="row-fluid">
                        <f:field property="description" label="crmContact.description.label">
                            <g:textArea name="description" rows="6" cols="80"
                                        value="${crmContact.description}" class="span10"/>
                        </f:field>
                    </div>

                </f:with>

            </div>

            <g:each in="${addressTypes}" var="addressType" status="i">
                <div class="tab-pane" id="${addressType.param ?: 'a' + addressType.id}">
                    <g:set var="parentAddr"
                           value="${crmContact.primaryContact?.addresses?.find { it.type == addressType }}"/>
                    <g:set var="myAddr" value="${crmContact.addresses?.find { it.type == addressType }}"/>
                    <div class="row-fluid">
                        <div class="span6">
                            <g:if test="${parentAddr}">
                                <p><g:message code="crmContact.address.self.label" default="Custom {0}" args="${[addressType]}"/></p>
                            </g:if>
                            <g:render template="address"
                                      model="${[bean: myAddr ?: new CrmContactAddress(type: addressType, contact: crmContact), row: i]}"/>

                            <a class="show-visible-extra hidden-extra"
                               href="javascript:void(0)"><g:message code="crmContact.fields.show.more" default="Show more fields"/></a>
                            <a class="hide-visible-extra visible-extra hide"
                               href="javascript:void(0)"><g:message code="crmContact.fields.show.less" default="Show less fields"/></a>
                        </div>

                        <g:if test="${parentAddr}">
                            <div class="span6">
                                <p><g:message code="crmContact.address.parent.label" default="{0} via {1}" args="${[addressType, crmContact.primaryContact]}"/></p>
                                <g:render template="address"
                                          model="${[bean: parentAddr, row: i, prefix: 'parent', disabled: true]}"/>
                            </div>
                        </g:if>

                    </div>
                </div>
            </g:each>

            <g:if test="${htmlContent}">
                <div class="tab-pane" id="html">
                    <g:textArea id="content" name="text" cols="80" rows="15" class="span11"
                                                    value="${htmlContent.text}"/>
                </div>
            </g:if>
        </div>
    </div>

    <div class="form-actions">
        <crm:button visual="warning" icon="icon-ok icon-white" label="crmContact.button.update.label"
                    accesskey="s"/>
        <crm:button action="delete" visual="danger" icon="icon-trash icon-white"
                    label="crmContact.button.delete.label"
                    confirm="crmContact.button.delete.confirm.message" permission="crmContact:delete"/>
        <crm:button type="link" action="show" id="${crmContact.id}" icon="icon-remove"
                    label="crmContact.button.cancel.label"
                    accesskey="b"/>
    </div>

</g:form>

<crm:timestamp bean="${crmContact}"/>

<g:if test="${grailsApplication.config.crm.map.google.api.key}">
    <g:render template="map-selector" model="${[key: grailsApplication.config.crm.map.google.api.key]}"/>
</g:if>

</body>
</html>
