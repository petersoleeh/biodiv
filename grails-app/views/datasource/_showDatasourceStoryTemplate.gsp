<%@page import="species.utils.Utils"%>
<%@page import="species.utils.ImageType"%>

<div class="observation_story">
    <div class="observation_story_body ${showFeatured?'toggle_story':''}" style=" ${showFeatured?'display:none;':''}">
        <g:if test="${datasourceInstance.description}">
        <div class="prop">
            <g:if test="${showDetails}">
            <span class="name"><i class="icon-info-sign"></i><g:message code="default.notes.label" /></span>
            <div class="value notes_view linktext">                        
                <%  def styleVar = 'block';
                def clickcontentVar = '' 
                %> 
                <g:if test="${datasourceInstance?.language?.id != userLanguage?.id}">
                <%  
                styleVar = "none"
                clickcontentVar = '<a href="javascript:void(0);" class="clickcontent btn btn-mini">'+datasourceInstance?.language?.threeLetterCode?.toUpperCase()+'</a>';
                %>
                </g:if>

                ${raw(clickcontentVar)}
                <div style="display:${styleVar}">${raw(Utils.linkifyYoutubeLink(datasourceInstance.description))}</div>

            </div>
            </g:if>
            <g:else>
            <div class="value notes_view linktext ${showDetails?'':'ellipsis'}">
                ${raw(Utils.stripHTML(datasourceInstance.description))}
            </div>

            </g:else>
        </div>
        </g:if>


    </div>
</div>
