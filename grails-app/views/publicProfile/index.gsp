<%@ page contentType="text/html;charset=UTF-8" %>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
    <meta name="layout" content="main"/>
    <title><g:message code="publicProfile.index.title" args="[crmContact.name, user.username, user.email]"/></title>
    <r:script>
        $(document).ready(function() {
            $(".thumbnail img").click(function(ev) {
                var thumbnail = $(this);
                var preview = $("#image-preview img");
                preview.fadeOut('fast', function() {
                    preview.attr('src', thumbnail.attr('src'));
                    preview.fadeIn('slow');
                });
            }).css("cursor", "pointer");
            $(".thumbnail .caption").click(function(ev) {
                $(this).focus();
            });
            $(".thumbnail .caption").focus(function(ev) {
                ev.stopPropagation();
                var container = $(this).closest(".thumbnail");
                $(".toggle", container).toggle();
                $(":input", container).focus();
                return false;
            });
            $(".thumbnail :input").blur(function(ev) {
                var input = $(this);
                var container = input.closest(".thumbnail");
                var caption = input.val();
                var id = input.data('crm-id');
                $.post("${createLink(action: 'updateImageCaption')}", {id:id, caption:caption}, function(data) {
                    var thumbnail = $("img", container);
                    $(".caption", container).html("<h5>" + data.name + "</h5>");
                    if($("#image-preview img").attr('src') == thumbnail.attr('src')) {
                        $("#image-preview .caption").text(data.name);
                    }
                    $(".toggle", container).toggle();
                });
            });
            $("#description,.thumbnail :input").keyup(function(ev) {
                if (ev.which == 13) {
                    $(this).blur();
                }
            });
            $(".thumbnail i.delete").click(function(ev) {
                if(!confirm("Vill du radera bilden?")) {
                    return false;
                }
                var container = $(this).closest(".thumbnail");
                var thumbnail = $("img", container);
                var id = $(this).data('crm-id');
                var active = ($("#image-preview img").attr('src') == thumbnail.attr('src'));
                $.post("${createLink(action: 'deleteImage')}", {id:id}, function(data) {
                    container.closest("li").remove();
                    if(active) {
                        $("#image-preview").html('<g:img dir="images" file="default-profile.png"/>');
                    }
                });
            }).css("cursor", "pointer");

            $("#description").blur(function(ev) {
                var text = $(this).val();
                $.post("${createLink(action: 'updateDescription')}", {description:text});
            });
        });
    </r:script>
</head>

<body>

<crm:header title="publicProfile.index.title" args="[crmContact.name, user.username, user.email]"/>

<div class="row-fluid">
    <div class="span9">

        <div class="row-fluid">

            <div class="span8">
                <ul class="thumbnails">
                    <li class="span6">
                        <div id="image-preview" class="thumbnail">
                            <g:if test="${photos}">
                                <g:set var="firstPhoto" value="${photos[0]}"/>
                                <img src="${crm.createResourceLink(resource: firstPhoto)}"/>
                                <h5 class="caption">${firstPhoto.name.encodeAsHTML()}</h5>
                            </g:if>
                            <g:unless test="${photos}">
                                <g:img dir="images" file="default-profile.png"/>
                                <h5>
                                    Välj bilder du har lagrade på din dator och klicka på
                                    <span class="label label-success">Ladda upp</span>
                                    för att ladda upp bilden till hemsidan.
                                </h5>
                            </g:unless>
                        </div>
                    </li>
                </ul>

                <p class="caption"></p>

                <g:textArea name="description" rows="7" cols="50" class="span6" value="${crmContact.description}"
                            placeholder="Ange en säljande text som beskriver din gård. 5-6 rader är lagom."/>
            </div>

            <div class="span4">
                <div class="pull-right">
                    <ul class="thumbnails">
                        <g:each in="${photos}" var="photo">
                            <li>
                                <div class="thumbnail span2">
                                    <img src="${crm.createResourceLink(resource: photo)}"/>
                                    <a href="#" class="caption toggle"><h5>${photo.name.encodeAsHTML()}</h5></a>
                                    <g:textField id="photo_${photo.id}_caption" name="caption" class="toggle hide"
                                                 style="width:87%;margin-top:3px;" maxlength="80"
                                                 value="${photo.name}" data-crm-id="${photo.id}"/>
                                    <i class="icon-trash pull-right delete" data-crm-id="${photo.id}"></i>
                                </div>
                            </li>
                        </g:each>
                        <li>
                            <div class="thumbnail span2">
                                <g:uploadForm action="upload">
                                    <p style="padding: 5px;">
                                        Här kan du ladda upp bilder till hemsidan.<br/>
                                        För bästa resultat bör bildstorleken vara 640x480 punkter.<br/>
                                        Andra storlekar kan ge ett utdraget eller ihoptryckt utseende.
                                        <input type="file" name="file" style="width:97%;"/>
                                        <crm:button visual="success" class="btn-mini" icon="icon-upload icon-white"
                                                    label="Ladda upp"/>
                                    </p>

                                </g:uploadForm>
                            </div>
                        </li>
                    </ul>
                </div>
            </div>

        </div>

    </div>

    <div class="span3">
        <crm:submenu title="Kontaktuppgifter">
            <li><strong>${crmContact.name?.encodeAsHTML()}</strong></li>
            <li><strong>${address.address1?.encodeAsHTML()}</strong></li>
            <li><strong>${address.postalCode?.encodeAsHTML()} ${address.city?.encodeAsHTML()}</strong></li>
            <g:if test="${crmContact.telephone}">
                <li><strong>${crmContact.telephone?.encodeAsHTML()}</strong></li>
            </g:if>
            <g:if test="${crmContact.mobile}">
                <li><strong>${crmContact.mobile?.encodeAsHTML()}</strong></li>
            </g:if>
            <g:if test="${crmContact.email}">
                <li><strong>${crmContact.email?.encodeAsHTML()}</strong></li>
            </g:if>
            <g:if test="${crmContact.url}">
                <li><strong>${crmContact.url?.encodeAsHTML()}</strong></li>
            </g:if>

            <li class="nav-header">Gårdsfakta</li>
            <li>
                <dl style="margin: 0;">
                    <dt>Brukare/Ägare</dt>
                    <dd>${crmContact.getTagValue("brukare")}</dd>

                    <dt>Djurslag</dt>
                    <dd>${crmContact.getTagValue("djurslag")}</dd>

                    <dt>Antal nöt</dt>
                    <dd>${crmContact.getTagValue("nöt-antal")}</dd>

                    <dt>Raser</dt>
                    <dd>${crmContact.getTagValue("nöt-raser")}</dd>
                </dl>
            </li>

            <li><g:link action="edit"><g:message code="publicProfile.edit.label"
                                                 args="[message(code:'publicProfile.label', default:'Profile')]"
                                                 default="Edit my profile"/></g:link>
            </li>

        </crm:submenu>
    </div>

</div>

</body>
</html>