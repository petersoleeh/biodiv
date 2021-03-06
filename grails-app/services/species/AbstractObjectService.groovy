package species;

import org.codehaus.groovy.grails.commons.ConfigurationHolder
import org.codehaus.groovy.grails.commons.DomainClassArtefactHandler
import org.springframework.context.i18n.LocaleContextHolder as LCH;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.text.SimpleDateFormat;
import species.groups.UserGroup;
import species.groups.SpeciesGroup;
import species.Resource.ResourceType;
import species.participation.Featured;
import species.auth.SUser;
import species.participation.Checklists;
import species.sourcehandler.XMLConverter;
import species.participation.Observation;
import species.Species;
import species.ScientificName.TaxonomyRank;
import species.participation.DownloadLog;
import species.participation.UploadLog;
import species.trait.Trait;
import species.trait.Trait.TraitTypes;
import species.trait.Trait.DataTypes;
import species.trait.Trait.Units;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.text.SimpleDateFormat;
import au.com.bytecode.opencsv.CSVReader;
import species.formatReader.SpreadsheetReader;

             
import org.apache.commons.logging.LogFactory;
import grails.plugin.cache.Cacheable;
import org.apache.log4j.Level;

class AbstractObjectService {
    
	def grailsApplication;
	def dataSource;
	def springSecurityService;
	def sessionFactory;
    def utilsService;
    def messageSource;

	protected static final log = LogFactory.getLog(this);
    
    /**
    */
    protected static List createUrlList2(observations) {
		def config = org.codehaus.groovy.grails.commons.ConfigurationHolder.config
		String iconBasePath = config.speciesPortal.observations.serverURL
		def urlList = createUrlList2(observations, iconBasePath)
		return urlList
	}

    //when a query is fired for map with fetchFields ... obv is a map
	protected static List createUrlList2(observations, String iconBasePath) {
		List urlList = []
		for(param in observations){
            def obv = param['observation'];

			def item, controller;
            if(DomainClassArtefactHandler.isDomainClass(obv.getClass())) {
                item = asJSON(obv, iconBasePath);
                controller = UtilsService.getTargetController(obv);
            } else {
                item = obv;
                controller = obv.remove('controller');
                item.lat = obv.remove('latitude');
                item.lng = obv.remove('longitude');
            }
            
			item.url = "/" + controller + "/show/" + obv.id
			item.title = param['title']
            item.type = controller                  
    		if(param.inGroup) {
				item.inGroup = param.inGroup;
			} 
            
            if(param['featuredNotes']) {
                item.featuredNotes = param['featuredNotes']
                 item.language= param['featuredNotes'].language
            }
           
            if(param['featuredOn']) {
                item.featuredOn = param['featuredOn'].getTime();
            }

	        
			urlList << item;
		}
		return urlList
	}

    protected static asJSON(def obv, String iconBasePath) {
            def item = [:] 
            item.id = obv.id
			def config = org.codehaus.groovy.grails.commons.ConfigurationHolder.config
            def sGroup = obv.fetchSpeciesGroup()
            if(sGroup)
			    item.sGroup = sGroup.name
            if(obv.hasProperty('habitat') && obv.habitat)
			    item.habitat = obv.habitat?.name
			
            Resource image = obv.mainImage()
			if(image){
				if(image.type == ResourceType.IMAGE) {
                    boolean isChecklist = obv.hasProperty("isChecklist")?obv.isChecklist:false ;
					item.imageLink = image.thumbnailUrl(isChecklist||(obv.hasProperty('dataTable') && obv.dataTable) ? null: iconBasePath, isChecklist|| ( obv.hasProperty('dataTable') && obv.dataTable) ? '.png' :null)//thumbnailUrl(iconBasePath)
				} else if(image.type == ResourceType.VIDEO) {
					item.imageLink = image.thumbnailUrl()
				} else if(image.type == ResourceType.AUDIO) {
                    item.imageLink = config.grails.serverURL+"/images/audioicon.png"
                }                
			}else{
				item.imageLink =  config.speciesPortal.resources.serverURL + "/" + "no-image.jpg"
			} 			
		
            item.notes = obv.notes()
  			item.summary = obv.summary();				
            
            def obj = obv;
            if(obj.hasProperty('latitude') && obj.latitude) item.lat = obj.latitude
            if(obj.hasProperty('longitude') && obj.longitude) item.lng = obj.longitude
            if(obj.hasProperty('isChecklist') && obj.isChecklist) item.isChecklist = obj.isChecklist
            if(obj.hasProperty('dataset') && obj.dataset) {
                item.dataset_id = obj.dataset.id
                item.datasource_title = obj.dataset.datasource.title;
                item.datasource_mainImage = obj.dataset.datasource.mainImage()?.fileName
            }
            if(obj.hasProperty('fromDate') && obj.fromDate) item.observedOn = obj.fromDate.getTime();
			if(obj.hasProperty('geoPrivacy') && obj.geoPrivacy){
				item.geoPrivacy = obj.geoPrivacy
				item.geoPrivacyAdjust = obj.fetchGeoPrivacyAdjustment()
			}
            return item;
    }
	
    /**
    */
    protected String getIconBasePath(String controller) {
		def config = org.codehaus.groovy.grails.commons.ConfigurationHolder.config
        String iconBasePath = '';
        switch(controller) {
            case "observation": 
		        iconBasePath = config.speciesPortal.observations.serverURL
                break;
            case "species":
                iconBasePath = config.speciesPortal.resources.serverURL
                break;
            case "content":
		        iconBasePath = config.speciesPortal.observations.serverURL
                break;
            default:
                log.warn "Invalid controller type for iconbasepath " + controller
        }
        return iconBasePath;
    }


    /**
    */
    protected Map getFeaturedObject(Long ugId, int limit, long offset, String controller){
        log.debug "Getting featured objects for ${controller} in usergroup ${ugId?ugId:'IBP'}. limit:${limit} offset:${offset}"
        def result;
        String type = ""
        String type1 = ""
        List eagerFetchProperties = [];
        //TODO:change hardcoded string to class definitions
        if (controller == "observation") {
            type = "species.participation.Observation";
            type1 = "species.participation.Checklists";
            eagerFetchProperties =  Observation.eagerFetchProperties;
        }
        else if (controller == "species") {
            type = "species.Species";
        }
        else if (controller == "document") {
            type = "content.eml.Document";
        }
        else if (controller == "discussion") {
            type = "species.participation.Discussion";
        }else {    
        }

        def featured = []
        def count = 0;
        def queryParams = [cache:true];
        def countQuery,query;
        if(type) {
            queryParams["type"] = type
            queryParams["type1"] = type1

            countQuery = "select count(*) from Featured feat where (feat.objectType = :type or feat.objectType = :type1) "

            query = "from Featured feat where (feat.objectType = :type or feat.objectType = :type1) "
        } else {
            countQuery = "select count(*) from Featured feat "
            query = "from Featured feat "
        }

        if(ugId) {
            queryParams["ugId"] = ugId
            countQuery += ' and feat.userGroup.id = :ugId'
            query +=  ' and feat.userGroup.id = :ugId'
        }

        log.debug "CountQuery:"+ countQuery + " params: "+queryParams
        count = Featured.executeQuery(countQuery, queryParams)

        queryParams["max"] = limit
        queryParams["offset"] = offset

        def orderByClause = " order by feat.createdOn desc"
        query += orderByClause

        log.debug "FeaturedQuery:"+ query + " params: "+queryParams

        featured = Featured.executeQuery(query, queryParams);
        def observations = [:]
        featured.each {
            def observation = activityFeedService.getDomainObject(it.objectType, it.objectId, eagerFetchProperties);
            def featuredNotes = [];
            if(observations.containsKey(observation)) {
                featuredNotes = observations.get(observation);
            } else {
                observations.put(observation, featuredNotes);
            }
            //JSON marsheller for this featured object is registered in Bootstrap
            featuredNotes << it
        }

        def i = 0;
        result = [];
        observations.each { key,value ->
            result.add([ 'observation':key, 'title': key.fetchSpeciesCall(), 'featuredNotes':value, 'controller':utilsService.getTargetController(key)]);
        }

        result = ['observations':result,'count':count[0], 'controller':controller?:'abstractObject']
        return result

    }


     /**
     * 
     */
    protected def createResourcesXML(params) {
        NodeBuilder builder = NodeBuilder.newInstance();
        XMLConverter converter = new XMLConverter();
        def resources = builder.createNode("resources");
        Node images = new Node(resources, "images");
        Node videos = new Node(resources, "videos");
        Node audios = new Node(resources, "audios");
        

        String uploadDir = ""
        if( params.resourceListType == "ofSpecies" || params.resourceListType == "fromSingleSpeciesField" ){
            uploadDir = grailsApplication.config.speciesPortal.resources.rootDir
        }
        else if(params.resourceListType == "ofObv" || params.resourceListType == null){
            uploadDir =  grailsApplication.config.speciesPortal.observations.rootDir;
        }
        else{
            uploadDir = grailsApplication.config.speciesPortal.usersResource.rootDir
        }
        BitSet indexes = new BitSet();
        List files = [];
        List titles = [];
        List licenses = [];
        List type = [];
        List url = []
        List source = [];
        List ratings = [];
        List contributor = [];
        List annotations = [];
        //List resContext = [];

        
        params.each { key, val ->
         
            int index = -1;
            if(key.startsWith('file_') || key.startsWith('url_')) {

                index = Integer.parseInt(key.substring(key.lastIndexOf('_')+1));
                if(indexes.get(index)) {
                    index = -1;
                } else {
                    if(val != ""){
                        indexes.set(index);
                    }    
                }

            }
           
            if(index != -1) {
                if(val != "") {
                    files.add(val);

                    titles.add(params.get('title_'+index));
                    licenses.add(params.get('license_'+index));
                    type.add(params.get('type_'+index));
                    url.add(params.get('url_'+index));
                    source.add(params.get('source_'+index));
                    ratings.add(params.get('rating_'+index));
                    //resContext.add(params.get('resContext_'+index));
                    //if( params.speciesId != null ){
                        contributor.add(params.get('contributor_'+index));
                    //}
                    annotations.add(params.get('media_annotations_'+index));
                }
            }
        }
        files.eachWithIndex { file, key ->
            Node image;
          
            if(file) {
                if(type.getAt(key).equalsIgnoreCase(ResourceType.IMAGE.value())) {
                    image = new Node(images, "image");
                    File f = new File(uploadDir, file);
                    if(f.exists())
                        new Node(image, "fileName", f.absolutePath);
                    else if(url.getAt(key)) {
                        new Node(image, "fileName", file);
                        new Node(image, "url", url.getAt(key));
                    }
                } else if(type.getAt(key).equalsIgnoreCase(ResourceType.VIDEO.value())) {
                    image = new Node(videos, "video");
                    new Node(image, "fileName", file);
                    new Node(image, "source", url.getAt(key));
                } else if(type.getAt(key).equalsIgnoreCase(ResourceType.AUDIO.value())) {
                    image = new Node(audios, "audio");                    
                    File f = new File(uploadDir, file);
                    new Node(image, "fileName", f.absolutePath);
                }	

              			
                new Node(image, "caption", titles.getAt(key));
                new Node(image, "license", licenses.getAt(key));
                new Node(image, "rating", ratings.getAt(key));
                new Node(image, "user", springSecurityService.currentUser?.id);
                new Node(image, "language", params.locale_language);
                new Node(image, "annotations", annotations.getAt(key));
                //new Node(image, "resContext", resContext.getAt(key));
                if( params.resourceListType == "ofObv" || params.resourceListType == "usersResource" ){
                    if(!params.author || !contributor.getAt(key)){
                        params.author = springSecurityService.currentUser;
                    }
                    new Node(image, "contributor", contributor.getAt(key)?:params.author.username); 
                }
                else{
                    new Node(image, "contributor", contributor.getAt(key));
                    if(type.getAt(key).equalsIgnoreCase(ResourceType.IMAGE.value())) {
                        new Node(image, "source", source.getAt(key));
                    }
                }
            } else {
                log.warn("No reference key for image : "+key);
            } 
        }

        return resources;
    }

    protected List<Resource> saveResources(instance, resourcesXML) {
        XMLConverter converter = new XMLConverter();
        def rootDir
        switch(instance.class.name) {
            case [Observation.class.name, Checklists.class.name]:
            rootDir = grailsApplication.config.speciesPortal.observations.rootDir
            break;
            
            case [Species.class.name, SpeciesField.class.name]:
            rootDir = grailsApplication.config.speciesPortal.resources.rootDir
            break;

            case SUser.class.name:
            rootDir = grailsApplication.config.speciesPortal.usersResource.rootDir
            break;

            case TraitValue.name:
            rootDir = grailsApplication.config.speciesPortal.traits.rootDir
            break;
        }
        converter.setResourcesRootDir(rootDir);

        def relImagesContext = ""
        for(def i=0; i<resourcesXML.images.image.size();i++){
            if(relImagesContext == ""){
                relImagesContext = resourcesXML.images.image?.getAt(i).fileName?.getAt(0)?.text()?.replace(rootDir.toString(), "")?:""
            }
            if(relImagesContext !="")
            break;
        }
       
        if(relImagesContext == ""){
            relImagesContext = resourcesXML.audios.audio?.getAt(0)?.fileName?.getAt(0)?.text()?.replace(rootDir.toString(), "")?:""
        }
        relImagesContext = new File(relImagesContext).getParent();
        return converter.createMedia(resourcesXML, relImagesContext);
    }


    /**
     * 
     * @param groupId
     * @return
     */
    Object getSpeciesGroupIds(groupId){
        return utilsService.getSpeciesGroupIds(groupId);
    }

    String getExportableValue(String key, String value) {
        if(!value) return;
        switch(key.toLowerCase()) {
            case 'rank' : return TaxonomyRank.getTRFromInt(Integer.parseInt(value)); 
            case ['group_id', 'species group'] : return SpeciesGroup.read(Long.parseLong(value))?.name;
            default : return value;
        }
    }
	
	def upload(params) {
        println "creating upload request"
        log.debug "^^^^^^^^^^^^^^^^^^^^^^^^^^^creating upload request"
        UploadLog dl = UploadLog.create(springSecurityService.currentUser, new Date(), null, params.file, params.notes, params.uploadType?:params.controller, params);
        def r = ['uploadLog':dl];
        if(dl) {
            if(!dl.hasErrors()) {
                r['success'] = true;
                r['msg']= messageSource.getMessage('observation.import.requsted',null,'Processing... You will be notified by email when it is completed. Login and check your user profile for import link.', LCH.getLocale())
            } else {
                r['success'] = false;
                r['msg'] = 'Error in creating upload log.' 
                def errors = [];
                dl.errors.allErrors.each {
                    def formattedMessage = messageSource.getMessage(it, LCH.getLocale());
                    errors << ['field': it.field, 'message': formattedMessage]
                }
                r['errors'] = errors 
                println dl.errors.allErrors
            }
        }
        return r;
    }

    protected Map getTraitQuery(Map traits) {
        Map andTraitLT = [:];
        List notTraitLT = [], anyTraitLT=[];
        String traitQuery = "";
        String traitJsonQuery = "";
        String orderQuery = "";
        String traitArraySlice = 't.traits';

        traits?.each{ it ->
            if(it.value.equalsIgnoreCase('none')) {
                notTraitLT << it.key;
            } else if(it.value.equalsIgnoreCase('any')) {
                anyTraitLT << it.key;
            } else if(it.value !='any') {
                andTraitLT[it.key] = it.value
            }
        }

        if(andTraitLT == null) {
            traitQuery = " and t.traits is null";
        } 
        if(notTraitLT) {
            notTraitLT.each {
                traitQuery += " and (not t.traits[1##999][1] @> cast(ARRAY[["+it+"]] as bigint[]) or t.traits is null)";
            }
        }
        if(anyTraitLT) {
            anyTraitLT.each {
                Trait t = Trait.read(Long.parseLong(it));
                if(t.traitTypes == TraitTypes.RANGE) {
                    if(t.dataTypes == DataTypes.DATE) {
                        traitJsonQuery += " and (traits_json#>>'{${t.id},from_date}') is not null ";
                    } else {
                        traitJsonQuery += " and (traits_json#>>'{${t.id},value}') is not null ";
                    }
                } else if (t.dataTypes == DataTypes.COLOR) {
                    traitJsonQuery += " and cast(traits_json#>>'{${t.id},r}' as integer) is not null ";
                } else { 
                    traitQuery += " and t.traits[1##999][1] @> cast(ARRAY[["+t.id+"]] as bigint[])";
                }
            }
        }
        if(andTraitLT) {
            traitQuery = " and t.traits @> cast(ARRAY[ "
            andTraitLT.each { traitId, traitValueId ->
                //for cases as trait.8= .. ie., with no value 
                if(!traitValueId) return;

                Trait t = Trait.read(Long.parseLong(traitId));
                String[] values;
                if(t.dataTypes == DataTypes.COLOR) {
                    values = traitValueId.split('\\),');
                } else {
                    values = traitValueId.split(',');
                }
                values.each { tvId ->
                    if(t.traitTypes == TraitTypes.RANGE) {
                        if(t.dataTypes == DataTypes.DATE) {
                            def range = tvId.split(':'); 
                            if(range.size() == 2) {
                                if(t.units == Units.MONTH) {
                                    int getFromMonth = utilsService.getMonthIndex(range[0]);
                                    int getToMonth = utilsService.getMonthIndex(range[1]);
                                    traitJsonQuery += " and (traits_json#>>'{${traitId},from_date}') is not null and numrange(cast(extract(month from cast(traits_json#>>'{${traitId},from_date}' as date)) as numeric), cast(extract(month from cast(traits_json#>>'{${traitId},to_date}' as date)) as numeric)) && numrange(${getFromMonth}, ${getToMonth})";
                                } else {
                                    //TODO: range value datatype is set to be float... can be date as well
                                    traitJsonQuery += " and (traits_json#>>'{${traitId},from_date}') is not null and daterange(cast(traits_json#>>'{${traitId},from_date}' as date), cast(traits_json#>>'{${traitId},to_date}' as date)) && daterange(getMonth(to_date('${range[0]}','DD/MM/YYYY'), to_date('${range[1]}','DD/MM/YYYY'))";
                                }
                            }
                        } else {
                            def range = tvId.split(':'); 
                            if(range.size() == 2) {
                            //TODO: range value datatype is set to be float... can be date as well
                            traitJsonQuery += " and (traits_json#>>'{${traitId},value}') is not null and numrange(cast(traits_json#>>'{${traitId},value}' as numeric), cast(traits_json#>>'{${traitId},to_value}' as numeric)) && numrange(${range[0]}, ${range[1]})";
                            }
                        }
                    } else if (t.dataTypes == DataTypes.COLOR) {
                            def range = tvId.replaceAll('rgb\\(|\\)','').split(','); 
                            //COLOR is specified as sarray of RGB values. 
                            //Computing Euclidean distance 
                            traitJsonQuery += " and cast(traits_json#>>'{${traitId},r}' as integer) is not null "
                            orderQuery += " (sqrt(power(${range[0]} - cast(traits_json#>>'{${traitId},r}' as integer), 2) + power(${range[1]} - cast(traits_json#>>'{${traitId},g}' as integer), 2) + power(${range[2]} - cast(traits_json#>>'{${traitId},b}' as integer), 2))), ";
                    } else {
                        if(traitId && tvId) {
                            traitQuery += "[${traitId}, ${tvId}],";
                        }
                    } 
                }
            }
            traitQuery = traitQuery[0..-2] + "] as bigint[])";
        }
        traitQuery += traitJsonQuery;
        return ['filterQuery' : traitQuery, 'orderQuery':orderQuery];
    }

    Map getTraits(String t) {
        //HACK to use this fn from obvUtilService in bulk upload... shd be placed in obvutil
        return utilsService.getTraits(t);
    }

    //TO BE DELETED AND MOVED TO UTILSSERVICE
    private CSVReader getCSVReader(File file) {
        char separator = '\t'
        if(file.exists()) {
            CSVReader reader = new CSVReader(new FileReader(file), separator, CSVWriter.NO_QUOTE_CHARACTER);
            return reader
        }
        return null;
    }

    Map validateCSVHeaders(String file, UploadLog dl, List reqdHeaders) {
        List errors = [];
        CSVReader reader = getCSVReader(new File(file))
        String[] headers = reader.readNext();//headers
        dl.writeLog("Reading headers : "+headers, Level.INFO);

        Map headerNames = [:];
        boolean[] reqdColIndexes = new boolean[headers.size()];
        for(int i=0; i<headers.size(); i++) {
            String lowercaseHeader = headers[i].trim().toLowerCase();
            headerNames[lowercaseHeader] = true;
            for(int j=0; j<reqdHeaders.size(); j++) {
                if(reqdHeaders[j].toLowerCase() == lowercaseHeader) {
                    reqdColIndexes[i] = true
                }
            }
        }
        
        List missingHeaders = reqdHeaders - headerNames.keySet();
        if(missingHeaders.size() != 0) {
            errors << "Columns missing : ${missingHeaders}";
            return ['success':false, 'errors':errors];
        }

        int rowNo = 2;
        String[] row = reader.readNext();
        while(row) {
            for(int i=0; i<row.size(); i++) {
                if(!row[i] && reqdColIndexes[i]) {
                    errors << "Row ${rowNo} has missing value for ${headers[i]}";
                }
            }
            row = reader.readNext();
            rowNo++;
        }

        if(errors) {
            return ['success':false, 'errors':errors];
        }
        return ['success':true];
    }

    Map validateSpreadsheetHeaders(String file, UploadLog dl, List reqdHeaders) {

        List errors = [];
        Map headerNames = [:];
        File f = file?new File(file):null;
        if(f && f.exists()) {
            def v = SpreadsheetReader.readSpreadSheet(f.getAbsolutePath()).get(0);
            dl.writeLog("Reading headers : "+v[0])

            List missingHeaders = reqdHeaders - v[0].keySet();
            if(missingHeaders.size() != 0) {
                errors << "Columns missing : ${missingHeaders}";
                return ['success':false, 'errors':errors];
            }

            v.eachWithIndex { m,index ->
                for(int i=0; i<reqdHeaders.size(); i++) {
                    if(!m[reqdHeaders[i]]) {
                        errors << "Row ${index+2} has missing value for ${reqdHeaders[i]}";
                    }
                }
            }
            if(errors) {
                return ['success':false, 'errors':errors];
            }
        } else {
            errors << "File ${file} doesn't exist."
            return ['success':false, 'msg':""];
        }
        return ['success':true, 'msg':""];
    }
}
