
<%@ page import="content.Project"%>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<meta name="layout" content="main" />
<g:set var="entityName"
	value="${message(code: 'project.label', default: 'Project')}" />
<title><g:message code="default.show.label" args="[entityName]" /></title>
<r:require modules="core" />


</head>
<body>

			<tc:tagCloud bean="${Project}" action="list" sort="${true}" style
				color="${[start: '#084B91', end: '#9FBBE5']}"
				size="${[start: 12, end: 30, unit: 'px']}" paramName='tag' />

	
</body>
</html>
