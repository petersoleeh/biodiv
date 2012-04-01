
<%@page import="species.utils.ImageType"%>
<div class="observation_story tablet">
        
        <h5><obv:showSpeciesName model="['observationInstance':observationInstance]" /></h5>
        <div class="icons-bar">
            <div class="observation-icons">
                    <img class="group_icon"
                            title="${observationInstance.group?.name}"  
							src="${createLinkTo(dir: 'images', file: observationInstance.group.icon(ImageType.VERY_SMALL)?.fileName?.trim(), absolute:true)}"/>

                    <g:if test="${observationInstance.habitat}">
                           <img class="habitat_icon group_icon"
                                    title="${observationInstance.habitat.name}" 
                                    src='${createLinkTo(dir: 'images', file:observationInstance.habitat.icon(ImageType.VERY_SMALL)?.fileName?.trim(), absolute:true)}'/>
                    </g:if>

            </div>

            <div class="user-icon">
                    <a href=/biodiv/SUser/show/${observationInstance.author.id}> <img
                            src="${observationInstance.author.icon()}" class="small_profile_pic"
                            title="${observationInstance.author.username}" /> </a>
            </div>
        </div>

        <div class="stats-box">
            <span><i class="icon-eye-open"></i>${observationInstance.getPageVisitCount()} views</span>
                
            <span><i class="icon-comment"></i><fb:comments-count href="${createLink(controller:'observation', action:'show', id:observationInstance.id, base:grailsApplication.config.grails.domainServerURL)}"></fb:comments-count> comments</span>
        </div>
</div>


