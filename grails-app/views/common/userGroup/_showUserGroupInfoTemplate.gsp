
<%@page import="species.utils.ImageType"%>
<div class="observation_info">

	<h5>
		${userGroupInstance.name }
	</h5>

	<div class="prop tablet">
		<span class="name tablet"><i class="icon-time"></i>Founded</span>
		<obv:showDate
			model="['userGroupInstance':userGroupInstance, 'propertyName':'FoundedOn']" />
	</div>

	<div class="btn btn-primary view-button">
		<g:link action="show"
			id="${userGroupInstance.id}">View</g:link>
	</div>


</div>


