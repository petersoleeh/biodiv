<div>
    <%
    def allowedExtensions = "['csv', 'xls', 'xlsx']"

    def fileParams = [uploadDir:dataTableInstance?dataTableInstance.dataset?.uFile.path+'/'+ UUID.randomUUID().toString()	:'datatable', fileConvert:true]
    def form_id = "addDataTable"
    def form_action = uGroup.createLink(action:'save', controller:'dataTable', 'userGroup':userGroupInstance, 'userGroupWebaddress':params.webaddress)
    def form_button_name = "Add ${dataTableInstance.dataTableType}"
    def form_button_val = "Add "+dataTableInstance.dataTableType; //"${g.message(code:'button.add.checklist')}"
    if(params.action == 'edit' || params.action == 'update'){
    form_action = uGroup.createLink(action:'update', controller:'dataTable', id:dataTableInstance.id, 'userGroup':userGroupInstance, 'userGroupWebaddress':params.webaddress)
    form_button_name = "Update Checklist"
    form_button_val = "${g.message(code:'button.update.checklist')}"
    }

    %>
    <form id="${form_id}" action="${form_action}" method="POST" class="form-horizontal ${form_id}">

        <input type="hidden" name="id" value="${dataTableInstance?.id}"/>
        <input type="hidden" name="dataset" value="${dataTableInstance?.dataset?.id}"/>
        <g:set var="dataset_contributor_autofillUsersId" value="contributor_id" />
        <g:render template="/dataset/collectionMetadataTemplate" model="['instance':dataTableInstance, autofillUserComp:dataset_contributor_autofillUsersId]"/>
        <div class="section">
            <h3><g:message code="default.dataTable.label" /> </h3>
    
                <div class="upload_file" style="display:inline-block">
                    <g:render template='/UFile/docUpload' model="['name': 'dataTableFile', fileParams:fileParams, allowedExtensions:allowedExtensions,uploadCallBack:'if(!responseJSON.success) {alert(responseJSON.msg);} else {showSampleDataTable()}']" />
                </div>
                <div id="gridSection" class="section" style="display:none; width:100%;margin-left:0px;">
                    <div id="myGrid" class=" ${hasErrors(bean: dataTableInstance, field: 'sciNameColumn', 'errors')}" style="width:100%;height:350px;overflow:auto;"></div>
                    <div class="section" style="clear:both;margin:0;">
                        <div class="row control-group ${hasErrors(bean: dataTableInstance, field: 'sciNameColumn', 'errors')}">
                            <div class="controls" style="clear:both;margin:0;">
                                <input type="hidden" id="dataTableType" name="dataTableType" value="${dataTableInstance.dataTableType.ordinal()}"/>
                                <input type="hidden" id="dataTableFilePath" name="dataTableFilePath" value=""/>
                                <input type="hidden" id="speciesGroupTraits" name="speciesGroupTraits" value=""/>
                                <div class="help-inline">
                                    <g:hasErrors bean="${dataTableInstance}" field="sciNameColumn">
                                    <g:message code="checklist.scientific_name.validator.invalid" />
                                    </g:hasErrors>
                                </div>
                                
                            </div>
                        </div>	
                    </div> 
                </div> 
        </div>
                            
        <div id="restOfForm">
            <div class="" style="margin-top: 20px; margin-bottom: 40px;">
                <g:if test="${dataTableInstance?.id}">
                <a href="${createLink(controller:'dataTable', action:'show', id:dataTableInstance.id)}" class="btn"
                style="float: right; margin-right: 5px;"> <g:message code="button.cancel" /> </a>
                </g:if>
                <g:else>
                <a href="${createLink(controller:'dataTable', action:'list')}" class="btn"
                style="float: right; margin-right: 5px;"> <g:message code="button.cancel" /> </a>
                </g:else>

                <g:if test="${dataTableInstance?.id}">
                <div class="btn btn-danger"
                style="float: right; margin-right: 5px;">
                <a
                href="${createLink(mapping:'dataTable', action:'delete', id:dataTableInstance?.id)}"
                onclick="return confirm('${message(code: 'default.delete.confirm.message', args:['dataset'])}');"><g:message code="button.delete.dataTable" /></a>
                </div>
                </g:if>
                <a id="createDataTableSubmit" class="btn btn-primary" style="float: right; margin-right: 5px;">
                ${form_button_val} </a>

                <g:checkBox style="margin-left:0px;" name="agreeTerms" value="${dataTableInstance?.agreeTerms}"/>
                                    <span class="policy-text"> <g:message code="checklist.create.submit.form" /></span></label>

            </div>
        </div>

    </form>

</div>
