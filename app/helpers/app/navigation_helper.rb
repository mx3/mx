# encoding: utf-8
module App::NavigationHelper
  # Links and similar methods, should minimally influence layout (but see the tabs code)

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
      :do => 'show',   # the view being shown as stored in the session, like session['show_taxon_name']
      :ord => 'id'     # the field to sort on for left/right navigation
    }.merge!(options)

    return content_tag(:div, '', :class => 'navigator_buttons') if @public

    klass = ActiveSupport::Inflector.underscore(opt[:obj].class.to_s) 
    klass = 'content_type' if klass =~ /content_type/ || klass =~ /text_content/ 
    klass = 'image' if klass == 'morphbank_image' && opt[:obj].is_morphbank == true
  
    content_tag(:div, :style => 'border-bottom:1px dotted silver;padding:2px;') do 
      id_box_tag(opt[:obj]) + 
        content_tag(:div, link_to('show', :action => :show, :id => opt[:obj]), :class => (opt[:do] == 'show' ? 'navigator_current' : ''), :style => 'margin:3px 0;') +
        content_tag(:div, :class => 'navigator_buttons') do
        content_tag(:span, link_to('&lt;', {:action => opt[:do], :controller => klass, :id => previous_rec(opt[:obj], opt[:ord])}, :class => 'navigator_link'), :class => 'navigator_button')  +
          content_tag(:span, link_to('edit', :action => :edit, :controller => klass, :id => opt[:obj].id) ) +
          content_tag(:span, link_to('&gt;', {:action => opt[:do], :controller => klass, :id => next_rec(opt[:obj], opt[:ord])}, :class => 'navigator_link'), :class => 'navigator_button')
      end  +
        content_tag(:div, :style => 'width: 100%; font-size:smaller; padding:2px;' ) do
        tag_link_for_show(opt[:obj]) + "&nbsp|&nbsp" + 
          content_tag(:span, link_to('Destroy', {:action => :destroy, :id => opt[:obj]}, :method => "post", :confirm => "Are you sure?", :style => 'display:inline;' ))
      end 
    end

  end 

  # DEPRECATED
  # TODO: exchange with navigator2
  # renders a styled forward/back button for use in shows
  def navigator(obj, action = 'show', ord = 'id')
    return content_tag(:div, '', :class =>  'navigator_buttons') if @public 
    s = '<div class="navigator_buttons"> <span class="navigator_button">'

    klass = ActiveSupport::Inflector.underscore(obj.class.to_s) # 2.1.1 code
    klass = 'content_type' if klass =~ /content_type/ || klass =~ /text_content/ # ['text_content', ContentType.custom_types.collect{|t| ActiveSupport::Inflector.underscore(t)}].flatten.include?( ActiveSupport::Inflector.underscore(obj.class.to_s)) # this is baaaad
    klass = 'morphbank_image' if  klass == 'image' && obj.is_morphbank == true
    
    s += link_to('&lt;', :action => action, :controller => klass, :id => previous_rec(obj, ord)) + '</span> <span class="navigator_link">'
    s += link_to('Edit', :action => 'edit', :controller => klass, :id => obj.id) + '</span>' 
    s += '<span class="navigator_button">' + link_to('&gt;', :action => action, :controller => klass, :id => next_rec(obj, ord)) + '</span></div>'
    s.html_safe
  end 

  # returns the previous/next record as sorted by Model#ord
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

    order =  "#{search_table}.#{ord} #{asc_desc}" if !order
    if id = klass.find(:first, :include => inc, 
        :conditions => ["#{c ? (c + " AND ") : ''} #{search_table}.#{ord} #{lt_gt} ?", rec.send(ord)],
        :order => order )
      return id
    else
      # hack. if c is false, above fails
      if c
        klass.find(:first, :include => inc, :conditions => c, :order => order) # we hit the last record, go back to the first
      else
        klass.find(:first, :include => inc, :order => order)  
      end
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
      "person" => { "text" => "", "group" => "none", "subnav" => {'default' => {"controller" => "none" , "text" => ""}}},
      "association_support" => {"text" => "", "group" => "association", "subnav" => {'default' => {"controller" => "association" , "text" => ""}}},

      "namespace" => { "text" => "", "group" => "none", "subnav" => {'default' => {"controller" => "none" , "text" => ""}}},
      "news" => {"text" => "News", "group" => "content", "subnav" => {'default' => {'controller' => "news",  "text" => "News"}}},
      "doc" => { "text" => "", "group" => "none", "subnav" => {'default' => {"controller" => "none" , "text" => ""}}},

      "lot" => { "text" => "Lot", "group" => "specimen", "subnav" => {'default' => {"controller" => "lot" , "text" => "Lots"}}},
      "lot_group" => { "text" => "", "group" => "specimen", "subnav" => {'default' => {"controller" => "lot_group" , "text" => "Lot&nbsp;groups".html_safe}}},
      "specimen" => { "text" => "Material", "group" => "specimen", "subnav" => {'default' => {"controller" => "specimen" , "text" => "Specimens"}}},
      "repository" => { "text" => "Repositories", "group" => "specimen", "subnav" => {'default' => {"controller" => "repository" , "text" => "Repositories"}}},
      "ce" => { "text" => "Collecting&nbsp;Events".html_safe, "group" => "specimen", "subnav" => {'default' => {"controller" => "ce" , "text" => "Collecting&nbsp;Events".html_safe}}},
      "geog" => { "text" => "Geographical&nbsp;Names".html_safe, "group" => "specimen", "subnav" => {'default' => {"controller" => "geog" , "text" => "Geographical&nbsp;Names".html_safe}}},
      "measurement" => { "text" => "Measurements", "group" => "measurement", "subnav" => {'default' => {"controller" => "measurement" , "text" => "Measurements"}}},
      "distribution" => { "text" => "Distributions", "group" => "specimen", "subnav" => {'default' => {"controller" => "distribution" , "text" => "Distribution"}}},

      "seq" => { "text" => "DNA", "group" => "seq", "subnav" => {'default' => {"controller" => "seq" , "text" => "Sequences"}}},
      "gene" => { "text" => "Genes", "group" => "seq", "subnav" => {'default' => {"controller" => "gene" , "text" => "Genes"}}},
      "gene_group" => { "text" => "Gene groups", "group" => "seq", "subnav" => {'default' => {"controller" => "gene_group" , "text" => "Gene groups"}}},
      "primer" => { "text" => "Primers", "group" => "seq", "subnav" => {'default' => {"controller" => "primer" , "text" => "Primers"}}},
      "extract" => { "text" => "Extracts", "group" => "seq", "subnav" => {'default' => {"controller" => "extract" , "text" => "Extracts"}}},
      "protocol" => { "text" => "Protocols", "group" => "seq", "subnav" => {'default' => {"controller" => "protocol" , "text" => "Protocols"}}},
      "protocol_step" => { "text" => "Protocol step", "group" => "seq", "subnav" => {'default' => {"controller" => "protocol" , "text" => "Protocols"}}},
      "chromatogram" => { "text" => "Chromatograms", "group" => "seq", "subnav" => {'default' => {"controller" => "chromatogram" , "text" => "Chromatograms"}}},
      "pcr" => { "text" => "PCRs", "group" => "seq", "subnav" => {'default' => {"controller" => "pcr" , "text" => "PCRs"}}},

      "proj" => { "text" => "", "group" => "none", "subnav" => {'default' => {"controller" => "none" , "text" => ""}}},
      "admin" => { "text" => "", "group" => "none", "subnav" => {'default' => {"controller" => "none" , "text" => ""}}},

      "otu" => { "text" => "OTUs", "group" => "main", "subnav" => {'default' => {"controller" => "otu" , "text" => "OTUs"}}}, 
      "otu_group" => {"text" =>'OTU groups', "group" => "otu", "subnav" =>{ 'default' => {"controller" => "otu_group", "text" => 'OTU groups' }}}, 

      "chr" => { "text" => "Characters", "group" => "main" , "subnav" => {'default' => {"controller" => "chr" , "text" => "Characters"}}},
      "mx" => { "text" => "Matrices", "group" => "main"},
      "chr_group" => {"text" => 'Character groups', "group" => "chr", "subnav" => { 'default' => {'controller' => "otu_group", "text" => 'Character groups'}}},
      "chr_state" => { "text" => "Character state", "group" => "chr" , "subnav" => {'default' => {"controller" => "chr_state" , "text" => "Character state"}}},
      "phenotype" => { "text" => "Phenotype", "group" => "chr" , "subnav" => {'default' => {"controller" => "phenotype" , "text" => "Phenotype"}}},

      "multikey" => { "text" => "Multikeys", "group" => "clave" , "subnav" => {'default' => {"controller" => "multikey" , "text" => "Multikeys"}}},
      "clave" => { "text" => "Keys", "group" => "clave" , "subnav" => {'default' => {"controller" => "clave" , "text" => "Keys"}}},

      "d_key" => {"text" =>"Keys", "group" => "main"},
      "foo" => {"text" => "Images", "group" => "main"},

      "foo1" => {"text" => "Genes", "group" => "main"},
      "association" => {"text" => "Associations", "group" => "main", "subnav" => {'default' => {"controller" => "association" , "text" => "Association"}}},

      "content" => {"text" => "Content", "group" => "main", "subnav" => {'default' => {'controller' => "content",  "text" => "Content"}}},
      "content_type" => {"text" => "Content types", "group" => "content", "subnav" => { 'default' => {'controller' => "content_type", "text" => "Content types"}}},
      "content_template" => {"text" => "Templates", "group" => "content", "subnav" => {'default' => {'controller' => "content_type",  "text" => "Templates"}}},
      "public_content" => {"text" => "Public content", "group" => "content", "subnav" => {'default' => {'controller' => "content_type",  "text" => "Public content"}}},
      
      "confidence" => {"text" => "Confidence", "group" => "tag", "subnav" => {'default' => {'controller' => 'association' , "text" => "Confidence"}}},
      
      "ref" => {"text" => "Refs", "group" => "main", "subnav" =>{ 'default' => {"controller" => "ref", "text" => "Refs"}}},
      "serial" => {"text" => "Serials", "group" => "ref", "subnav" =>{ 'default' => {"controller" => "serial", "text" => "Serials"}}},

      "keyword" => {"text" => "keywords", "group" => "tag", "subnav" =>{ 'default' => {"controller" => "tag", "text" => "Keywords"}}},
      "tag" => {"text" => "Tags", "group" => "tag", "subnav" =>{ 'default' => {"controller" => "tag", "text" => "Tags"}}},

      "sensu" => {"text" => "sensu", "group" => "ontology", "subnav" =>{ 'default' => {"controller" => "sensu", "text" => "Sensu"}}},
      "label" => {"text" => "labels", "group" => "ontology", "subnav" =>{ 'default' => {"controller" => "label", "text" => "Labels"}}},
      "ontology" => {"text" => "Ontology", "group" => "ontology", "subnav" =>{ 'default' => {"controller" => "ontology", "text" => "Home"}}},
      "ontology_class" => {"text" => "classes", "group" => "ontology", "subnav" =>{'default' => {"controller" => "ontology_class", "text" => "Classes"}}},
      "object_relationship" => {"text" => "relationships", "group" => "ontology", "subnav" =>{'default' => {"controller" => "ontology_class", "text" => "Relationships"}}},

      "taxon_name" => {"text" => 'Taxon&nbsp;names'.html_safe, "group" => "main", "subnav" =>{ 'default' => {"controller" => "taxon_name", "text" => content_tag(:span, "Taxon names", :style => 'white-space:nowrap')}}},
      "taxon_hist" => {"text" => "Taxon name histories", "group" => "taxon_name", "subnav" =>{ 'default' => {"controller" => "taxon_name", "text" => "Taxon name histories"}}},

      "image" => {"text" => "Images", "group" => "main", "subnav" =>{ 'default' => {"controller" => "image", "text" => "images"}}},
      "part" => {"text" => "Parts", "group" => "image", "subnav" =>{ 'default' => {"controller" => "part", "text" => "parts"}}},
      "figure" => {"text" => "Figures", "group" => "image", "subnav" =>{ 'default' => {"controller" => "figure", "text" => "figures"}}},
      "image_view" => {"text" => "Image views", "group" => "none", "subnav" =>{ 'default' => {"controller" => "none", "text" => ""}}},
      "standard_view" => {"text" => "Standard views", "group" => "image", "subnav" =>{ 'default' => {"controller" => "standard_view", "text" => "standard views"}}},
      "standard_view_group" => {"text" => "Standard view groups", "group" => "image", "subnav" =>{ 'default' => {"controller" => "standard_view_group", "text" => "standard view groups"}}},
      "morphbank_image" => {"text" => "Morphbank image", "group" => "image", "subnav" =>{ 'default' => {"controller" => "image", "text" => "morphbank image"}}},
      
      "image_description" => {"text" => "summarize/manage", "group" => "image", "subnav" =>{ 'default' => {"controller" => "image_description", "text" => "summarize/manage"}}},

      "tree" => {"text" => "Phylo", "group" => "tree", "subnav" =>{ 'default' => {"controller" => "tree", "text" => "Trees"}}},
      "data_source" => {"text" => "Data sources", "group" => "tree", "subnav" =>{'default' => {"controller" => "data_source", "text" => "Data sources"}}},
      "test" => {"text" => "TEST", "group" => "tree", "subnav" =>{ 'default' => {"controller" => "test", "text" => "Trees"}}}
    }
    # "statement" => { "text" => "Statements", "group" => "main"},
  end

  # The default Tab layout, elements are controller names
  def calc_nav_tabs
    ["otu", "chr", "mx", "content", "specimen", "measurement", "seq", "ref", "association",  "taxon_name", "image", "ontology", "clave", "tag", "tree" ] # statements are not developed
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
      "proj" => ["namespace"],
      "main" => main_navbar,
      "ontology" => ["ontology", "label", "ontology_class", "sensu",  "object_relationship"],
      "otu" => ["otu", "otu_group"],
      "chr" => ["chr", "chr_group"],
      "association" => ["association", "object_relationship" ],
      "specimen" => [ "specimen", "lot", "lot_group", "ce", "distribution", "repository", "geog"],
      "measurement" => ["measurement", "standard_view", "standard_view_group"],
      "ref" => ["ref",  "serial"],
      "seq" => ["seq", "extract", "pcr", "gene", "primer", "gene_group", "chromatogram", "protocol"] ,
      "content" => [ "content", "public_content", "content_type", "content_template", "news"],
      "image" => ["image", "image_description",   "label", "standard_view", "standard_view_group", "figure"],
      "taxon_name" => ["taxon_name", "taxon_hist"],
      "clave" => ["clave", "multikey"],
      "tag" => ['tag', 'keyword', 'confidence'],
      "tree" => ['tree', 'data_source']
    }
  end
 
  # TODO: memoize this @ Proj level(?)
  def main_navbar
    b = nav_tabs
    if @proj
      b.delete(@proj.starting_tab)
      b.insert(0, @proj.starting_tab) 
    else
      b = []
    end
    b
  end

  # Creates the nav links for the standard project layout, legal 'types' are ('main', 'subnav', 'none')
  def menu_tabs(type = 'main')
    return '' if not @proj
    c_name = self.controller.controller_name
    result_str = "<div " + (type == "main" ? "id= \"tabs" : "class =\"subnav" ) + "\">"   

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
      if not (type == "main" and @proj and @proj.hidden_tabs and @proj.hidden_tabs.include?(tab))
        linktext = ( type == "main" ? links[tab]['text'] : links[tab]['subnav']['default']['text']  )
        if (c_name == tab) || ((links[c_name]['group'] == tab) && (type == "main"))
          result_str << link_to(linktext,  {:controller => tab} , {:class => "current"}) 
        else
          result_str << link_to(linktext, {:controller => tab})         
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

  # ripped straight out of Rails docs, modified for ajax
  # see also here http://www.reality.com/roberts/markus/software/ruby/rails/wiki/How%20to%20Paginate%20With%20Ajax.textile
  def pagination_links_with_ajax(paginator, options={})
    options.merge!(ActionView::Helpers::PaginationHelper::DEFAULT_OPTIONS) {|key, old, new| old}
    options[:window_size] = 5

    window_pages = paginator.current.window(options[:window_size]).pages
    url_options = { 
      :action => options[:action].andand.html_safe,
      :genus => params[:genus].andand.html_safe,
      :species => params[:species].andand.html_safe,
      :author => params[:author].andand.html_safe,
      :other => params[:other].andand.html_safe,
      :proj_to_search => options[:proj_to_search].andand.html_safe
    }
    
    next_page = paginator.current.next
    previous_page = paginator.current.previous

    return if window_pages.length <= 1 unless
    options[:link_to_current_page]

    first, last = paginator.first, paginator.last

    html = ''.html_safe
    html.tap  do
      html << link_to("previous",
        url_options.merge(:page => previous_page),
        :remote => true,
        :loading => "Element.show('pg_spinner');".html_safe,
        :complete => "Element.hide('pg_spinner');".html_safe #,
        # :update => options[:element_name]
      )
      html << '&nbsp;|&nbsp;'.html_safe
      html <<  link_to("next",
        url_options.merge(:page => next_page),
        :remote => true,
        :class => 'ajax_page_nav_link'
      )
        # :loading => "Element.show('pg_spinner');",
        # :complete => "Element.hide('pg_spinner');",
        # :update => options[:element_name])
      html << '&nbsp;|&nbsp;'.html_safe
    
      if options[:always_show_anchors] and not window_pages[0].first?
        html << link_to(first.number,
          url_options.merge(:page => first),
          :remote => true,
          :loading => "Element.show('pg_spinner')".html_safe,
          :complete => "Element.hide('pg_spinner')".html_safe,
          :update => options[:element_name]
          )
        html << ' ... ' if window_pages[0].number - first.number > 1
        html << ' '
      end

      window_pages.each do |page|
        if paginator.current == page && !options[:link_to_current_page]
          html << content_tag(:span, page.number.to_s, :class => 'box1', :style => 'padding:.1em;')
        else
          html << link_to(page.number,
            url_options.merge(:page => page),
            :remote => true,
            :loading => "Element.show('pg_spinner')",
            :complete => "Element.hide('pg_spinner')",
            :update => options[:element_name]
            )
        end
        html << ' '
      end

      if options[:always_show_anchors] && !window_pages.last.last?
        html << ' ... ' if last.number - window_pages[-1].number > 1
        html << link_to(last.number,
          url_options.merge(:page => last),
          :remote => true,
          :loading => "Element.show('pg_spinner')".html_safe,
          :complete => "Element.hide('pg_spinner')".html_safe,
          :update => options[:element_name].html_safe
          )
      end
    
      html << '&nbsp;|&nbsp;'.html_safe
      html << link_to("refresh current",
        url_options.merge(:page => paginator.current),
        :remote => true,
        :loading => "Element.show('pg_spinner')".html_safe,
        :complete => "Element.hide('pg_spinner')".html_safe,
        :update => options[:element_name].html_safe
        )
      html << '&nbsp;&nbsp;'.html_safe
      html << image_tag('/images/spinner.gif', :alt => 'Loading', :id => 'pg_spinner', :style => "display: none; vertical-align:text-top;")
      html
    end
    html.html_safe
    
  end

  def wiki_help_link
    if "#{self.controller.action_name}" != "index"
      "<a href=\"http://#{HELP_WIKI}/index.php/app/#{self.controller.request.parameters[:controller]}/#{self.controller.action_name}\" target=\"blank\" >wiki-help</a>".html_safe
    else
      "<a href=\"http://#{HELP_WIKI}/index.php/app/#{self.controller.request.parameters[:controller]}\" target=\"blank\" >wiki-help</a>".html_safe
    end
  end

  def otu_blog_link(otu, content_template)
    url_for(:controller => 'public/blog', :action => :otu_page, :otu_id => otu.id, :content_template_id => content_template.id)
  end

end
