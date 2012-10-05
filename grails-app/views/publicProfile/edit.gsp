<%@ page contentType="text/html;charset=UTF-8" %>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
    <meta name="layout" content="main"/>
    <title><g:message code="crmPublicProfile.edit.title" args="[cmd.name, cmd.username, cmd.email]"/></title>
    <r:require modules="googleMaps"/>
</head>

<body>

<crm:header title="${cmd.name}" subtitle="${cmd.username}"/>

<g:form action="edit">
    <g:hiddenField name="id" value="${crmContact.id}"/>

    <div class="row-fluid">

        <div class="span9">

            <g:hasErrors bean="${cmd}">
                <crm:alert class="alert-error">
                    <ul>
                        <g:eachError bean="${cmd}" var="error">
                            <li <g:if test="${error in org.springframework.validation.FieldError}">data-field-id="${error.field}"</g:if>><g:message
                                    error="${error}"/></li>
                        </g:eachError>
                    </ul>
                </crm:alert>
            </g:hasErrors>

            <f:with bean="${cmd}">
                <div class="row-fluid">
                    <div class="span4">
                        <fieldset>
                            <legend>Namn &amp; adress</legend>
                            <f:field property="name" label="crmContact.name.label"/>
                            <f:field property="address1" label="crmAddress.address1.label"/>
                            <f:field property="address2" label="crmAddress.address2.label"/>
                            <!--
                            <f:field property="address3" label="crmAddress.address3.label"/>
                            -->
                            <f:field property="postalCode" label="crmAddress.postalAddress.label">
                                <g:textField name="postalCode" value="${cmd.postalCode}" style="width:20%;"/>
                                <g:textField name="city" value="${cmd.city}" style="width:54%;"/>
                            </f:field>
                            <!--
                            <f:field property="region" label="crmAddress.region.label"/>
                            <f:field property="countryCode" label="crmAddress.country.label"/>
                            -->
                            <div class="control-group">
                                <label class="control-label"><g:message code="crmAddress.latitude.label"/></label>

                                <div class="controls">
                                    <div class="input-append">
                                        <input type="text" name="latitude"
                                               value="${formatNumber(number: cmd.latitude, type: 'number', minFractionDigits: 6, maxFractionDigits: 6)}"
                                               pattern="[0-9,\\.]+" min="-90" max="90" step="0.000001"
                                               class="input-medium"/>
                                        <g:if test="${grailsApplication.config.crm.map.google.api.key}">
                                            <button class="btn btn-map" type="button"
                                                    data-crm-latitude="latitude"
                                                    data-crm-longitude="longitude"><i
                                                    class="icon-map-marker"></i>
                                            </button>
                                        </g:if>
                                    </div>
                                </div>
                            </div>

                            <div class="control-group">
                                <label class="control-label"><g:message code="crmAddress.longitude.label"/></label>

                                <div class="controls">
                                    <div class="input-append">
                                        <input type="text" name="longitude"
                                               value="${formatNumber(number: cmd.longitude, type: 'number', minFractionDigits: 6, maxFractionDigits: 6)}"
                                               pattern="[0-9,\\.]+" min="-180" max="180" step="0.000001"
                                               class="input-medium"/>
                                        <g:if test="${grailsApplication.config.crm.map.google.api.key}">
                                            <button class="btn btn-map" type="button"
                                                    data-crm-latitude="latitude"
                                                    data-crm-longitude="longitude"><i
                                                    class="icon-map-marker"></i>
                                            </button>
                                        </g:if>
                                    </div>
                                </div>
                            </div>
                        </fieldset>
                    </div>

                    <div class="span4">
                        <fieldset>
                            <legend>Telefon &amp; e-post</legend>
                            <f:field property="telephone" label="crmContact.telephone.label"/>
                            <f:field property="email" label="crmContact.email.label"/>
                            <f:field property="url" label="crmContact.url.label"/>
                        </fieldset>
                    </div>

                    <div class="span4">
                        <fieldset>
                            <legend>Ändra lösenord</legend>
                            <f:field property="password1" label="publicProfile.password1.label">
                                <g:passwordField name="password1" value="${cmd.password1}"/>
                            </f:field>
                            <f:field property="password2" label="publicProfile.password2.label">
                                <g:passwordField name="password2" value="${cmd.password2}"/>
                            </f:field>
                        </fieldset>
                    </div>
                </div>
            </f:with>

            <div class="form-actions">
                <crm:button visual="success" action="edit" icon="icon-ok icon-white" label="Uppdatera"/>
                <crm:button type="link" action="index" id="${crmContact.id}" icon="icon-remove"
                            label="publicProfile.button.back.label"/>
            </div>
        </div>

        <div class="span3">
            <div class="well">

                <ul class="nav nav-list">
                    <li class="nav-header">Gårdsfakta</li>
                    <li>
                        <label>Brukare/Ägare</label>
                        <g:textField name="brukare" class="input-medium" value="${crmContact.getTagValue('brukare')}"
                                     placeholder="Familjens namn..."/>

                        <label>Djurslag</label>
                        <g:textField name="djurslag" class="input-medium" value="${crmContact.getTagValue('djurslag')}"
                                     placeholder="Nöt, lamm..."/>

                        <label>Antal nöt</label>
                        <g:textField name="antal" class="input-medium" value="${crmContact.getTagValue('nöt-antal')}"
                                     placeholder="Ange antal nöt..."/>

                        <label>Raser</label>
                        <g:textField name="raser" class="input-medium" value="${crmContact.getTagValue('nöt-raser')}"
                                     placeholder="Ange nötraser..."/>
                    </li>
                </ul>

            </div>
        </div>
    </div>
</g:form>

<g:if test="${grailsApplication.config.crm.map.google.api.key}">
    <g:render template="/crmContact/map-selector" plugin="crm-contact-lite" model="${[key: grailsApplication.config.crm.map.google.api.key]}"/>
</g:if>

</body>
</html>