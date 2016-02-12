<%@page import="species.Resource.ResourceType"%>
<%@page import="species.utils.ImageType"%>
<%@page import="species.Resource"%>
<g:set var="mainImage" value="${speciesInstance.mainImage()}" />
<%
    def imagePath = '';
    def speciesGroupIcon =  speciesInstance.fetchSpeciesGroup().icon(ImageType.ORIGINAL)
    if(mainImage?.fileName == speciesGroupIcon.fileName) { 
        imagePath = mainImage.thumbnailUrl(null, '.png');
    } else
        imagePath = mainImage?mainImage.thumbnailUrl():null;

    def obvId = speciesInstance.id
%>

<g:if test="${speciesInstance}">
    <g:set var="featureCount" value="${speciesInstance.featureCount}"/>
</g:if>
<div class="snippet tablet ">
    <span class="badge ${speciesInstance.fetchSpeciesGroup().iconClass()} ${(featureCount>0) ? 'featured':''}" > </span>
    <div class="figure"
        title='<g:if test="${obvTitle != null}">${obvTitle.replaceAll("</i>","").replaceAll("<i>","")}</g:if>'>
                <g:link url="${uGroup.createLink(controller:'species', action:'show', id:obvId, 'pos':pos, 'userGroup':userGroup) }" name="g${pos}">
                
                <g:if test="${imagePath}">
                <span class="img-polaroid" style="background-image:url(${imagePath});">
                </span>
                </g:if>
                <g:else>
                <span class="img-polaroid" title="${g.message(code:'showobservationsnippet.title.contribute')}" style="background-image:url(${createLinkTo( file:"no-image.jpg", base:grailsApplication.config.speciesPortal.resources.serverURL)});">
                </g:else>
		</g:link>
	</div>
	<div class="caption" >
            <g:render template="/species/showSpeciesStoryTabletTemplate" model="['speciesInstance':speciesInstance, 'userGroup':userGroup, 'userGroupWebaddress':userGroupWebaddress]"/>
            <uGroup:objectPost model="['objectInstance':speciesInstance, 'userGroup':userGroup, canPullResource:canPullResource]" />
	</div>
</div>
