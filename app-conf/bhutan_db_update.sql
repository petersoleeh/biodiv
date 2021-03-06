/*
 *  All the sql commands are specific to Postgres database only 
 */

alter table field add column connection bigint;
alter table field drop column version;

ALTER TABLE observation ADD language_id bigint;
alter table observation add constraint language_id foreign key (language_id) references language(id) match full;
update observation set language_id = 1;
alter table observation alter column language_id set not null;

ALTER TABLE document ADD language_id bigint;
alter table document add constraint language_id foreign key (language_id) references language(id) match full;
update document set language_id = 1;
alter table document alter column language_id set not null;

ALTER TABLE suser ADD language_id bigint;
alter table suser add constraint language_id foreign key (language_id) references language(id) match full;
update suser set language_id = 1;
alter table suser alter column language_id set not null;

ALTER TABLE user_group ADD language_id bigint;
alter table user_group add constraint language_id foreign key (language_id) references language(id) match full;
update user_group set language_id = 1;	
alter table user_group alter column language_id set not null;

ALTER TABLE resource ADD language_id bigint;
alter table resource add constraint language_id foreign key (language_id) references language(id) match full;
update resource set language_id = 1;
alter table resource alter column language_id set not null;

ALTER TABLE comment ADD language_id bigint;
alter table comment add constraint language_id foreign key (language_id) references language(id) match full;
update comment set language_id = 1;
alter table comment alter column language_id set not null;

alter table classification add column language_id bigint;
alter table classification add constraint language_id foreign key (language_id) references language(id) match full;
update classification set language_id = 1;
alter table classification alter column language_id set not null;


alter table species_field add column language_id bigint;
alter table species_field add constraint language_id foreign key (language_id) references language(id) match full;
update species_field set language_id = 1;
 alter table species_field alter column language_id set not null;

alter table field add column language_id bigint;
alter table field add constraint language_id foreign key (language_id) references language(id) match full;
update field set language_id = 1;
alter table field alter column language_id set not null;


update field set connection = display_order;
alter table field alter column connection set not null;

alter table featured add column language_id bigint;
alter table featured add constraint language_id foreign key (language_id) references language(id) match full;
update featured set language_id = 1;
alter table featured alter column language_id set not null;


alter table facebook_user  add column access_token_expires timestamp without time zone ;

ALTER TABLE observation ADD license_id bigint;
alter table observation add constraint license_id foreign key (license_id) references license(id) match full;


update observation set license_id = c.license_id from checklists c where observation.source_id = c.id and  observation.is_checklist = 'f' and observation.id != observation.source_id;
update observation set license_id = c.license_id from checklists c where observation.source_id = c.id and  observation.is_checklist = 't' and observation.id = observation.source_id;
update observation set license_id = 2 where license_id is null and is_checklist='f' and id=source_id;
alter table observation alter column license_id set not null;

select count(*) from document where license_id is null;
update document set license_id = 2 where license_id is null;
alter table document alter column license_id set not null;

ALTER TABLE checklists DROP COLUMN license_id;

alter table suser add column send_digest boolean;
alter table suser add column fb_profile_pic character varying(255) ;
update suser set send_digest  = false;


alter table observation add column is_locked  boolean;
update observation set is_locked = false;


//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////// AFTER RUNNING MIGRATION SCRIPT //////////////////
///////////////////////////////////////////////////////////////////////////////////////////

update species_field_contributor set attributors_idx = 0;
update taxonomy_registry_suser set contributors_idx = 0;
update species_field_suser set contributors_idx = 0;
update taxonomy_definition_suser set contributors_idx = 0;
update synonyms_suser set contributors_idx = 0;
update common_names_suser set contributors_idx = 0;

UPDATE resource set context = 'OBSERVATION' where id in (select resource_id from observation_resource);
UPDATE resource set context = 'SPECIES' where id in (select resource_id from species_resource);
UPDATE resource set context = 'SPECIES_FIELD' where id in (select resource_id from species_field_resources);
UPDATE resource set context = 'USER' where id in (select res_id from users_resource);

delete from species_field_contributor where species_field_contributors_id is not null;
alter table species_field_contributor drop column species_field_contributors_id;
drop table species_taxonomy_registry ;

update species_field set uploader_id = 1, upload_time = '1970-01-01 00:00:00';
update resource set uploader_id = 1, upload_time = '1970-01-01 00:00:00' where uploader_id is null;

update synonyms set uploader_id = 1, upload_time = '1970-01-01 00:00:00';
update taxonomy_definition set uploader_id = 1, upload_time = '1970-01-01 00:00:00';
update common_names set uploader_id = 1, upload_time = '1970-01-01 00:00:00';
update taxonomy_registry set uploader_id = 1, upload_time = '1970-01-01 00:00:00';

delete from species_field_license where species_field_licenses_id in (select id from species_field where field_id in (select id from field where category='Author Contributed Taxonomy Hierarchy'));;
delete from species_field_contributor where species_field_attributors_id in (select id from species_field where field_id in (select id from field where category='Author Contributed Taxonomy Hierarchy'));
delete from species_field where field_id in (select id from field where category='Author Contributed Taxonomy Hierarchy');


/////////////////////////////on bhutanmaps database/////////////////////////////////
create view  observation_locations as SELECT obs.id,
    obs.source,
    obs.species_name,
    obs.topology
   FROM dblink('dbname=biodiv'::text, 'select id, source, species_name, topology from observation_locations'::text) obs(id bigint, source text, species_name character varying(255), topology geometry);

 create view checklist_species_locations as SELECT obs.id,
    obs.source,
    obs.title,
    obs.species_name,
    obs.topology
   FROM dblink('dbname=biodiv'::text, 'select id, source, title, species_name, topology from checklist_species_locations'::text) obs(id bigint, source text, title character varying(255), species_name character varying(255), topology geometry);
   

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////  Migration on 5th July 2016 /////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


CREATE INDEX root_holder_id_comment_idx ON comment(root_holder_id);
CREATE INDEX root_holder_type_comment_idx ON comment(root_holder_type);
CREATE INDEX last_updated_comment_idx ON comment(last_updated);

ANALYZE activity_feed;
ANALYZE comment;



/////////////////////////////////////////STAT NAMELIST ////////////////////////////////////////////


ALTER TABLE taxonomy_definition ALTER COLUMN canonical_form SET NOT NULL;

//adding place for super-family rank

update taxonomy_definition set rank = 2 where rank = 3 ;
update taxonomy_definition set rank = 3 where rank = 5 ;
update taxonomy_definition set rank = 5 where rank = 7 ;
update taxonomy_definition set rank = 6 where rank = 8 ;
update taxonomy_definition set rank = 7 where rank = 9 ;
update taxonomy_definition set rank = 8 where rank = 10 ;
update taxonomy_definition set rank = 9 where rank = 11 ;
update taxonomy_definition set rank = 10 where rank = 12 ;

//add columns to common name, synonyms and taxon def

ALTER TABLE common_names ADD COLUMN  transliteration varchar(255);
ALTER TABLE common_names ADD COLUMN  status varchar(255);
ALTER TABLE common_names ADD COLUMN  position varchar(255);
ALTER TABLE common_names ADD COLUMN  author_year varchar(255);
ALTER TABLE common_names ADD COLUMN  match_database_name varchar(255);
ALTER TABLE common_names ADD COLUMN  match_id varchar(255);
ALTER TABLE common_names ADD COLUMN  ibp_source varchar(255);
ALTER TABLE common_names ADD COLUMN  via_datasource varchar(255);

update common_names set status = 'COMMON';
update  common_names set position = 'RAW';


ALTER TABLE taxonomy_definition ADD COLUMN  status varchar(255);
ALTER TABLE taxonomy_definition ADD COLUMN  position varchar(255);
ALTER TABLE taxonomy_definition ADD COLUMN  author_year varchar(255);
ALTER TABLE taxonomy_definition ADD COLUMN  match_database_name varchar(255);
ALTER TABLE taxonomy_definition ADD COLUMN  match_id varchar(255);
ALTER TABLE taxonomy_definition ADD COLUMN  ibp_source varchar(255);
ALTER TABLE taxonomy_definition ADD COLUMN  via_datasource varchar(255);

update  taxonomy_definition set status = 'ACCEPTED';
update  taxonomy_definition set position = 'RAW';


ALTER TABLE synonyms ADD COLUMN  status varchar(255);
ALTER TABLE synonyms ADD COLUMN  position varchar(255);
ALTER TABLE synonyms ADD COLUMN  author_year varchar(255);
ALTER TABLE synonyms ADD COLUMN  match_database_name varchar(255);
ALTER TABLE synonyms ADD COLUMN  match_id varchar(255);
ALTER TABLE synonyms ADD COLUMN  ibp_source varchar(255);
ALTER TABLE synonyms ADD COLUMN  via_datasource varchar(255);

update  synonyms set status = 'SYNONYM';
update  synonyms set position = 'RAW';

//added on 25th Feb 2015

ALTER TABLE taxonomy_definition add column is_flagged boolean;
update taxonomy_definition set is_flagged = false;

////////////////**SYNONYM Migration**//////////////
//////////////////////////////////////////////////
RUN-APP to create SynonymsMerged table;
then run these sqls
/////////////////////////////////////////////////



ALTER TABLE taxonomy_definition ADD COLUMN class varchar(255);
update taxonomy_definition set class = 'species.TaxonomyDefinition';
alter table taxonomy_definition alter column class set not null;

ALTER TABLE taxonomy_definition DROP COLUMN flagging_reason;
ALTER TABLE taxonomy_definition ADD COLUMN flagging_reason varchar(1500);

ALTER TABLE recommendation add column is_flagged boolean;
update recommendation set is_flagged = false;
ALTER TABLE recommendation ALTER COLUMN flagging_reason type varchar(1500);
alter table activity_feed alter column activity_descrption type varchar(2000);

ALTER TABLE taxonomy_definition ADD COLUMN no_ofcolmatches int;

ALTER TABLE taxonomy_definition add column is_deleted boolean;
update taxonomy_definition set is_deleted = false;

alter table taxonomy_definition drop column dirty_list_reason;
alter table taxonomy_definition add column dirty_list_reason  varchar(1000);

update taxonomy_definition set no_ofcolmatches = -99;
update taxonomy_definition set position = NULL;

update recommendation set lowercase_name = lower(name); 
update common_names set lowercase_name = lower(name); 
update taxonomy_definition set lowercase_match_name = lower(canonical_form); 

CREATE INDEX taxonomy_definition_lowercase_match_name ON taxonomy_definition(lowercase_match_name);
CREATE INDEX recommendation_lowercase_name ON recommendation(lowercase_name);
CREATE INDEX common_names_lowercase_name ON common_names(lowercase_name);


////////////////////////////////////// ENDS NAMELIST ///////////////////////////////////////////////


1. Add IBP and col hierarchy using addIBPTaxonHie() in namelist_wikwio.groovy.

2. Download COL XML if required using Utils.downloadColXml("file directory path") in colReport.groovy, can mention from what id to do or all. 

3. curateAllNames() in namelist_wikwio.groovy

4. addSynonymsFromCOL() in namelist_wikwio.groovy

5. migrateSynonyms() in namelist_wikwio.groovy

update recommendation set lowercase_name = lower(name); 
update common_names set lowercase_name = lower(name); 
update taxonomy_definition set lowercase_match_name = lower(canonical_form);

/*
 * After Migration clean up steps
 */
1. Add constrain for deltetion in taxonomy_registry.
ALTER TABLE taxonomy_registry DROP CONSTRAINT fk9ded596b7e532be5,
ADD CONSTRAINT fk9ded596b7e532be5 FOREIGN KEY (parent_taxon_id) REFERENCES taxonomy_registry(id) ON DELETE CASCADE;

ALTER TABLE taxonomy_registry_suser ADD CONSTRAINT fk87a93aea76e99a2e FOREIGN KEY (taxonomy_registry_contributors_id) REFERENCES taxonomy_registry(id) ON DELETE CASCADE;

2. Drop hir for all raw names. In checklistObvPost.groovy run dropRawHir()


/////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////// 29th july 2015 ////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////


ALTER TABLE synonyms_suser ADD CONSTRAINT fkc2e9df97c09419c5 FOREIGN KEY (synonyms_contributors_id) REFERENCES synonyms(id) ON DELETE CASCADE;

ALTER TABLE common_names_suser ADD CONSTRAINT fka5241eb35d2d07c2 FOREIGN KEY (common_names_contributors_id) REFERENCES common_names(id) ON DELETE CASCADE;

/////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////// 29 OCT 2015 ////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////// FOR WIKWIO AND BHUTAN //////////////////////////////
1. copyIbpHir() in checklistObvPost.groovy
2. addIBPHirToRawNames()  in checklistObvPost.groovy




////////////////////////////////////// ENDS NAMELIST ///////////////////////////////////////////////


CREATE EXTENSION pg_trgm;
CREATE INDEX ON recommendation using GIST(name gist_trgm_ops);
CREATE INDEX ON taxonomy_definition using GIST(canonical_form gist_trgm_ops);


#not working
delete from recommendation where id in (select r.id from recommendation r left outer join recommendation_vote rv on r.id=rv.recommendation_id where lower(r.name) in (select lower(r.name) from recommendation as r, taxonomy_definition as t where r.name ilike t.canonical_form and r.taxon_concept_id is null and r.is_scientific_name = true) and r.taxon_concept_id is not null and rv.id is  null);
#=====

delete from recommendation where id in (select r.id from recommendation r left outer join recommendation_vote rv on r.id=rv.recommendation_id where lower(r.name) in (select lower(r.name) from recommendation as r, synonyms as s where r.name ilike s.canonical_form and r.taxon_concept_id is null and r.is_scientific_name = true) and r.taxon_concept_id is not null and rv.id is  null);

CREATE TABLE tmp_table_update_taxonconcept as ( select r.id as recoid,  t.id as taxonid, r.name as name, r.language_id as rl, c.language_id as c_lang from recommendation as r, taxonomy_definition as t, common_names as c where 
            r.name ilike c.name and 
                    ((r.language_id is null and c.language_id is null) or (r.language_id is not null and c.language_id is not null and r.language_id = c.language_id ) or (r.language_id = c.language_id )) and 
                            c.taxon_concept_id = t.id and c.taxon_concept_id is not null and
                                    r.taxon_concept_id is null and r.is_scientific_name = false);

delete from recommendation where id in (select r.id from recommendation r left outer join recommendation_vote rv on r.id=rv.recommendation_id or r.id=rv.common_name_reco_id where r.id in (select r.id from recommendation r , tmp_table_update_taxonconcept t where lower(r.name)=lower(t.name) and ((r.language_id is not null and t.c_lang is not null and r.language_id = t.c_lang) or (r.language_id is null and t.c_lang is null)) and r.is_scientific_name = false and r.taxon_concept_id = t.taxonid ));



ALTER TABLE species DROP COLUMN repr_image_id ;
ALTER TABLE species DROP constraint if exists fk8849413c32f2eca9 ;




/** Then run script crop.groovy **/

/** 16th Jan 2015
    FilePicker security
    1. switch on security for biodiv account on filepicker
    2. generate secret key
    3. put it in additional-config file like this - 
    -----------------
    speciesPortal {
        observations {
            filePicker.key = 'AXCVl73JWSwe7mTPb2kXdz'
            filePicker.secret = '4UCJGK6GLVDTRDAHETOCHGPGIY'
        }
    }
    ----------------
**/

/** 27th Jan 2015
    Adding new column has_media in species
    to apply filter on species having media
 **/
ALTER TABLE species ADD COLUMN has_media boolean ;
update species set has_media = false;
update species set has_media = true where id in (select distinct(species_resources_id) from species_resource);
update species set has_media = true where id in (select distinct(sf.species_id) from species_field_resources sfr, species_field sf where sfr.species_field_id = sf.id);

/** 28th Jan 2015
    Updating observations which were not marked deleted when its checklist was deleted
 **/
update observation set is_deleted = true where source_id in (select id from observation where is_checklist = true and is_deleted = true) and is_deleted = false;




#added by sathish for add references
#===========
update species_field SET description = 'dummy' where field_id = 81 and description = '';




# 6th may 2015
# Observation enhancement
update observation set location_scale = 'APPROXIMATE' where  location_scale is null;
alter table observation  alter column location_scale set not null;


# 22 june 2015
////////////////////////////// redundant table drop //////////////
drop table un_curated_scientific_names_un_curated_common_names;
drop table un_curated_votes;
drop table un_curated_common_names;
drop table un_curated_scientific_names;


#23 june 2015 activity feed correction for species page
update activity_feed set activity_descrption = activity_type where activity_type like 'Added hierarchy%';
update activity_feed set activity_descrption = activity_type where activity_type like 'Updated hierarchy%';
update activity_feed set activity_descrption = activity_type where activity_type like 'Deleted hierarchy%';
update activity_feed set activity_descrption = activity_type where activity_type like 'Added common name%';
update activity_feed set activity_descrption = activity_type where activity_type like 'Updated common name%';
update activity_feed set activity_descrption = activity_type where activity_type like 'Deleted common name%';
update activity_feed set activity_descrption = activity_type where activity_type like 'Added synonym%';
update activity_feed set activity_descrption = activity_type where activity_type like 'Updated synonym%';
update activity_feed set activity_descrption = activity_type where activity_type like 'Deleted synonym%';
update activity_feed set activity_descrption = activity_type where activity_type like 'Updated species field%';
update activity_feed set activity_descrption = activity_type where activity_type like 'Added species field%';
update activity_feed set activity_descrption = activity_type where activity_type like 'Deleted species field%';


update activity_feed set activity_type = 'Added hierarchy' where activity_type like 'Added hierarchy%';
update activity_feed set activity_type = 'Updated hierarchy' where activity_type like 'Updated hierarchy%';
update activity_feed set activity_type = 'Deleted hierarchy' where activity_type like 'Deleted hierarchy%';
update activity_feed set activity_type = 'Added common name' where activity_type like 'Added common name%';
update activity_feed set activity_type = 'Updated common name'  where activity_type like 'Updated common name%';
update activity_feed set activity_type = 'Deleted common name' where activity_type like 'Deleted common name%';
update activity_feed set activity_type = 'Added synonym' where activity_type like 'Added synonym%';
update activity_feed set activity_type =  'Updated synonym' where activity_type like 'Updated synonym%';
update activity_feed set activity_type = 'Deleted synonym' where activity_type like 'Deleted synonym%';
update activity_feed set activity_type = 'Updated species field' where activity_type like 'Updated species field%';
update activity_feed set activity_type = 'Added species field' where activity_type like 'Added species field%';
update activity_feed set activity_type = 'Deleted species field' where activity_type like 'Deleted species field%';


# 30th Jun 2015
alter table doc_sci_name add column taxon_concept_id bigint;

#7th July 2015
alter table taxonomy_registry add column parent_taxon_definition_id bigint;
alter table taxonomy_registry add constraint td_fk foreign key (parent_taxon_definition_id) references taxonomy_definition(id);
update taxonomy_registry set parent_taxon_definition_id=t1.taxon_definition_id from taxonomy_registry t1 where taxonomy_registry.parent_taxon_id=t1.id;

///////////////////////////// 7th aug 2015 ////////////////////////
alter table user_group add column send_digest_mail boolean;
update user_group set send_digest_mail = false; 
update user_group set send_digest_mail = true where id in (select user_group_id from digest);
alter table user_group alter column send_digest_mail set not NULL;

alter table user_group  add column stat_start_date timestamp without time zone;
update user_group set stat_start_date = founded_on;
alter table user_group alter column stat_start_date set not NULL;

alter table digest drop column start_date_stats;

#13th Aug 2015
alter table download_log add column offset_param bigint;
update download_log set offset_param=0;
alter table download_log alter column offset_param set not null;



#16th Nov 2015 
drop index if exists last_updated_comment_idx, root_holder_type_comment_idx, root_holder_id_comment_idx;

#16th Nov 2015
update newsletter set language_id=205;
alter table newsletter alter column language_id set not null;
update newsletter set parent_id=0;
alter table newsletter alter column parent_id set not null;



#25 Nov 2015
#Please stop app before running these queries
alter table document add column visit_count integer not null default 0;
alter table document add column rating integer not null default 0;
alter table document add column is_deleted boolean not null default 'false';

alter table observation add column protocol varchar(255);
update observation set protocol='SINGLE_OBSERVATION';
alter table observation alter column protocol set  not null;

alter table observation add column basis_of_record varchar(255);
update observation set basis_of_record='HUMAN_OBSERVATION';
alter table observation alter column basis_of_record set  not null;

insert into license(id,name) values (828,'UNSPECIFIED');

select max(id) from activity_feed;

update dataset set type='OBSERVATIONS';
alter table dataset alter column type set not null;

ALTER TABLE dataset ALTER COLUMN rights type text;
ALTER TABLE dataset ALTER COLUMN purpose type text;
ALTER TABLE dataset ALTER COLUMN additional_info type text;
ALTER TABLE dataset ALTER COLUMN description type text;
ALTER TABLE datasource ALTER COLUMN description type text;

#28th Dec 2015

alter table observation alter column place_name drop not null;
alter table observation alter column reverse_geocoded_name drop not null ;
alter table observation alter column place_name type text;
alter table observation alter column reverse_geocoded_name type text;



#20thJan2016
#Please stop app before running these queries
create index external_id_idx on observation(external_id);

drop view observation_locations ;
drop view checklist_species_locations;
drop view checklist_species_view;
ALTER TABLE recommendation ALTER COLUMN name type text;


create view observation_locations as  SELECT obs.id,
    'observation:'::text || obs.id AS source,
        r.name AS species_name,
            obs.topology,
                obs.last_revised
                   FROM observation obs,
                    recommendation r
                      WHERE obs.max_voted_reco_id = r.id AND obs.is_deleted = false AND (obs.is_showable = true OR obs.external_id is not null);

create view checklist_species_view as SELECT obs.source_id AS id,
    r.name AS species_name
       FROM observation obs,
        recommendation r
          WHERE obs.max_voted_reco_id = r.id AND obs.is_deleted = false AND obs.is_showable = false
          GROUP BY obs.source_id, r.name;


create view checklist_species_locations as SELECT csv.id,
'checklist:'::text || csv.id AS source,
    cls.title,
        csv.species_name,
            obs.topology
                FROM checklist_species_view csv,
                observation obs,
                    checklists cls
                        WHERE csv.id = obs.id AND obs.id = cls.id;



#1st Feb 2016
#Please stop app before running these queries
# Upload gbif data before this
ALTER TABLE observation DISABLE TRIGGER ALL ;
alter table observation add constraint obv_dataset_id_fk foreign key (dataset_id) references dataset(id);

alter table observation add column no_of_images integer not null default 0, add column no_of_videos integer not null default 0,  add column no_of_audio integer not null default 0, add column no_of_identifications integer not null default 0;

update observation set no_of_images = g.count from (select observation_id, count(*) as count from resource r inner join observation_resource or1 on r.id=or1.resource_id and r.type='IMAGE' group by observation_id) g where g.observation_id = id;
update observation set no_of_videos = g.count from (select observation_id, count(*) as count from resource r inner join observation_resource or1 on r.id=or1.resource_id and r.type='VIDEO' group by observation_id) g where g.observation_id = id;
update observation set no_of_audio = g.count from (select observation_id, count(*) as count from resource r inner join observation_resource or1 on r.id=or1.resource_id and r.type='AUDIO' group by observation_id) g where g.observation_id = id;

create table tmp as select observation_id, count(*) as count from recommendation_vote group by observation_id;

update observation set no_of_identifications = g.count from (select * from tmp) g where g.observation_id=id;

drop table tmp;

create table tmp as select resource_id, observation_id, rating_ref, (case when avg is null then 0 else avg end) as avg, (case when count is null then 0 else count end) as count from observation_resource o left outer join (select rating_link.rating_ref, avg(rating.stars), count(rating.stars) from rating_link , rating  where rating_link.type='resource' and rating_link.rating_id = rating.id  group by rating_link.rating_ref) c on o.resource_id =  c.rating_ref order by observation_id asc, avg desc, resource_id asc;

update observation set repr_image_id = g.resource_id from (select b.observation_id,b.resource_id from (select observation_id, max(avg) as max_avg from tmp group by observation_id) a inner join tmp b on a.observation_id=b.observation_id where b.avg=a.max_avg) g where g.observation_id=id;

drop table tmp;

create index on observation(external_id);
create index on observation(dataset_id);
create index on observation(group_id);
create index on observation(max_voted_reco_id);
create index on recommendation(taxon_concept_id);
create index on observation(is_checklist, is_deleted, is_showable);
create index on observation(last_revised desc, id asc);
CREATE INDEX observation_topology_gist ON observation USING GIST (topology);
ANALYZE observation;
VACUUM ANALYZE observation;

ALTER TABLE observation ENABLE TRIGGER ALL ;

#8th Feb 2016
#Please stop app before running these queries
alter table taxonomy_definition add column species_id bigint;
alter table taxonomy_definition add foreign key(species_id) references species(id);
update taxonomy_definition set species_id = s.sid from (select taxon_concept_id, id as sid from species) s  where s.taxon_concept_id = id;

#adding defaultHierarchy json to taxon_definition table
alter table taxonomy_definition alter column default_hierarchy type text;

#7th feb 2016
CREATE INDEX normalized_form_idx ON taxonomy_definition(normalized_form);
CREATE INDEX status_idx ON taxonomy_definition(status);
CREATE INDEX rank_idx ON taxonomy_definition(rank);
CREATE INDEX position_idx ON taxonomy_definition(position);
CREATE INDEX match_id_idx ON taxonomy_definition(match_id);

#10thFeb 2016
#creating single license for resource instead of multiple
alter table resource add column license_id bigint;
alter table resource add foreign key (license_id) references license(id);
update resource set license_id = g.license_id from (select license_id,resource_licenses_id from resource_license group by resource_licenses_id, license_id) g where g.resource_licenses_id=id;
update resource set license_id=822 where license_id is null;
alter table resource alter column license_id set not null;

#creating single contributor instead of multiple for resource

#11th Feb 2016
alter table recommendation alter column is_scientific_name set not null;
alter table recommendation_vote add column given_sci_name text, add column given_common_name text;
update recommendation_vote set given_sci_name=reco.name from recommendation reco where reco.is_scientific_name='t' and reco.id=recommendation_id;
update recommendation_vote set given_common_name=reco.name from recommendation reco where reco.is_scientific_name='f' and reco.id=common_name_reco_id;


#15 Feb
update recommendation set accepted_name_id = taxon_concept_id;

#run gbifMigration + colReport userscripts before gbifupload

# 22 Feb 2016
alter table observation alter column longitude type double precision;
alter table observation alter column latitude type double precision;

create view reco_vote_details as  SELECT rv.id as reco_vote_id, rv.common_name_reco_id, rv.author_id, rv.voted_on, rv.comment, rv.original_author, rv.given_sci_name, rv.given_common_name, r.id as reco_id, r.name, r.is_scientific_name, r.language_id, t.id as taxon_concept_id, t.canonical_form, t.species_id, o.id as observation_id, o.is_locked, o.max_voted_reco_id FROM recommendation_vote rv inner join recommendation r on rv.recommendation_id=r.id inner join observation o on rv.observation_id=o.id left outer join taxonomy_definition t on t.id = r.taxon_concept_id;

#24 feb 2016
ALTER TABLE recommendation DROP CONSTRAINT recommendation_taxon_concept_id_key; 
ALTER TABLE recommendation ADD CONSTRAINT recommendation_taxon_concept_id_key UNIQUE (taxon_concept_id, accepted_name_id, name, language_id);
 

#3rd march update representative image for species
DROP TABLE IF EXISTS  tmp;
DROP TABLE IF EXISTS  tmp1;
create table tmp as ((select resource_id, species_resources_id, rating_ref, (case when avg is null then 0 else avg end) as avg, (case when count is null then 0 else count end) as count from species_resource o left outer join (select rl.rating_ref, avg(r.stars), count(r.stars) from rating_link rl, rating r where rl.type='resource' and rl.rating_id = r.id  group by rl.rating_ref) c on o.resource_id =  c.rating_ref, resource r where resource_id = r.id  and r.type = 'IMAGE' )
union (select resource_id, sf.species_id as species_resources_id, rating_ref, (case when avg is null then 0 else avg end) as avg, (case when count is null then 0 else count end) as count from species_field sf join species_field_resources o on species_field_id= sf.id left outer join (select rl.rating_ref, avg(r.stars), count(r.stars) from rating_link rl, rating r where rl.type='resource' and rl.rating_id = r.id group by rl.rating_ref) c on o.resource_id = c.rating_ref, resource r where resource_id = r.id and r.type = 'IMAGE' ));
create table tmp1 as select species_resources_id, max(avg) as avg from tmp  x  group by x.species_resources_id order by avg, x.species_resources_id;
update species set repr_image_id = g.resource_id from (select tmp.species_resources_id, tmp.resource_id from tmp, tmp1 where tmp.species_resources_id = tmp1.species_resources_id and tmp.avg = tmp1.avg) g where g.species_resources_id = id;
DROP TABLE IF EXISTS  tmp;
DROP TABLE IF EXISTS  tmp1;

#4thMar datasource and dataset seq
alter table resource alter column access_rights type varchar(2055);

#8 March
update observation set protocol='LIST' where is_checklist = true or (id != source_id);

#16 March
drop view reco_vote_details;
create view reco_vote_details as  SELECT rv.id as reco_vote_id, rv.common_name_reco_id, rv.author_id, rv.voted_on, rv.comment, rv.original_author, rv.given_sci_name, rv.given_common_name, r.id as reco_id, r.name, r.is_scientific_name, r.language_id, t.id as taxon_concept_id, t.normalized_form,t.status, t.species_id, o.id as observation_id, o.is_locked, o.max_voted_reco_id FROM recommendation_vote rv inner join recommendation r on rv.recommendation_id=r.id inner join observation o on rv.observation_id=o.id left outer join taxonomy_definition t on t.id = r.taxon_concept_id;

#20thMar2016
alter table dataset add column attribution text;
update dataset set attribution='';
alter table dataset alter column attribution set  not null;


#6thApr2016
update field set sub_category ='Local Endemicity Geographic Entity' where id=64;
update field set sub_category ='Local Distribution Geographic Entity' where id=61;

#22ndApr2016
alter table doc_sci_name add column primary_name integer not null default 0;
alter table doc_sci_name add column is_deleted boolean not null default 'false';

#02May2016
create view ibp_taxonomy_registry as
with recursive cte as
(   
    select
    *,
    cast(0 as text) as level
    from taxonomy_registry
    where parent_taxon_id is null and classification_id=265799
    union all
    select
    t.*,
    level || '.' || t.parent_taxon_definition_id AS level
    from taxonomy_registry t 
    inner join cte i on i.id = t.parent_taxon_id
    where t.classification_id = 265799
)
select * from cte;

#4th may
#alter table common_names add column is_deleted boolean not null default 'false';
ALTER TABLE common_names DROP constraint common_names_taxon_concept_id_key ;
ALTER TABLE common_names ADD CONSTRAINT common_names_taxon_concept_id_key UNIQUE (taxon_concept_id, language_id, name, is_deleted);

create index on common_names(is_deleted);
create index on taxonomy_definition(is_deleted);


#16th may
alter table species add column is_deleted boolean not null default 'false';
create index on species(is_deleted);


#17 may 
update document set external_url =uri where uri !='';
alter table document drop column uri;

#26 may
ALTER TABLE document ALTER COLUMN latitude TYPE double precision;
ALTER TABLE document ALTER COLUMN longitude TYPE double precision;


alter table common_names add column is_deleted boolean not null default 'false';
alter table synonyms add column is_deleted boolean not null default 'false';


//after running old sql
ALTER TABLE taxonomy_definition DROP CONSTRAINT taxonomy_definition_rank_canonical_form_key;
delete from taxonomy_registry where classification_id = 7;		
alter table activity_feed alter column activity_descrption type varchar(2000);
alter table taxonomy_definition alter column activity_description type varchar(2000);
alter sequence hibernate_sequence restart with 40000;

drop sequence document_id_seq; drop sequence observation_id_seq; drop sequence species_id_seq; drop sequence suser_id_seq;
select max(id) from document; select max(id) from observation; select max(id) from species; select max(id) from suser;
create sequence document_id_seq start 100;
create sequence observation_id_seq start 12000;
create  sequence species_id_seq start 8000; 
create sequence suser_id_seq start 1000;

//after adding bbp hir
update taxonomy_definition set default_hierarchy = g.dh from (select x.lid, json_agg(x) dh from (select s.lid, t.id, t.name, t.canonical_form, t.rank from taxonomy_definition t, (select taxon_definition_id as lid, regexp_split_to_table(path,'_')::integer as tid from taxonomy_registry tr where tr.classification_id = 40000 order by tr.id) s where s.tid=t.id order by lid, t.rank) x group by x.lid) g where g.lid=id;
update taxonomy_definition set position = 'WORKING' where match_id is not null;    
drop view tmp_taxon_concept;
drop view tmp_common_names;

//syning of names

