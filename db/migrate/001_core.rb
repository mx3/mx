class Core < ActiveRecord::Migration
  # as of 2008 do not use tables.sql
  # this is the core set of tables executed, yes we're tied to MySQL until someone parses this out 
  def self.up
  
    execute %{
    CREATE TABLE
      `people` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `last_name` VARCHAR(255) NOT NULL DEFAULT '',
        `first_name` VARCHAR(100) NOT NULL DEFAULT '',
        `middle_name` VARCHAR(100) NOT NULL DEFAULT '',
        `login` VARCHAR(32) DEFAULT NULL,
        `password` VARCHAR(40) DEFAULT NULL,
        `is_admin` BOOLEAN NOT NULL DEFAULT 0,
        `creates_projects` BOOLEAN NOT NULL DEFAULT 0,
        `email` VARCHAR(255), -- a valid e-mail adress

        updated_on TIMESTAMP NOT NULL,
        created_on TIMESTAMP NOT NULL,
        
        PRIMARY KEY (id),
        UNIQUE (last_name, first_name, middle_name),
        UNIQUE (login),
        INDEX login_ind (login),
        INDEX password_ind (password),
        INDEX is_admin_ind (is_admin)
      ) ENGINE=INNODB;
    }
  
    execute %{
    CREATE TABLE 
      `repositories` ( -- space holder for respositories
        `id` INT(11) NOT NULL auto_increment,
        `name` TEXT NOT NULL,
        `codon` VARCHAR(12) DEFAULT NULL, -- coden
        `url` text,
        `synonymous_with_id` INT(11) , 
       
        creator_id INT(11) NOT NULL,
        updator_id INT(11) NOT NULL,
        updated_on TIMESTAMP NOT NULL,
        created_on TIMESTAMP NOT NULL,

        PRIMARY KEY (id),
        UNIQUE(`codon`), -- coden

        INDEX (creator_id),
        INDEX (updator_id),
        INDEX (synonymous_with_id),
          
        FOREIGN KEY (synonymous_with_id) REFERENCES repositories(id),
        FOREIGN KEY (creator_id) REFERENCES people(id),
        FOREIGN KEY (updator_id) REFERENCES people(id)
      ) ENGINE=INNODB;
    }

  ### Projects
  
  execute %{
  CREATE TABLE
    `projs` (
      `id`    INT(11) NOT NULL AUTO_INCREMENT,
      `name`  VARCHAR(255) NOT NULL,

      -- settings
      `hidden_tabs` TEXT,
      `public_server_name` VARCHAR(255),
      `unix_name` VARCHAR(32), -- maps to local folder/controllers, should be unique
      `public_controllers` TEXT,
      `public_tn_criteria` VARCHAR(32),
      `repository_id` INT(11) ,
      `starting_tab` VARCHAR(32) default 'otu', 
      `default_ontology_id` INT(11) , -- maps to another projects public ontology in some places  
      `default_content_template_id` INT(11) , -- the default template to show content for 

      `gmaps_API_key` VARCHAR(90),

      creator_id INT(11) NOT NULL,
      updator_id INT(11) NOT NULL,
      updated_on TIMESTAMP NOT NULL,
      created_on TIMESTAMP NOT NULL,

      PRIMARY KEY (id), 
      INDEX (public_server_name),
      INDEX (repository_id),
      --  added at bottom of file:  default_content_template_id index 
      INDEX (default_ontology_id),
      INDEX (creator_id),
      INDEX (updator_id),
      FOREIGN KEY (repository_id) REFERENCES repositories(id),
      --  added at bottom of file: FOREIGN KEY (default_content_template_id) REFERENCES content_templates(id) 
      FOREIGN KEY (default_ontology_id) REFERENCES projs(id),
      FOREIGN KEY (creator_id) REFERENCES people(id),
      FOREIGN KEY (updator_id) REFERENCES people(id)
  ) ENGINE=INNODB;
  }

  ### Namespaces

  execute %{
CREATE TABLE
`namespaces` (
  `id`  INT(11) NOT NULL AUTO_INCREMENT,
  `name`  VARCHAR(255) NOT NULL,
  `owner` VARCHAR(255), -- who to contact with qustions
  `notes` text DEFAULT NULL,
  `url_access` text, -- when used in combiation with an identifier returns the object in question
  `short_name` VARCHAR(6), -- used in display
  `last_loaded_on` TIMESTAMP,
  
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,
  
  PRIMARY KEY (id), 
  INDEX (creator_id),
  INDEX (updator_id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;

  }

  ### Misc
  
  execute %{
  CREATE TABLE 
  `confidences` (
    `id`      INT(11) NOT NULL auto_increment,
    `name`      VARCHAR(128),
    `position`    INT(11) , -- rails sort code
    `short_name`  VARCHAR(4), -- for display purposes   

    proj_id INT(11) NOT NULL,
    creator_id INT(11) NOT NULL,
    updator_id INT(11) NOT NULL,
    updated_on TIMESTAMP NOT NULL,
    created_on TIMESTAMP NOT NULL,
    
    PRIMARY KEY (id),
    INDEX (proj_id),
    INDEX (creator_id),
    INDEX (updator_id),
    INDEX `position_ind` (`position`),
    INDEX (short_name),
    INDEX `short_name_proj` (`short_name`, `proj_id`), 
    -- UNIQUE (short_name, proj_id), not good for null records

    FOREIGN KEY (proj_id) REFERENCES projs (id),
    FOREIGN KEY (creator_id) REFERENCES people(id),
    FOREIGN KEY (updator_id) REFERENCES people(id)
  ) ENGINE=INNODB;
  }

  execute %{
  CREATE TABLE 
  `languages` ( -- fixed (uneditable), and verbatim from http://www.iana.org/assignments/language-subtag-registry
    `id`      INT(11) NOT NULL auto_increment,
    `ltype`    VARCHAR(128),
    `subtag`  VARCHAR(4),
    `description` VARCHAR(1024), -- when multiple descriptions were included in the table they are concatonated with a comma
    `suppress_script` VARCHAR(256),
    `preferred_value` VARCHAR(4),
    `tag` VARCHAR(64),
    `prfx` VARCHAR(255), -- for prefix, a reserved word?
    `added` DATE,
    `deprecated` DATE,
    `comments` TEXT,

    PRIMARY KEY (id)	
  ) ENGINE=INNODB;
  }

  ### references/serials

  execute %{
CREATE TABLE
`serials` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(1024),
  `city` VARCHAR(255),
  `atTAMU` VARCHAR(12), -- yes, no, not checked, SHOULD BE at_home_institution 
  `notes` TEXT,
  `URL` TEXT,
  `call_num` VARCHAR(255),
  `abbreviation` VARCHAR(255),
  `synonymous_with_id` INT(11) , -- just in case, a serial ID
  `language_id` INT(11) ,  

  `namespace_id` INT(11) DEFAULT NULL,
  `external_id` INT(11) DEFAULT NULL,
 
  `ISSN` VARCHAR(10), 
 
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,
  
  PRIMARY KEY (id),
  INDEX (language_id),
  INDEX namespace_ind (namespace_id),
  INDEX synonymous_with_id (synonymous_with_id),
  INDEX (name(100)),

  UNIQUE (namespace_id, external_id),
  FOREIGN KEY (language_id) REFERENCES languages (id),
  FOREIGN KEY (synonymous_with_id) REFERENCES serials (id),
  FOREIGN KEY (namespace_id) REFERENCES namespaces (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;
    }

  execute %{
CREATE TABLE
`pdfs` ( -- see attachment_fu plugin
  id INT(11) NOT NULL AUTO_INCREMENT,
  parent_id INT(11) ,
  content_type VARCHAR(255),
  filename VARCHAR(1024),
  size INT(11) ,

  PRIMARY KEY (id)
) ENGINE=INNODB;

  }

  execute %{
CREATE TABLE
`refs` (
  id INT(11) NOT NULL AUTO_INCREMENT,
  namespace_id INT(11) DEFAULT NULL,
  external_id   INT(11) DEFAULT NULL,
  serial_id INT(11) DEFAULT NULL,
  valid_ref_id INT(11) DEFAULT NULL, -- for merged duplicate refs
  language_id INT(11) DEFAULT NULL,

  pdf_id INT(11) DEFAULT NULL,

  year SMALLINT ,
  year_letter VARCHAR(255),
  
  ref_type varchar(50),
  title TEXT,
  volume VARCHAR(255),
  issue VARCHAR(255), -- /number/report_number
  pages VARCHAR(255), -- other
  pg_start VARCHAR(8),
  pg_end VARCHAR(8),
  book_title TEXT, -- /conference_name
  city VARCHAR(255), -- /conference_location
  publisher VARCHAR(255),
  institution VARCHAR(255),
  date VARCHAR(255), 
  language_OLD VARCHAR(255), -- DEPRECATED
  notes TEXT,

  `ISBN` VARCHAR(14),
  `DOI` VARCHAR(255),

  is_public BOOLEAN DEFAULT 0, -- allow public display
  pub_med_url text,
  other_url text,

  full_citation TEXT,
  temp_citation TEXT,
  
  display_name varchar(2047), -- the auto-generated citation
  short_citation varchar(255), -- another auto-generated citation, for rendering speed
  
  -- bad fields
  author VARCHAR(255), -- redundant for new records and should ultimately be removed
  journal VARCHAR(255), -- this is redundant with serial_id and should ultimately be removed
  
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,
  
  PRIMARY KEY (id),
  INDEX (language_id),
  INDEX (pdf_id),
  INDEX (namespace_id),
  INDEX author_ind (author),
  INDEX display_name_ind (display_name(10)),
  INDEX year_ind (year),
  INDEX (external_id),
  INDEX (namespace_id),
  INDEX (serial_id),

  UNIQUE (namespace_id, external_id),
  FOREIGN KEY (pdf_id) REFERENCES pdfs(id),
  FOREIGN KEY (language_id) REFERENCES languages(id),
  FOREIGN KEY (serial_id) REFERENCES serials(id),
  FOREIGN KEY (namespace_id) REFERENCES namespaces (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB DEFAULT CHARSET=utf8;

  }

  # -- one-to-many with refs: not fully normalized (authors are duplicated)
  execute %{
CREATE TABLE 
`authors` (
  id INT(11) NOT NULL AUTO_INCREMENT,
  ref_id INT(11) NOT NULL,
  position INT(11) ,
  last_name VARCHAR(255) NOT NULL,
  first_name VARCHAR(255),
  title VARCHAR(255), -- for 'Jr.', 'III' and such
  initials VARCHAR(8),
  auth_is VARCHAR(16) NOT NULL DEFAULT 'author' , -- 'author', 'editor', etc.

  use_initials BOOLEAN, -- ultimately redundant
  name_with_init VARCHAR(255), -- Last Name + Initials, ultimately redundant.

  join_name VARCHAR(255),
 
  namespace_id INT(11) DEFAULT NULL,
  external_id  INT(11) DEFAULT NULL,
  
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (id),
  INDEX (ref_id),
  INDEX (namespace_id),
  FOREIGN KEY (ref_id) REFERENCES refs (id),
  FOREIGN KEY (namespace_id) REFERENCES namespaces (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB DEFAULT CHARSET=utf8;
}

  execute %{
CREATE TABLE 
`projs_refs` (
  proj_id INT(11) NOT NULL,
  ref_id INT(11) NOT NULL,
  UNIQUE (proj_id, ref_id),
  INDEX (proj_id),
  INDEX (ref_id)
) ENGINE=INNODB;

    }


  ### Taxonomy

  execute %{
CREATE TABLE 
`taxon_names` ( -- this is VALID/AVAILABLE ICZN or goverened names
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `author` VARCHAR(128) DEFAULT NULL, -- # this was changed
  `year` VARCHAR(4), -- things like 194? are alowed

  `nominotypical_subgenus` BOOLEAN, -- USED!
  `parent_id` INT(11) DEFAULT NULL,
  `valid_name_id` INT(11) DEFAULT NULL, -- unsure about this implementation

  `namespace_id` INT(11) DEFAULT NULL, -- required if external_id present
  `external_id` INT(11) DEFAULT NULL,
  
  `taxon_name_status_id` INT(11) DEFAULT NULL,
  -- is_nomen_nudum BOOLEAN, -- we can change this if desired (see status)
  
  `l` INT(11) DEFAULT NULL, -- tree fields. 'left' and 'right' are reserved words :(
  `r` INT(11) DEFAULT NULL,

  `orig_genus_id` INT(11) DEFAULT NULL,
  `orig_subgenus_id` INT(11) DEFAULT NULL,
  `orig_species_id` INT(11) DEFAULT NULL,
  
  `iczn_group` VARCHAR(8), -- species, genus, family only
  
  -- DEPRECATED -- see type material table now!
  `type_type` VARCHAR(255), -- holotype/lectotype/syntype/neotype
  `type_count` INT(11) , -- only allowed if status = syntypes
  `type_sex` VARCHAR(255), -- male/female/gynadromorph/undetermined
  `type_repository_id` INT(11) ,
  `type_repository_notes` VARCHAR(255), -- keep here
  `type_geog_id` INT(11) ,
  `type_locality` text,
  -- type_specimen_id INT(11) , -- id of the type specimen
  `type_notes` VARCHAR(255) COMMENT 'e.g. lost, number of males and females, etc',
  `type_taxon_id` INT(11) , -- for genera, families, the type name
  `type_by` VARCHAR(64), -- how did this become a type (monotypy etc.)
  `type_lost` BOOLEAN,

  `ref_id` INT(11) ,
  `page_validated_on` INT,
  `page_first_appearance` INT,
  
  `notes` TEXT,
  `import_notes` TEXT,
  
  `display_name` VARCHAR(255), -- html formatted string built on save or update
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,
  
  PRIMARY KEY (id),
  UNIQUE (namespace_id, external_id),
  INDEX (name),
  INDEX (namespace_id),
  INDEX (external_id),
  INDEX (parent_id),
  INDEX (l),
  INDEX (r),
  INDEX (valid_name_id),
  INDEX (taxon_name_status_id),
  INDEX (type_taxon_id),
  INDEX (ref_id),
  INDEX (creator_id),
  INDEX (updator_id),
  
  FOREIGN KEY (parent_id) REFERENCES taxon_names (id),
  FOREIGN KEY (valid_name_id) REFERENCES taxon_names (id),
  FOREIGN KEY (taxon_name_status_id) REFERENCES taxon_names(id),
  FOREIGN KEY (type_taxon_id) REFERENCES taxon_names(id),
  FOREIGN KEY (namespace_id) REFERENCES namespaces (id),
  FOREIGN KEY (ref_id) REFERENCES refs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;


  }

  execute %{
create table projs_taxon_names( -- defines taxon name visibility for projects 
  `id` INT(11) NOT NULL AUTO_INCREMENT, -- apparently needed for :through's with attributes now
  `proj_id` INT(11) NOT NULL,
  `taxon_name_id` INT(11) NOT NULL, -- don't allow subnodes (<>) of those already present
  `is_public` BOOLEAN NOT NULL DEFAULT 0,

  PRIMARY KEY(id),
  INDEX (proj_id),
  INDEX (taxon_name_id),
  INDEX (proj_id,taxon_name_id),

  FOREIGN KEY (proj_id) REFERENCES projs(id),
  FOREIGN KEY (taxon_name_id) REFERENCES taxon_names(id)
) ENGINE=INNODB;

  }

  execute %{
create table people_taxon_names( -- defines create/update permissions for people
  person_id INT(11) NOT NULL,
  taxon_name_id INT(11) NOT NULL,  -- don't allow subnodes (<>) of those already present

  PRIMARY KEY(person_id, taxon_name_id),
  FOREIGN KEY (person_id) REFERENCES people(id),
  FOREIGN KEY (taxon_name_id) REFERENCES taxon_names(id)
) ENGINE=INNODB;
  }

  execute %{

CREATE TABLE -- types of synonymy
`taxon_name_status` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `status` VARCHAR(128),
  
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,
  
  PRIMARY KEY (`id`),
  UNIQUE (`status`),
  INDEX (creator_id),
  INDEX (updator_id),

  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
  
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE
`taxon_hists` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `taxon_name_id` INT(11) NOT NULL,

  `higher_id` INT(11) , -- use this
  -- OR 
  `genus_id` INT(11) , -- these (not both)
  `subgenus_id` INT(11) ,
  `species_id` INT(11) ,
  `subspecies_id` INT(11) ,
  `author` VARCHAR(255),
  `year` VARCHAR(6),

  `varietal_id` INT(11) ,
  `varietal_usage` VARCHAR(24),

  `ref_id` INT(11) ,
  `ref_page` VARCHAR(64),
  `taxon_name_status_id` INT(11) ,
  `notes` TEXT,

  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,
  
  PRIMARY KEY (id),
  INDEX (higher_id),
  INDEX (taxon_name_id),
  INDEX (genus_id),
  INDEX (subgenus_id),
  INDEX (species_id),
  INDEX (subspecies_id),
  INDEX (varietal_id),
  INDEX (ref_id),
  INDEX (taxon_name_status_id),
  INDEX (creator_id),
  INDEX (updator_id),
  INDEX (taxon_name_id),

  FOREIGN KEY (taxon_name_id) REFERENCES taxon_names(id),
  FOREIGN KEY (higher_id) REFERENCES taxon_names(id),
  FOREIGN KEY (genus_id) REFERENCES taxon_names(id),
  FOREIGN KEY (subgenus_id) REFERENCES taxon_names(id),
  FOREIGN KEY (species_id) REFERENCES taxon_names(id),
  FOREIGN KEY (subspecies_id) REFERENCES taxon_names(id),
  FOREIGN KEY (varietal_id) REFERENCES taxon_names(id),
  FOREIGN KEY (ref_id) REFERENCES refs(id),
  FOREIGN KEY (taxon_name_status_id) REFERENCES taxon_name_status(id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;

  }

  
  ### OTUs
  
  execute %{
CREATE TABLE
`otus` (
  `id`          INT(11) NOT NULL AUTO_INCREMENT,
  `taxon_name_id`   INT(11) DEFAULT NULL,
  `is_child`      BOOLEAN DEFAULT 0, -- determines whether the taxon_name_id represents the immediate parent or the actual OTU
  `name`        VARCHAR(255),
  `manuscript_name`   VARCHAR(255),
  `matrix_name`     VARCHAR(64)           COMMENT 'when present overrides name for matrix output',
  `parent_otu_id`   INT(11) DEFAULT NULL,
  `as_cited_in`     INT(11) DEFAULT NULL, -- should only refer to names mentioned but not available
  `revision_history`  TEXT,
  `iczn_group`      VARCHAR(32),
  `syn_with_otu_id` INT(11) DEFAULT NULL COMMENT 'references another OTU',
  `sensu`       VARCHAR(255), -- an unpublished concept from this person
  `notes` TEXT, -- begrudgingly added- CONS should be used instead

  -- display_name TEXT, -- html formatted string built on save or update
  proj_id     INT(11) NOT NULL,
  creator_id  INT(11) NOT NULL,  -- needs to be 
  updator_id  INT(11) NOT NULL,
  updated_on  TIMESTAMP NOT NULL,
  created_on  TIMESTAMP NOT NULL,

  PRIMARY KEY (id),
  INDEX taxon_name_id_ind (taxon_name_id),
  INDEX as_cited_in_ind (as_cited_in),
  INDEX (syn_with_otu_id),
  -- INDEX sensu_ref_id_ind (sensu_ref_id),
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),
    
-- temporary to free up taxon_names table 
--  FOREIGN KEY (taxon_name_id) REFERENCES taxon_names(id),
  FOREIGN KEY (as_cited_in) REFERENCES refs(id),
  FOREIGN KEY (syn_with_otu_id) REFERENCES otus(id),
  -- FOREIGN KEY (sensu_ref_id) REFERENCES refs(id),
  FOREIGN KEY (proj_id) REFERENCES projs(id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE
`otu_groups` (
  `id`  INT(11) NOT NULL AUTO_INCREMENT,
  `name`      VARCHAR(64),
  `is_public` BOOLEAN,

  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (id), 
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),
  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE
`otu_groups_otus` (
  `otu_group_id`  INT(11) NOT NULL,
  `otu_id`    INT(11) NOT NULL,
  `position`    INT(11) , -- sort code

  PRIMARY KEY (`otu_group_id`, `otu_id`),

  INDEX `otu_group_id_ind` (`otu_group_id`),
  INDEX `otu_id_ind` (`otu_id`),
  FOREIGN KEY (`otu_id`) REFERENCES `otus`(`id`),
  FOREIGN KEY (`otu_group_id`) REFERENCES `otu_groups`(`id`)
) ENGINE=INNODB;

  }


  ### Collect Events, Geography etc.


  execute %{
CREATE TABLE -- PROJECT FREE, USGS based
`geog_types` ( 
  `id` INT(11) NOT NULL auto_increment,
  `name` VARCHAR(255),
  `feature_class` INT(11) , -- don't know what this is (USGS)

  PRIMARY KEY (id)
) ENGINE=INNODB;

  }

  execute %{
CREATE TABLE
`geogs` (
  `id` INT(11) NOT NULL auto_increment,
  `name` VARCHAR(255) NOT NULL,
  `abbreviation` VARCHAR(64),
  -- `proj_id` INT(11) NOT NULL,
  `fips_code` INT(11) DEFAULT NULL,
  `sort_NS` INT(11) DEFAULT NULL,
  `sort_WE` INT(11) DEFAULT NULL,
  `center_lat` VARCHAR (64), 
  `center_long` VARCHAR (64),

  `geog_type_id` INT(11) DEFAULT NULL, 
  -- these are all refs to a geog
  `inclusive_biogeo_region_id` INT(11) DEFAULT NULL,
  `country_id` INT(11) DEFAULT NULL,
  `state_id` INT(11) DEFAULT NULL,
  `county_id` INT(11) DEFAULT NULL,
  `continent_ocean_id` INT(11) DEFAULT NULL,

  `namespace_id` INT(11) ,
  `external_id`  INT(11) ,

  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (`id`),
  UNIQUE (namespace_id, external_id),
  -- INDEX `proj_id_ind` (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),
  INDEX (name(8)),
  INDEX `namespace_id_ind` (`namespace_id`),
  INDEX `geog_type_id_ind` (`geog_type_id`),
  INDEX `inclusive_biogeo_region_id_ind` (`inclusive_biogeo_region_id`),
  INDEX `country_id_ind` (`country_id`),
  INDEX `state_id_ind` (`state_id`),
  INDEX `county_id_ind` (`county_id`),
  INDEX `continent_ocean_id_ind` (`continent_ocean_id`),
  
  -- FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (`namespace_id`) REFERENCES `namespaces`(id),FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id),
  FOREIGN KEY (`geog_type_id`) REFERENCES `geog_types`(`id`),
  FOREIGN KEY (`inclusive_biogeo_region_id`) REFERENCES `geogs`(`id`),
  FOREIGN KEY (`country_id`) REFERENCES `geogs`(`id`),
  FOREIGN KEY (`state_id`) REFERENCES `geogs`(`id`),
  FOREIGN KEY (`county_id`) REFERENCES `geogs`(`id`),
  FOREIGN KEY (`continent_ocean_id`) REFERENCES `geogs`(`id`)
)  ENGINE=INNODB;
  }


  execute %{
create table 
distributions (
  id INT(11) NOT NULL auto_increment,
  geog_id INT(11) ,
  otu_id INT(11) ,
  ref_id INT(11) ,
  confidence_id INT(11) ,
  verbatim_geog VARCHAR(255),
  introduced BOOLEAN,
  num_specimens INT(11) NOT NULL, -- for ARC collection records
  notes TEXT,

  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,
  
  PRIMARY KEY (id),
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),
  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
)  ENGINE=INNODB;

  }

  execute %{
CREATE TABLE 
`ces` ( -- collecting events
  `id` INT(11) NOT NULL auto_increment,
  `proj_id` INT(11) NOT NULL,
  `namespace_id` INT(11) ,
  `external_id`  INT(11) DEFAULT NULL,

  `label` text, -- PRINT/VERBATIM
  `num_to_print` INT(11) ,
  `collectors` text,
  `locality` text,
  `geography` text,
  `geog_id` INT(11) DEFAULT NULL, -- closest geographical unit

  `mthd` VARCHAR(255), -- method (which is protect) could be dropdown ultimately

  -- these are set to hold roman numerals in month as well, as per entomologists zaniness
  `sd_d` VARCHAR(2),
  `sd_m` VARCHAR(4), -- 4!
  `sd_y` VARCHAR(4), 
  `ed_d` VARCHAR(2),
  `ed_m` VARCHAR(4), -- 4!
  `ed_y` VARCHAR(4),
  
  `latitude` double,
  `longitude` double,
  `lat_lon_error_m` INT(11) comment 'error in meters',
  `elev_min` double,
  `elev_max` double,
  `elev_unit` VARCHAR(6), -- ENUM("meters", "feet"),
  `label_lat` VARCHAR(48), -- lat long label
  `label_lon` VARCHAR(48),
  
  `undet_ll` BOOLEAN NOT NULL DEFAULT 0 comment 'the label does not have a ll determinable beyond county level',

  `notes`     text,

  `trip_code` VARCHAR(255),
  `trip_namespace_id` INT(11) DEFAULT NULL, -- person responsible for trip_code
  `doc_label` text comment 'an expanded version of the label for use in docuements/publications',
  `verbatim_method` VARCHAR(255),
  `host_genus` varchar(255),
  `host_species` varchar(255),

  -- error checking
  `err_label`   BOOLEAN NOT NULL DEFAULT 0 comment 'there is an error written on the label',
  `err_entry`   BOOLEAN NOT NULL DEFAULT 0 comment 'there is an error in the field due to incorrect data entry',
  `err_checked` BOOLEAN NOT NULL DEFAULT 0 comment 'this label has been checked for errors, CElabel is verbatim label when checked',
  `undetgeog`   BOOLEAN NOT NULL DEFAULT 0 comment 'the label does not contain a determinable geog',

  `updated_on`  TIMESTAMP NOT NULL,
  `created_on`  TIMESTAMP NOT NULL,
  `creator_id`  INT(11) NOT NULL,
  `updator_id`  INT(11) NOT NULL,

  PRIMARY KEY (`id`),
  INDEX `creator_id_ind` (`creator_id`),
  INDEX `updator_id_ind` (`updator_id`),
  INDEX `geog_id_ind` (`geog_id`),
  INDEX `proj_id_ind` (`proj_id`),

  INDEX `trip_namespace_id_ind` (`trip_namespace_id`),
  INDEX `namespace_id_ind` (`namespace_id`),
  
  FOREIGN KEY (`namespace_id`) REFERENCES `namespaces`(id),
  FOREIGN KEY (`trip_namespace_id`) REFERENCES `namespaces`(id),
  FOREIGN KEY (`geog_id`) REFERENCES `geogs`(`id`),
  FOREIGN KEY (`proj_id`) REFERENCES projs(`id`),
  FOREIGN KEY (`updator_id`) REFERENCES `people`(`id`),
  FOREIGN KEY (`creator_id`) REFERENCES `people`(`id`)  
) ENGINE=INNODB;

 
  }


  ### Content

  execute %{
CREATE TABLE 
`content_types` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,

	`sti_type` VARCHAR(255),  -- RAILS STI
  `is_public` BOOLEAN DEFAULT FALSE,

	-- for custom/text
	`name` VARCHAR(255),
  `can_markup` BOOLEAN DEFAULT TRUE,  

  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (id),
  UNIQUE (name, proj_id),
  
  INDEX name_ind (name), 
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),
  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;
  }


  execute %{
CREATE TABLE 
`content_templates` (
  `id` INT(11) NOT NULL auto_increment,
  `name` VARCHAR(255) NOT NULL,
  `is_default` BOOLEAN NOT NULL DEFAULT '0',
  `is_public` BOOLEAN NOT NULL DEFAULT FALSE,

  `proj_id` INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (id),
  UNIQUE(name, proj_id),
  
  INDEX proj_id_ind (proj_id),
  INDEX name_ind (name),
  INDEX creator_id_ind (creator_id),
  INDEX updator_id_ind (updator_id),
  
  FOREIGN KEY (proj_id) references projs (id),
  FOREIGN KEY (creator_id) references people (id)   
) ENGINE=INNODB;

  }


  execute %{
CREATE TABLE
`contents` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `otu_id` INT(11) ,
  `content_type_id` INT(11) ,
  `text` TEXT,
  `is_public` BOOLEAN NOT NULL DEFAULT TRUE, -- refers to the publishable property, not whether it actually is public

  -- STI (sortof) for public_contents
  `pub_content_id` INT(11) , -- indicates the original text
  `revision` INT(11) ,

  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (id), 
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),
  INDEX otu_id_ind (otu_id),
  INDEX content_type_id_ind (content_type_id),
  INDEX pub_content_id_ind (pub_content_id),

  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id),
  FOREIGN KEY (`otu_id`) REFERENCES `otus` (`id`),
  FOREIGN KEY (`pub_content_id`) REFERENCES `contents` (`id`)

) ENGINE=INNODB DEFAULT CHARSET=utf8;

  }

  ### Statements !! NOT USED !!
  
  execute %{
CREATE TABLE
`statements` (
  `id`          INT(11) NOT NULL AUTO_INCREMENT,
  `as_cited_in`     INT(11) ,
  `content_id`      INT(11) ,
  `attributed_to`     INT(11)    COMMENT 'who made this statement (if not cited)?',
  `pages`         VARCHAR (64),
  `figures`       VARCHAR (64),
  `revision_history`    TEXT,
  `temp_citation`     TEXT,

  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,
  
  PRIMARY KEY (id), 
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),
  INDEX `as_cited_in_ind` (`as_cited_in`),
  INDEX `content_id_ind` (`content_id`),
  INDEX `attributed_to_ind` (`attributed_to`),

  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id),
  FOREIGN KEY (`as_cited_in`) REFERENCES `refs`(`id`),
  FOREIGN KEY (`content_id`) REFERENCES `contents`(`id`),
  FOREIGN KEY (`attributed_to`) REFERENCES `people`(`id`)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE
`otus_statements` (
  `otu_id`        INT(11) NOT NULL,
  `statement_id`    INT(11) NOT NULL,
  `qualifier`     VARCHAR(255),
  
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,
    
  PRIMARY KEY (`otu_id`, `statement_id`),
  INDEX (creator_id),
  INDEX (updator_id),
  INDEX `creator_id_ind` (`creator_id`),
  INDEX `statement_id_ind` (`statement_id`),  
  INDEX `otu_id_ind` (`otu_id`),  

  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id),
  FOREIGN KEY (`statement_id`) REFERENCES `statements`(`id`),
  FOREIGN KEY (`otu_id`) REFERENCES `otus`(`id`)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE
`hhs` (
  `id`          INT(11) NOT NULL AUTO_INCREMENT,
  `working_name`    VARCHAR(255),
  `description`   text,
  `revision_history`  TEXT,
  
  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,
  
  PRIMARY KEY (id), 
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),
  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE
`hhs_statements` (
  `hh_id`       INT(11) NOT NULL,
  `statement_id`    INT(11) NOT NULL AUTO_INCREMENT,
  `qualifier`     VARCHAR(64)                 COMMENT 'not implmented yet?',
  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,
  
  PRIMARY KEY (`hh_id`, `statement_id`),
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),
  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id),
  INDEX `statement_id_ind` (`statement_id`),
  FOREIGN KEY (`hh_id`) REFERENCES `hhs`(`id`),
  FOREIGN KEY (`statement_id`) REFERENCES `statements`(`id`)
) ENGINE=INNODB;
  }

  ### Matrices
  
  execute %{
CREATE TABLE
`mxes` (
  `id`          INT(11) NOT NULL AUTO_INCREMENT,
  `name`          VARCHAR(255),
  `revision_history`  TEXT, -- not implmemented
  `notes` TEXT,
  `web_description` TEXT,

  `is_multikey` boolean default 0,
  `is_public` boolean default 0, 

  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (id), 
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),
  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;
  }
  

  execute %{
CREATE TABLE
`chrs` (
  `id`    INT(11) NOT NULL AUTO_INCREMENT,
  `name`        VARCHAR(255) NOT NULL,
  `cited_in`      INT(11) , -- ref_id
  `cited_page`    VARCHAR(64),
  `cited_char_no`   VARCHAR(4),
  `revision_history`  TEXT     COMMENT 'as in notes field for image records', -- not implemented
  `syn_with`      INT(11) COMMENT 'points to a chrs.id',
  `doc_char_code`   VARCHAR(4)   COMMENT 'character code (generally number in cited work), or number to use in manuscript if uncited)',
  `doc_char_descr`  TEXT     COMMENT 'textual description in citation, or to be used in citation if uncited',     
  `short_name`    VARCHAR(6),
  `notes`       TEXT,
  `continuous`    BOOLEAN DEFAULT 0,
  `ordered`    BOOLEAN DEFAULT 0,
  `position` INT(11) , 

  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (id), 
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),
  INDEX `cited_in_ind` (`cited_in`),
  INDEX `syn_with_ind` (`syn_with`),

  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id),
  FOREIGN KEY (`cited_in`) REFERENCES `refs`(`id`),
  FOREIGN KEY (`syn_with`) REFERENCES `chrs`(`id`)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE
`chr_states` (
  `id`        INT(11) NOT NULL AUTO_INCREMENT,
  `chr_id`      INT(11) NOT NULL, 
  `state`       VARCHAR(8) NOT NULL, 
  `name`        VARCHAR(255),
  `cited_polarity`  VARCHAR(15) DEFAULT "none", -- ENUM("none", "plesiomorphic", "apomorphic", "ambiguous") 
  `hh_id`       INT(11) ,
  `revision_history`  TEXT, 
  `notes`       TEXT,
  
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (`id`), 
  UNIQUE KEY `id_state` (chr_id, state),
  INDEX (id, state, name), -- for codings table FK
  INDEX (state),
  INDEX (name),
  INDEX `chr_id_ind` (`chr_id`),
  INDEX `state_ind` (`state`),
  INDEX `hh_id_ind` (`hh_id`),
  INDEX (creator_id),
  INDEX (updator_id),
  
  FOREIGN KEY (`chr_id`) REFERENCES `chrs`(`id`),
  FOREIGN KEY (`hh_id`) REFERENCES `hhs`(`id`),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE
`chrs_mxes` (
  `chr_id`    INT(11) NOT NULL,
  `mx_id`     INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (`chr_id`, `mx_id`),
  INDEX `mx_id_ind` (`mx_id`),
  INDEX `chr_id_ind` (`chr_id`),
  INDEX (creator_id),
  INDEX (updator_id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id),
  FOREIGN KEY (`mx_id`) REFERENCES `mxes`(`id`),
  FOREIGN KEY (`chr_id`) REFERENCES `chrs`(`id`)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE
`mxes_otus` (
  `foo_id`  INT(11) NOT NULL AUTO_INCREMENT, -- used with position- join is mx_id and otu_id
  `mx_id`   INT(11) NOT NULL,
  `otu_id`  INT(11) NOT NULL,
  `notes`   TEXT,
  `position`  INT(11) ,
  `creator_id` INT(11) NOT NULL,
  `updator_id` INT(11) NOT NULL,
  `updated_on` TIMESTAMP NOT NULL,
  `created_on` TIMESTAMP NOT NULL,

  PRIMARY KEY (`foo_id`), 
  UNIQUE (`mx_id`, `otu_id`),
  INDEX `mx_id_ind` (`mx_id`),
  INDEX `otu_id_ind` (`otu_id`),  
  INDEX (creator_id),
  INDEX (updator_id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id),
  FOREIGN KEY (`mx_id`) REFERENCES `mxes`(`id`),
  FOREIGN KEY (`otu_id`) REFERENCES `otus`(`id`)
) ENGINE=INNODB;
  }
  
  execute %{
CREATE TABLE
`chr_groups` (
  `id`          INT(11) NOT NULL AUTO_INCREMENT,
  `name`        VARCHAR(255),
  `notes`         TEXT,
  `position` INT(11) ,
  `content_type_id`  INT(11) , -- maps for translation of group to content
  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,
  
  PRIMARY KEY (id), 
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),
  INDEX (content_type_id),
  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (content_type_id) REFERENCES content_types (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE
`chr_groups_mxes` (
  `mx_id`       INT(11) NOT NULL,
  `chr_group_id`  INT(11) NOT NULL,

  PRIMARY KEY (`mx_id`, `chr_group_id`),
  INDEX `mx_id_ind` (`mx_id`),
  INDEX `chr_group_id_ind` (`chr_group_id`),
  FOREIGN KEY (`mx_id`) REFERENCES `mxes`(`id`),
  FOREIGN KEY (`chr_group_id`) REFERENCES `chr_groups`(`id`)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE
`chr_groups_chrs` (
  `chr_group_id`    INT(11) NOT NULL,
  `chr_id`      INT(11) NOT NULL,
  `position`      INT(11) ,
 -- creator_id INT(11) NOT NULL,
 -- updator_id INT(11) NOT NULL,
 -- updated_on TIMESTAMP NOT NULL,
 -- created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (`chr_group_id`, `chr_id`),
 -- INDEX (creator_id),
 -- INDEX (updator_id),
  INDEX `chr_group_id_ind` (`chr_group_id`),
  INDEX `chr_id_ind` (`chr_id`),

 -- FOREIGN KEY (creator_id) REFERENCES people(id),
 -- FOREIGN KEY (updator_id) REFERENCES people(id),
  FOREIGN KEY (`chr_group_id`) REFERENCES `chr_groups`(`id`),
  FOREIGN KEY (`chr_id`) REFERENCES `chrs`(`id`)  
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE
`mx_minus_chrs` (
  `chr_id`      INT(11) NOT NULL,
  `mx_id`       INT(11) NOT NULL,

  PRIMARY KEY (`mx_id`, `chr_id`),  
  INDEX `chr_id_ind` (`chr_id`),
  INDEX `mx_id_ind` (`mx_id`),
  FOREIGN KEY (`chr_id`) REFERENCES `chrs`(`id`),
  FOREIGN KEY (`mx_id`) REFERENCES `mxes`(`id`)
) ENGINE=INNODB;
  }
  
  execute %{
CREATE TABLE
`mx_chr_sorts` (
  `id`          INT(11) NOT NULL AUTO_INCREMENT,
  `chr_id`      INT(11) NOT NULL,
  `mx_id`       INT(11) NOT NULL,
  `position`    INT(11) , -- allow null for acts_as_list

  PRIMARY KEY (id), 
  UNIQUE (`mx_id`, `chr_id`),  
  INDEX `chr_id_ind` (`chr_id`),
  INDEX `mx_id_ind` (`mx_id`),
  FOREIGN KEY (`chr_id`) REFERENCES `chrs`(`id`),
  FOREIGN KEY (`mx_id`) REFERENCES `mxes`(`id`)
)  ENGINE=INNODB;
  }

  execute %{
CREATE TABLE
`people_projs` (
  `person_id`   INT(11) NOT NULL,
  `proj_id`   INT(11) NOT NULL,
  
  PRIMARY KEY (`person_id`, `proj_id`),
  INDEX `person_id_ind` (`person_id`),
  INDEX `proj_id_ind` (`proj_id`),
  FOREIGN KEY (`person_id`) REFERENCES `people` (`id`),
  FOREIGN KEY (`proj_id`) REFERENCES `projs` (`id`)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE 
`content_templates_content_types` (
  `foo_id` INT(11) NOT NULL auto_increment,
  `content_type_id` INT(11) NOT NULL,
  `content_template_id` INT(11) NOT NULL,
  `position` tinyint ,  -- can't have NOT NULL here for acts as list
  
  PRIMARY KEY (foo_id),
  UNIQUE (content_type_id, content_template_id),
  INDEX content_type_id_ind (content_type_id),
  INDEX content_template_id_ind (content_template_id),
  FOREIGN KEY (content_type_id) references content_types (id),
  FOREIGN KEY (content_template_id) references content_templates (id)
) ENGINE=innodb;
  }
  
  execute %{
CREATE TABLE
`codings` (
  `id`        		INT NOT NULL auto_increment,
  `otu_id`      	INT NOT NULL,
  `chr_id`      	INT NOT NULL,
  `chr_state_id`	INT NOT NULL,
  
	`continuous_state`  REAL, -- if continuous character this is filled in (not implemented)
  `cited_in`    INT(11) , 
  `notes`       TEXT,

  -- non normalized for speed
  `chr_state_state` VARCHAR(8) NOT NULL, 
  `chr_state_name`  VARCHAR(255),

  `qualifier`     TEXT, -- not implemented
  
  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,
  
  PRIMARY KEY (id), -- this is the PK because of rails

  -- this would be the PK if it were normalized (chr_state_id is UNIQUE to a chr), 
  -- and i'm trusting the chrs table to maintain its integrity
  UNIQUE KEY `chr_state_id_otu_id` (chr_state_id, otu_id),  
  
  INDEX `coding_speed` (`otu_id`, `chr_id`, `chr_state_id`),
  INDEX `cited_in_ind` (`cited_in`),
  INDEX `otu_id_ind` (`otu_id`),
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),
  INDEX (chr_id),
  INDEX (chr_state_id),
  INDEX (chr_state_id, chr_state_state, chr_state_name),
  
  FOREIGN KEY (proj_id) REFERENCES projs(id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id),
  FOREIGN KEY (chr_id) REFERENCES chrs(id),
  
  -- non normalized for speed
  FOREIGN KEY (chr_state_id, chr_state_state, chr_state_name) 
  REFERENCES chr_states(id, state, name) ON UPDATE CASCADE ON DELETE RESTRICT,
    
  FOREIGN KEY (`cited_in`) REFERENCES `refs`(`id`),
  FOREIGN KEY (`otu_id`) REFERENCES `otus`(`id`)
) ENGINE=INNODB;
  }

  ### Specimens, Lots, DNA related

  execute %{
CREATE TABLE 
`lots` ( 
  `id`        INT(11) NOT NULL AUTO_INCREMENT,
  `otu_id`      INT(11) NOT NULL, -- require this (its the point of an OTU based system)
  `key_specimens`   INT(11) NOT NULL DEFAULT 0,
  `value_specimens` INT(11) NOT NULL DEFAULT 0,
  `ce_id`       INT(11) DEFAULT NULL,
  `ce_labels`     TEXT    COMMENT 'ultimately a ce_id, presently stores verbatim collecting event labels',
  `rarity`      VARCHAR(16)  COMMENT '0-10 or whatever scale you want',
  `source_quality`  VARCHAR(16)  COMMENT 'place to note the possible quality of the sample',
  `single_specimen` BOOLEAN NOT NULL DEFAULT 0,
  `dnd`       BOOLEAN NOT NULL DEFAULT 0  COMMENT 'do not destroy flag',
  `notes`       TEXT,
  `repository_id` INT(11) DEFAULT NULL,
  `dna_usable`    BOOLEAN DEFAULT 1 comment 'the value specimens can be used for sequencing',
  `determination_unsure`    BOOLEAN DEFAULT 0 comment 'not confident in the identification',
  `mixed_lot`   BOOLEAN DEFAULT 0 comment 'more than 1 species',
  `sex` varchar(64), -- mayhaps moved to biological chars

  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (id),
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id), 
  INDEX `repository_id_ind` (`repository_id`),
  INDEX `otu_id_ind` (`otu_id`),

  FOREIGN KEY (`repository_id`) REFERENCES `repositories`(`id`),
  FOREIGN KEY (`otu_id`) REFERENCES `otus`(`id`), 
  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)

) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE 
`lot_groups` ( -- this will alias to Loans (in out as well)
  `id` INT(11) NOT NULL auto_increment,
  `name` VARCHAR(255) NOT NULL,
  `notes` TEXT,

  `is_loan` BOOLEAN NOT NULL DEFAULT 0,
  `outgoing_loan` BOOLEAN NOT NULL DEFAULT 0,
  `incoming_transaction_code` VARCHAR(255), -- given by external agency, = id for outgoing id 
  `repository_id` INT(11) , -- the place the loan came from 
  `material_requested` TEXT,
  `date_requested` DATE,
  `date_recieved` DATE,
  `total_specimens_recieved` INT(11) , -- perhaps ultimately calculated from lots
  `loan_start_date` DATE,
  `loan_end_date` DATE,
  `specimens_returned_date` DATE,
  `loan_closed` BOOLEAN NOT NULL DEFAULT 0,
  `contact_name` VARCHAR(255),
  `contact_email` VARCHAR(255),
  `policy_page_url` VARCHAR(255),
  `loan_notes` TEXT,
  
  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (id),
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),
  INDEX (repository_id),
  
  FOREIGN KEY (repository_id) REFERENCES repositories (id),
  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
)ENGINE=INNODB;
  }

  execute %{
CREATE TABLE 
`lot_groups_lots` (
  `lot_id` INT(11) NOT NULL,
  `lot_group_id` INT(11) NOT NULL NOT NULL,
  `notes` TEXT,
  PRIMARY KEY (lot_id, lot_group_id),
  INDEX (lot_id),
  INDEX (lot_group_id),
  FOREIGN KEY (lot_id) REFERENCES lots (id),
  FOREIGN KEY (lot_group_id) REFERENCES lot_groups(id)
)ENGINE=INNODB;
  }
  
  execute %{
CREATE TABLE 
`lot_identifiers` (
  `id` INT(11) NOT NULL auto_increment,
  `lot_id`    INT(11) NOT NULL,
  `identifier`  VARCHAR(64),
  `namespace_id`  INT(11) NOT NULL,
    
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (id),
  UNIQUE (`lot_id`, `identifier`), 
  INDEX (creator_id),
  INDEX (updator_id),
  INDEX `lot_id_ind` (`lot_id`),
  INDEX `namespace_id_ind` (`namespace_id`),

  FOREIGN KEY (`namespace_id`) REFERENCES `namespaces`(`id`),
  FOREIGN KEY (`lot_id`) REFERENCES `lots`(`id`),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;
  }
  
  execute %{
CREATE TABLE 
`specimens` (
  `id` INT(11) NOT NULL auto_increment,
  `ce_id` INT(11) DEFAULT NULL,
  `temp_ce` TEXT,
  `parent_specimen_id` INT(11) DEFAULT NULL,
  `repository_id` INT(11) DEFAULT NULL,
  `dna_usable` BOOLEAN DEFAULT 0, -- this might go better in a biological attributes area
  `notes`   text,
  
  `sex`   varchar(64), -- mayhaps moved to biological chars
  `stage`   varchar(64), -- mayhaps moved to biological chars
  `lost` BOOLEAN DEFAULT 0, -- specimen is lost?

  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (id),
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),
  INDEX `repository_id_ind` (`repository_id`),
  INDEX `parent_specimen_id_ind` (`parent_specimen_id`),
  INDEX `ce_id_ind` (`ce_id`),

  FOREIGN KEY (proj_id) REFERENCES projs (id), 
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id),
  FOREIGN KEY (`repository_id`) REFERENCES `repositories`(`id`),
  FOREIGN KEY (`parent_specimen_id`) REFERENCES `specimens`(`id`),
  FOREIGN KEY (`ce_id`) REFERENCES `ces`(`id`)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE 
`type_specimens` (
  `id` INT(11) NOT NULL auto_increment,
  `specimen_id` INT(11) NOT NULL,
  `taxon_name_id` INT(11) NOT NULL,
  `type_type` VARCHAR(24),
	`notes` TEXT, 

  PRIMARY KEY (id),
  INDEX (specimen_id),
  INDEX (taxon_name_id),
  UNIQUE (specimen_id, taxon_name_id),

  FOREIGN KEY (taxon_name_id) REFERENCES taxon_names(id),
  FOREIGN KEY (specimen_id) REFERENCES specimens(id)
) ENGINE=INNODB DEFAULT CHARSET=utf8;
  }

  execute %{
CREATE TABLE 
`specimen_identifiers` (
  `id`      INT(11) NOT NULL auto_increment,
  `specimen_id` INT(11) NOT NULL,
  `identifier`  VARCHAR(64) NOT NULL,
  `namespace_id`  INT(11) NOT NULL  COMMENT 'filled if identifier comes from an alternate source',

  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,
  
  PRIMARY KEY (id),
  UNIQUE (`identifier`,`specimen_id`, `namespace_id`),
  INDEX (creator_id),
  INDEX (updator_id),
  INDEX `namespace_ind` (`namespace_id`),
  INDEX `specimen_id_ind` (`specimen_id`),
  
  FOREIGN KEY (`namespace_id`) REFERENCES `namespaces`(`id`),
  FOREIGN KEY (`specimen_id`) REFERENCES `specimens`(`id`),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE 
`specimen_determinations` (
  `id`      INT(11) NOT NULL auto_increment,
  `specimen_id` INT(11) DEFAULT NULL,
  `otu_id`    INT(11) DEFAULT NULL,
  `current_det` BOOLEAN DEFAULT 1, -- ## needs application validation
  `determiner`  VARCHAR (255),
  `name`      VARCHAR (255), -- either otu or name, otu takes precidence
  `det_year`      VARCHAR (4) DEFAULT NULL,
  `confidence_id` INT(11) , 
  `determination_basis` VARCHAR(255),

  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,
  
  PRIMARY KEY (`id`),
  INDEX (creator_id),
  INDEX (updator_id),
  -- UNIQUE (`specimen_id`, `otu_id`, `determiner`), these two are not ok together, permanently removed
  -- UNIQUE (`specimen_id`, `name`, `determiner`),
  INDEX `specimen_id_ind` (`specimen_id`),
  INDEX `otu_id_ind` (`otu_id`),
  INDEX `confidence_id_ind` (`confidence_id`),
  
  FOREIGN KEY (`confidence_id`) REFERENCES `confidences`(`id`),
  FOREIGN KEY (`specimen_id`) REFERENCES `specimens`(`id`),
  FOREIGN KEY (`otu_id`) REFERENCES `otus`(`id`),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE
berkeley_mapper_results (
  id         INT(11) NOT NULL auto_increment,
  tabfile    MEDIUMTEXT, -- should be able to hold 16,000 rows with an average of 1000 characters per row
  proj_id    INT(11) NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (id),
  INDEX (proj_id),

  FOREIGN KEY (proj_id) REFERENCES projs (id)
) ENGINE=INNODB;
  }

  ### Parts/Ontology

  execute %{
CREATE TABLE
`parts` ( -- Morphological, also Terms in ontology
  `id` INT(11) NOT NULL auto_increment,  
  `name`  VARCHAR(128) NOT NULL COMMENT 'name of the morphological part',
  `abbrev`  VARCHAR(24) default null,
  `description` TEXT,
  `ref_id`  INT(11)  COMMENT 'a ref_id wherin the name was *originally* proposed',
  `ref_page`  VARCHAR(25)   COMMENT 'page within reference',
  `notes` TEXT,
  `taxon_name_id` INT(11) ,
  `language_id` INT(11) ,

  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (id),
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),
  
  -- UNIQUE (`name`, `taxon_name_id`, `proj_id`), 

  INDEX (`ref_id`),
  INDEX (taxon_name_id),
  INDEX (language_id),
  FOREIGN KEY (taxon_name_id) REFERENCES taxon_names(id),

  FOREIGN KEY (`language_id`) REFERENCES `languages` (`id`),
  FOREIGN KEY (`ref_id`) REFERENCES `refs` (`id`),
  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;
  }

  ### Images

  execute %{
CREATE TABLE
`image_views` ( -- anterior/posterior etc. (global to all projects)
  `id` INT(11) NOT NULL auto_increment,
  `name` VARCHAR(64) NOT NULL,
  
  `updated_on`  TIMESTAMP NOT NULL,
  `created_on`  TIMESTAMP NOT NULL,
  `creator_id`  INT(11) NOT NULL,
  `updator_id`  INT(11) NOT NULL,
  
  PRIMARY KEY (id),
  INDEX (`creator_id`),
  INDEX (`updator_id`),
  FOREIGN KEY (`updator_id`) REFERENCES `people`(`id`),
  FOREIGN KEY (`creator_id`) REFERENCES `people`(`id`)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE
`standard_views` (
  `id` INT(11) NOT NULL auto_increment,
  `name` VARCHAR(64), -- an alternative name if part/view doesn't work
  `part_id` INT(11) NOT NULL,
  `image_view_id` INT(11) NOT NULL, 
  `stage` VARCHAR(32), -- adult, egg, 1st instar larva, 2nd instar larva, 3rd instar larva, 4th instar larva, final instar larva, larva, instar unknown, pupa, pupal exuviae
  `sex` VARCHAR(32),   -- unknown, male, female, gynandromorph

  -- may want to add other qualifiers here! (sex/type/size- any other qualifier)
  
  `notes` TEXT,

  `proj_id` INT(11) NOT NULL,
  `updated_on`  TIMESTAMP NOT NULL,
  `created_on`  TIMESTAMP NOT NULL,
  `creator_id`  INT(11) NOT NULL,
  `updator_id`  INT(11) NOT NULL,
  
  PRIMARY KEY (id), 
  UNIQUE (`name`),
  UNIQUE (`proj_id`, `part_id`, `image_view_id`),
  INDEX (proj_id),
  INDEX (`creator_id`),
  INDEX (`updator_id`),

  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (`updator_id`) REFERENCES `people`(`id`),
  FOREIGN KEY (`creator_id`) REFERENCES `people`(`id`)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE
`standard_view_groups` (
  `id` INT(11) NOT NULL auto_increment,
  `name` VARCHAR(255),
  `notes` TEXT,
  `other_identifier` varchar(32), -- a project code/abreviation for this id

  `proj_id` INT(11) NOT NULL,
  `updated_on`  TIMESTAMP NOT NULL,
  `created_on`  TIMESTAMP NOT NULL,
  `creator_id`  INT(11) NOT NULL,
  `updator_id`  INT(11) NOT NULL,
  
  PRIMARY KEY (id), 
  UNIQUE (`name`),
  INDEX (proj_id),
  INDEX (`creator_id`),
  INDEX (`updator_id`),

  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (`updator_id`) REFERENCES `people`(`id`),
  FOREIGN KEY (`creator_id`) REFERENCES `people`(`id`)
) ENGINE=INNODB;
  }


  execute %{
CREATE TABLE
`standard_view_groups_standard_views` (
  `standard_view_id` INT(11) NOT NULL,
  `standard_view_group_id` INT(11) NOT NULL,
  `proj_id` INT(11) NOT NULL,
  `sort`  INT(11) , -- a rails sorter

  PRIMARY KEY (standard_view_id, standard_view_group_id), 
  UNIQUE (proj_id, standard_view_group_id, standard_view_id),
  INDEX (proj_id),
  INDEX (standard_view_id),
  INDEX (standard_view_group_id),

  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (standard_view_id) REFERENCES standard_views (id),
  FOREIGN KEY (standard_view_group_id) REFERENCES standard_view_groups (id)
) ENGINE=INNODB;
  }

  execute %{
  CREATE TABLE 
`images` (
  `id` INT(11) NOT NULL auto_increment,
  `file_name` VARCHAR(64),
  `file_md5` CHAR(32)              COMMENT 'Stores the md5 checksum of the image file.',
  `file_type` CHAR(4),
  `file_size` INT(11)              COMMENT 'In bytes.',
  `width` MEDIUMINT                COMMENT 'In pixels.',
  `height` MEDIUMINT               COMMENT 'In pixels.',
  `user_file_name` VARCHAR(64)     COMMENT 'The name the file had when the user uploaded it.',
  `taken_on_year` smallint default null COMMENT 'Date the original image was taken. If only the year is known, that is ok.',
  `taken_on_month` tinyint default null COMMENT 'Date the original image was taken. If only the year is known, that is ok.',
  `taken_on_day` tinyint default null COMMENT 'Date the original image was taken. If only the year is known, that is ok.',
  `owner` VARCHAR(255)          COMMENT 'i.e. the copyright holder.',

  -- color space?

  `ref_id` INT(11) ,

  `technique` varchar(12), -- brightfield, SEM COMMENT 'Create a table of allowable types instead?',
  -- tied to protocol ??
  
  -- Morphbank subclass
  `mb_id` INT(11) , -- replaces both previous columns

  `notes`  TEXT  COMMENT 'On backend, add date and user to each comment- an append-only log file.',
  
  `updated_on` TIMESTAMP NOT NULL,
  `created_on` TIMESTAMP NOT NULL,
  `creator_id` INT(11) NOT NULL,
  `updator_id` INT(11) NOT NULL,
  
  `proj_id` INT(11) NOT NULL,
  
  PRIMARY KEY (`id`),
  INDEX (ref_id),
  INDEX (proj_id),
  INDEX (`creator_id`),
  INDEX (`updator_id`),
  FOREIGN KEY (`ref_id`) REFERENCES `refs`(`id`),
  FOREIGN KEY (`updator_id`) REFERENCES `people`(`id`),
  FOREIGN KEY (`creator_id`) REFERENCES `people`(`id`),
  FOREIGN KEY (proj_id) REFERENCES projs (id)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE
`image_descriptions` (
  `id` INT(11) NOT NULL auto_increment,
  `otu_id`  INT(11) NOT NULL,
  `proj_id` INT(11) NOT NULL,
  `image_id`  INT(11) ,
  `image_view_id` INT(11) ,
  `part_id`   INT(11) ,
  `stage` VARCHAR(32), -- adult, egg, 1st instar larva, 2nd instar larva, 3rd instar larva, 4th instar larva, final instar larva, larva, instar unknown, pupa, pupal exuviae
  `sex` VARCHAR(32),   -- unknown, male, female, gynandromorph
  `specimen_id` INT(11) ,
  `svg_txt` TEXT,
  `notes` TEXT,
  `is_public` BOOLEAN NOT NULL DEFAULT FALSE,

  -- tied to protocol ??

  -- image request inheritance
  `priority` varchar(6), -- high, medium, low
  `requestor_id` INT(11) , -- a project member at present, defaults to user
  `contractor_id` INT(11) , -- a project member at present, who the image is to be taken by
  `request_notes` TEXT,
  `status` varchar(64), -- a non-calculated completion status?

  `updated_on`  TIMESTAMP NOT NULL,
  `created_on`  TIMESTAMP NOT NULL,
  `creator_id`  INT(11) NOT NULL,
  `updator_id`  INT(11) NOT NULL,
  
  PRIMARY KEY (`id`),
  -- UNIQUE (image_id, view_id, part_id, otu_id, proj_id),
  INDEX (`otu_id`),
  INDEX (`proj_id`),
  INDEX (`image_id`),
  INDEX (`image_view_id`),
  INDEX (`part_id`),
  INDEX (`specimen_id`),
  
  INDEX (`requestor_id`),
  INDEX (`contractor_id`),

  INDEX (`creator_id`),
  INDEX (`updator_id`),

  FOREIGN KEY (otu_id) references otus(id),
  FOREIGN KEY (proj_id) references projs(id),
  FOREIGN KEY (image_id) references images (id),
  FOREIGN KEY (`image_view_id`) REFERENCES image_views(`id`),
  FOREIGN KEY (`part_id`) REFERENCES parts(`id`),
  FOREIGN KEY (specimen_id) references specimens(id),

  FOREIGN KEY (requestor_id) references  people(id),
  FOREIGN KEY (contractor_id) references  people(id),

  FOREIGN KEY (`updator_id`) REFERENCES `people`(`id`),
  FOREIGN KEY (`creator_id`) REFERENCES `people`(`id`)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE
`measurements` (
  `id`  INT(11) NOT NULL auto_increment,
  `specimen_id` INT(11) NOT NULL,
  `measurement` DOUBLE,
  `standard_view_id` INT(11) NOT NULL,
  `units` varchar(12),
  `conversion_factor` DOUBLE, -- include a conversion factor if your measurement is no in the actual units

  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (id),
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),
  INDEX (specimen_id),
  INDEX (standard_view_id),
  
  FOREIGN KEY (specimen_id) REFERENCES specimens (id),
  FOREIGN KEY (standard_view_id) REFERENCES standard_views (id),
  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
  
) ENGINE=INNODB;

  }

  ### DNA
  
  execute %{
CREATE TABLE 
`protocols` ( -- protocols can be defined and used for each extraction
  `id`  INT(11) NOT NULL auto_increment,
  `kind` VARCHAR(10), --  ENUM ("extraction", "pcr", "clean"),
  `description` text, -- abstract to many table with moveable "steps"

  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (id),
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),

  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE 
`protocol_steps` ( 
  `id` INT(11) NOT NULL auto_increment,
  `protocol_id` INT(11) NOT NULL,
  `description` TEXT,
  `reagent`  VARCHAR(255),
  `reagent_quanitity` VARCHAR(64),
  `step_time` VARCHAR(64),
  `step_order` INT(11) ,    -- rails ordering column
  `step_temp` DOUBLE,
  `step_cycles` INT, 

  PRIMARY KEY (`id`),
  INDEX `protocol_id_ind` (`protocol_id`),

  FOREIGN KEY (`protocol_id`) REFERENCES `protocols`(`id`)
)  ENGINE=INNODB;
  }

  execute %{
CREATE TABLE 
`genes` (
  `id` INT(11) NOT NULL auto_increment,
  `name`  VARCHAR(255),
  `notes` TEXT,
  `position` INT(11) ,    

  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (id),
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),

  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;
  }


  execute %{
CREATE TABLE
`seqs` ( -- used to be gene_attempts
  `id`  INT(11) NOT NULL auto_increment,
  `gene_id` INT(11) NOT NULL,
  `specimen_id` INT(11) DEFAULT NULL, 
  `type_of_voucher` VARCHAR(32),
  `otu_id`  INT(11) NOT NULL,
  `genbank_identifier`  VARCHAR(24),
  `ref_id` INT(11) , -- where the seq was first published
  `consensus_sequence`  TEXT,
  `attempt_complete`  BOOLEAN DEFAULT 0,
  `assigned_to`  VARCHAR(64),  -- refering to a person who will add this sequence
  `notes` TEXT,
  `status` varchar(32), -- to replace attempt complete with multiple options?

  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (id),
  INDEX (specimen_id),
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),
  INDEX `gene_id_ind` (`gene_id`),
  INDEX `out_id_ind` (`otu_id`),

  FOREIGN KEY (`specimen_id`) REFERENCES `specimens`(`id`),
  FOREIGN KEY (`otu_id`) REFERENCES `otus`(`id`),
  FOREIGN KEY (`gene_id`) REFERENCES `genes`(`id`),
  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE -- allows multiple extracts (extraction attempts) from each lot and or specimen (i.e. many parts tried independantly)
`extracts` (
  `id` INT(11) NOT NULL auto_increment,
  `lot_id`  INT(11) , -- ONE
  `specimen_id` INT(11) , -- OR THE OTHER
  `protocol_id` INT(11) DEFAULT NULL,
  `parts_extracted_from`  text,
  `quality` VARCHAR(12), -- failed, ok, poor, good
  `notes` text,
  `extracted_on` date,
  `extracted_by` VARCHAR(128),
  `other_extract_identifier` VARCHAR(128), -- a secondary slot for an alternative extract_id 
  
  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (id),
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),
  INDEX `lot_id_ind` (`lot_id`),
  INDEX `specimen_id_ind` (`specimen_id`),
  INDEX `protocol_id_ind` (`protocol_id`),
  
  FOREIGN KEY (`protocol_id`) REFERENCES `protocols`(`id`), 
  FOREIGN KEY (`specimen_id`) REFERENCES `specimens`(`id`),
  FOREIGN KEY (`lot_id`) REFERENCES `lots`(`id`),
  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;
  }

  execute %{
  CREATE TABLE -- stores UNIQUE primers, load as option -3'5'
`primers` (
  `id`    INT(11) NOT NULL auto_increment,
  `gene_id` INT(11) DEFAULT NULL, -- only if you want to reference it to a specific gene, all primers can be used for all pcrs
  `name`    VARCHAR (64),
  `sequence`  VARCHAR(255),
  `regex`   VARCHAR(255),
  `ref_id`  INT(11) ,
  `protocol_id` INT(11) , -- a recommend protocol to use with this primer
  `notes`   TEXT,
  `designed_by` VARCHAR(255),
 
  `target_otu_id` INT(11) , -- post add, FROM 'BIOCORDER' SCHEMA

  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (id),
  UNIQUE (`sequence`,`gene_id`, `proj_id`),
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),
  INDEX (ref_id),
  INDEX (protocol_id),
  INDEX `gene_id_ind` (`gene_id`),
  INDEX (target_otu_id),
  FOREIGN KEY (`ref_id`) REFERENCES `refs`(`id`),
  FOREIGN KEY (`protocol_id`) REFERENCES `protocols`(`id`),
  FOREIGN KEY (`target_otu_id`) REFERENCES `otus`(`id`),
  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id),
  FOREIGN KEY (`gene_id`) REFERENCES `genes`(`id`)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE 
`gel_images` ( 
  `id`      INT(11) NOT NULL auto_increment,
  `name` VARCHAR(255),
  `file_name` VARCHAR(64) NOT NULL,
  `user_file_name` VARCHAR(255),
  `file_md5` CHAR(32) NOT NULL     COMMENT 'Stores the md5 checksum of the image file.',
  `file_type` CHAR(4),
  `file_size` INT(11)         COMMENT 'In bytes.',
  `width` MEDIUMINT                COMMENT 'In pixels.',
  `height` MEDIUMINT               COMMENT 'In pixels.',
  `notes` TEXT,

  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (id),
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),
  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)  
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE 
`pcrs` ( 
  `id`      INT(11) NOT NULL auto_increment,
  `extract_id`   INT(11) DEFAULT NULL,
  `fwd_primer_id`   INT(11) DEFAULT NULL,
  `rev_primer_id`   INT(11) DEFAULT NULL,
  `protocol_id`   INT(11) DEFAULT NULL,
  `gel_image_id`  INT(11) ,
  `lane` tinyint default null,
  `done_by` VARCHAR(255),
  `result` VARCHAR(24), -- ENUM("succeeded", "failed", "reamplify/merge", "reamplify/redo"),  
  `notes` TEXT,

  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (id),
  index (gel_image_id),
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),
  INDEX `fwd_primer_id_ind` (`fwd_primer_id`),
  INDEX `rev_primer_id_ind` (`rev_primer_id`),
  INDEX `extract_id_ind` (`extract_id`),

  FOREIGN KEY (gel_image_id) REFERENCES gel_images(id),
  FOREIGN KEY (`extract_id`) REFERENCES `extracts`(`id`),
  FOREIGN KEY (`fwd_primer_id`) REFERENCES `primers`(`id`),
  FOREIGN KEY (`rev_primer_id`) REFERENCES `primers`(`id`),
  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)  
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE 
chromatograms ( 
  `id` INT(11) NOT NULL auto_increment,
  `pcr_id`   INT(11) DEFAULT NULL,
  `primer_id`   INT(11) DEFAULT NULL,
  `protocol_id`   INT(11) DEFAULT NULL,
  `done_by` VARCHAR(255),
  `chromatograph_file` VARCHAR(255), 
  `result` VARCHAR(24), -- succeeded failed reamplify/merge reamplify/redo 
  `seq`  text,
  `notes` TEXT,

  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (id),
  INDEX (pcr_id),
  INDEX (primer_id),
  INDEX (protocol_id),
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),

  FOREIGN KEY (pcr_id) REFERENCES pcrs(id),
  FOREIGN KEY (primer_id) REFERENCES primers(id),
  FOREIGN KEY (protocol_id) REFERENCES protocols(id),
  FOREIGN KEY (proj_id) REFERENCES projs(id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)  
) ENGINE=INNODB;
  }
  
  execute %{
CREATE TABLE 
`chromatograms_seqs` ( 
  `chromatogram_id` INT(11) NOT NULL,
  `seq_id` INT(11) NOT NULL,

  PRIMARY KEY (`chromatogram_id`, `seq_id`),
  
  INDEX `chromatogram_id_ind` (`chromatogram_id`),
  INDEX `seq_id_ind` (`seq_id`),
  
  FOREIGN KEY (`chromatogram_id`) REFERENCES `chromatograms`(`id`),
  FOREIGN KEY (`seq_id`) REFERENCES `seqs`(`id`)
) ENGINE=INNODB;
  }


    execute %{
CREATE TABLE 
gene_groups (
  id INT(11) NOT NULL auto_increment,
  `name` VARCHAR(255),
  `notes` text,

  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,
    
  PRIMARY KEY (id),
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),

  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;
    }

  execute %{
CREATE TABLE gene_groups_genes (
  gene_group_id INT(11) NOT NULL,
  gene_id INT(11) NOT NULL,
  sort tinyint ,
  
  FOREIGN KEY (gene_group_id) references gene_groups(id),
  FOREIGN KEY (gene_id) references genes(id)
) ENGINE=INNODB;
  }

  ### Associations/Ontology
  
  execute %{
      CREATE TABLE 
`isas` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `interaction` VARCHAR(255),
  `complement` VARCHAR(255),
  `notes` text,
  `position`    INT(11) , -- rails sort code

  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (id),
  UNIQUE (`interaction`, `complement`),
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),
  INDEX `position_ind` (`position`),
  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE 
`associations` (
  `id`    INT(11) NOT NULL auto_increment,
  `notes`   text,

  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (id),
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),

  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) engine = innodb;
  }

  execute %{
CREATE TABLE association_parts (
  `id`    INT(11) NOT NULL auto_increment,
  `association_id` INT(11) NOT NULL,
  `position` INT(11) NOT NULL,
  `isa_id`  INT(11) DEFAULT NULL,
  `isa_complement` BOOLEAN DEFAULT NULL,  
  `otu_id`  INT(11) NOT NULL,

  PRIMARY KEY (`id`),
  INDEX `association_id_ind` (`association_id`),
  INDEX `position_ind` (`position`),
  INDEX `isa_id_ind` (`isa_id`),
  INDEX `otu_id_ind` (`otu_id`),
  FOREIGN KEY (`association_id`) REFERENCES `associations`(`id`),
  FOREIGN KEY (`isa_id`) REFERENCES `isas`(`id`),
  FOREIGN KEY (`otu_id`) REFERENCES `otus`(`id`)
) ENGINE=INNODB;
  }

  execute %{
  CREATE TABLE 
association_supports (
  `id`        INT(11) NOT NULL auto_increment,
  `association_id`  INT(11) NOT NULL,
  `confidence_id` INT(11) NOT NULL,
  
  `type`  VARCHAR(32), -- for single table inheritence, along with the next 3 columns
  `ref_id`      INT(11) , 
  `voucher_lot_id`  INT(11) , 
  `specimen_id`   INT(11) ,

  `temp_ref` TEXT,     -- might remove

  `temp_ref_mjy_id` INT(11) , -- remove ultimately (not now)
  `setting` VARCHAR(32), -- where this occured (lab/field etc.)
  `notes`   text,
  `negative`        BOOLEAN DEFAULT 0,

  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (`id`),
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),
  INDEX `association_id_ind` (`association_id`),
  INDEX `confidence_id_ind` (`confidence_id`),
  INDEX `negative_ind` (`negative`),

  FOREIGN KEY (`confidence_id`) REFERENCES `confidences`(`id`),
  FOREIGN KEY (`association_id`) REFERENCES `associations`(`id`),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;
  }

  ### Tags/Figures/Keywords

  execute %{
CREATE TABLE
`figures` (
 `id` INT(11) NOT NULL auto_increment,
  `addressable_id` INT(11) , -- using polymorphic associations in rails
  `addressable_type`  varchar(64),  
  `image_id` INT(11) NOT NULL,
  `position` TINYINT ,
  `caption`  TEXT,
  `updated_on`  TIMESTAMP NOT NULL,
  `created_on`  TIMESTAMP NOT NULL,
  `creator_id`  INT(11) NOT NULL,
  `updator_id`  INT(11) NOT NULL,
  `proj_id` INT(11) NOT NULL,
  `morphbank_annotation_id` int(10) default NULL,
  `svg_txt` TEXT,

  PRIMARY KEY (`id`),
  INDEX (`image_id`),
  INDEX (`addressable_type`),
  INDEX (`addressable_id`),
  INDEX (`addressable_id`, `addressable_type`),
  INDEX (`creator_id`),
  INDEX (`updator_id`),
  INDEX (`proj_id`),

  UNIQUE (addressable_id, addressable_type, image_id, proj_id),
  
  FOREIGN KEY (`proj_id`) REFERENCES `projs` (`id`),
  FOREIGN KEY (`image_id`) REFERENCES `images` (`id`) ON DELETE RESTRICT, -- prevent deletion
  FOREIGN KEY (`updator_id`) REFERENCES `people`(`id`),
  FOREIGN KEY (`creator_id`) REFERENCES `people`(`id`)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE 
`keywords` ( -- space holder for collecting events
  `id` INT(11) NOT NULL auto_increment,
  `keyword` VARCHAR(255) NOT NULL,
  `shortform` VARCHAR(6),
  `explanation` TEXT,
  `is_public` BOOLEAN DEFAULT 0, -- export this keyword?
  `html_color` VARCHAR(6), -- hex value for displaying this keyword

  proj_id    INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY (id),
  INDEX (keyword(4)),
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),

  FOREIGN KEY (proj_id) REFERENCES projs(id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE 
`tags` (
  `id` INT(11) NOT NULL auto_increment, -- need this even with polys
  `keyword_id` INT(11) ,
  `addressable_id` INT(11) , -- using polymorphic associations in rails
  `addressable_type`  varchar(64),  
  `notes` TEXT,
  `ref_id` INT(11) ,
  
  pages VARCHAR(255), -- other
  pg_start VARCHAR(8), -- xi etc. are possibilities!
  pg_end VARCHAR(8),
  
  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,
 
  PRIMARY KEY (id),
  UNIQUE (keyword_id, addressable_id, addressable_type, ref_id),
  INDEX (keyword_id),
  INDEX (addressable_id),
  INDEX (addressable_type(4)),
  INDEX (ref_id),
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id)
)  ENGINE=INNODB;
  }

  ### Other

  execute %{
CREATE TABLE
`docs` (
  `id` INT(11) NOT NULL auto_increment,
  `controller_name` varchar(255),
  `body` text,
  `is_help_start` boolean, -- one page should be marked as the 'overview' or 'index' help page
  
  PRIMARY KEY (id),
  unique (is_help_start),
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,
  INDEX (controller_name),
  INDEX (creator_id),
  INDEX (updator_id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE
`news` (
  `id` INT(11) NOT NULL auto_increment,
  `news_type` VARCHAR(255), -- ('news', 'notice', 'warning')
  `body` TEXT,
  `expires_on` DATE,
  `proj_id` INT(11) , -- can be specific to a project
  `title` VARCHAR(255),  
  `is_public` boolean not null default false,

  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL, 
  
  PRIMARY KEY (id),  
  INDEX (creator_id),
  INDEX (updator_id),
  INDEX (proj_id),
  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;
  }

  execute %{
CREATE TABLE
`ontologies` ( -- for technically the relationships in ontologies
  `id` INT(11) NOT NULL auto_increment,
  `part1_id` INT(11) NOT NULL,
  `part2_id` INT(11) NOT NULL,
  `isa_id` INT(11) NOT NULL,
  `notes` TEXT,
  `proj_id` INT(11) NOT NULL,
    `creator_id` INT(11) NOT NULL,
  `updator_id` INT(11) NOT NULL,
    `updated_on` TIMESTAMP NOT NULL,
  `created_on` TIMESTAMP NOT NULL,

  PRIMARY KEY (id),
    UNIQUE (`part1_id`, `part2_id`, `isa_id`),
    INDEX (proj_id),
    INDEX (creator_id),
    INDEX (updator_id),
  INDEX (part1_id),
  INDEX (part2_id),
  INDEX (isa_id),

  FOREIGN KEY (part1_id) REFERENCES parts(id),
  FOREIGN KEY (part2_id) REFERENCES parts(id),
  FOREIGN KEY (isa_id) REFERENCES isas(id),
  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
    FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB;
  }

  ### Keys

  execute %{
  create table
`claves` ( -- well, keys is reserved at some level, and bikeys sounds dumb and dichotomous_keys is too long and not strictly true
  `id` INT(11) NOT NULL auto_increment,
  `parent_id` INT(11) default NULL,
  `otu_id` INT(11) default NULL,
  `couplet_text` TEXT,
  `position` int(3) ,
  `link_out` text, -- provides an alternate URL to display as a terminal link
  `link_out_text` VARCHAR(1024), -- the text to display for the URL above
  `edit_annotation` text,
  `pub_annotation` text,
  `head_annotation` text, -- a description used on head nodes
  `manual_id` varchar(7) default NULL,
  `ref_id` INT(11) default null,
  `l` INT(11) , -- not presently used
  `r` INT(11) , -- not presently used
  `is_public` BOOLEAN NOT NULL DEFAULT FALSE,
  `redirect_id` INT(11) default NULL,
  
  proj_id INT(11) NOT NULL,
  creator_id INT(11) NOT NULL,
  updator_id INT(11) NOT NULL,
  updated_on TIMESTAMP NOT NULL,
  created_on TIMESTAMP NOT NULL,

  PRIMARY KEY  (`id`),
  INDEX (redirect_id),
  INDEX (parent_id),
  INDEX (otu_id),
  INDEX (creator_id),
  INDEX (updator_id),
  INDEX (proj_id),
  INDEX (creator_id),
  INDEX (updator_id),
  INDEX (ref_id),
  
  FOREIGN KEY (redirect_id) REFERENCES claves(id),
  FOREIGN KEY (parent_id) REFERENCES claves(id),
  FOREIGN KEY (ref_id) REFERENCES refs(id),
  FOREIGN KEY (otu_id) REFERENCES otus(id),
  FOREIGN KEY (proj_id) REFERENCES projs (id),
  FOREIGN KEY (creator_id) REFERENCES people(id),
  FOREIGN KEY (updator_id) REFERENCES people(id)
) ENGINE=INNODB DEFAULT CHARSET=utf8;
  }

  ### Phylogenetic Trees
  
  execute %{
    CREATE TABLE
    `datasets` ( -- NOT implemented yet unrelated datasets, simply a file manager, attachment_fu plugin
      `id` INT(11) NOT NULL AUTO_INCREMENT,
      `parent_id` INT(11) ,
      `content_type` VARCHAR(255),
      `filename` VARCHAR(1024),
      `size` INT(11) ,

      proj_id INT(11) NOT NULL,
      creator_id INT(11) NOT NULL,
      updator_id INT(11) NOT NULL,
      updated_on TIMESTAMP NOT NULL,
      created_on TIMESTAMP NOT NULL,

      PRIMARY KEY (id),
      INDEX (proj_id),
      INDEX (creator_id),
      INDEX (updator_id),
      
      FOREIGN KEY (proj_id) REFERENCES projs(id),
      FOREIGN KEY (creator_id) REFERENCES people(id),
      FOREIGN KEY (updator_id) REFERENCES people(id)
    ) ENGINE=INNODB;
      }

  execute %{
    create table
    `data_sources` (
     `id` INT(11) NOT NULL auto_increment,
     `name` varchar(255) NOT NULL,
     `mx_id` INT(11) ,
     `dataset_id` INT(11) ,
     `notes` TEXT,
     `ref_id` INT(11) ,
     `proj_id` INT(11) NOT NULL,
     `creator_id` INT(11) NOT NULL,
     `updator_id` INT(11) NOT NULL,
     `updated_on` TIMESTAMP NOT NULL,
     `created_on` TIMESTAMP NOT NULL,

      PRIMARY KEY (id),
      INDEX (ref_id),
      INDEX (proj_id),
      INDEX (creator_id),
      INDEX (updator_id),
      INDEX (mx_id),
      
      FOREIGN KEY (ref_id) REFERENCES refs(id),
      FOREIGN KEY (mx_id) REFERENCES mxes(id),
      FOREIGN KEY (proj_id) REFERENCES projs(id),
      FOREIGN KEY (creator_id) REFERENCES people(id),
      FOREIGN KEY (updator_id) REFERENCES people(id)

    ) ENGINE=INNODB;
      }

  execute %{
    create table
    `trees` (
      `id` INT(11) NOT NULL auto_increment,
      `tree_string` LONGTEXT,
      `name` varchar(255),
      `data_source_id` INT(11) ,
      `notes` TEXT,

      -- some meta data useful in calculations
      `max_depth` INT(11) ,
      
      proj_id    INT(11) NOT NULL,
      creator_id INT(11) NOT NULL,
      updator_id INT(11) NOT NULL,
      updated_on TIMESTAMP NOT NULL,
      created_on TIMESTAMP NOT NULL,

      PRIMARY KEY (id),
      INDEX (proj_id),
      INDEX (creator_id),
      INDEX (updator_id),
      INDEX (data_source_id),

      FOREIGN KEY (data_source_id) REFERENCES data_sources(id),
      FOREIGN KEY (proj_id) REFERENCES projs(id),
      FOREIGN KEY (creator_id) REFERENCES people(id),
      FOREIGN KEY (updator_id) REFERENCES people(id)
    ) ENGINE=INNODB;
      }

  execute %{
    create table
    -- uses better_nested_set
    `tree_nodes` (
      `id` INT(11) NOT NULL auto_increment, -- root node can be null
      `parent_id` INT(11),
      `tree_id` INT(11) NOT NULL, 
      `label` varchar(255),
      `branch_length` double,
      `cumulative_branch_length` double, -- from the root
      `otu_id` INT(11) ,
      `depth` INT(11) , -- counted depth, useful in calcs
     
      `lft` INT(11), -- tree fields. 'left' and 'right' are reserved words :(
      `rgt` INT(11),

      PRIMARY KEY (id),
      INDEX (tree_id),
      INDEX (otu_id),
      INDEX (parent_id),
      INDEX (lft),
      INDEX (rgt),
      INDEX (lft, rgt),

      -- can't foreign key to trees because we use better_nested_set and a 1-many
      FOREIGN KEY (otu_id) REFERENCES otus(id)
    ) ENGINE=INNODB;
      }

  ### Additional foreign keys etc. (preserve order of tables above!!)

  execute %{alter table projs add INDEX (default_content_template_id);}
  execute %{alter table projs add FOREIGN KEY (default_content_template_id) REFERENCES content_templates(id);}
  
  ### Hacks/Kludges from original source, can be removed on fresh installs
  
  execute %{
create table
xyl_hosts (
  id INT(11) NOT NULL auto_increment,
  taxon_name_id INT(11) NOT NULL,
  name varchar(255),
  PRIMARY KEY (id),
  INDEX (taxon_name_id),
  FOREIGN KEY (taxon_name_id) REFERENCES taxon_names(id)
) ENGINE=INNODB;
  }

  execute %{
create table
xyl_syn_errors (
  tax_id INT(11) NOT NULL,
  external_id INT(11) NOT NULL,
  name varchar(255),
  genus varchar(255)
) ENGINE=INNODB;
  }

  ### Other (don't need?)
  
  execute %{COMMIT;}
  execute %{SET AUTOCOMMIT=1;}


  end

  def self.down
   # at this point you should just drop the databases
    drop_table :people
    drop_table :repositories
    drop_table :projs
    drop_table :namespaces
    drop_table :confidences
    drop_table :languages
    drop_table :serials
    drop_table :pdfs
    drop_table :refs
    drop_table :authors
    drop_table :projs_refs
    drop_table :taxon_names
    drop_table :projs_taxon_names
    drop_table :people_taxon_names
    drop_table :taxon_name_status
    drop_table :taxon_hists
    
    drop_table :otus
    drop_table :otu_groups
    drop_table :otu_groups_otus

    drop_table :geog_types
    drop_table :geogs
    drop_table :distributions
    drop_table :ces

    drop_table :content_types
    drop_table :content_templates
    drop_table :contents

    # not used
    drop_table :statements
    drop_table :otus_statements
    drop_table :hhs
    drop_table :hhs_statements
    
    drop_table :mxes
    drop_table :chrs
    drop_table :chr_states
    drop_table :chrs_mxes
    drop_table :mxes_otus
    drop_table :chr_groups
    drop_table :chr_groups_mxes
    drop_table :chr_groups_chrs
    drop_table :mx_chr_sorts
    
    drop_table :people_projs
    drop_table :content_templates_content_types
    drop_table :codings  
  
    drop_table :lots
    drop_table :lot_groups
    drop_table :lot_groups_lots
    drop_table :lot_identifiers
    drop_table :specimens
    drop_table :type_specimens
    drop_table :specimen_identifiers
    drop_table :specimen_determinations
    drop_table :berkeley_mapper_results
    
    drop_table :parts
    drop_table :image_views
    drop_table :standard_views
    drop_table :standard_view_groups
    drop_table :standard_view_groups_standard_views
    drop_table :images
    drop_table :image_descriptions
    drop_table :measurements

    drop_table :protocols
    drop_table :protocol_steps
    drop_table :genes
    drop_table :seqs
    drop_table :extracts
    drop_table :primers
    drop_table :gel_images
    drop_table :pcrs
    drop_table :chromatograms
    drop_table :chromatograms_seqs
    drop_table :gene_groups
    drop_table :gene_groups_genes

    drop_table :isas
    drop_table :associations
    drop_table :association_parts
    drop_table :association_supports
    
    drop_table :figures
    drop_table :keywords
    drop_table :tags

    drop_table :docs
    drop_table :news
    drop_table :ontologies

    drop_table :claves
    drop_table :datasets
    drop_table :data_sources
    drop_table :trees

    drop_table :tree_nodes

    drop_table :xyl_hosts
    drop_table :xyl_syn_errors


  end
end
