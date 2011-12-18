Edge::Application.routes.draw do

  root :to => "projs#index"

  # matrix/coding routes
  match "/projects/:proj_id/mxes/:id/fast_code/:mode/:position/:otu_id/:chr_id/:chr_state_id", :controller => 'mxes', :action => "fast_code" , :constraints => { :id => /\d+/, :otu_id => /\d+/, :chr_id => /\d+/, :mode => /row|col/} # mode is "row" or "col"
  match "/projects/:proj_id/mxes/:id/fast_code/:mode/:position/:otu_id/:chr_id", :controller => 'mxes', :action => "fast_code", :constraints => { :id => /\d+/, :otu_id => /\d+/, :chr_id => /\d+/, :mode => /row|col/}


  # All non-RESTful routes that are unique to a Resource are defined here.
  # Shared restful routes (e.g. 'autocomplete_for_xxx') are defined together
  # below, and need not be included here.
  #
  #  Collections - add actions without :ids like otus/foo
  #  Members - add actions with :ids like otus/1/bar

  PRIVATE_RESOURCES = {

  'associations' => {
    members: %w{
    post destroy_part
  },
  collections: %w{
    get list_supporting_refs
    get association_tree
    get browse
    get browse_by_confidence
    get browse_by_object_relationship
    get browse_by_otu
    get browse_by_ref
    get browse_by_taxon_name
    get browse_by_year
    get browse_chronological
    get browse_confidences
    get browse_negatives
    get browse_objectrelationships
    get browse_otus
    get browse_refs
    get browse_show
    get browse_taxon_names
    get browse_unsupported
    get browse_untied
    get list_associations_by_confidence
    get list_associations_by_object_relationship
    get list_associations_by_otu
  }
  },

  'ces' => {
    members: %w{
    get show_material
    get clone
  },
    collections: %w{
    get auto_complete_for_ces
    get batch_create
    get batch_geocode
    get batch_load
    get batch_verify
    get create_from_gmap
    get find_similar
    get labels
    get labels_clear_to_zero
    get labels_print_preview
    get list
    get list_by_scope
    get list_params
    get new_fast
    get new_from_geocoder
    get new_from_gmap
    post batch_verify
  }
  },

  'chr_groups' => {
    members: %w{
    get add_ungrouped_characters
    get assign_chrs_without_groups
    get show_content_mapping
    get show_detailed
    post add_chr
    post make_default
    post move
    post remove_chr
    post sort_chrs
  },
    collections: %w{
    get chrs_without_groups
    post clear_default
    post reset_position
  }
  },

  'chr_states' => {
    members: %w{
    get show_figures
    post _in_place_notes_update
    post destroy_phenotype
    post set_chr_state_notes
  },
    collections: %w{}
  },

  'chromatograms' => {
    members: %w{
    get return_chromatograph_file
  },
    collections: %w{}
  },

  'chrs' => {
    members: %w{
  get _find_otus_for_mx
  get owl_export
  get show_coded_otus
  get show_edit_expanded
  get show_groups
  get show_merge_states
  get show_mxes
  get show_otus_for_state
  post _in_place_description_update
  post _in_place_notes_update
  post add_state
  post add_to_group
  post clone_chr
  post destroy_state
  post merge_states
  post position_chr
  post set_chr_doc_char_descr
  post set_chr_notes
  post update_state
  },
  collections: %w{
  get doc_export
  get list_all
  get list_by_char_group
  get list_chars_not_in_matrices
  get list_recent_changes_by_chr
  get list_recent_changes_by_chr_state
  get list_states
  post reset_order
  }
  },

  'claves' => {
    members: %w{
    post destroy_couplet
    post duplicate
    post edit_meta
    post insert_couplet
    post new_couplet
    post update_meta
    post delete_couplet
  },
    collections: %w{
    get	show_all
	  get show_all_print
  }
  },

  'codings' => {
    members: %w{},
    collections: %w{
    get owl_export
  }
  },

  'confidences' => {
    members: %w{
	  get popup
	  post merge
	  post sort_confidences
  	post apply_from_popup
  },
    collections: %w{}
  },


  'content_templates' => {
    members: %w{
    get show_page
    get add_remove_type
    post make_default
    post sort_content_types
  },
    collections: %w{}
  },

  'content_types' => {
    members: %w{},
    collections: %w{
    get list_by_type
  }
  },

  'contents' => {
    members: %w{
    get show_figures
  },
    collections: %w{
    get sync
    post publish_all
    post sync
  }
  },

  'data_sources' => {
    members: %w{
	  get show_convert
	  get show_file_contents
    post _delete_dataset
  },
    collections: %w{}
  },

  'distributions' => {
    members: %w{},
    collections: %w{}
  },

  'extracts' => {
    members: %w{},
    collections: %w{
    get summarize
    post tag_by_range
  }
  },

  'extracts_genes' => {
    members: %w{},
    collections: %w{
	  get popup
    post apply_from_popup
  }
  },

  'figure_markers' => {
    members: %w{
    get annotate
    get show_zoom
    get test
    post create_all_for_content_by_otu
    post down
    post draw_save
    post move
    post sort_figure_markers
    post up
    post update_marker
  },
    collections: %w{
    get draw
    get find_images
    get illustrate
    get list_by_scope
  }
  },

  'figures' => {
    members: %w{
    get up
    get down
    post draw_save
    get draw
    post update_marker
    get test
  },
    collections: %w{
    post find_images
    get create_al_content_for_otu
    get list_by_scope
    get move
    get illustrate
    get annotate
    get show_zoom
    get sort_figure_markers
  }
  },

  'gene_groups' => {
    members: %w{
    post add_gene
    post remove_gene
  },
    collections: %w{}
  },

  'genes' => {
    members: %w{},
    collections: %w{
    get sort
	  post sort_genes
  }
  },

  'geogs' => {
    members: %w{},
    collections: %w{}
  },

  'identifiers' => {
    members: %w{},
    collections: %w{}
  },

  'image_descriptions' => {
    members: %w{
	  post destroy_from_image
	  get more
  },
    collections: %w{
    get	add
	  post add_list
    post summarize
  }
  },

  'images' => {
    members: %w{
   get show_figure_markers
   get show_figures
   get show_image_descriptions
  },
  collections: %w{
   get auto_complete_for_images
   get browse_figure_markers
   get list_by_id
   get search_list
  }
  },

  'ipt_records' => {
    members: %w{},
    collections: %w{
    get download_by_ce
    get download_by_otu
    get download_by_taxon_name
    post serialize_by_ce
    post serialize_by_otu
    post serialize_by_taxon_name
  }
  },

  'keywords' => {
    members: %w{
    get show_tags
  },
    collections: %w{}
  },

  'labels' => {
    members: %w{
     get show_tags
  },
  collections: %w{
     get list_alpha
     get list_by_active_on
     get list_by_keyword
     get list_by_scope
     get list_homonyms
     get list_lbls_in_defs_wo_ontology_classes
     get list_params
     get list_simple_with_tags
     get list_synonyms
     get list_without_definitions
     get list_without_plural
  }
  },

  'languages' => {
    members: %w{},
    collections: %w{}
  },

  'lot_groups' => {
    members: %w{
     get show_members
     post	add_lot
     post remove_lot
  },
  collections: %w{
     get grand_summary
    }
  },

 'lots' => {
    members: %w{
    get gs
    post clone_to_specimen
    post destroy_identifier
    post divide
    post extract_specimen
  },
    collections: %w{
    get grand_summary
    get grand_summary_xsl
  }
  },

  'measurements' => {
    members: %w{},
    collections: %w{
    post batch_create
    get	batch_new
  }
  },

 'morphbank_images' => {
    members: %w{},
    collections: %w{
    get MB_batch_load
    get navigate
    post MB_batch_create
    post MB_batch_load
    post MB_batch_verify
    post _add_thumb
    post _set_otu_for_mb_cart
    post search
  }
  },

  'mxes' => {
    members: %w{
    get _cell_zoom
    get _get_window_params
    get _otu_zoom
    get as_file
    get auto_link
    get browse
    get current_cycle
    get cycle
    get excerpt
    get generate
    get highlight
    get invalid_codings
    get owl_export
    get show_ascii
    get show_batch_code
    get show_characters
    get show_code
    post show_code
    get show_data_sources
    get show_figures
    get show_nexus
    get show_otus
    get show_sort_characters
    get show_sort_otus
    get show_tnt
    get show_trees
    get show_unused_character_states
    get simple_format
    get sort_chrs
    get sort_otus
    get test
    post _set_overlay_preference
    post add_chr
    post add_otu
    post clone
    post code
    post remove_chr
    post remove_otu
    post reset_chr_positions
    post reset_cycle
    post reset_otu_positions
  },
    collections: %w{}
  },

 'namespaces' => {
    members: %w{},
    collections: %w{}
  },

  'news' => {
    members: %w{},
    collections: %w{
    get list_admin
  }
  },

  'object_relationships' => {
    members: %w{
   post	down
	 post up
  },
    collections: %w{}
  },

 'ontology_classes' => {
    members: %w{
    get _render_newick
    get show_figures
    get show_history
    get show_next_without
    get show_tags
    get show_visualize_newick
    post _in_place_definition_update
    post _populate_consituent_parts
    post generate_xref
    post set_ontology_class_definition
  },
    collections: %w{
    get list_by_missmatched_genus
    get list_by_scope
    get list_label_summary
    get list_params
    get list_simple_with_tags
    get list_tip_figures
  }
  },

  'ontology_compositions' => {
    members: %w{},
    collections: %w{}
  },

 'ontology_relationships' => {
    members: %w{},
    collections: %w{}
  },

  'otu_groups' => {
    members: %w{
    get show_collecting_events
    get show_content_grid
    get show_descriptions
    get show_extract_grid
    get show_extract_grid_by_extract
    get show_extract_grid_by_gene
    get show_images
    get show_material
    get show_verbose_specimens_examined
    post add_otu
    post make_default
    post remove_otu
    post sort_otus
  },
  collections: %w{
    get all_groups_summary
    get download_kml
    get edit_multiple_content
    get otus_without_groups
    get sort_by_select
    post clear_default
    post combine
    post update_content
    post update_multiple_content
  }
  },

  'otus' => {
    members: %w{
    get	_refresh_compare_content
    get _update_codings
    get _update_compare_content
    get _update_content_page
    get compare_params
    get edit_page
    get eol_test
    get preview_public_page
    get show_all_content
    get show_associations
    get show_codings
    get show_compare_content
    get show_content
    get show_distribution
    get show_groups
    get show_images
    get show_kml_text
    get show_map
    get show_material
    get show_material_examined
    get show_matrices
    get show_matrix_sync
    get show_molecular
    get show_params
    get show_summary
    get show_tags
    get show_tags_no_layout
    get test_modal
    get tree
    post add_to_otu_group
    post clone_or_transfer_template_content
    post move_images_to_otu
    post remove_from_otu_group
 },
 collections: %w{
  get batch_load
  get list_all
  get list_by_scope
  get list_params
  post batch_create
  post batch_verify
  post update_content_from_matrix_sync
  post update_edit_page
  }
  },

  'pcrs' => {
    members: %w{
    },
    collections: %w{
    get _batch_add_extracts_to_batch
    get _batch_add_extracts_to_batch_via_confidence
    get _batch_add_extracts_to_batch_via_tags
    get batch_pcr
    get list_by_scope
    get list_in_range
    post _add_extract_to_batch
    post _remove_extract_from_batch
    post _worksheet
    post list_in_range
  }
  },

  'people' => {
    members: %w{},
    collections: %w{}
  },

  'phenotypes' => {
    members: %w{
  },
    collections: %w{
    get edit
    get new_concrete_phenotype
    get new_differentia
    get new_term
    post create_composition
    post create_term
    post remove_ontology_value
    post update_count_phenotype
    post update_presence_absence_phenotype
    post update_qualitative_phenotype
    post update_relative_phenotype
  }
  },

  'primers' => {
    members: %w{},
    collections: %w{
    get show_by_gene
  }
  },

  'protocols' => {
    members: %w{
 	  post add_step
	  post remove_step
  },
    collections: %w{}
  },

  'public_contents' => {
    members: %w{},
    collections: %w{
    post unpublish
  }
  },

  'refs' => {
    members: %w{
  get auto_complete_for_ref_other_projs
  get endnote_batch_verify_or_create
  get link_search
  get ocr_text
  get show_associations
  get show_distributions
  get show_sensus
  get show_tags
  post _count_labels
  post create_tags_for_all_parts
  post delete_pdf
  post destroy_author
  post endnote_batch_verify_or_create
  post replace
  },
  collections: %w{
   get add
   get endnote
   get list_by_author
   get list_by_scope
   post add
   post sort_authors
   post update_all_proj_display_names
  }
  },

  'repositories' => {
    members: %w{},
    collections: %w{}
  },

  'sensus' => {
    members: %w{},
    collections: %w{
    get batch_load
	  get batch_verify_or_create
	  post batch_verify_or_create
    post sort_sensus
  }
  },

  'seqs' => {
    members: %w{
    },
    collections: %w{
    get create_multiple
    get list_by_scope
    get new_from_table
    get seqs_as_fasta_file
    get seqs_as_nexus
    get seqs_as_oneline
    get seqs_from_FASTA
    get summarize
    get verify_seqs_from_FASTA
    get view_query
    post _batch_add_FASTA
  }
  },

  'serials' => {
    members: %w{},
    collections: %w{
    get _add_ref_to_proj
    get _download_biostor
    get _show_params
    get find_many
    get match
    get show_all_refs
  }
  },

  'specimens' => {
    members: %w{
    get accordion
    get show_seqs
    get test
    post clone
    post destroy_determination
    post destroy_identifier
    post destroy_type_assignment
  },
  collections: %w{
   get batch_load
   get batch_verify_or_create
   get group
   get group_result_update
   get identifier_search
   get list_all
   get list_by_creator
   get list_by_current_user
   get list_by_id
   get quick_new
   post batch_verify_or_create
   post quick_create
   post search_by_identifier
  }
  },

  'standard_view_groups' => {
    members: %w{
   post add_standard_view
   post remove_standard_view
  },
  collections: %w{}
  },

  'standard_views' => {
    members: %w{},
    collections: %w{}
  },

  'tags' => {
    members: %w{
  get _popup_info
  post in_place_notes_update
  post set_tag_notes
  },
  collections: %w{
  get  list_by_keyword
  }
  },

  'taxon_hists' => {
    members: %w{},
    collections: %w{}
  },

  'taxon_names' => {
    members: %w{
    get download_taxon_name_report
    get report_ITIS_dump
    get report_taxon_names
    get show_all_children
    get show_images
    get show_immediate_child_otus
    get show_material
    get show_summary
    get show_tags
    get show_taxonomic_history
    get show_type_material
    get test
    post add_type
    post remove_type
  },
    collections: %w{
    get batch_load
    get batch_verify
    get search
    get search_list
    get visibility
    post batch_create
    post rebuild_cached_display_name
    post toggle_public
  }
  },

  'trees' => {
    members: %w{
    get _select_node
    get phylowidget
    get show_nested_set
    get show_phylowidget
    get test
    get test2
  },
    collections: %w{
  }
  },

  } # end PRIVATE_RESOURCES

  PUBLIC_RESOURCES = {
  'associations' => {
    members: %w{},
    collections: %w{
    get browse
    get browse_by_confidence
    get browse_by_object_relationship
    get browse_by_otu
    get browse_by_ref
    get browse_by_taxon_name
    get browse_by_year
    get browse_chronological
    get browse_confidences
    get browse_negatives
    get browse_object_relationships
    get browse_otus
    get browse_refs
    get browse_show
    get browse_taxon_names
    get browse_unsupported
    get browse_untied
    get conditional
  },
  },

  'blog' => {
    members: %w{},
    collections: %w{
    get otu_page
  },
  },

  'chrs' => {
    members: %w{},
    collections: %w{
  },
  },

  'claves' => {
    members: %w{},
    collections: %w{
  },
  },

  'images' => {
    members: %w{},
    collections: %w{
  },
  },

  'labels' => {
    members: %w{},
    collections: %w{
    get list_all
    get show_via_name
  },
  },

  'multikey' => {
    members: %w{
    get _close_popup_figs
    get _cycle_elim_chr_txt_choices
    get _cycle_elim_otu_txt_choices
    get _cycle_remn_chr_txt_choices
    get _cycle_remn_otu_txt_choices
    get _popup_figs_for_chr
    get _popup_figs_for_state
    get _show_figures_for_chr
    get _update_otu_for_compare
    get add_state
    get check_for_bot_formatted_links_and_return_404s
    get choose_otu
    get conditional
    get remove_state
    get reset
    get return_chr
    get return_otu
    get show_chosen_figures
    get show_chosen_states
    get show_compare
    get show_default
    get show_otu_by_chr
    get show_remaining_figures
    get show_tags
  },
    collections: %w{
  },
  },


  'multikey_simple' => {
    members: %w{
    get _close_popup_figs
    get _popup_figs_for_chr
    get _popup_figs_for_state
    get _update_otu_for_compare
    get add_state
    get check_for_bot_formatted_links_and_return_404s
    get choose_otu
    get remove_state
    get reset
    get return_chr
    get return_otu
    get show_chosen_states
    get show_compare
    get show_default
    get show_otu_by_chr
    get show_tags
  },
    collections: %w{
  },
  },


  'mxes' => {
    members: %w{
  get current_cycle
  get cycle
  get grid_coding_params
  get reset_cycle
  get set_export_variables
  get show_ascii
  get show_chrs
  get show_grid_coding
  get show_grid_tags
  get show_nexus
  get show_otus
  get show_phylowidget
  get show_tnt
  get show_trees
  get simple_format
  get tnt_as_file
  },
    collections: %w{
  },
  },

  'news' => {
    members: %w{},
    collections: %w{
  },
  },

  'ontology_classes' => {
    members: %w{},
    collections: %w{
   post auto_complete_for_ontology_class
   get random
   get show_expanded
  },

  },

 'public_contents' => {
    members: %w{},
    collections: %w{
    get _markup_description
	  get show_kml_text
  },
  },

  'refs' => {
    members: %w{},
    collections: %w{
    get list_by_author
    get list_recent
    get list_simple
  },
  },

 'repostories' => {
    members: %w{},
    collections: %w{
  },
  },

  'sensus' => {
    members: %w{},
    collections: %w{
    get refs
  },
  },

  'taxon_names' => {
    members: %w{},
    collections: %w{
    get  browse
    get list_by_repository
    get search
    get search_help
    get search_taxon_names
  },
  },

  } # end PUBLIC_RESOURCES

  [PUBLIC_RESOURCES, PRIVATE_RESOURCES].each do |resrc|
    resrc.keys.each do |r|
      resrc[r][:members] = %w{} if resrc[r][:members].nil?
      resrc[r][:collections] = %w{} if resrc[r][:collections].nil?
    end
  end

  mx_resources = {}
  mx_resources = {:private => PRIVATE_RESOURCES, :public => PUBLIC_RESOURCES}

  mx_resources.keys.each do |r|
    mx_resources[r].keys.each do |c|
      scope :projects, :path => "/projects/:proj_id#{r == :public ? "/public" : ''}" do

        resources c.to_sym,
          :controller => (r == :public ? "public/#{c}" : c.to_sym),
          :except => (r == :public ? [:create, :destroy, :edit, :new, :update] : %w{} ) do

          # CAUTION! The following collection and member blocks
          # define actinos available to all public/private resources.
          collection do
            get 'list'
            get "auto_complete_for_#{c}"
          end

          collection do
            mx_resources[r][c][:collections].each_slice(2) do |rt|
              next if rt.size == 0
              method,action = rt.to_a
              case method
              when 'get'
                get action
              when 'post'
                post action
              else
                raise
              end
            end
          end

          member do
            mx_resources[r][c][:members].each_slice(2) do |rt|
              next if rt.size == 0
              method,action = rt.to_a
              case method
              when 'get'
                get action
              when 'post'
                post action
              else
                raise
              end
            end
          end

        end
      end
    end
  end




  resource :account, :controller => 'account', :only => [] do
    collection do
      get :index
      get :change_email
      get :change_password
      post :delete
      get :login
      post :login
      get :logout
      get :signup
    end
  end

  resource :admin, :controller => 'admin', :only => [] do
    collection do
      get :index
      post :create_proj
      get :debug
      post :destroy_image
      get :eol_dump
      get :new_proj
      post :nuke_proj
      get :orphaned_images
      get :people_tn
      post :reset_password
      get :stats
      get :title
    end
  end

  resources 'association_supports', :controller => 'associations_supports', :only => [] do
    collection do
      post :move
      post :new_ref
      post :new_specimen
      post :new_voucher
    end
  end

  # TODO: remove from above
  resources 'people' do
    collection do
      get :preferences
    end
  end

  resource :shared, :controller => 'shared', :only => [] do
    collection do
      get  :show_or_edit
    end
  end

  resource :ontology, :controller => 'ontology', :path => '/projects/:proj_id/ontology', :only => [] do
    collection do
     get '_ref_context_for_label'
     get '_tree_navigate_through_child'
     get '_tree_populate_target'
     get '_tree_set_root'
     get :analyze
     get :auto_complete_for_ontology
     get :download_analyzer_result
     get :export_class_depictions
     get :index
     get :proofer
     get :search
     get :show_OBO_file
     get :show_external_OBO_file
     get :stats
     get :tree
     get :visualize_dot
     post :analyze
     post :proofer_batch_create
    end
  end

  resource 'public_ontology', :controller => 'public/ontology', :only => [] do
    collection do
      get '_tree_navigate_through_child'
      get '_tree_populate_target'
      get '_tree_set_root'
      get :conditional
      get :parts
      get :proof
      get :pulse
      get :pulse_rss
      get :refs
      get :search
      get :tree
    end
  end

  # why can't we include :show, :index in :only?! (tests fail)
  resource :multikey, :controller => 'multikey', :path => '/projects/:proj_id/multikey', :only => [] do
    collection do
      get :index
      get '_close_popup_figs'
      get '_cycle_elim_chr_txt_choices'
      get '_cycle_elim_otu_txt_choices'
      get '_cycle_remaining_figures_by_chr'
      get '_cycle_remn_chr_txt_choices'
      get '_cycle_remn_otu_txt_choices'
      get '_popup_figs_for_chr'
      get '_popup_figs_for_state'
      get '_show_figures_for_chr'
      get '_update_otu_for_compare'
      get :add_state
      get :choose_otu
      get :list
      get :remove_state
      get :reset
      get :return_chr
      get :return_otu
    end

    member do
      get :show
      get :show_chosen_figures
      get :show_chosen_states
      get :show_compare
      get :show_default
      get :show_otu_by_chr
      get :show_remaining_figures
    end
  end


  # NON /project/proj_id specified routes (?!)

  # TODO: merge
  resources :projs do
     collection do
      get :list
      get :eol_dump
      get :my_data
      get :summary
      post '_set_pub_controllers'
      post :generate_ipt_records
    end
  end

  resources :taxon_names, :only => [] do
     collection do
      post 'auto_complete_for_taxon_names'
    end
  end

  resources :geogs, :only => [] do
     collection do
      post 'auto_complete_for_geogs'
    end
  end

  resources :news, :only => [] do
     collection do
      post 'list_admin'
    end
  end

  resources :namespaces

  resources :geog_types do
    collection do
      get 'list'
      get 'auto_complete_for_geog_types'
    end
  end

  resources :image_views do
   collection do
    get 'auto_complete_for_image_views'
    get 'list'
   end
  end


  # resource :ontology, :path => '/api'

  # Some non-RESTfull API calls
  match "/projects/:proj_id/api/ontology/obo_file", :action => :obo_file, :controller => "api/ontology"
  match "/projects/:proj_id/api/ontology/class_depictions", :action => :class_depictions, :controller => "api/ontology"
  match "api/ontology/obo_file", :action => :obo_file, :controller => "api/ontology"
  match "api/ontology/class_depictions", :action => :class_depictions, :controller => "api/ontology"

  # TODO: review all these for mx3
  # map.namespace  :api, :only => [:index, :show] do |api|
  #  api.resources :figure
  #  api.resources :ontology
  #  api.resources :ref
  # end

  # # handles development non-api calls
  # map.namespace :api, :path_prefix => "/projects/:proj_id/api", :only => [:index, :show] do |api|
  #  api.resources :figure
  #  api.resources :ontology
  #  api.resources :ref
  # end


 #  match "*anything", :to => "application#index", :unresolvable => "true"
end
