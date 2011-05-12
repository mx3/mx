class Nexml
  # this is currently bare bones NeXML translation, but it should be an easily expandable (namespaces etc.)
  # because we already have unique ids (in mx) for most objects the translation is pretty straightforward

  attr :doc
  attr_reader :mx

  def initialize(options)
    @opt = {
      :target => "xml", 
      :include_otus => true,
      :include_chrs => true,
      :include_codings => true, 
      :include_trees => true
    }.merge!(options).to_options

    @mx = @opt[:mx]

    @doc = Builder::XmlMarkup.new(:indent => 2, :target => @opt[:target])
    @doc.instruct!(:xml, :version => "1.0", :encoding => "ISO-8859-1")
  
    # return and RDF triple version
    if @opt[:transform]
     @doc.instruct!('xml-stylesheet', :type => 'text/xsl', :href => '/stylesheets/roger_messing.xsl')  
     # <?xml-stylesheet type="text/xsl" href="cdcatalog.xsl"?>
    end
  
    @doc.tag!("nex:nexml", 
              :version => "0.8", # this will update to "0.8" 
              'xmlns' => "http://www.nexml.org/1.0",
              'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
              'xsi:schemaLocation' => 'http://www.nexml.org/1.0 http://www.nexml.org/nexml/xsd/nexml.xsd', # this might be borked
              'xmlns:nex' => "http://www.nexml.org/1.0",
              'xmlns:xi' => "http://www.w3.org/2003/XInclude",
              'xmlns:xlink' => "http://www.w3.org/1999/xlink",
              'generator' => 'mx'
             ) do |d|

             # @doc.dict('xsi:type' => "nex:RCSId") do |d|
             #   @doc.key("id")
             #   @doc.string("$Id: taxa.xml 201 2007-11-12 13:03:38Z rutgeraldo $")
             # end

              include_otus if @opt[:include_otus]
              include_chrs if @opt[:include_chrs] && @mx.codings.size > 0
              include_trees if @opt[:include_trees]
    end
  end

  private

  def include_otus
      @doc.otus(
        :id => 'taxa1',
        :label => 'taxa_block',
        'xml:base' => 'http://foo.bar.org/', #  indicating the base url of the resource
        'xml:id' => 'taxa1', # a file-scope unique ID
        'class'=> "taxset1",
        'xlink:href' => '#taxa1', # a link to somewhere else
        'xml:lang' => "EN") do |b|
        @mx.otus.each do |o|
          @doc.otu(:id => "t#{o.id}", :label => o.display_name(:type => :matrix_name))
        end

      end
  end

  def include_chrs
    @uncertain_cells = {}
    @doc.characters(:id => 'c0', :otus => 'taxa1', :label => 'characters block', 'xsi:type' => 'nex:StandardCells') do |d|
     @doc.format do |f|  # all characters listed within this 
        @mx.chrs.each do |c|
          @doc.states(:id => "states_for_chr_#{c.id}") do |states| # all individual states, and each cell with a unique combination of states needs a state & or set
            # we need to uniquely identify every state (EASY- use db id) 
            # AND also every missing character (i.e. "?")
                   
            # the states are easy because we have built in IDs
            c.chr_states.each_with_index do |cs,i|
              @doc.tag!(:state, :id => "cs#{cs.id}", :label => cs.name, :symbol => "#{i}") 
            end

            # the missing character is a little trickier since we don't explicitly provide a ChrState for them
            # so we create an id using the Chr.id and + "missing", this makes it easy to refer back 
            @doc.tag!(:state, :id => "missing#{c.id}", :symbol => c.chr_states.size, :label => "?")

            # now we have to actually look at the matrix to get the uncertain/polymorphic cells
            # we should cache this for later use as well
            # DON'T CONFUSE POLYMORPHIC vs UNCERTAIN ... not defined in mx per say, maybe an output option
            uncertain = @mx.polymorphic_cells_for_chr(:chr => c, :symbol_start => c.chr_states.size + 1)
            
            uncertain.keys.each do |pc|
              # the id of a given uncertain state set is composed as follows:
              # cs<Chr.id>unc<symbol>
              # we do this so that we can back reference using position BUT
              # in the by cell version we don't need symbols, so just make a unique ID by concatinating
              # the ids of the states in question
              @doc.uncertain_state_set(:id => "cs#{c.id}unc_#{uncertain[pc].sort.join}", :symbol => pc) do |uss|
                uncertain[pc].collect{|m| @doc.tag!(:member, :state => "cs#{m}") }
              end
            end

            @uncertain_cells[c.id] = uncertain
          end # end chrs loop generating states
        end # end characters/state definitions
        
      # the character id/names, coming after states because they need to reference states
     @mx.chrs.collect{|c| @doc.tag!(:char, :id => "c#{c.id}", :states => "states_for_chr_#{c.id}", :label => c.name)}

     end # end format

      include_codings(@uncertain_cells) if @opt[:include_codings]

    end
  end

  def include_codings(uncertain_cells)
    @codings = @mx.codings_in_grid({}) # gets all the codings in a 3d grid

    # I should just be able to get the polymorphic states for chr, then reverse the hash, loop through them to get the index
    
    @doc.matrix do |m|
      @mx.otus.each do |o|
        @doc.row(:id => "row#{o.id}", :otu => "t#{o.id}") do |r| # use Otu#id to uniquely id the row

          # cell representation
          @mx.chrs.each do |c|

            codings = @codings[@mx.chrs.index(c)][@mx.otus.index(o)]
             
            case codings.size
            when 0 
              state = "missing#{c.id}"
            when 1
              state = "cs#{codings[0].chr_state_id}"
            when 2
              state = "cs#{c.id}unc_#{codings.collect{|i| i.chr_state_id}.sort.join}" # should just unify identifiers with above.
            end

            @doc.tag!(:cell, :char => "c#{c.id}", :state => state)
          end
        end # end the row
      end

    end
  end
  						
  def include_trees
    @doc.trees(:otus => 'taxa1', :id => "tree_#{@mx.id}", :label => @mx.display_name) do |tree_block|
      @mx.trees.each do |mx_tree|
        # possible types are nex:IntNetwork,  
        @doc.tree(:id => "t#{mx_tree.id}", 'xsi:type' => "nex:IntTree", :label => mx_tree.display_name) do |doc_tree|
          # we dont' handle networks, so we traverse the nodes 2x, once for nodes, once for edges  
          mx_tree.tree_nodes.each do |node|
            @doc.node({:id => "node_#{node.id}", :label => "n#{node.id}"}.update(node.otu_id.blank? ? {} : {:otu => "t#{node.otu_id}" }).update(node.parent_id.blank? ? {:root => true} : {}))
          end
          mx_tree.tree_nodes.each do |edge|
            @doc.edge(:target => "node_#{edge.id}", :source => "node_#{edge.parent_id}", :id => "e#{edge.id}", :length => 1 ) if !edge.parent_id.blank?
          end
        end
      end
    end
  end
end

