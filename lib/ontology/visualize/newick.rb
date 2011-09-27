# you must restart the server when changes are made to this file

module Ontology::Visualize::Newick

  # update this array when the method is returns- ultimately class these out
  ONTOLOGY_COLOR_MODES = [:random, :tags, :depth, :immediate_part_of_children, :logical_children, :oldest_sensu_tag, :attached_muscles, :number_of_sensus, :number_of_labels]

  # return a Newick string representation of an Ontology
  # Is there a way to do the recursive traversal so the gsub cheat isn't neaded at the end?
  def self.newick_string(options = {})
    return "ERROR: :ontology_class not set." if options[:ontology_class].nil? 
  
    # kludge 
    options.merge!(:rel1 => Proj.find(options[:ontology_class].proj_id).object_relationships.by_interaction('is_a').first.id) if options[:rel1].nil?
    options.merge!(:rel2 => Proj.find(options[:ontology_class].proj_id).object_relationships.by_interaction('part_of').first.id) if options[:rel2].nil?

    @opt = {  # requires @ for recursion?
      :ontology_class => nil,        # an OntologyClass, initially the root, then the present node
      :max_depth => 999,             # the maximum depth to recurse to
      :depth => 0,                   # the current depth we're at
      :hilight_depth => 5,           # the maximum depth at which to highlight nodes/branches
      :string => '',                 # the Newick string to return
      :relationship_type => 'all',   # or an Array of ObjectRelationship#ids !! careful for recusrion with is_a, part_of 
      :labels => [],                 # contains all existing terminal labels within the Newick string, so that labels can be modified for display
      :parent => '',                 # internally referenced
      :color => :random,             # see mode to color in, see Ontology::Visualize::Newick#_newick_color
      :color_bin => [],              # TODO: used in prior versions for jacknifing color selection -- NOT FUNCTIONAL 
      :annotate_value => false,      # include value= statement (incoming/original value for color) in the newick tree
      :annotate_index => false,      # include index= statement (transformed/index value for color) in the newick tree
      :annotate_clades => false,     # include the !hilight= statement in the newick tree
      :annotate_branches => false,   # include the !color= statement in the newick tree
    }.merge!(options.symbolize_keys)

    return "ERROR: hilight_depth > max_depth" if @opt[:hilight_depth] > @opt[:max_depth]

    # convenience alias
    oc = @opt[:ontology_class]

    # Newick trees can only have unique terminal labels, make sure they are so
    n = oc.label_name(:type => :preferred)
   
    if !n.nil?  
     n.gsub!(/'/,"-") # no apostrophes
    else
     n = "not labeled"
    end 

    if @opt[:labels].include?(n) 
      n = "#{n}-"
      while @opt[:labels].include?(n)
        n = "#{n}-"
      end 
    end

    @opt[:labels] << n                              # "remember" which labels we are using 
    n = "'#{n}'"

    # puts "opening depth: #{@opt[:depth]}"
    # puts "max depth: #{@opt[:max_depth]}"
    # puts "label: #{n}" 

    if @opt[:depth] < @opt[:max_depth]              # render only as deep as requested 
      @opt[:depth] = @opt[:depth] + 1
        
      children = oc.child_ontology_relationships(@opt) # no :depth in a child
      # puts "# children: #{children.size}"
      # render the terminal labels and associated structure 
      if children.size == 0
        @opt[:string] << "#{n}"

        # color it?  (no labeling terminal branches)
        if @opt[:hilight_depth] - @opt[:depth] + 1 > 0 && ONTOLOGY_COLOR_MODES.include?(@opt[:color])
          @opt[:string] << "[&#{_newick_color(@opt)}]" 
        end

        @opt[:string] << "," 
        # puts @opt[:depth]
        return @opt[:string] 
      else
        @opt[:string] << "#{n}"  
        # color it? (no labeling terminal branches)
        if @opt[:hilight_depth] - @opt[:depth] + 1 > 0 && ONTOLOGY_COLOR_MODES.include?(@opt[:color])
          @opt[:string] << "[&#{_newick_color(@opt)}]" 
        end

        if @opt[:depth] + 1 < @opt[:max_depth] # look ahead
          @opt[:string] << ",("
        else
          @opt[:string] << ","
        end
      end

      # recurse the children
      @opt[:parent] = oc.label_name(:type => :preferred) 
      if @opt[:depth] < @opt[:max_depth]   
        children.each do |c|
          newick_string(@opt.merge!(:ontology_class => c.ontology_class1))
          @opt[:depth] = @opt[:depth] - 1 # because we pass the depth along now we need to drop back once we've jumped in
          # puts "after child:: #{@opt[:string]}"
        end
      end

      # and add closing structure 
      if @opt[:depth] + 1 < @opt[:max_depth] # look ahead 
        @opt[:string] << ")"

        # color and label the preceeding node? 
        if @opt[:hilight_depth] - @opt[:depth] + 1 > 0  && ONTOLOGY_COLOR_MODES.include?(@opt[:color])
          @opt[:string] <<  "[&!name=#{n[1..(n.length - 2)]}" 
          @opt[:string] << ",#{_newick_color(@opt.merge(:ontology_class => oc))}" 
          @opt[:string] << "]"
        end

        (@opt[:string] << ",") if children.size > 0
      end
    end # end depth check

    # hack, to deal with the extra "," in the "join" 
    return "(#{@opt[:string]})".gsub(/,\)/, ")") + ";"
  end 

  # returns a Figtree specific branch/node hilight statement
  def self._newick_color(opt = {})
    # convenience alias
    oc = opt[:ontology_class]

    child_clade_width = 0

    if opt[:annotate_clades]
      # the total number of children as rendered in the present tree, hilights an arc in Figtree
      # CAREFUL - we only want children form this point forward
      child_clade_width = oc.related_ontology_relationships(opt.merge(:max_depth => (opt[:max_depth].to_i - opt[:depth].to_i))).size
    end
   
    i = -1 
    s = -1

    case opt[:color]
    when :random
      i = rand(10)
      s = i
      color = ColorHelper::palette(:index => i)  
  # when :jacknifed_random 
  #   i = rand(10)
  #   opt[:color_bin] = [] if opt[:color_bin].size == 10 
  #   color = ColorHelper::palette(:index => i)
  #   until !opt[:color_bin].include?(color) do
  #     i = rand(10)
  #     color = ColorHelper::palette(:index => i)
  #   end
  #   opt[:color_bin].push(color)

    when :depth # maxes at 8
      # color = ColorHelper::hexstr_to_signed32int("ff00#{"%x" % (255 - opt[:depth] * 10)}00")
      s = opt[:depth] 
      i = s > 8 ? 8 : s 
      color = ColorHelper::palette(:palette => :cb_seq_9_mh_green, :index => i) 
    when :immediate_part_of_children
      s = oc.child_ontology_relationships(:relationship_type => Proj.find(oc.proj_id).object_relationships.by_interaction('part_of').first.id).size
      case s
      when 0 
        i = 0
      when 1
        i = 1
      when 2..4  
        i = 2
      when 5..7
        i = 3
      when 8..10
        i = 4
      when 11..13
        i = 5
      when 14..16
        i = 6
      when 17..19
        i = 7
      when 20..999999
        i = 8
      else
        i = 0 
      end 
      color = ColorHelper::palette(:index => i, :palette => :heat_9)

  #when :parts_refs
   #  s = oc.ontology_classes.size
   #  case s
   #  when 0..99 
   #    i = s
   #  when 100..10000
   #    i = 100 
   #  else
   #    i = 0 
   #  end 
   #  color = ColorHelper::palette(:index => i, :palette => :blue_100)
   #when :parts_in_refs_count
   #  # TODO: update this to Terms
   #  s = oc.labels_ref.inject(0){|sum, pr| sum += pr.total}
   #  case s
   #  when 0..99 
   #    i = s
   #  when 100..10000
   #    i = 100 
   #  else
   #    i = 0 
   #  end 
   #  color = ColorHelper::palette(:index => i, :palette => :blue_100)
   
    when :attached_muscles
      s = oc.child_ontology_relationships(:relationship_type => Proj.find(oc.proj_id).object_relationships.by_interaction('attaches_to').first.id).size
      case s
      when 0 
        i = 0
      when 1
        i = 1
      when 2..4  
        i = 2
      when 5..7
        i = 3
      when 8..10
        i = 4
      when 11..13
        i = 5
      when 14..16
        i = 6
      when 17..19
        i = 7
      when 20..999999
        i = 8
      else
        i = 0 
      end 
      color = ColorHelper::palette(:index => i, :palette => :heat_9)

    when :number_of_labels
      s = oc.labels.count
      case s
      when 0 
        i = 0
      when 1
        i = 1
      when 2..4  
        i = 2
      when 5..7
        i = 3
      when 8..10
        i = 4
      when 11..13
        i = 5
      when 14..16
        i = 6
      when 17..19
        i = 7
      when 20..999999
        i = 8
      else
        i = 0 
      end 
      color = ColorHelper::palette(:index => i, :palette => :heat_9)

    when :number_of_sensus
      s = oc.sensus.count
      case s
      when 0 
        i = 0
      when 1
        i = 1
      when 2..4  
        i = 2
      when 5..7
        i = 3
      when 8..10
        i = 4
      when 11..13
        i = 5
      when 14..16
        i = 6
      when 17..19
        i = 7
      when 20..999999
        i = 8
      else
        i = 0 
      end 
      color = ColorHelper::palette(:index => i, :palette => :heat_9)

    when :logical_children
      s = oc.logical_relatives.size
      case s
      when 0 
        i = 0
      when 1
        i = 1
      when 2..4  
        i = 2
      when 5..7
        i = 3
      when 8..10
        i = 4
      when 11..13
        i = 5
      when 14..16
        i = 6
      when 17..19
        i = 7
      when 20..999999
        i = 8
      else
        i = 0 
      end 
      color = ColorHelper::palette(:index => i, :palette => :heat_9)

    when :oldest_sensu_tag
      sensu = oc.sensus.ordered_by_age.first
      if !sensu.nil? 
       s = sensu.ref.year.to_i
      else
        s = 0 
      end
      oldest_year = 1870 
      unit_range = 10 
      if s.to_i < oldest_year && s.to_i != 0  
        i = unit_range - 1 
      elsif s == 0
        i = 0
      else
        i = (((Time.now.year.to_i - (s.to_i == 0 ? Time.now.year.to_i : s.to_i)).to_f / (Time.now.year.to_i - oldest_year).to_f) * unit_range).to_i
      end
      s ||= 0
      if i == 0
        color = ColorHelper::palette(:index => 15, :palette => :grey_scale)  # white
      else 
        color = ColorHelper::palette(:index => i, :palette => :blues_10)
      end
    when :tags
      s = oc.tags.size
      if s == 0
        i = 0
      elsif s > 9 
        i = 9 
      end
      color = ColorHelper::palette(:index => i, :palette => :blues_10)
    end

    annotations = []
    annotations << "!color=#{color}" if opt[:annotate_branches]
    annotations << "!hilight={#{child_clade_width},0.0,##{color}}" if opt[:annotate_clades] && (child_clade_width > 1) 
    annotations << "value=#{s}" if opt[:annotate_value]
    annotations << "index=#{i}" if opt[:annotate_index]

    annotations.join(",")
  end

end

