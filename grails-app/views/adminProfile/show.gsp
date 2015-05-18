<%@ page import="grails.plugins.crm.core.TenantUtils; grails.plugins.crm.contact.CrmContact" %>
<!DOCTYPE html>
<html>
<head>
    <meta name="layout" content="main"/>
    <g:set var="entityName" value="${message(code: 'crmContact.label', default: 'Contact')}"/>
    <title><g:message code="crmContact.show.title" args="[entityName, crmContact]"/></title>
    <r:script>
        $(document).ready(function () {
            $('#editModal').on('shown', function () {
                // If there's no employers in the list, hide the accept button.
                if (!$(":radio", $(this))) {
                    $("button[name='_action_changeParent']").hide();
                }
            });
        });
    </r:script>
</head>

<body>

<div class="row-fluid">
<div class="span9">

<header class="page-header clearfix">
    <g:if test="${crmContact.person && crmContact.email}">
        <avatar:gravatar email="${crmContact.email}" size="64" id="avatar" cssClass="avatar pull-right"
                         defaultGravatarUrl="mm"/>
    </g:if>

    <g:if test="${crmContact.company}">
        <img src="${resource(dir: 'images', file: 'company-avatar.png')}" class="avatar pull-right"
             width="64" height="64"/>
    </g:if>

    <crm:user>
        <h1>
            ${crmContact.encodeAsHTML()}
            <crm:favoriteIcon bean="${crmContact}"/>
            <small>${crmContact.title?.encodeAsHTML()}</small>
        </h1>
    </crm:user>

    <g:if test="${crmContact.parent}">
        <h2>${crmContact.parent.encodeAsHTML()}</h2>
    </g:if>
</header>

<div class="tabbable">

<ul class="nav nav-tabs">
    <li class="active"><a href="#main" data-toggle="tab"><g:message code="crmContact.tab.main.label"/></a>
    </li>
    <crm:pluginViews location="tabs" var="view">
        <crm:pluginTab id="${view.id}" label="${view.label}" count="${view.model?.totalCount}"/>
    </crm:pluginViews>
</ul>

<div class="tab-content">

<div class="tab-pane active" id="main">
<div class="row-fluid">
    <div class="span4">
        <dl>
            <dt><g:message code="crmContact.name.label"/></dt>
            <dd>${crmContact.name.encodeAsHTML()}</dd>

            <g:if test="${crmContact.title}">
                <dt><g:message code="crmContact.title.label" default="Title"/></dt>
                <dd><g:fieldValue bean="${crmContact}" field="title"/></dd>
            </g:if>
            <g:if test="${crmContact.parent}">
                <g:if test="${crmContact.company}">
                    <dt><g:message code="crmCompany.parent.label" default="Parent Company"/></dt>
                </g:if>
                <g:else>
                    <dt><g:message code="crmContact.parent.label" default="Company"/></dt>
                </g:else>
                <dd><g:link action="show" id="${crmContact.parent.id}"><g:fieldValue
                        bean="${crmContact}"
                        field="parent"/></g:link></dd>
            </g:if>

            <g:if test="${crmContact.addresses}">
                <g:each in="${crmContact.addresses.sort { it.type.orderIndex }}" var="address" status="i">
                    <dt>${address.type}</dt>
                    <dd>${address}
                        <g:if test="${address.latitude && address.longitude}">
                            <a href="http://maps.google.com/?q=${crmContact.encodeAsURL()}@${address.latitude},${address.longitude}&z=16&t=m"
                               target="map"
                               title="${message(code: 'crmContact.map.show.label', default: 'Show on map')}"><i
                                    class="icon-map-marker"></i>
                            </a>
                        </g:if>
                    </dd>
                </g:each>
            </g:if>
            <g:else>
                <dt>${crmContact.address?.type}</dt>
                <dd>${crmContact.address?.encodeAsHTML()}</dd>
            </g:else>
        </dl>
    </div>

    <div class="span4">
        <dl>
            <g:if test="${crmContact.email}">
                <dt><g:message code="crmContact.email.label" default="Email"/></dt>
                <dd><a href="mailto:${crmContact.email}"><g:decorate include="abbreviate" max="30"><g:fieldValue
                        bean="${crmContact}"
                        field="email"/></g:decorate></a>
                </dd>
            </g:if>
            <g:if test="${crmContact.telephone}">
                <dt><g:message code="crmContact.telephone.label" default="Telephone"/></dt>
                <dd><a href="tel:${crmContact.telephone}"><g:fieldValue bean="${crmContact}"
                                                                        field="telephone"/></a>
                </dd>
            </g:if>
            <g:if test="${crmContact.mobile}">
                <dt><g:message code="crmContact.mobile.label" default="Mobile"/></dt>
                <dd><a href="tel:${crmContact.mobile}"><g:fieldValue bean="${crmContact}"
                                                                     field="mobile"/></a>
                </dd>
            </g:if>
            <g:if test="${crmContact.fax}">
                <dt><g:message code="crmContact.fax.label" default="Fax"/></dt>
                <dd><a href="tel:${crmContact.fax}"><g:fieldValue bean="${crmContact}"
                                                                     field="fax"/></a>
                </dd>
            </g:if>
            <g:if test="${crmContact.url}">
                <dt><g:message code="crmContact.url.label" default="Web"/></dt>
                <dd style="overflow: hidden;"><g:decorate include="url"><g:fieldValue bean="${crmContact}" field="url"/></g:decorate></dd>
            </g:if>
        </dl>
    </div>

    <div class="span4">
        <dl>
            <g:if test="${crmContact.categories}">
                <dt><g:message code="crmContact.category.label" default="Categorys"/></dt>
                <dd>${crmContact.categories.sort{it.toString()}.join(', ').encodeAsHTML()}</dd>
            </g:if>
            <g:if test="${crmContact.number}">
                <dt><g:message code="crmContact.number.label" default="Customer ID"/></dt>
                <dd><g:fieldValue bean="${crmContact}" field="number"/></dd>
            </g:if>
            <g:if test="${crmContact.number2}">
                <dt><g:message code="crmContact.number2.label" default="Reference Number"/></dt>
                <dd><g:fieldValue bean="${crmContact}" field="number2"/></dd>
            </g:if>
            <g:if test="${crmContact.ssn}">
                <dt><g:message code="crmContact.ssn.label" default="Social Security Number"/></dt>
                <dd><g:fieldValue bean="${crmContact}" field="ssn"/></dd>
            </g:if>
            <g:if test="${crmContact.duns}">
                <dt><g:message code="crmContact.duns.label" default="D-U-N-S Number"/></dt>
                <dd><g:fieldValue bean="${crmContact}" field="duns"/></dd>
            </g:if>
            <g:if test="${crmContact.birthYear || crmContact.birthMonth || crmContact.birthDay}">
                <dt><g:message code="crmContact.birthDate.label" default="Date of Birth"/></dt>
                <dd>
                    <g:if test="${crmContact.birthDay}">${crmContact.birthDay}</g:if>
                    <g:if test="${crmContact.birthMonth}">${message(code: 'default.monthName.' + crmContact.birthMonth + '.long', default: crmContact.birthMonth.toString())}</g:if>
                    <g:if test="${crmContact.birthYear}">${crmContact.birthYear}</g:if>
                </dd>
            </g:if>
            <g:if test="${crmContact.username}">
                <dt><g:message code="crmContact.username.label" default="Owner"/></dt>
                <dd><crm:user username="${crmContact.username}">${name}</crm:user></dd>
            </g:if>
        </dl>

        <div class="vcard hide">
            ${crmContact.vcard.replace('\n', '<br/>\n')}
        </div>
    </div>
</div>

<g:if test="${crmContact.description}">
    <div class="row-fluid">
        <div class="span8">
            <dl>
                <dt><g:message code="crmContact.description.label" default="Description"/></dt>
                <dd><g:decorate encode="HTML" nlbr="true">${crmContact.description}</g:decorate></dd>
            </dl>
        </div>
    </div>
</g:if>

<div class="form-actions btn-toolbar">

    <crm:selectionMenu location="crmContact" visual="primary">
        <crm:button type="link" action="index"
                    visual="primary" icon="icon-search icon-white"
                    label="crmContact.find.label" permission="crmContact:show"/>
    </crm:selectionMenu>

    <crm:button type="link" action="edit" id="${crmContact?.id}" visual="warning"
                icon="icon-pencil icon-white" accesskey="r"
                label="crmContact.button.edit.label" permission="crmContact:edit"/>

    <crm:button type="link" action="create" visual="success" permission="crmContact:create"
                icon="icon-file icon-white"
                label="crmContact.button.create.label" permission="crmContact:create"/>

    <div class="btn-group">
        <button class="btn btn-info dropdown-toggle" data-toggle="dropdown">
            <i class="icon-info-sign icon-white"></i>
            <g:message code="crmContact.button.view.label" default="View"/>
            <span class="caret"></span></button>
        <ul class="dropdown-menu">
            <g:if test="${selection}">
                <li>
                    <select:link action="list" selection="${selection}" params="${[view:'list']}">
                        <g:message code="crmContact.show.result.label" default="Show result in list view"/>
                    </select:link>
                </li>
            </g:if>
        </ul>
    </div>

</div>

<crm:timestamp bean="${crmContact}"/>

</div>

<crm:pluginViews location="tabs" var="view">
    <div class="tab-pane tab-${view.id}" id="${view.id}">
        <g:render template="${view.template}" model="${view.model}" plugin="${view.plugin}"/>
    </div>
</crm:pluginViews>

</div>
</div>

</div>

<div class="span3">

    <g:render template="/tags" plugin="crm-tags" model="${[bean: crmContact]}"/>

    <crm:pluginViews location="sidebar" var="view">
        <g:render template="${view.template}" model="${view.model}" plugin="${view.plugin}"/>
    </crm:pluginViews>

</div>

</div>

</body>
</html>
