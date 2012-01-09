module App::NavigationHelper
  # Links and similar methods, should minimally influence layout (but see the tabs code)

  # Used in _navigator renderings when show methods are called to
  # display an individual record.
  # :link => must have a corresponding show_<link> method in the controller, and partial in the /show/ for the given model
  def show_nav_link(options = {})
    opt = {
      :obj => nil,
      :link => nil,
      :bound_action => nil
    }.merge(options)

    if opt[:bound_action].nil?
      bound_action = "show_#{opt[:link].gsub(/\s/, '_')}"
    else
      bound_action = opt[:bound_action]
    end

    content_tag(:div, :class => 'item') do
     if params[:action].to_s == bound_action
       content_tag(:span, opt[:link], :class => 'navigator_current')
     else
       content_tag(:span, link_to(opt[:link], :action => bound_action, :id => opt[:obj].id), :class => 'navigator_away')
     end
    end
  end

  # Returns a link for use _navigator.html.erb
  def navigator_link_tag(options = {})
    opt = {
      :session_param => nil, # the session param to check
      :do => nil,            # style if session param matches
      :link_text => nil,
      :link_params => {}
    }.merge!(options)
    return "Error with navigator_link_tag." if opt[:session_param].nil? || opt[:do].nil? || opt[:link_text].nil?
    content_tag(:div, :class => 'item') do
      if session[opt[:session_param]] == opt[:do]
        content_tag(:span, opt[:link_text], :class => 'navigator_current')
      else
        content_tag(:span, link_to(opt[:link_text], opt[:link_params]) )
      end
    end
  end

  # Determine whether the current model has additional links for the top right navigation
  # TODO: this is very convienent now, but likely not optimal, should probably set a constant in the controller
  def has_links
    File.exist?("#{Rails.root.to_s}/app/views/#{self.controller.controller_name}/_links.html.erb")
  end

  def navigator2(options = {}) # :yields: String (html, navigator for a particular show view)
    opt = {
      :obj => nil,     # the Object instance being shown
      :do => 'show',   # we just repeat the last action called
      :ord => 'id'     # the field to sort on for left/right navigation
    }.merge!(options)

    return content_tag(:div, '', :class => 'navigator_buttons') if @public

    klass = ActiveSupport::Inflector.underscore(opt[:obj].class.to_s)
    klass = 'content_type' if klass =~ /content_type/ || klass =~ /text_content/
    klass = 'image' if klass == 'morphbank_image' && opt[:obj].is_morphbank == true

    klass = klass.pluralize

    content_tag(:div, :style => 'border-bottom:1px dotted silver;padding:2px;') do
      id_box_tag(opt[:obj]) +
        content_tag(:div, link_to('show', :action => :show, :id => opt[:obj]), :class => (opt[:do] == 'show' ? 'navigator_current' : ''), :style => 'margin:3px 0;') +
      content_tag(:div, :class => 'navigator_buttons') do
        content_tag(:span, link_to("&#8678;".html_safe, {:action => opt[:do], :controller => klass, :id => previous_rec(opt[:obj], opt[:ord])}, :class => 'navigator_link'), :class => 'navigator_button')  +
        content_tag(:span, link_to('edit', :action => :edit, :controller => klass, :id => opt[:obj].id) ) +
        content_tag(:span, link_to('&#8680;'.html_safe, {:action => opt[:do], :controller => klass, :id => next_rec(opt[:obj], opt[:ord])}, :class => 'navigator_link'), :class => 'navigator_button')
      end  +
       content_tag(:div, :style => 'width: 100%; font-size:smaller;padding:2px;' ) do

        if opt[:obj].respond_to?('taggable?') && opt[:obj].taggable?
         tg = new_tag_tag(:object=>opt[:obj], :html_selector=>"#inner_wrapper") + "&nbsp;|&nbsp;".html_safe
        else
          tg = ''
        end

        tg += content_tag(:span, link_to('Destroy', {:action => :destroy, :id => opt[:obj]}, :method => "post", :confirm => "Are you sure?", :style => 'display:inline;' ) )
        tg.html_safe
       end
    end

  end

  # Returns the previous/next record as sorted by Model#ord
  def next_rec(rec, ord = 'id', prev = false)
    search_table = ActiveSupport::Inflector.underscore(rec.class.to_s).pluralize
    search_table = 'content_types' if rec.class.to_s =~ /ContentType::/ || rec.class.to_s == 'TextContent'

    # TODO: R3 revisit - hack in an exception for subclasses
    if search_table == 'content_types'
      klass = ContentType
    else
      klass = rec.class
    end

    c = conditions_for_prev_next(search_table)
    asc_desc = (prev ? "DESC" : "ASC")
    lt_gt = (prev ? "<" : ">") # this is sql, not HTML

    inc = nil

    case search_table
    when 'taxon_hists'
      inc = :taxon_name
    when 'refs'
      inc = :projs
    when 'otus'
      inc = :otu_groups
    when 'chrs'
      inc = :chr_groups
      order = "chr_groups_chrs.position #{asc_desc}" if session['group_ids'] && session['group_ids']['chr']
    end

    bj = nil

    order =  "#{search_table}.#{ord} #{asc_desc}" if !order
    if obj = klass.find(:first, :include => inc,
        :conditions => ["#{c ? (c + " AND ") : ''} #{search_table}.#{ord} #{lt_gt} ?", rec.send(ord)],
        :order => order )
      return obj.id
    else
      # hack. if c is false, above fails
      if c
       obj = klass.find(:first, :include => inc, :conditions => c, :order => order) # we hit the last record, go back to the first
      else
       obj = klass.find(:first, :include => inc, :order => order)
      end

      return (obj.nil? ? rec.id : obj.id) # We have to return an id to ensure the routes work.
    end
  end

  def previous_rec(rec, ord = 'id')
    next_rec(rec, ord, true)
  end

  # in conjuction with previous|next _rec
  def conditions_for_prev_next(search_table)
    # TaxonNames, TaxonHists and some others are "project free"
    if (search_table == 'taxon_names') || (search_table == 'taxon_hists')
      return "(" + @proj.sql_for_taxon_names('taxon_names') + ")"
    elsif ['geogs', 'repositories', 'serials'].include?(search_table) #  search_table == 'geogs' or search_table == 'repositories' or search_table == 'serials'
      return false
    elsif search_table == 'chrs' && session['group_ids'] && session['group_ids']['chr']
      return "(chr_groups.id = #{session['group_ids']['chr']} AND chrs.proj_id = #{@proj.id})"
    elsif search_table == 'otus' && session['group_ids'] && session['group_ids']['otu']
      return "otus.id IN (select otu_id from otu_groups_otus where otu_groups_otus.otu_group_id = #{session['group_ids']['otu']})"
    elsif search_table == 'refs' # refs are habtm with projs, so we include the project and add this condition
      return "projs.id = #{@proj.id}"
    else
      return "proj_id = #{@proj.id}"
    end
  end

  # hash aiding navigation, if you use a controller it has to be listed here at present
  # in process of being deprecated for something simpler

  # setup for memoization?
  def links
    @calc_links ||= calc_links
  end

  def calc_links
    {
      "login" => { "text" => "", "group" => "none", "subnav" => {'default' => {"controller" => "none" , "text" => ""}}},
      "signup" => { "text" => "", "group" => "none", "subnav" => {'default' => {"controller" => "none" , "text" => ""}}},
      "account" => { "text" => "", "group" => "none", "subnav" => {'default' => {"controller" => "none" , "text" => ""}}},
      "people" => { "text" => "", "group" => "none", "subnav" => {'default' => {"controller" => "none" , "text" => ""}}},
      "association_supports" => {"text" => "", "group" => "associations", "subnav" => {'default' => {"controller" => "associations" , "text" => ""}}},

      "namespaces" => { "text" => "", "group" => "none", "subnav" => {'default' => {"controller" => "none" , "text" => ""}}},
      "news" => {"text" => "News", "group" => "contents", "subnav" => {'default' => {'controller' => "news",  "text" => "News"}}},
      "doc" => { "text" => "", "group" => "none", "subnav" => {'default' => {"controller" => "none" , "text" => ""}}},

      "lots" => { "text" => "Lot", "group" => "specimens", "subnav" => {'default' => {"controller" => "lots" , "text" => "Lots"}}},
      "lot_groups" => { "text" => "", "group" => "specimens", "subnav" => {'default' => {"controller" => "lot_groups" , "text" => "Lot&nbsp;groups".html_safe}}},
      "specimens" => { "text" => "Material", "group" => "specimens", "subnav" => {'default' => {"controller" => "specimens" , "text" => "Specimens"}}},
      "repositories" => { "text" => "Repositories", "group" => "specimens", "subnav" => {'default' => {"controller" => "repositories" , "text" => "Repositories"}}},
      "ces" => { "text" => "Collecting&nbsp;Events".html_safe, "group" => "specimens", "subnav" => {'default' => {"controller" => "ces" , "text" => "Collecting&nbsp;Events".html_safe}}},
      "geogs" => { "text" => "Geographical&nbsp;Names".html_safe, "group" => "specimens", "subnav" => {'default' => {"controller" => "geogs" , "text" => "Geographical&nbsp;Names".html_safe}}},
      "measurements" => { "text" => "Measurements", "group" => "measurements", "subnav" => {'default' => {"controller" => "measurements" , "text" => "Measurements"}}},
      "distributions" => { "text" => "Distributions", "group" => "specimens", "subnav" => {'default' => {"controller" => "distributions" , "text" => "Distribution"}}},

      "seqs" => { "text" => "DNA", "group" => "seqs", "subnav" => {'default' => {"controller" => "seqs" , "text" => "Sequences"}}},
      "genes" => { "text" => "Genes", "group" => "seqs", "subnav" => {'default' => {"controller" => "genes" , "text" => "Genes"}}},
      "gene_groups" => { "text" => "Gene groups", "group" => "seqs", "subnav" => {'default' => {"controller" => "gene_groups" , "text" => "Gene groups"}}},
      "primers" => { "text" => "Primers", "group" => "seqs", "subnav" => {'default' => {"controller" => "primers" , "text" => "Primers"}}},
      "extracts" => { "text" => "Extracts", "group" => "seqs", "subnav" => {'default' => {"controller" => "extracts" , "text" => "Extracts"}}},
      "protocols" => { "text" => "Protocols", "group" => "seqs", "subnav" => {'default' => {"controller" => "protocols" , "text" => "Protocols"}}},
      "protocol_steps" => { "text" => "Protocol step", "group" => "seqs", "subnav" => {'default' => {"controller" => "protocols" , "text" => "Protocols"}}},
      "chromatograms" => { "text" => "Chromatograms", "group" => "seqs", "subnav" => {'default' => {"controller" => "chromatograms" , "text" => "Chromatograms"}}},
      "pcrs" => { "text" => "PCRs", "group" => "seqs", "subnav" => {'default' => {"controller" => "pcrs" , "text" => "PCRs"}}},

      "projs" => { "text" => "", "group" => "none", "subnav" => {'default' => {"controller" => "none" , "text" => ""}}},
      "admin" => { "text" => "", "group" => "none", "subnav" => {'default' => {"controller" => "none" , "text" => ""}}},

      "otus" => { "text" => "OTUs", "group" => "main", "subnav" => {'default' => {"controller" => "otus" , "text" => "OTUs"}}},
      "otu_groups" => {"text" =>'OTU groups', "group" => "otus", "subnav" =>{ 'default' => {"controller" => "otu_groups", "text" => 'OTU groups' }}},

      "chrs" => { "text" => "Characters", "group" => "main" , "subnav" => {'default' => {"controller" => "chrs" , "text" => "Characters"}}},
      "mxes" => { "text" => "Matrices", "group" => "main"},
      "chr_groups" => {"text" => 'Character groups', "group" => "chrs", "subnav" => { 'default' => {'controller' => "otu_groups", "text" => 'Character groups'}}},
      "chr_states" => { "text" => "Character state", "group" => "chrs" , "subnav" => {'default' => {"controller" => "chr_states" , "text" => "Character state"}}},
      "phenotypes" => { "text" => "Phenotype", "group" => "chrs" , "subnav" => {'default' => {"controller" => "phenotypes" , "text" => "Phenotype"}}},

      "multikey" => { "text" => "Multikeys", "group" => "claves" , "subnav" => {'default' => {"controller" => "/multikey" , "text" => "Multikeys"}}},
      "claves" => { "text" => "Keys", "group" => "claves" , "subnav" => {'default' => {"controller" => "claves" , "text" => "Keys"}}},

      "d_key" => {"text" =>"Keys", "group" => "main"},
      "foo" => {"text" => "Images", "group" => "main"},

      "foo1" => {"text" => "Genes", "group" => "main"},
      "associations" => {"text" => "Associations", "group" => "main", "subnav" => {'default' => {"controller" => "associations" , "text" => "Association"}}},

      "contents" => {"text" => "Content", "group" => "main", "subnav" => {'default' => {'controller' => "contents",  "text" => "Content"}}},
      "content_types" => {"text" => "Content types", "group" => "contents", "subnav" => { 'default' => {'controller' => "content_types", "text" => "Content types"}}},
      "content_templates" => {"text" => "Templates", "group" => "contents", "subnav" => {'default' => {'controller' => "content_templates",  "text" => "Templates"}}},
      "public_contents" => {"text" => "Public content", "group" => "contents", "subnav" => {'default' => {'controller' => "content_types",  "text" => "Public content"}}},

      "confidences" => {"text" => "Confidence", "group" => "tags", "subnav" => {'default' => {'controller' => 'confidences' , "text" => "Confidence"}}},

      "refs" => {"text" => "Refs", "group" => "main", "subnav" =>{ 'default' => {"controller" => "refs", "text" => "Refs"}}},
      "serials" => {"text" => "Serials", "group" => "refs", "subnav" =>{ 'default' => {"controller" => "serials", "text" => "Serials"}}},

      "keywords" => {"text" => "keywords", "group" => "tags", "subnav" =>{ 'default' => {"controller" => "keywords", "text" => "Keywords"}}},
      "tags" => {"text" => "Tags", "group" => "tags", "subnav" =>{ 'default' => {"controller" => "tags", "text" => "Tags"}}},

      "ontology" => {"text" => "Ontology", "group" => "ontology", "subnav" =>{ 'default' => {"controller" => "ontology", "text" => "Home"}}},
      "ontology_classes" => {"text" => "classes", "group" => "ontology", "subnav" =>{'default' => {"controller" => "ontology_classes", "text" => "Classes"}}},
      "sensus" => {"text" => "sensu", "group" => "ontology", "subnav" =>{ 'default' => {"controller" => "sensus", "text" => "Sensu"}}},
      "labels" => {"text" => "labels", "group" => "ontology", "subnav" =>{ 'default' => {"controller" => "labels", "text" => "Labels"}}},
      "object_relationships" => {"text" => "relationships", "group" => "ontology", "subnav" =>{'default' => {"controller" => "object_relationships", "text" => "Relationships"}}},

      "taxon_names" => {"text" => 'Taxon&nbsp;names'.html_safe, "group" => "main", "subnav" =>{ 'default' => {"controller" => "taxon_names", "text" => content_tag(:span, "Taxon names", :style => 'white-space:nowrap')}}},
      "taxon_hists" => {"text" => "Taxon name histories", "group" => "taxon_names", "subnav" =>{ 'default' => {"controller" => "taxon_hists", "text" => "Taxon name histories"}}},

      "images" => {"text" => "Images", "group" => "main", "subnav" =>{ 'default' => {"controller" => "images", "text" => "images"}}},
      "figures" => {"text" => "Figures", "group" => "images", "subnav" =>{ 'default' => {"controller" => "figures", "text" => "figures"}}},
      "image_views" => {"text" => "Image views", "group" => "none", "subnav" =>{ 'default' => {"controller" => "none", "text" => ""}}},
      "standard_views" => {"text" => "Standard views", "group" => "images", "subnav" =>{ 'default' => {"controller" => "standard_views", "text" => "standard views"}}},
      "standard_view_groups" => {"text" => "Standard view groups", "group" => "images", "subnav" =>{ 'default' => {"controller" => "standard_view_groups", "text" => "standard view groups"}}},
      "morphbank_images" => {"text" => "Morphbank image", "group" => "images", "subnav" =>{ 'default' => {"controller" => "images", "text" => "morphbank image"}}},

      "image_descriptions" => {"text" => "summarize/manage", "group" => "images", "subnav" =>{ 'default' => {"controller" => "image_descriptions", "text" => "summarize/manage"}}},

      "trees" => {"text" => "Phylo", "group" => "trees", "subnav" =>{ 'default' => {"controller" => "trees", "text" => "Trees"}}},
      "data_sources" => {"text" => "Data sources", "group" => "trees", "subnav" =>{'default' => {"controller" => "data_sources", "text" => "Data sources"}}},
      "test" => {"text" => "TEST", "group" => "trees", "subnav" =>{ 'default' => {"controller" => "test", "text" => "Trees"}}}
    }
    # "statement" => { "text" => "Statements", "group" => "main"},
  end

  # The default Tab layout, elements are controller names
  def calc_nav_tabs
    ["otus", "chrs", "mxes", "contents", "specimens", "measurements", "seqs", "refs", "associations",  "taxon_names", "images", "ontology", "claves", "tags", "trees" ] # statements are not developed
  end

  # Array containing the first level tabs/keys to subtabs
  def nav_tabs
    @nav_tabs ||= calc_nav_tabs
  end

  # A Hash representing the sub tabs of the first level tabs
  def navbars
    @navbars ||= calc_navbars
  end

  # Defines the structure of the tabs/subnav, these are controller names
  def calc_navbars
    {
      "projs" => ["namespaces"],
      "main" => main_navbar,
      "otus" => ["otus", "otu_groups"],
      "ontology" => ["ontology", "labels", "ontology_classes", "sensus", "object_relationships"],
      "chrs" => ["chrs", "chr_groups"],
      "associations" => ["associations", "object_relationships" ],
      "specimens" => [ "specimens", "lots", "lot_groups", "ces", "distributions", "repositories", "geogs"],
      "measurements" => ["measurements", "standard_views", "standard_view_groups"],
      "refs" => ["refs",  "serials"],
      "seqs" => ["seqs", "extracts", "pcrs", "genes", "primers", "gene_groups", "chromatograms", "protocols"] ,
      "contents" => [ "contents", "public_contents", "content_types", "content_templates", "news"],
      "images" => ["images", "image_descriptions",   "labels", "standard_views", "standard_view_groups", "figures"],
      "taxon_names" => ["taxon_names", "taxon_hists"],
      "claves" => ["claves", "multikey"],
      "tags" => ['tags', 'keywords', 'confidences'],
      "trees" => ['trees', 'data_sources']
    }
  end

  # TODO: memoize this @ Proj level(?)
  def main_navbar
    b = nav_tabs
    if @proj
      # It is a stable sort, so it effecively just moves the starting tab (if present) to the front
      b.sort_by! {|proj| [proj == @proj.starting_tab ? 0 : 1] }
    else
      b = []
    end
    b
  end

  # Creates the nav links for the standard project layout, legal 'types' are ('main', 'subnav', 'none')
  def menu_tabs(type = 'main')
    return '' if !@proj
    c_name = self.controller.controller_name
    result_str = '<div ' + (type == "main" ? 'id= "tabs' : 'class ="subnav' ) + '">'

    # nothing special has to be done for type 'main'!!!
    if (type == 'subnav')
      if (links[c_name]['group'] == 'main')
        if (links[c_name]['subnav'])
          type = links[c_name]['subnav']['default']['controller']
        else
          return
        end
      else
        type = links[c_name]['group']
      end
    end

    (type == 'none') && return

    # render the bars
    navbars[type].each{|tab|
      if not (type == "main" && @proj && @proj.hidden_tabs && @proj.hidden_tabs.include?(tab))
        linktext = ( type == "main" ? links[tab]['text'] : links[tab]['subnav']['default']['text'] )
        if (c_name == tab) || ((links[c_name]['group'] == tab) && (type == "main"))
          result_str << link_to(linktext, {:controller => tab, :proj_id => @proj.id} , {:class => "current"})
        else
          result_str << link_to(linktext, {:controller => tab, :proj_id => @proj.id})
        end
      end
    }
    result_str << "</div>"
    result_str.html_safe
  end

  # take the list of links from the controller helper and format it, this IS USED in 3rd level navbars in mx/associations, mx/seqs
  def format_subnav(links)
    content_for(:div, :class => 'subnav') do
      links.collect{|link|
        if self.controller.action_name == link['options'][:action]
          link_to(link['text'], link['options'], {:class => "current"})
        else
          link_to(link['text'], link['options'])
        end }.join('|')
    end
  end

  # TODO: Determine whether to keep singular controller help in wiki, or migrate wiki to plural
  def wiki_help_link
    if "#{self.controller.action_name}" != "index"
      "<a href=\"http://#{HELP_WIKI}/index.php/app/#{self.controller.request.parameters[:controller].to_s.singularize}/#{self.controller.action_name}\" target=\"blank\" >wiki-help</a>".html_safe
    else
      "<a href=\"http://#{HELP_WIKI}/index.php/app/#{self.controller.request.parameters[:controller].to_s.singularize}\" target=\"blank\" >wiki-help</a>".html_safe
    end
  end

  def otu_blog_link(otu, content_template)
    url_for(:controller => 'public/blog', :action => :otu_page, :otu_id => otu.id, :content_template_id => content_template.id)
  end

end
