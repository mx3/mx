# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20111129035626) do

  create_table "association_parts", :force => true do |t|
    t.integer "association_id",         :null => false
    t.integer "position",               :null => false
    t.integer "object_relationship_id"
    t.boolean "isa_complement"
    t.integer "otu_id",                 :null => false
  end

  add_index "association_parts", ["association_id"], :name => "association_id_ind"
  add_index "association_parts", ["object_relationship_id"], :name => "isa_id_ind"
  add_index "association_parts", ["otu_id"], :name => "otu_id_ind"
  add_index "association_parts", ["position"], :name => "position_ind"

  create_table "association_supports", :force => true do |t|
    t.integer   "association_id",                                   :null => false
    t.integer   "confidence_id",                                    :null => false
    t.string    "type",            :limit => 32
    t.integer   "ref_id"
    t.integer   "voucher_lot_id"
    t.integer   "specimen_id"
    t.text      "temp_ref"
    t.integer   "temp_ref_mjy_id"
    t.string    "setting",         :limit => 32
    t.text      "notes"
    t.boolean   "negative",                      :default => false
    t.integer   "proj_id",                                          :null => false
    t.integer   "creator_id",                                       :null => false
    t.integer   "updator_id",                                       :null => false
    t.timestamp "updated_on",                                       :null => false
    t.timestamp "created_on",                                       :null => false
  end

  add_index "association_supports", ["association_id"], :name => "association_id_ind"
  add_index "association_supports", ["confidence_id"], :name => "confidence_id_ind"
  add_index "association_supports", ["creator_id"], :name => "creator_id"
  add_index "association_supports", ["negative"], :name => "negative_ind"
  add_index "association_supports", ["proj_id"], :name => "proj_id"
  add_index "association_supports", ["updator_id"], :name => "updator_id"

  create_table "associations", :force => true do |t|
    t.text      "notes"
    t.integer   "proj_id",    :null => false
    t.integer   "creator_id", :null => false
    t.integer   "updator_id", :null => false
    t.timestamp "updated_on", :null => false
    t.timestamp "created_on", :null => false
  end

  add_index "associations", ["creator_id"], :name => "creator_id"
  add_index "associations", ["proj_id"], :name => "proj_id"
  add_index "associations", ["updator_id"], :name => "updator_id"

  create_table "authors", :force => true do |t|
    t.integer   "ref_id",                                             :null => false
    t.integer   "position"
    t.string    "last_name",                                          :null => false
    t.string    "first_name"
    t.string    "title"
    t.string    "initials",       :limit => 8
    t.string    "auth_is",        :limit => 16, :default => "author", :null => false
    t.boolean   "use_initials"
    t.string    "name_with_init"
    t.string    "join_name"
    t.integer   "namespace_id"
    t.integer   "external_id"
    t.integer   "creator_id",                                         :null => false
    t.integer   "updator_id",                                         :null => false
    t.timestamp "updated_on",                                         :null => false
    t.timestamp "created_on",                                         :null => false
  end

  add_index "authors", ["creator_id"], :name => "creator_id"
  add_index "authors", ["namespace_id"], :name => "namespace_id"
  add_index "authors", ["ref_id"], :name => "ref_id"
  add_index "authors", ["updator_id"], :name => "updator_id"

  create_table "beats", :force => true do |t|
    t.integer  "addressable_id"
    t.string   "addressable_type"
    t.string   "message"
    t.integer  "proj_id"
    t.integer  "creator_id"
    t.integer  "updator_id"
    t.datetime "created_on"
    t.datetime "updated_on"
  end

  create_table "berkeley_mapper_results", :force => true do |t|
    t.text      "tabfile",    :limit => 16777215
    t.integer   "proj_id",                        :null => false
    t.timestamp "created_on",                     :null => false
  end

  add_index "berkeley_mapper_results", ["proj_id"], :name => "proj_id"

  create_table "ces", :force => true do |t|
    t.integer   "proj_id",                                                              :null => false
    t.integer   "namespace_id"
    t.integer   "external_id"
    t.text      "verbatim_label"
    t.integer   "num_to_print"
    t.text      "collectors"
    t.text      "locality"
    t.text      "geography"
    t.integer   "geog_id"
    t.string    "mthd"
    t.string    "sd_d",                                :limit => 2
    t.string    "sd_m",                                :limit => 4
    t.string    "sd_y",                                :limit => 4
    t.string    "ed_d",                                :limit => 2
    t.string    "ed_m",                                :limit => 4
    t.string    "ed_y",                                :limit => 4
    t.float     "latitude"
    t.float     "longitude"
    t.integer   "dc_coordinate_uncertainty_in_meters"
    t.float     "elev_min"
    t.float     "elev_max"
    t.string    "elev_unit",                           :limit => 6
    t.string    "dc_verbatim_latitude",                :limit => 48
    t.string    "dc_verbatim_longitude",               :limit => 48
    t.boolean   "undet_ll",                                          :default => false, :null => false
    t.text      "notes"
    t.string    "trip_code"
    t.integer   "trip_namespace_id"
    t.text      "doc_label"
    t.string    "verbatim_method"
    t.string    "host_genus"
    t.string    "host_species"
    t.boolean   "err_label",                                         :default => false, :null => false
    t.boolean   "err_entry",                                         :default => false, :null => false
    t.boolean   "err_checked",                                       :default => false, :null => false
    t.boolean   "undetgeog",                                         :default => false, :null => false
    t.timestamp "updated_on",                                                           :null => false
    t.timestamp "created_on",                                                           :null => false
    t.integer   "creator_id",                                                           :null => false
    t.integer   "updator_id",                                                           :null => false
    t.text      "print_label"
    t.float     "depth_min"
    t.float     "depth_max"
    t.string    "verbatim_label_md5"
    t.text      "micro_habitat"
    t.text      "macro_habitat"
    t.integer   "locality_accuracy_confidence_id"
    t.text      "dc_verbatim_SRS"
    t.text      "dc_verbatim_coordinate_system"
    t.text      "dc_geodetic_dataum"
    t.integer   "dc_georeference_protocol_id"
    t.text      "dc_georeference_verification_status"
    t.text      "dc_footprint_SRS"
    t.text      "dc_georeferenced_by"
    t.text      "dc_georeference_remarks"
    t.time      "time_start"
    t.time      "time_end"
    t.text      "dc_georeference_sources"
    t.boolean   "is_public",                                         :default => true
  end

  add_index "ces", ["creator_id"], :name => "creator_id_ind"
  add_index "ces", ["geog_id"], :name => "geog_id_ind"
  add_index "ces", ["namespace_id"], :name => "namespace_id_ind"
  add_index "ces", ["proj_id"], :name => "proj_id_ind"
  add_index "ces", ["trip_namespace_id"], :name => "trip_namespace_id_ind"
  add_index "ces", ["updator_id"], :name => "updator_id_ind"

  create_table "chr_groups", :force => true do |t|
    t.string    "name"
    t.text      "notes"
    t.integer   "position"
    t.integer   "content_type_id"
    t.integer   "proj_id",         :null => false
    t.integer   "creator_id",      :null => false
    t.integer   "updator_id",      :null => false
    t.timestamp "updated_on",      :null => false
    t.timestamp "created_on",      :null => false
  end

  add_index "chr_groups", ["content_type_id"], :name => "content_type_id"
  add_index "chr_groups", ["creator_id"], :name => "creator_id"
  add_index "chr_groups", ["proj_id"], :name => "proj_id"
  add_index "chr_groups", ["updator_id"], :name => "updator_id"

  create_table "chr_groups_chrs", :force => true do |t|
    t.integer "chr_group_id", :null => false
    t.integer "chr_id",       :null => false
    t.integer "position"
  end

  add_index "chr_groups_chrs", ["chr_group_id"], :name => "chr_group_id_ind"
  add_index "chr_groups_chrs", ["chr_id"], :name => "chr_id_ind"

  create_table "chr_groups_mxes", :id => false, :force => true do |t|
    t.integer "mx_id",        :null => false
    t.integer "chr_group_id", :null => false
  end

  add_index "chr_groups_mxes", ["chr_group_id"], :name => "chr_group_id_ind"
  add_index "chr_groups_mxes", ["mx_id"], :name => "mx_id_ind"

  create_table "chr_states", :force => true do |t|
    t.integer   "chr_id",                                             :null => false
    t.string    "state",            :limit => 8,                      :null => false
    t.string    "name"
    t.string    "cited_polarity",   :limit => 15, :default => "none"
    t.integer   "hh_id"
    t.text      "revision_history"
    t.text      "notes"
    t.integer   "creator_id",                                         :null => false
    t.integer   "updator_id",                                         :null => false
    t.timestamp "updated_on",                                         :null => false
    t.timestamp "created_on",                                         :null => false
    t.integer   "phenotype_id"
    t.string    "phenotype_type"
  end

  add_index "chr_states", ["chr_id", "state"], :name => "id_state", :unique => true
  add_index "chr_states", ["chr_id"], :name => "chr_id_ind"
  add_index "chr_states", ["creator_id"], :name => "creator_id"
  add_index "chr_states", ["hh_id"], :name => "hh_id_ind"
  add_index "chr_states", ["id", "state", "name"], :name => "id"
  add_index "chr_states", ["name"], :name => "name"
  add_index "chr_states", ["state"], :name => "state"
  add_index "chr_states", ["state"], :name => "state_ind"
  add_index "chr_states", ["updator_id"], :name => "updator_id"

  create_table "chromatograms", :force => true do |t|
    t.integer   "pcr_id"
    t.integer   "primer_id"
    t.integer   "protocol_id"
    t.string    "done_by"
    t.string    "filename"
    t.string    "result",       :limit => 24
    t.text      "seq"
    t.text      "notes"
    t.integer   "proj_id",                    :null => false
    t.integer   "creator_id",                 :null => false
    t.integer   "updator_id",                 :null => false
    t.timestamp "updated_on",                 :null => false
    t.timestamp "created_on",                 :null => false
    t.integer   "size"
    t.string    "content_type"
  end

  add_index "chromatograms", ["creator_id"], :name => "creator_id"
  add_index "chromatograms", ["pcr_id"], :name => "pcr_id"
  add_index "chromatograms", ["primer_id"], :name => "primer_id"
  add_index "chromatograms", ["proj_id"], :name => "proj_id"
  add_index "chromatograms", ["protocol_id"], :name => "protocol_id"
  add_index "chromatograms", ["updator_id"], :name => "updator_id"

  create_table "chrs", :force => true do |t|
    t.string    "name",                                              :null => false
    t.integer   "cited_in"
    t.string    "cited_page",       :limit => 64
    t.string    "cited_char_no",    :limit => 4
    t.text      "revision_history"
    t.integer   "syn_with"
    t.string    "doc_char_code",    :limit => 4
    t.text      "doc_char_descr"
    t.string    "short_name",       :limit => 6
    t.text      "notes"
    t.boolean   "ordered",                        :default => false
    t.integer   "position"
    t.integer   "proj_id",                                           :null => false
    t.integer   "creator_id",                                        :null => false
    t.integer   "updator_id",                                        :null => false
    t.timestamp "updated_on",                                        :null => false
    t.timestamp "created_on",                                        :null => false
    t.integer   "standard_view_id"
    t.boolean   "is_continuous",                  :default => false
    t.string    "phenotype_class"
  end

  add_index "chrs", ["cited_in"], :name => "cited_in_ind"
  add_index "chrs", ["creator_id"], :name => "creator_id"
  add_index "chrs", ["proj_id"], :name => "proj_id"
  add_index "chrs", ["syn_with"], :name => "syn_with_ind"
  add_index "chrs", ["updator_id"], :name => "updator_id"

  create_table "chrs_mxes", :force => true do |t|
    t.integer  "chr_id",     :null => false
    t.integer  "mx_id",      :null => false
    t.integer  "position"
    t.text     "notes"
    t.integer  "creator_id"
    t.integer  "updator_id"
    t.datetime "updated_on"
    t.datetime "created_on"
  end

  add_index "chrs_mxes", ["chr_id"], :name => "chr_id_ind"
  add_index "chrs_mxes", ["mx_id", "chr_id"], :name => "mx_id", :unique => true
  add_index "chrs_mxes", ["mx_id"], :name => "mx_id_ind"

  create_table "claves", :force => true do |t|
    t.integer   "parent_id"
    t.integer   "otu_id"
    t.text      "couplet_text"
    t.integer   "position"
    t.text      "link_out"
    t.string    "link_out_text",   :limit => 1024
    t.text      "edit_annotation"
    t.text      "pub_annotation"
    t.text      "head_annotation"
    t.string    "manual_id",       :limit => 7
    t.integer   "ref_id"
    t.integer   "l"
    t.integer   "r"
    t.boolean   "is_public",                       :default => false, :null => false
    t.integer   "redirect_id"
    t.integer   "proj_id",                                            :null => false
    t.integer   "creator_id",                                         :null => false
    t.integer   "updator_id",                                         :null => false
    t.timestamp "updated_on",                                         :null => false
    t.timestamp "created_on",                                         :null => false
  end

  add_index "claves", ["creator_id"], :name => "creator_id"
  add_index "claves", ["creator_id"], :name => "creator_id_2"
  add_index "claves", ["otu_id"], :name => "otu_id"
  add_index "claves", ["parent_id"], :name => "parent_id"
  add_index "claves", ["proj_id"], :name => "proj_id"
  add_index "claves", ["redirect_id"], :name => "redirect_id"
  add_index "claves", ["ref_id"], :name => "ref_id"
  add_index "claves", ["updator_id"], :name => "updator_id"
  add_index "claves", ["updator_id"], :name => "updator_id_2"

  create_table "codings", :force => true do |t|
    t.integer   "otu_id",           :null => false
    t.integer   "chr_id",           :null => false
    t.integer   "chr_state_id"
    t.float     "continuous_state"
    t.integer   "cited_in"
    t.text      "notes"
    t.string    "chr_state_state"
    t.string    "chr_state_name"
    t.text      "qualifier"
    t.integer   "proj_id",          :null => false
    t.integer   "creator_id",       :null => false
    t.integer   "updator_id",       :null => false
    t.timestamp "updated_on",       :null => false
    t.timestamp "created_on",       :null => false
    t.integer   "confidence_id"
  end

  add_index "codings", ["chr_id"], :name => "chr_id"
  add_index "codings", ["chr_state_id", "chr_state_state", "chr_state_name"], :name => "chr_state_id_2"
  add_index "codings", ["chr_state_id", "otu_id"], :name => "chr_state_id_otu_id", :unique => true
  add_index "codings", ["chr_state_id"], :name => "chr_state_id"
  add_index "codings", ["cited_in"], :name => "cited_in_ind"
  add_index "codings", ["confidence_id"], :name => "codings_confidence_fk"
  add_index "codings", ["creator_id"], :name => "creator_id"
  add_index "codings", ["otu_id", "chr_id", "chr_state_id"], :name => "coding_speed"
  add_index "codings", ["otu_id"], :name => "otu_id_ind"
  add_index "codings", ["proj_id"], :name => "proj_id"
  add_index "codings", ["updator_id"], :name => "updator_id"

  create_table "confidences", :force => true do |t|
    t.string    "name",             :limit => 128
    t.integer   "position"
    t.string    "short_name",       :limit => 4
    t.integer   "proj_id",                         :null => false
    t.integer   "creator_id",                      :null => false
    t.integer   "updator_id",                      :null => false
    t.timestamp "updated_on",                      :null => false
    t.timestamp "created_on",                      :null => false
    t.string    "html_color",       :limit => 8
    t.text      "applicable_model"
  end

  add_index "confidences", ["creator_id"], :name => "creator_id"
  add_index "confidences", ["position"], :name => "position_ind"
  add_index "confidences", ["proj_id"], :name => "proj_id"
  add_index "confidences", ["short_name", "proj_id"], :name => "short_name_proj"
  add_index "confidences", ["short_name"], :name => "short_name"
  add_index "confidences", ["updator_id"], :name => "updator_id"

  create_table "content_templates", :force => true do |t|
    t.string    "name",                          :null => false
    t.boolean   "is_default", :default => false, :null => false
    t.boolean   "is_public",  :default => false, :null => false
    t.integer   "proj_id",                       :null => false
    t.integer   "creator_id",                    :null => false
    t.integer   "updator_id",                    :null => false
    t.timestamp "updated_on",                    :null => false
    t.timestamp "created_on",                    :null => false
  end

  add_index "content_templates", ["creator_id"], :name => "creator_id_ind"
  add_index "content_templates", ["name", "proj_id"], :name => "name", :unique => true
  add_index "content_templates", ["name"], :name => "name_ind"
  add_index "content_templates", ["proj_id"], :name => "proj_id_ind"
  add_index "content_templates", ["updator_id"], :name => "updator_id_ind"

  create_table "content_templates_content_types", :primary_key => "foo_id", :force => true do |t|
    t.integer "content_type_id",                  :null => false
    t.integer "content_template_id",              :null => false
    t.integer "position",            :limit => 1
  end

  add_index "content_templates_content_types", ["content_template_id"], :name => "content_template_id_ind"
  add_index "content_templates_content_types", ["content_type_id", "content_template_id"], :name => "content_type_id", :unique => true
  add_index "content_templates_content_types", ["content_type_id"], :name => "content_type_id_ind"

  create_table "content_types", :force => true do |t|
    t.string    "sti_type"
    t.boolean   "is_public",            :default => false
    t.string    "name"
    t.boolean   "can_markup",           :default => true
    t.integer   "proj_id",                                 :null => false
    t.integer   "creator_id",                              :null => false
    t.integer   "updator_id",                              :null => false
    t.timestamp "updated_on",                              :null => false
    t.timestamp "created_on",                              :null => false
    t.string    "doc_name"
    t.string    "subject"
    t.boolean   "render_as_subheading", :default => false
    t.boolean   "is_image_box",         :default => false
  end

  add_index "content_types", ["creator_id"], :name => "creator_id"
  add_index "content_types", ["name", "proj_id"], :name => "name", :unique => true
  add_index "content_types", ["name"], :name => "name_ind"
  add_index "content_types", ["proj_id"], :name => "proj_id"
  add_index "content_types", ["updator_id"], :name => "updator_id"

  create_table "contents", :force => true do |t|
    t.integer   "otu_id"
    t.integer   "content_type_id"
    t.text      "text"
    t.boolean   "is_public",        :default => true,  :null => false
    t.integer   "pub_content_id"
    t.integer   "revision"
    t.integer   "proj_id",                             :null => false
    t.integer   "creator_id",                          :null => false
    t.integer   "updator_id",                          :null => false
    t.timestamp "updated_on",                          :null => false
    t.timestamp "created_on",                          :null => false
    t.string    "license"
    t.string    "copyright_holder"
    t.string    "maker"
    t.string    "editor"
    t.boolean   "is_image_box",     :default => false
  end

  add_index "contents", ["content_type_id"], :name => "content_type_id_ind"
  add_index "contents", ["creator_id"], :name => "creator_id"
  add_index "contents", ["otu_id"], :name => "otu_id_ind"
  add_index "contents", ["proj_id"], :name => "proj_id"
  add_index "contents", ["pub_content_id"], :name => "pub_content_id_ind"
  add_index "contents", ["updator_id"], :name => "updator_id"

  create_table "data_sources", :force => true do |t|
    t.string    "name",       :null => false
    t.integer   "mx_id"
    t.integer   "dataset_id"
    t.text      "notes"
    t.integer   "ref_id"
    t.integer   "proj_id",    :null => false
    t.integer   "creator_id", :null => false
    t.integer   "updator_id", :null => false
    t.timestamp "updated_on", :null => false
    t.timestamp "created_on", :null => false
  end

  add_index "data_sources", ["creator_id"], :name => "creator_id"
  add_index "data_sources", ["mx_id"], :name => "mx_id"
  add_index "data_sources", ["proj_id"], :name => "proj_id"
  add_index "data_sources", ["ref_id"], :name => "ref_id"
  add_index "data_sources", ["updator_id"], :name => "updator_id"

  create_table "datasets", :force => true do |t|
    t.integer   "parent_id"
    t.string    "content_type"
    t.string    "filename",     :limit => 1024
    t.integer   "size"
    t.integer   "proj_id",                      :null => false
    t.integer   "creator_id",                   :null => false
    t.integer   "updator_id",                   :null => false
    t.timestamp "updated_on",                   :null => false
    t.timestamp "created_on",                   :null => false
  end

  add_index "datasets", ["creator_id"], :name => "creator_id"
  add_index "datasets", ["proj_id"], :name => "proj_id"
  add_index "datasets", ["updator_id"], :name => "updator_id"

  create_table "differentiae", :force => true do |t|
    t.integer "property_id",             :null => false
    t.integer "value_id",                :null => false
    t.string  "value_type",              :null => false
    t.integer "ontology_composition_id"
  end

  create_table "distributions", :force => true do |t|
    t.integer   "geog_id"
    t.integer   "otu_id"
    t.integer   "ref_id"
    t.integer   "confidence_id"
    t.string    "verbatim_geog"
    t.integer   "introduced"
    t.text      "notes"
    t.integer   "proj_id",       :null => false
    t.integer   "creator_id",    :null => false
    t.integer   "updator_id",    :null => false
    t.timestamp "updated_on",    :null => false
    t.timestamp "created_on",    :null => false
  end

  add_index "distributions", ["creator_id"], :name => "creator_id"
  add_index "distributions", ["proj_id"], :name => "proj_id"
  add_index "distributions", ["updator_id"], :name => "updator_id"

  create_table "extracts", :force => true do |t|
    t.integer   "lot_id"
    t.integer   "specimen_id"
    t.integer   "protocol_id"
    t.text      "parts_extracted_from"
    t.string    "quality",                  :limit => 12
    t.text      "notes"
    t.date      "extracted_on"
    t.string    "extracted_by",             :limit => 128
    t.string    "other_extract_identifier", :limit => 128
    t.integer   "proj_id",                                                    :null => false
    t.integer   "creator_id",                                                 :null => false
    t.integer   "updator_id",                                                 :null => false
    t.timestamp "updated_on",                                                 :null => false
    t.timestamp "created_on",                                                 :null => false
    t.boolean   "is_depleted",                             :default => false
  end

  add_index "extracts", ["creator_id"], :name => "creator_id"
  add_index "extracts", ["lot_id"], :name => "lot_id_ind"
  add_index "extracts", ["proj_id"], :name => "proj_id"
  add_index "extracts", ["protocol_id"], :name => "protocol_id_ind"
  add_index "extracts", ["specimen_id"], :name => "specimen_id_ind"
  add_index "extracts", ["updator_id"], :name => "updator_id"

  create_table "extracts_genes", :force => true do |t|
    t.text     "notes"
    t.datetime "created_on",    :null => false
    t.datetime "updated_on",    :null => false
    t.integer  "gene_id",       :null => false
    t.integer  "confidence_id", :null => false
    t.integer  "extract_id",    :null => false
    t.integer  "proj_id",       :null => false
    t.integer  "updator_id",    :null => false
    t.integer  "creator_id",    :null => false
  end

  create_table "figure_markers", :force => true do |t|
    t.text     "svg",                                                           :null => false
    t.decimal  "x_origin",    :precision => 6, :scale => 0, :default => 0
    t.decimal  "y_origin",    :precision => 6, :scale => 0, :default => 0
    t.decimal  "rotation",    :precision => 6, :scale => 0, :default => 0
    t.decimal  "scale",       :precision => 6, :scale => 0, :default => 0
    t.string   "marker_type",                               :default => "area", :null => false
    t.integer  "position"
    t.datetime "created_on",                                                    :null => false
    t.datetime "updated_on",                                                    :null => false
    t.integer  "figure_id",                                                     :null => false
    t.integer  "proj_id",                                                       :null => false
    t.integer  "updator_id",                                                    :null => false
    t.integer  "creator_id",                                                    :null => false
  end

  add_index "figure_markers", ["figure_id"], :name => "index_figure_markers_on_figure_id"

  create_table "figures", :force => true do |t|
    t.integer   "addressable_id"
    t.string    "addressable_type",        :limit => 64
    t.integer   "image_id",                              :null => false
    t.integer   "position",                :limit => 1
    t.text      "caption"
    t.timestamp "updated_on",                            :null => false
    t.timestamp "created_on",                            :null => false
    t.integer   "creator_id",                            :null => false
    t.integer   "updator_id",                            :null => false
    t.integer   "proj_id",                               :null => false
    t.integer   "morphbank_annotation_id"
    t.text      "svg_txt"
  end

  add_index "figures", ["addressable_id", "addressable_type", "image_id", "proj_id"], :name => "addressable_id_3", :unique => true
  add_index "figures", ["addressable_id", "addressable_type"], :name => "addressable_id_2"
  add_index "figures", ["addressable_id"], :name => "addressable_id"
  add_index "figures", ["addressable_type"], :name => "addressable_type"
  add_index "figures", ["creator_id"], :name => "creator_id"
  add_index "figures", ["image_id"], :name => "image_id"
  add_index "figures", ["proj_id"], :name => "proj_id"
  add_index "figures", ["updator_id"], :name => "updator_id"

  create_table "gel_images", :force => true do |t|
    t.string    "name"
    t.string    "file_name",      :limit => 64, :null => false
    t.string    "user_file_name"
    t.string    "file_md5",       :limit => 32, :null => false
    t.string    "file_type",      :limit => 4
    t.integer   "file_size"
    t.integer   "width",          :limit => 3
    t.integer   "height",         :limit => 3
    t.text      "notes"
    t.integer   "proj_id",                      :null => false
    t.integer   "creator_id",                   :null => false
    t.integer   "updator_id",                   :null => false
    t.timestamp "updated_on",                   :null => false
    t.timestamp "created_on",                   :null => false
  end

  add_index "gel_images", ["creator_id"], :name => "creator_id"
  add_index "gel_images", ["proj_id"], :name => "proj_id"
  add_index "gel_images", ["updator_id"], :name => "updator_id"

  create_table "gene_groups", :force => true do |t|
    t.string    "name"
    t.text      "notes"
    t.integer   "proj_id",    :null => false
    t.integer   "creator_id", :null => false
    t.integer   "updator_id", :null => false
    t.timestamp "updated_on", :null => false
    t.timestamp "created_on", :null => false
  end

  add_index "gene_groups", ["creator_id"], :name => "creator_id"
  add_index "gene_groups", ["proj_id"], :name => "proj_id"
  add_index "gene_groups", ["updator_id"], :name => "updator_id"

  create_table "gene_groups_genes", :id => false, :force => true do |t|
    t.integer "gene_group_id",              :null => false
    t.integer "gene_id",                    :null => false
    t.integer "sort",          :limit => 1
  end

  add_index "gene_groups_genes", ["gene_group_id"], :name => "gene_group_id"
  add_index "gene_groups_genes", ["gene_id"], :name => "gene_id"

  create_table "genes", :force => true do |t|
    t.string    "name"
    t.text      "notes"
    t.integer   "position"
    t.integer   "proj_id",    :null => false
    t.integer   "creator_id", :null => false
    t.integer   "updator_id", :null => false
    t.timestamp "updated_on", :null => false
    t.timestamp "created_on", :null => false
  end

  add_index "genes", ["creator_id"], :name => "creator_id"
  add_index "genes", ["proj_id"], :name => "proj_id"
  add_index "genes", ["updator_id"], :name => "updator_id"

  create_table "geog_types", :force => true do |t|
    t.string  "name"
    t.integer "feature_class"
  end

  create_table "geogs", :force => true do |t|
    t.string    "name",                                     :null => false
    t.string    "abbreviation",               :limit => 64
    t.integer   "fips_code"
    t.integer   "sort_NS"
    t.integer   "sort_WE"
    t.string    "center_lat",                 :limit => 64
    t.string    "center_long",                :limit => 64
    t.integer   "geog_type_id"
    t.integer   "inclusive_biogeo_region_id"
    t.integer   "country_id"
    t.integer   "state_id"
    t.integer   "county_id"
    t.integer   "continent_ocean_id"
    t.integer   "namespace_id"
    t.integer   "external_id"
    t.integer   "creator_id",                               :null => false
    t.integer   "updator_id",                               :null => false
    t.timestamp "updated_on",                               :null => false
    t.timestamp "created_on",                               :null => false
    t.text      "iso_3166_1_alpha_2_code"
  end

  add_index "geogs", ["continent_ocean_id"], :name => "continent_ocean_id_ind"
  add_index "geogs", ["country_id"], :name => "country_id_ind"
  add_index "geogs", ["county_id"], :name => "county_id_ind"
  add_index "geogs", ["creator_id"], :name => "creator_id"
  add_index "geogs", ["geog_type_id"], :name => "geog_type_id_ind"
  add_index "geogs", ["inclusive_biogeo_region_id"], :name => "inclusive_biogeo_region_id_ind"
  add_index "geogs", ["name"], :name => "name", :length => {"name"=>8}
  add_index "geogs", ["namespace_id", "external_id"], :name => "namespace_id", :unique => true
  add_index "geogs", ["namespace_id"], :name => "namespace_id_ind"
  add_index "geogs", ["state_id"], :name => "state_id_ind"
  add_index "geogs", ["updator_id"], :name => "updator_id"

  create_table "identifiers", :force => true do |t|
    t.integer  "addressable_id"
    t.string   "addressable_type"
    t.integer  "namespace_id"
    t.string   "identifier"
    t.string   "global_identifier"
    t.string   "global_identifier_type"
    t.integer  "position"
    t.string   "cached_display_name"
    t.boolean  "is_catalog_number",      :default => true
    t.text     "notes"
    t.integer  "proj_id"
    t.integer  "creator_id"
    t.integer  "updator_id"
    t.datetime "created_on"
    t.datetime "updated_on"
  end

  add_index "identifiers", ["addressable_id"], :name => "index_identifiers_on_addressable_id"
  add_index "identifiers", ["addressable_type", "addressable_id"], :name => "index_identifiers_on_addressable_type_and_addressable_id"
  add_index "identifiers", ["addressable_type"], :name => "index_identifiers_on_addressable_type"
  add_index "identifiers", ["cached_display_name"], :name => "index_identifiers_on_cached_display_name"
  add_index "identifiers", ["global_identifier"], :name => "index_identifiers_on_global_identifier"
  add_index "identifiers", ["global_identifier_type", "global_identifier"], :name => "gidt_gid"
  add_index "identifiers", ["identifier"], :name => "index_identifiers_on_identifier"
  add_index "identifiers", ["namespace_id", "identifier"], :name => "index_identifiers_on_namespace_id_and_identifier"
  add_index "identifiers", ["namespace_id"], :name => "index_identifiers_on_namespace_id"

  create_table "image_descriptions", :force => true do |t|
    t.integer   "otu_id"
    t.integer   "proj_id",                                              :null => false
    t.integer   "image_id"
    t.integer   "image_view_id"
    t.integer   "label_id"
    t.string    "stage",               :limit => 32
    t.string    "sex",                 :limit => 32
    t.integer   "specimen_id"
    t.text      "notes"
    t.boolean   "is_public",                         :default => false, :null => false
    t.string    "priority",            :limit => 6
    t.integer   "requestor_id"
    t.integer   "contractor_id"
    t.text      "request_notes"
    t.string    "status",              :limit => 64
    t.timestamp "updated_on",                                           :null => false
    t.timestamp "created_on",                                           :null => false
    t.integer   "creator_id",                                           :null => false
    t.integer   "updator_id",                                           :null => false
    t.string    "magnification"
    t.string    "ontology_class_xref"
  end

  add_index "image_descriptions", ["contractor_id"], :name => "contractor_id"
  add_index "image_descriptions", ["creator_id"], :name => "creator_id"
  add_index "image_descriptions", ["image_id"], :name => "image_id"
  add_index "image_descriptions", ["image_view_id"], :name => "image_view_id"
  add_index "image_descriptions", ["label_id"], :name => "index_image_descriptions_on_label_id"
  add_index "image_descriptions", ["label_id"], :name => "part_id"
  add_index "image_descriptions", ["ontology_class_xref"], :name => "index_image_descriptions_on_ontology_class_dbxref"
  add_index "image_descriptions", ["otu_id"], :name => "otu_id"
  add_index "image_descriptions", ["proj_id"], :name => "proj_id"
  add_index "image_descriptions", ["requestor_id"], :name => "requestor_id"
  add_index "image_descriptions", ["specimen_id"], :name => "specimen_id"
  add_index "image_descriptions", ["updator_id"], :name => "updator_id"

  create_table "image_views", :force => true do |t|
    t.string    "name",       :limit => 64, :null => false
    t.timestamp "updated_on",               :null => false
    t.timestamp "created_on",               :null => false
    t.integer   "creator_id",               :null => false
    t.integer   "updator_id",               :null => false
  end

  add_index "image_views", ["creator_id"], :name => "creator_id"
  add_index "image_views", ["updator_id"], :name => "updator_id"

  create_table "images", :force => true do |t|
    t.string    "file_name",        :limit => 64
    t.string    "file_md5",         :limit => 32
    t.string    "file_type",        :limit => 4
    t.integer   "file_size"
    t.integer   "width",            :limit => 3
    t.integer   "height",           :limit => 3
    t.string    "user_file_name",   :limit => 64
    t.integer   "taken_on_year",    :limit => 2
    t.integer   "taken_on_month",   :limit => 1
    t.integer   "taken_on_day",     :limit => 1
    t.string    "maker"
    t.integer   "ref_id"
    t.string    "technique",        :limit => 12
    t.integer   "mb_id"
    t.text      "notes"
    t.timestamp "updated_on",                     :null => false
    t.timestamp "created_on",                     :null => false
    t.integer   "creator_id",                     :null => false
    t.integer   "updator_id",                     :null => false
    t.integer   "proj_id",                        :null => false
    t.string    "copyright_holder"
    t.string    "contributor"
    t.string    "license"
  end

  add_index "images", ["creator_id"], :name => "creator_id"
  add_index "images", ["proj_id"], :name => "proj_id"
  add_index "images", ["ref_id"], :name => "ref_id"
  add_index "images", ["updator_id"], :name => "updator_id"

  create_table "ipt_records", :force => true do |t|
    t.string   "occurrence_id"
    t.datetime "modified"
    t.string   "basis_of_record"
    t.string   "institution_code"
    t.string   "collection_code"
    t.string   "catalog_number"
    t.string   "information_withheld"
    t.text     "occurrence_remarks"
    t.string   "scientific_name"
    t.string   "parent_name_usage"
    t.string   "kingdom"
    t.string   "phylum"
    t.string   "tn_class"
    t.string   "tn_order"
    t.string   "family"
    t.string   "genus"
    t.string   "specific_epithet"
    t.string   "taxon_rank"
    t.string   "infraspecific_epithet"
    t.string   "scientific_name_authorship"
    t.string   "nomenclatural_code"
    t.string   "identification_qualifier"
    t.string   "higher_geography"
    t.string   "continent"
    t.string   "water_body"
    t.string   "island_group"
    t.string   "island"
    t.string   "country"
    t.string   "state_province"
    t.string   "county"
    t.string   "locality"
    t.string   "minimum_elevation_in_meters"
    t.string   "maximum_elevation_in_meters"
    t.string   "minimum_depth_in_meters"
    t.string   "maximum_depth_in_meters"
    t.string   "sampling_protocol"
    t.string   "establishment_means"
    t.string   "event_date"
    t.integer  "start_day_of_year"
    t.string   "recorded_by"
    t.string   "sex"
    t.string   "life_stage"
    t.string   "dynamic_properties"
    t.text     "associated_media"
    t.string   "occurrence_details"
    t.string   "identified_by"
    t.datetime "date_identified"
    t.string   "record_number"
    t.string   "field_number"
    t.string   "field_notes"
    t.string   "verbatim_event_date"
    t.string   "verbatim_elevation"
    t.string   "verbatim_depth"
    t.string   "preparations"
    t.string   "type_status"
    t.string   "associated_sequences"
    t.string   "other_catalog_numbers"
    t.string   "associated_occurrences"
    t.string   "disposition"
    t.integer  "individual_count"
    t.string   "decimal_latitude"
    t.string   "decimal_longitude"
    t.string   "geodetic_datum"
    t.string   "coordinate_uncertainty_in_meters"
    t.string   "point_radius_spatial_fit"
    t.string   "verbatim_coordinates"
    t.string   "verbatim_latitude"
    t.string   "verbatim_longitude"
    t.string   "verbatim_coordinate_system"
    t.string   "georeference_protocol"
    t.string   "georeference_sources"
    t.string   "georeference_verification_status"
    t.string   "georeference_remarks"
    t.string   "footprint_WKT"
    t.string   "footprint_spatial_fit"
    t.integer  "proj_id"
    t.integer  "specimen_id"
    t.integer  "lot_id"
    t.integer  "ce_id"
    t.integer  "ce_geog_id"
    t.integer  "otu_id"
    t.integer  "taxon_name_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "year"
    t.string   "month"
    t.string   "day"
  end

  add_index "ipt_records", ["ce_id", "lot_id"], :name => "index_ipt_records_on_ce_id_and_lot_id"
  add_index "ipt_records", ["ce_id", "specimen_id"], :name => "index_ipt_records_on_ce_id_and_specimen_id"
  add_index "ipt_records", ["occurrence_id"], :name => "index_ipt_records_on_occurrence_id", :unique => true
  add_index "ipt_records", ["proj_id", "ce_id"], :name => "index_ipt_records_on_proj_id_and_ce_id"
  add_index "ipt_records", ["proj_id", "lot_id"], :name => "index_ipt_records_on_proj_id_and_lot_id"
  add_index "ipt_records", ["proj_id", "specimen_id"], :name => "index_ipt_records_on_proj_id_and_specimen_id"

  create_table "keywords", :force => true do |t|
    t.string    "keyword",                                     :null => false
    t.string    "shortform",   :limit => 6
    t.text      "explanation"
    t.boolean   "is_public",                :default => false
    t.string    "html_color",  :limit => 6
    t.integer   "proj_id",                                     :null => false
    t.integer   "creator_id",                                  :null => false
    t.integer   "updator_id",                                  :null => false
    t.timestamp "updated_on",                                  :null => false
    t.timestamp "created_on",                                  :null => false
    t.boolean   "is_xref",                  :default => false
  end

  add_index "keywords", ["creator_id"], :name => "creator_id"
  add_index "keywords", ["keyword"], :name => "keyword", :length => {"keyword"=>4}
  add_index "keywords", ["proj_id"], :name => "proj_id"
  add_index "keywords", ["updator_id"], :name => "updator_id"

  create_table "labels", :force => true do |t|
    t.string    "name",                                             :null => false
    t.integer   "language_id"
    t.integer   "proj_id",                                          :null => false
    t.integer   "creator_id",                                       :null => false
    t.integer   "updator_id",                                       :null => false
    t.timestamp "created_on",                                       :null => false
    t.timestamp "updated_on",                                       :null => false
    t.text      "classify_IP_votes"
    t.integer   "plural_of_label_id"
    t.datetime  "active_on"
    t.integer   "active_person_id"
    t.string    "active_msg",         :limit => 144
    t.integer   "active_level",                      :default => 0
  end

  add_index "labels", ["creator_id"], :name => "creator_id"
  add_index "labels", ["language_id"], :name => "language_id"
  add_index "labels", ["name"], :name => "index_labels_on_name"
  add_index "labels", ["proj_id", "name", "language_id"], :name => "index_labels_on_proj_id_and_name_and_language_id", :unique => true
  add_index "labels", ["updator_id"], :name => "updator_id"

  create_table "labels_refs", :force => true do |t|
    t.integer  "ref_id",                    :null => false
    t.integer  "label_id",                  :null => false
    t.integer  "total",      :default => 0, :null => false
    t.datetime "created_on"
    t.datetime "updated_on"
  end

  add_index "labels_refs", ["label_id"], :name => "label_id"
  add_index "labels_refs", ["ref_id", "label_id"], :name => "index_labels_refs_on_ref_id_and_label_id"

  create_table "languages", :force => true do |t|
    t.string "ltype",           :limit => 128
    t.string "subtag",          :limit => 4
    t.string "description",     :limit => 1024
    t.string "suppress_script", :limit => 256
    t.string "preferred_value", :limit => 4
    t.string "tag",             :limit => 64
    t.string "prfx"
    t.date   "added"
    t.date   "deprecated"
    t.text   "comments"
  end

  create_table "lot_groups", :force => true do |t|
    t.string    "name",                                         :null => false
    t.text      "notes"
    t.boolean   "is_loan",                   :default => false, :null => false
    t.boolean   "outgoing_loan",             :default => false, :null => false
    t.string    "incoming_transaction_code"
    t.integer   "repository_id"
    t.text      "material_requested"
    t.date      "date_requested"
    t.date      "date_recieved"
    t.integer   "total_specimens_recieved"
    t.date      "loan_start_date"
    t.date      "loan_end_date"
    t.date      "specimens_returned_date"
    t.boolean   "loan_closed",               :default => false, :null => false
    t.string    "contact_name"
    t.string    "contact_email"
    t.string    "policy_page_url"
    t.text      "loan_notes"
    t.integer   "proj_id",                                      :null => false
    t.integer   "creator_id",                                   :null => false
    t.integer   "updator_id",                                   :null => false
    t.timestamp "updated_on",                                   :null => false
    t.timestamp "created_on",                                   :null => false
  end

  add_index "lot_groups", ["creator_id"], :name => "creator_id"
  add_index "lot_groups", ["proj_id"], :name => "proj_id"
  add_index "lot_groups", ["repository_id"], :name => "repository_id"
  add_index "lot_groups", ["updator_id"], :name => "updator_id"

  create_table "lot_groups_lots", :id => false, :force => true do |t|
    t.integer "lot_id",       :null => false
    t.integer "lot_group_id", :null => false
    t.text    "notes"
  end

  add_index "lot_groups_lots", ["lot_group_id"], :name => "lot_group_id"
  add_index "lot_groups_lots", ["lot_id"], :name => "lot_id"

  create_table "lots", :force => true do |t|
    t.integer   "otu_id",                                                   :null => false
    t.integer   "key_specimens",                         :default => 0,     :null => false
    t.integer   "value_specimens",                       :default => 0,     :null => false
    t.integer   "ce_id"
    t.text      "ce_labels"
    t.string    "rarity",                  :limit => 16
    t.string    "source_quality",          :limit => 16
    t.text      "notes"
    t.integer   "repository_id"
    t.boolean   "dna_usable",                            :default => true
    t.boolean   "mixed_lot",                             :default => false
    t.string    "sex",                     :limit => 64
    t.integer   "proj_id",                                                  :null => false
    t.integer   "creator_id",                                               :null => false
    t.integer   "updator_id",                                               :null => false
    t.timestamp "updated_on",                                               :null => false
    t.timestamp "created_on",                                               :null => false
    t.string    "stage"
    t.string    "disposition"
    t.integer   "preparation_protocol_id"
    t.boolean   "is_public",                             :default => true
  end

  add_index "lots", ["creator_id"], :name => "creator_id"
  add_index "lots", ["otu_id"], :name => "otu_id_ind"
  add_index "lots", ["proj_id"], :name => "proj_id"
  add_index "lots", ["repository_id"], :name => "repository_id_ind"
  add_index "lots", ["updator_id"], :name => "updator_id"

  create_table "measurements", :force => true do |t|
    t.integer   "specimen_id",                     :null => false
    t.float     "measurement"
    t.integer   "standard_view_id",                :null => false
    t.string    "units",             :limit => 12
    t.float     "conversion_factor"
    t.integer   "proj_id",                         :null => false
    t.integer   "creator_id",                      :null => false
    t.integer   "updator_id",                      :null => false
    t.timestamp "updated_on",                      :null => false
    t.timestamp "created_on",                      :null => false
  end

  add_index "measurements", ["creator_id"], :name => "creator_id"
  add_index "measurements", ["proj_id"], :name => "proj_id"
  add_index "measurements", ["specimen_id"], :name => "specimen_id"
  add_index "measurements", ["standard_view_id"], :name => "standard_view_id"
  add_index "measurements", ["updator_id"], :name => "updator_id"

  create_table "mxes", :force => true do |t|
    t.string    "name"
    t.text      "revision_history"
    t.text      "notes"
    t.text      "web_description"
    t.boolean   "is_multikey",      :default => false
    t.boolean   "is_public",        :default => false
    t.integer   "proj_id",                             :null => false
    t.integer   "creator_id",                          :null => false
    t.integer   "updator_id",                          :null => false
    t.timestamp "updated_on",                          :null => false
    t.timestamp "created_on",                          :null => false
  end

  add_index "mxes", ["creator_id"], :name => "creator_id"
  add_index "mxes", ["proj_id"], :name => "proj_id"
  add_index "mxes", ["updator_id"], :name => "updator_id"

  create_table "mxes_minus_chrs", :force => true do |t|
    t.integer "chr_id", :null => false
    t.integer "mx_id",  :null => false
  end

  add_index "mxes_minus_chrs", ["chr_id"], :name => "chr_id_ind"
  add_index "mxes_minus_chrs", ["mx_id"], :name => "mx_id_ind"

  create_table "mxes_minus_otus", :force => true do |t|
    t.integer "mx_id",  :null => false
    t.integer "otu_id", :null => false
  end

  create_table "mxes_otu_groups", :id => false, :force => true do |t|
    t.integer "mx_id",        :null => false
    t.integer "otu_group_id", :null => false
  end

  create_table "mxes_otus", :force => true do |t|
    t.integer   "mx_id",      :null => false
    t.integer   "otu_id",     :null => false
    t.text      "notes"
    t.integer   "position"
    t.integer   "creator_id", :null => false
    t.integer   "updator_id", :null => false
    t.timestamp "updated_on", :null => false
    t.timestamp "created_on", :null => false
  end

  add_index "mxes_otus", ["creator_id"], :name => "creator_id"
  add_index "mxes_otus", ["mx_id", "otu_id"], :name => "mx_id", :unique => true
  add_index "mxes_otus", ["mx_id"], :name => "mx_id_ind"
  add_index "mxes_otus", ["otu_id"], :name => "otu_id_ind"
  add_index "mxes_otus", ["updator_id"], :name => "updator_id"

  create_table "mxes_plus_chrs", :force => true do |t|
    t.integer "chr_id", :null => false
    t.integer "mx_id",  :null => false
  end

  add_index "mxes_plus_chrs", ["chr_id"], :name => "chr_id_ind"
  add_index "mxes_plus_chrs", ["mx_id"], :name => "mx_id_ind"

  create_table "mxes_plus_otus", :force => true do |t|
    t.integer "mx_id",  :null => false
    t.integer "otu_id", :null => false
  end

  create_table "namespaces", :force => true do |t|
    t.string    "name",                                 :null => false
    t.string    "owner"
    t.text      "notes"
    t.string    "short_name",                           :null => false
    t.datetime  "last_loaded_on"
    t.integer   "creator_id",                           :null => false
    t.integer   "updator_id",                           :null => false
    t.timestamp "updated_on",                           :null => false
    t.timestamp "created_on",                           :null => false
    t.boolean   "is_admin_use_only", :default => false
  end

  add_index "namespaces", ["creator_id"], :name => "creator_id"
  add_index "namespaces", ["updator_id"], :name => "updator_id"

  create_table "news", :force => true do |t|
    t.string    "news_type"
    t.text      "body"
    t.date      "expires_on"
    t.integer   "proj_id"
    t.string    "title"
    t.boolean   "is_public",  :default => false, :null => false
    t.integer   "creator_id",                    :null => false
    t.integer   "updator_id",                    :null => false
    t.timestamp "updated_on",                    :null => false
    t.timestamp "created_on",                    :null => false
  end

  add_index "news", ["creator_id"], :name => "creator_id"
  add_index "news", ["proj_id"], :name => "proj_id"
  add_index "news", ["updator_id"], :name => "updator_id"

  create_table "object_relationships", :force => true do |t|
    t.string    "interaction"
    t.string    "complement"
    t.text      "notes"
    t.integer   "position"
    t.integer   "proj_id",                                           :null => false
    t.integer   "creator_id",                                        :null => false
    t.integer   "updator_id",                                        :null => false
    t.timestamp "updated_on",                                        :null => false
    t.timestamp "created_on",                                        :null => false
    t.string    "html_color",        :limit => 6
    t.boolean   "is_transitive"
    t.boolean   "is_reflexive"
    t.boolean   "is_anti_symmetric"
    t.string    "xref"
    t.boolean   "is_symmetric",                   :default => false
    t.boolean   "is_irreflexive",                 :default => false
  end

  add_index "object_relationships", ["complement"], :name => "index_object_relationships_on_complement"
  add_index "object_relationships", ["creator_id"], :name => "creator_id"
  add_index "object_relationships", ["interaction"], :name => "index_object_relationships_on_interaction"
  add_index "object_relationships", ["position", "proj_id"], :name => "index_object_relationships_on_position_and_proj_id"
  add_index "object_relationships", ["proj_id", "interaction", "complement"], :name => "proj_int_comp", :unique => true
  add_index "object_relationships", ["updator_id"], :name => "updator_id"

  create_table "ontology_classes", :force => true do |t|
    t.text      "definition"
    t.integer   "highest_applicable_taxon_name_id"
    t.integer   "obo_label_id"
    t.integer   "written_by_ref_id"
    t.boolean   "is_public",                        :default => true
    t.string    "xref"
    t.integer   "proj_id",                                             :null => false
    t.integer   "creator_id",                                          :null => false
    t.integer   "updator_id",                                          :null => false
    t.timestamp "created_on",                                          :null => false
    t.timestamp "updated_on",                                          :null => false
    t.text      "genus_differentia_definition"
    t.text      "illustration_IP_votes"
    t.boolean   "is_obsolete",                      :default => false
    t.text      "is_obsolete_reason"
    t.boolean   "relationships_are_sufficient",     :default => false
  end

  add_index "ontology_classes", ["creator_id"], :name => "creator_id"
  add_index "ontology_classes", ["highest_applicable_taxon_name_id"], :name => "highest_applicable_taxon_name_id"
  add_index "ontology_classes", ["id", "xref", "obo_label_id"], :name => "index_ontology_classes_on_id_and_dbxref_and_obo_label_id"
  add_index "ontology_classes", ["obo_label_id"], :name => "obo_label_id"
  add_index "ontology_classes", ["proj_id"], :name => "proj_id"
  add_index "ontology_classes", ["updator_id"], :name => "updator_id"
  add_index "ontology_classes", ["written_by_ref_id"], :name => "written_by_ref_id"
  add_index "ontology_classes", ["xref", "obo_label_id"], :name => "index_ontology_classes_on_dbxref_and_obo_label_id"
  add_index "ontology_classes", ["xref"], :name => "index_ontology_classes_on_dbxref"

  create_table "ontology_compositions", :force => true do |t|
    t.integer "genus_id", :null => false
  end

  create_table "ontology_relationships", :force => true do |t|
    t.integer   "ontology_class1_id",     :null => false
    t.integer   "ontology_class2_id",     :null => false
    t.integer   "object_relationship_id", :null => false
    t.integer   "proj_id",                :null => false
    t.integer   "creator_id",             :null => false
    t.integer   "updator_id",             :null => false
    t.timestamp "updated_on",             :null => false
    t.timestamp "created_on",             :null => false
  end

  add_index "ontology_relationships", ["creator_id"], :name => "creator_id"
  add_index "ontology_relationships", ["object_relationship_id", "ontology_class1_id", "ontology_class2_id"], :name => "classes_and_relationship", :unique => true
  add_index "ontology_relationships", ["ontology_class1_id", "ontology_class2_id"], :name => "classes_index"
  add_index "ontology_relationships", ["ontology_class2_id"], :name => "ontology_class2_id"
  add_index "ontology_relationships", ["proj_id"], :name => "proj_id"
  add_index "ontology_relationships", ["updator_id"], :name => "updator_id"

  create_table "ontology_terms", :force => true do |t|
    t.string "uri",                           :null => false
    t.string "label"
    t.string "bioportal_ontology_identifier"
  end

  create_table "otu_groups", :force => true do |t|
    t.string    "name",       :limit => 64
    t.boolean   "is_public"
    t.integer   "proj_id",                  :null => false
    t.integer   "creator_id",               :null => false
    t.integer   "updator_id",               :null => false
    t.timestamp "updated_on",               :null => false
    t.timestamp "created_on",               :null => false
  end

  add_index "otu_groups", ["creator_id"], :name => "creator_id"
  add_index "otu_groups", ["proj_id"], :name => "proj_id"
  add_index "otu_groups", ["updator_id"], :name => "updator_id"

  create_table "otu_groups_otus", :force => true do |t|
    t.integer "otu_group_id", :null => false
    t.integer "otu_id",       :null => false
    t.integer "position"
  end

  add_index "otu_groups_otus", ["otu_group_id"], :name => "otu_group_id_ind"
  add_index "otu_groups_otus", ["otu_id"], :name => "otu_id_ind"

  create_table "otus", :force => true do |t|
    t.integer   "taxon_name_id"
    t.boolean   "is_child",                      :default => false
    t.string    "name"
    t.string    "manuscript_name"
    t.string    "matrix_name",     :limit => 64
    t.integer   "as_cited_in"
    t.string    "iczn_group",      :limit => 32
    t.integer   "syn_with_otu_id"
    t.string    "sensu"
    t.text      "notes"
    t.integer   "proj_id",                                          :null => false
    t.integer   "creator_id",                                       :null => false
    t.integer   "updator_id",                                       :null => false
    t.timestamp "updated_on",                                       :null => false
    t.timestamp "created_on",                                       :null => false
  end

  add_index "otus", ["as_cited_in"], :name => "as_cited_in_ind"
  add_index "otus", ["creator_id"], :name => "creator_id"
  add_index "otus", ["proj_id"], :name => "proj_id"
  add_index "otus", ["syn_with_otu_id"], :name => "syn_with_otu_id"
  add_index "otus", ["taxon_name_id"], :name => "taxon_name_id_ind"
  add_index "otus", ["updator_id"], :name => "updator_id"

  create_table "pcrs", :force => true do |t|
    t.integer   "extract_id"
    t.integer   "fwd_primer_id"
    t.integer   "rev_primer_id"
    t.integer   "protocol_id"
    t.integer   "gel_image_id"
    t.integer   "lane",          :limit => 1
    t.string    "done_by"
    t.text      "notes"
    t.integer   "proj_id",                    :null => false
    t.integer   "creator_id",                 :null => false
    t.integer   "updator_id",                 :null => false
    t.timestamp "updated_on",                 :null => false
    t.timestamp "created_on",                 :null => false
    t.integer   "confidence_id"
  end

  add_index "pcrs", ["confidence_id"], :name => "index_pcrs_on_confidence_id"
  add_index "pcrs", ["creator_id"], :name => "creator_id"
  add_index "pcrs", ["extract_id"], :name => "extract_id_ind"
  add_index "pcrs", ["fwd_primer_id"], :name => "fwd_primer_id_ind"
  add_index "pcrs", ["gel_image_id"], :name => "gel_image_id"
  add_index "pcrs", ["proj_id"], :name => "proj_id"
  add_index "pcrs", ["rev_primer_id"], :name => "rev_primer_id_ind"
  add_index "pcrs", ["updator_id"], :name => "updator_id"

  create_table "pdfs", :force => true do |t|
    t.integer "parent_id"
    t.string  "content_type"
    t.string  "filename",     :limit => 1024
    t.integer "size"
    t.boolean "is_ocred"
  end

  create_table "people", :force => true do |t|
    t.string    "last_name",                                           :default => "",    :null => false
    t.string    "first_name",                           :limit => 100, :default => "",    :null => false
    t.string    "middle_name",                          :limit => 100
    t.string    "login",                                :limit => 32
    t.string    "password",                             :limit => 40
    t.boolean   "is_admin",                                            :default => false, :null => false
    t.boolean   "creates_projects",                                    :default => false, :null => false
    t.string    "email"
    t.timestamp "updated_on",                                                             :null => false
    t.timestamp "created_on",                                                             :null => false
    t.integer   "pref_mx_display_width",                :limit => 3,   :default => 20
    t.integer   "pref_mx_display_height",               :limit => 3,   :default => 10
    t.string    "pref_creator_html_color",              :limit => 6
    t.boolean   "is_ontology_admin"
    t.integer   "pref_default_repository_id"
    t.boolean   "pref_receive_reference_update_emails",                :default => false
  end

  add_index "people", ["is_admin"], :name => "is_admin_ind"
  add_index "people", ["last_name", "first_name", "middle_name"], :name => "last_name", :unique => true
  add_index "people", ["login"], :name => "login", :unique => true
  add_index "people", ["login"], :name => "login_ind"
  add_index "people", ["password"], :name => "password_ind"

  create_table "people_projs", :id => false, :force => true do |t|
    t.integer "person_id", :null => false
    t.integer "proj_id",   :null => false
  end

  add_index "people_projs", ["person_id"], :name => "person_id_ind"
  add_index "people_projs", ["proj_id"], :name => "proj_id_ind"

  create_table "people_taxon_names", :id => false, :force => true do |t|
    t.integer "person_id",     :null => false
    t.integer "taxon_name_id", :null => false
  end

  add_index "people_taxon_names", ["taxon_name_id"], :name => "taxon_name_id"

  create_table "phenotypes", :force => true do |t|
    t.string  "type"
    t.integer "entity_id"
    t.string  "entity_type"
    t.integer "within_entity_id"
    t.string  "within_entity_type"
    t.boolean "is_present"
    t.integer "minimum"
    t.integer "maximum"
    t.integer "quality_id"
    t.string  "quality_type"
    t.integer "dependent_entity_id"
    t.string  "dependent_entity_type"
    t.float   "relative_proportion"
    t.string  "relative_magnitude"
    t.integer "relative_entity_id"
    t.string  "relative_entity_type"
    t.integer "relative_quality_id"
    t.string  "relative_quality_type"
  end

  create_table "primers", :force => true do |t|
    t.integer   "gene_id"
    t.string    "name",          :limit => 64
    t.string    "sequence"
    t.string    "regex"
    t.integer   "ref_id"
    t.integer   "protocol_id"
    t.text      "notes"
    t.string    "designed_by"
    t.integer   "target_otu_id"
    t.integer   "proj_id",                     :null => false
    t.integer   "creator_id",                  :null => false
    t.integer   "updator_id",                  :null => false
    t.timestamp "updated_on",                  :null => false
    t.timestamp "created_on",                  :null => false
  end

  add_index "primers", ["creator_id"], :name => "creator_id"
  add_index "primers", ["gene_id"], :name => "gene_id_ind"
  add_index "primers", ["proj_id"], :name => "proj_id"
  add_index "primers", ["protocol_id"], :name => "protocol_id"
  add_index "primers", ["ref_id"], :name => "ref_id"
  add_index "primers", ["sequence", "gene_id", "proj_id"], :name => "sequence", :unique => true
  add_index "primers", ["target_otu_id"], :name => "target_otu_id"
  add_index "primers", ["updator_id"], :name => "updator_id"

  create_table "projs", :force => true do |t|
    t.string    "name",                                                                       :null => false
    t.text      "hidden_tabs"
    t.string    "public_server_name"
    t.string    "unix_name",                                :limit => 32
    t.text      "public_controllers"
    t.string    "public_tn_criteria",                       :limit => 32
    t.integer   "default_institution_repository_id"
    t.string    "starting_tab",                             :limit => 32, :default => "otus"
    t.integer   "default_ontology_id"
    t.integer   "default_content_template_id"
    t.string    "gmaps_API_key",                            :limit => 90
    t.integer   "creator_id",                                                                 :null => false
    t.integer   "updator_id",                                                                 :null => false
    t.timestamp "updated_on",                                                                 :null => false
    t.timestamp "created_on",                                                                 :null => false
    t.string    "ontology_namespace",                       :limit => 32
    t.integer   "default_ontology_class_id"
    t.text      "obo_remark"
    t.integer   "ontology_inclusion_keyword_id"
    t.integer   "ontology_exclusion_keyword_id"
    t.integer   "default_specimen_identifier_namespace_id"
    t.string    "default_license"
    t.string    "api_name"
    t.string    "default_copyright_holder"
    t.boolean   "is_eol_exportable",                                      :default => false
    t.string    "collection_code"
    t.boolean   "is_exportable_to_gbif",                                  :default => false
  end

  add_index "projs", ["creator_id"], :name => "creator_id"
  add_index "projs", ["default_content_template_id"], :name => "default_content_template_id"
  add_index "projs", ["default_institution_repository_id"], :name => "repository_id"
  add_index "projs", ["default_ontology_class_id"], :name => "index_projs_on_default_ontology_term_id"
  add_index "projs", ["default_ontology_id"], :name => "default_ontology_id"
  add_index "projs", ["public_server_name"], :name => "public_server_name"
  add_index "projs", ["updator_id"], :name => "updator_id"

  create_table "projs_refs", :force => true do |t|
    t.integer "proj_id",  :null => false
    t.integer "ref_id",   :null => false
    t.integer "position"
  end

  add_index "projs_refs", ["proj_id", "ref_id"], :name => "proj_id", :unique => true
  add_index "projs_refs", ["proj_id", "ref_id"], :name => "projs_refs_index", :unique => true
  add_index "projs_refs", ["proj_id"], :name => "proj_id_2"
  add_index "projs_refs", ["ref_id"], :name => "ref_id"

  create_table "projs_taxon_names", :force => true do |t|
    t.integer "proj_id",                          :null => false
    t.integer "taxon_name_id",                    :null => false
    t.boolean "is_public",     :default => false, :null => false
  end

  add_index "projs_taxon_names", ["proj_id", "taxon_name_id"], :name => "proj_id_2"
  add_index "projs_taxon_names", ["proj_id"], :name => "proj_id"
  add_index "projs_taxon_names", ["taxon_name_id"], :name => "taxon_name_id"

  create_table "protocol_steps", :force => true do |t|
    t.integer "protocol_id",                     :null => false
    t.text    "description"
    t.string  "reagent"
    t.string  "reagent_quanitity", :limit => 64
    t.string  "step_time",         :limit => 64
    t.integer "step_order"
    t.float   "step_temp"
    t.integer "step_cycles"
  end

  add_index "protocol_steps", ["protocol_id"], :name => "protocol_id_ind"

  create_table "protocols", :force => true do |t|
    t.string    "kind",        :limit => 10
    t.text      "description"
    t.integer   "proj_id",                   :null => false
    t.integer   "creator_id",                :null => false
    t.integer   "updator_id",                :null => false
    t.timestamp "updated_on",                :null => false
    t.timestamp "created_on",                :null => false
  end

  add_index "protocols", ["creator_id"], :name => "creator_id"
  add_index "protocols", ["proj_id"], :name => "proj_id"
  add_index "protocols", ["updator_id"], :name => "updator_id"

  create_table "refs", :force => true do |t|
    t.integer   "namespace_id"
    t.integer   "external_id"
    t.integer   "serial_id"
    t.integer   "valid_ref_id"
    t.integer   "language_id"
    t.integer   "pdf_id"
    t.integer   "year",                :limit => 2
    t.string    "year_letter"
    t.string    "ref_type",            :limit => 50
    t.text      "title"
    t.string    "volume"
    t.string    "issue"
    t.string    "pages"
    t.string    "pg_start",            :limit => 8
    t.string    "pg_end",              :limit => 8
    t.text      "book_title"
    t.string    "city"
    t.string    "publisher"
    t.string    "institution"
    t.string    "date"
    t.text      "notes"
    t.boolean   "is_public",                               :default => false
    t.text      "full_citation"
    t.text      "temp_citation"
    t.string    "cached_display_name", :limit => 2047
    t.string    "short_citation"
    t.string    "author"
    t.string    "journal"
    t.integer   "creator_id",                                                 :null => false
    t.integer   "updator_id",                                                 :null => false
    t.timestamp "updated_on",                                                 :null => false
    t.timestamp "created_on",                                                 :null => false
    t.text      "ocr_text",            :limit => 16777215
  end

  add_index "refs", ["author"], :name => "author_ind"
  add_index "refs", ["cached_display_name"], :name => "display_name_ind", :length => {"cached_display_name"=>10}
  add_index "refs", ["creator_id"], :name => "creator_id"
  add_index "refs", ["external_id"], :name => "external_id"
  add_index "refs", ["language_id"], :name => "language_id"
  add_index "refs", ["namespace_id", "external_id"], :name => "namespace_id_3", :unique => true
  add_index "refs", ["namespace_id"], :name => "namespace_id"
  add_index "refs", ["namespace_id"], :name => "namespace_id_2"
  add_index "refs", ["pdf_id"], :name => "pdf_id"
  add_index "refs", ["serial_id"], :name => "serial_id"
  add_index "refs", ["updator_id"], :name => "updator_id"
  add_index "refs", ["year"], :name => "year_ind"

  create_table "repositories", :force => true do |t|
    t.text      "name",                             :null => false
    t.string    "coden",              :limit => 12
    t.text      "url"
    t.integer   "synonymous_with_id"
    t.integer   "creator_id",                       :null => false
    t.integer   "updator_id",                       :null => false
    t.timestamp "updated_on",                       :null => false
    t.timestamp "created_on",                       :null => false
  end

  add_index "repositories", ["coden"], :name => "codon", :unique => true
  add_index "repositories", ["creator_id"], :name => "creator_id"
  add_index "repositories", ["synonymous_with_id"], :name => "synonymous_with_id"
  add_index "repositories", ["updator_id"], :name => "updator_id"

  create_table "sensus", :force => true do |t|
    t.integer  "ref_id",                                      :null => false
    t.integer  "label_id",                                    :null => false
    t.integer  "proj_id",                                     :null => false
    t.text     "notes"
    t.integer  "creator_id",                                  :null => false
    t.integer  "updator_id",                                  :null => false
    t.datetime "created_on",                                  :null => false
    t.datetime "updated_on",                                  :null => false
    t.integer  "confidence_id"
    t.integer  "position",                 :default => 0
    t.text     "preferred_label_IP_votes"
    t.boolean  "preferred_by_ref",         :default => false
    t.integer  "ontology_class_id",                           :null => false
  end

  add_index "sensus", ["label_id"], :name => "index_sensus_on_label_id"
  add_index "sensus", ["ontology_class_id", "label_id", "ref_id"], :name => "index_sensus_on_ontology_class_id_and_label_id_and_ref_id", :unique => true
  add_index "sensus", ["ontology_class_id", "label_id"], :name => "index_sensus_on_ontology_class_id_and_label_id"
  add_index "sensus", ["ref_id"], :name => "index_sensus_on_ref_id"

  create_table "seqs", :force => true do |t|
    t.integer   "gene_id"
    t.integer   "specimen_id"
    t.string    "type_of_voucher",    :limit => 32
    t.integer   "otu_id"
    t.string    "genbank_identifier", :limit => 24
    t.integer   "ref_id"
    t.text      "sequence"
    t.boolean   "attempt_complete",                 :default => false
    t.string    "assigned_to",        :limit => 64
    t.text      "notes"
    t.string    "status",             :limit => 32
    t.integer   "proj_id",                                             :null => false
    t.integer   "creator_id",                                          :null => false
    t.integer   "updator_id",                                          :null => false
    t.timestamp "updated_on",                                          :null => false
    t.timestamp "created_on",                                          :null => false
    t.integer   "pcr_id"
  end

  add_index "seqs", ["creator_id"], :name => "creator_id"
  add_index "seqs", ["gene_id"], :name => "gene_id_ind"
  add_index "seqs", ["otu_id"], :name => "out_id_ind"
  add_index "seqs", ["pcr_id"], :name => "index_seqs_on_pcr_id"
  add_index "seqs", ["proj_id"], :name => "proj_id"
  add_index "seqs", ["specimen_id"], :name => "specimen_id"
  add_index "seqs", ["updator_id"], :name => "updator_id"

  create_table "serials", :force => true do |t|
    t.string    "name",               :limit => 1024
    t.string    "city"
    t.string    "atTAMU",             :limit => 12
    t.text      "notes"
    t.text      "URL"
    t.string    "call_num"
    t.string    "abbreviation"
    t.integer   "synonymous_with_id"
    t.integer   "language_id"
    t.integer   "namespace_id"
    t.integer   "external_id"
    t.string    "issn_print",         :limit => 10
    t.integer   "creator_id",                         :null => false
    t.integer   "updator_id",                         :null => false
    t.timestamp "updated_on",                         :null => false
    t.timestamp "created_on",                         :null => false
    t.string    "issn_digital"
  end

  add_index "serials", ["creator_id"], :name => "creator_id"
  add_index "serials", ["language_id"], :name => "language_id"
  add_index "serials", ["name"], :name => "name", :length => {"name"=>100}
  add_index "serials", ["namespace_id", "external_id"], :name => "namespace_id", :unique => true
  add_index "serials", ["namespace_id"], :name => "namespace_ind"
  add_index "serials", ["synonymous_with_id"], :name => "synonymous_with_id"
  add_index "serials", ["updator_id"], :name => "updator_id"

  create_table "sessions", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "data",       :limit => 2147483647
    t.string   "session_id"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "specimen_determinations", :force => true do |t|
    t.integer   "specimen_id"
    t.integer   "otu_id"
    t.boolean   "current_det",         :default => true
    t.string    "determiner"
    t.string    "name"
    t.datetime  "det_on",                                :null => false
    t.integer   "confidence_id"
    t.string    "determination_basis"
    t.integer   "creator_id",                            :null => false
    t.integer   "updator_id",                            :null => false
    t.timestamp "updated_on",                            :null => false
    t.timestamp "created_on",                            :null => false
    t.integer   "proj_id",                               :null => false
  end

  add_index "specimen_determinations", ["confidence_id"], :name => "confidence_id_ind"
  add_index "specimen_determinations", ["creator_id"], :name => "creator_id"
  add_index "specimen_determinations", ["otu_id"], :name => "otu_id_ind"
  add_index "specimen_determinations", ["proj_id"], :name => "proj_id"
  add_index "specimen_determinations", ["specimen_id"], :name => "specimen_id_ind"
  add_index "specimen_determinations", ["updator_id"], :name => "updator_id"

  create_table "specimens", :force => true do |t|
    t.integer   "ce_id"
    t.text      "temp_ce"
    t.integer   "parent_specimen_id"
    t.integer   "repository_id"
    t.boolean   "dna_usable",                            :default => false
    t.text      "notes"
    t.string    "sex",                     :limit => 64
    t.string    "stage",                   :limit => 64
    t.integer   "proj_id",                                                  :null => false
    t.integer   "creator_id",                                               :null => false
    t.integer   "updator_id",                                               :null => false
    t.timestamp "updated_on",                                               :null => false
    t.timestamp "created_on",                                               :null => false
    t.string    "disposition"
    t.integer   "preparation_protocol_id"
    t.boolean   "is_public",                             :default => true
  end

  add_index "specimens", ["ce_id"], :name => "ce_id_ind"
  add_index "specimens", ["creator_id"], :name => "creator_id"
  add_index "specimens", ["parent_specimen_id"], :name => "parent_specimen_id_ind"
  add_index "specimens", ["proj_id"], :name => "proj_id"
  add_index "specimens", ["repository_id"], :name => "repository_id_ind"
  add_index "specimens", ["updator_id"], :name => "updator_id"

  create_table "standard_view_groups", :force => true do |t|
    t.string    "name",                           :null => false
    t.text      "notes"
    t.string    "other_identifier", :limit => 32
    t.integer   "proj_id",                        :null => false
    t.timestamp "updated_on",                     :null => false
    t.timestamp "created_on",                     :null => false
    t.integer   "creator_id",                     :null => false
    t.integer   "updator_id",                     :null => false
  end

  add_index "standard_view_groups", ["creator_id"], :name => "creator_id"
  add_index "standard_view_groups", ["proj_id"], :name => "proj_id"
  add_index "standard_view_groups", ["updator_id"], :name => "updator_id"

  create_table "standard_view_groups_standard_views", :id => false, :force => true do |t|
    t.integer "standard_view_id",       :null => false
    t.integer "standard_view_group_id", :null => false
    t.integer "proj_id",                :null => false
    t.integer "sort"
  end

  add_index "standard_view_groups_standard_views", ["proj_id", "standard_view_group_id", "standard_view_id"], :name => "proj_id", :unique => true
  add_index "standard_view_groups_standard_views", ["proj_id"], :name => "proj_id_2"
  add_index "standard_view_groups_standard_views", ["standard_view_group_id"], :name => "standard_view_group_id"
  add_index "standard_view_groups_standard_views", ["standard_view_id"], :name => "standard_view_id"

  create_table "standard_views", :force => true do |t|
    t.string    "name",                :limit => 64
    t.integer   "image_view_id"
    t.string    "stage",               :limit => 32
    t.string    "sex",                 :limit => 32
    t.text      "notes"
    t.integer   "proj_id",                           :null => false
    t.timestamp "updated_on",                        :null => false
    t.timestamp "created_on",                        :null => false
    t.integer   "creator_id",                        :null => false
    t.integer   "updator_id",                        :null => false
    t.text      "formula"
    t.string    "ontology_class_xref"
  end

  add_index "standard_views", ["creator_id"], :name => "creator_id"
  add_index "standard_views", ["name", "proj_id"], :name => "name", :unique => true
  add_index "standard_views", ["ontology_class_xref"], :name => "index_standard_views_on_ontology_class_dbxref"
  add_index "standard_views", ["proj_id"], :name => "proj_id_2"
  add_index "standard_views", ["updator_id"], :name => "updator_id"

  create_table "tags", :force => true do |t|
    t.integer   "keyword_id"
    t.integer   "addressable_id"
    t.string    "addressable_type",  :limit => 64
    t.text      "notes"
    t.integer   "ref_id"
    t.string    "pages"
    t.string    "pg_start",          :limit => 8
    t.string    "pg_end",            :limit => 8
    t.integer   "proj_id",                         :null => false
    t.integer   "creator_id",                      :null => false
    t.integer   "updator_id",                      :null => false
    t.timestamp "updated_on",                      :null => false
    t.timestamp "created_on",                      :null => false
    t.string    "referenced_object"
  end

  add_index "tags", ["addressable_id", "addressable_type", "keyword_id", "proj_id", "ref_id"], :name => "all"
  add_index "tags", ["addressable_id", "addressable_type", "keyword_id", "ref_id"], :name => "all_minus_proj"
  add_index "tags", ["addressable_id", "addressable_type", "keyword_id"], :name => "addressable_with_keywords"
  add_index "tags", ["addressable_id", "addressable_type"], :name => "addressable"
  add_index "tags", ["addressable_id"], :name => "addressable_id"
  add_index "tags", ["addressable_type"], :name => "addressable_type", :length => {"addressable_type"=>4}
  add_index "tags", ["creator_id"], :name => "creator_id"
  add_index "tags", ["keyword_id"], :name => "keyword_id_2"
  add_index "tags", ["proj_id"], :name => "proj_id"
  add_index "tags", ["ref_id"], :name => "ref_id"
  add_index "tags", ["referenced_object"], :name => "index_tags_on_referenced_object"
  add_index "tags", ["updator_id"], :name => "updator_id"

  create_table "taxon_hists", :force => true do |t|
    t.integer   "taxon_name_id",                      :null => false
    t.integer   "higher_id"
    t.integer   "genus_id"
    t.integer   "subgenus_id"
    t.integer   "species_id"
    t.integer   "subspecies_id"
    t.string    "author"
    t.string    "year",                 :limit => 6
    t.integer   "varietal_id"
    t.string    "varietal_usage",       :limit => 24
    t.integer   "ref_id"
    t.string    "ref_page",             :limit => 64
    t.integer   "taxon_name_status_id"
    t.text      "notes"
    t.integer   "creator_id",                         :null => false
    t.integer   "updator_id",                         :null => false
    t.timestamp "updated_on",                         :null => false
    t.timestamp "created_on",                         :null => false
  end

  add_index "taxon_hists", ["creator_id"], :name => "creator_id"
  add_index "taxon_hists", ["genus_id"], :name => "genus_id"
  add_index "taxon_hists", ["higher_id"], :name => "higher_id"
  add_index "taxon_hists", ["ref_id"], :name => "ref_id"
  add_index "taxon_hists", ["species_id"], :name => "species_id"
  add_index "taxon_hists", ["subgenus_id"], :name => "subgenus_id"
  add_index "taxon_hists", ["subspecies_id"], :name => "subspecies_id"
  add_index "taxon_hists", ["taxon_name_id"], :name => "taxon_name_id"
  add_index "taxon_hists", ["taxon_name_id"], :name => "taxon_name_id_2"
  add_index "taxon_hists", ["taxon_name_status_id"], :name => "taxon_name_status_id"
  add_index "taxon_hists", ["updator_id"], :name => "updator_id"
  add_index "taxon_hists", ["varietal_id"], :name => "varietal_id"

  create_table "taxon_name_status", :force => true do |t|
    t.string    "status",      :limit => 128
    t.integer   "creator_id",                 :null => false
    t.integer   "updator_id",                 :null => false
    t.timestamp "updated_on",                 :null => false
    t.timestamp "created_on",                 :null => false
    t.string    "status_type"
  end

  add_index "taxon_name_status", ["creator_id"], :name => "creator_id"
  add_index "taxon_name_status", ["status"], :name => "status", :unique => true
  add_index "taxon_name_status", ["updator_id"], :name => "updator_id"

  create_table "taxon_names", :force => true do |t|
    t.string    "name",                                  :null => false
    t.string    "author",                 :limit => 128
    t.string    "year",                   :limit => 4
    t.boolean   "nominotypical_subgenus"
    t.integer   "parent_id"
    t.integer   "valid_name_id"
    t.integer   "namespace_id"
    t.integer   "external_id"
    t.integer   "taxon_name_status_id"
    t.integer   "l"
    t.integer   "r"
    t.integer   "orig_genus_id"
    t.integer   "orig_subgenus_id"
    t.integer   "orig_species_id"
    t.string    "iczn_group",             :limit => 8
    t.string    "type_type"
    t.integer   "type_count"
    t.string    "type_sex"
    t.integer   "type_repository_id"
    t.string    "type_repository_notes"
    t.integer   "type_geog_id"
    t.text      "type_locality"
    t.string    "type_notes"
    t.integer   "type_taxon_id"
    t.string    "type_by",                :limit => 64
    t.boolean   "type_lost"
    t.integer   "ref_id"
    t.string    "page_validated_on"
    t.string    "page_first_appearance"
    t.text      "notes"
    t.text      "import_notes"
    t.string    "cached_display_name"
    t.integer   "creator_id",                            :null => false
    t.integer   "updator_id",                            :null => false
    t.timestamp "updated_on",                            :null => false
    t.timestamp "created_on",                            :null => false
    t.string    "original_spelling"
    t.string    "agreement_name"
  end

  add_index "taxon_names", ["creator_id"], :name => "creator_id"
  add_index "taxon_names", ["external_id"], :name => "external_id"
  add_index "taxon_names", ["l"], :name => "l"
  add_index "taxon_names", ["name"], :name => "name"
  add_index "taxon_names", ["namespace_id", "external_id"], :name => "namespace_id", :unique => true
  add_index "taxon_names", ["namespace_id"], :name => "namespace_id_2"
  add_index "taxon_names", ["parent_id"], :name => "parent_id"
  add_index "taxon_names", ["r"], :name => "r"
  add_index "taxon_names", ["ref_id"], :name => "ref_id"
  add_index "taxon_names", ["taxon_name_status_id"], :name => "taxon_name_status_id"
  add_index "taxon_names", ["type_taxon_id"], :name => "type_taxon_id"
  add_index "taxon_names", ["updator_id"], :name => "updator_id"
  add_index "taxon_names", ["valid_name_id"], :name => "valid_name_id"

  create_table "term_exclusions", :force => true do |t|
    t.string   "name"
    t.integer  "count",      :default => 0
    t.integer  "proj_id"
    t.datetime "created_on"
    t.datetime "updated_on"
  end

  add_index "term_exclusions", ["name"], :name => "index_term_exclusions_on_name"

  create_table "terms", :force => true do |t|
    t.string   "name"
    t.integer  "proofer_ignored",                                    :default => 0
    t.integer  "proj_id"
    t.datetime "created_on"
    t.datetime "updated_on"
    t.boolean  "common",                                             :default => false
    t.integer  "common_votes",                                       :default => 0
    t.integer  "proofer_count",                                      :default => 0
    t.decimal  "common_threshold",    :precision => 10, :scale => 0, :default => 0
    t.text     "ontologize_IP_votes"
  end

  create_table "tree_nodes", :force => true do |t|
    t.integer "parent_id"
    t.integer "tree_id",                  :null => false
    t.string  "label"
    t.float   "branch_length"
    t.float   "cumulative_branch_length"
    t.integer "otu_id"
    t.integer "depth"
    t.integer "lft"
    t.integer "rgt"
  end

  add_index "tree_nodes", ["lft", "rgt"], :name => "lft_2"
  add_index "tree_nodes", ["lft"], :name => "lft"
  add_index "tree_nodes", ["otu_id"], :name => "otu_id"
  add_index "tree_nodes", ["parent_id"], :name => "parent_id"
  add_index "tree_nodes", ["rgt"], :name => "rgt"
  add_index "tree_nodes", ["tree_id"], :name => "tree_id"

  create_table "trees", :force => true do |t|
    t.text      "tree_string",    :limit => 2147483647
    t.string    "name"
    t.integer   "data_source_id"
    t.text      "notes"
    t.integer   "max_depth"
    t.integer   "proj_id",                              :null => false
    t.integer   "creator_id",                           :null => false
    t.integer   "updator_id",                           :null => false
    t.timestamp "updated_on",                           :null => false
    t.timestamp "created_on",                           :null => false
  end

  add_index "trees", ["creator_id"], :name => "creator_id"
  add_index "trees", ["data_source_id"], :name => "data_source_id"
  add_index "trees", ["proj_id"], :name => "proj_id"
  add_index "trees", ["updator_id"], :name => "updator_id"

  create_table "type_specimens", :force => true do |t|
    t.integer "specimen_id",                 :null => false
    t.integer "taxon_name_id"
    t.string  "type_type",     :limit => 24, :null => false
    t.text    "notes"
    t.integer "ref_id"
    t.integer "otu_id"
  end

  add_index "type_specimens", ["specimen_id", "taxon_name_id"], :name => "specimen_id_2", :unique => true
  add_index "type_specimens", ["specimen_id"], :name => "specimen_id"
  add_index "type_specimens", ["taxon_name_id"], :name => "taxon_name_id"

  create_table "versions", :force => true do |t|
    t.integer  "versioned_id"
    t.string   "versioned_type"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "user_name"
    t.text     "modifications"
    t.integer  "number"
    t.string   "tag"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "versions", ["created_at"], :name => "index_versions_on_created_at"
  add_index "versions", ["number"], :name => "index_versions_on_number"
  add_index "versions", ["tag"], :name => "index_versions_on_tag"
  add_index "versions", ["user_id", "user_type"], :name => "index_versions_on_user_id_and_user_type"
  add_index "versions", ["user_name"], :name => "index_versions_on_user_name"
  add_index "versions", ["versioned_id", "versioned_type"], :name => "index_versions_on_versioned_id_and_versioned_type"

  create_table "xyl_hosts", :force => true do |t|
    t.integer "taxon_name_id", :null => false
    t.string  "name"
  end

  add_index "xyl_hosts", ["taxon_name_id"], :name => "taxon_name_id"

  create_table "xyl_syn_errors", :id => false, :force => true do |t|
    t.integer "tax_id",      :null => false
    t.integer "external_id", :null => false
    t.string  "name"
    t.string  "genus"
  end

end
