# encoding: utf-8
class MaterialExamined
  # a table-less class that summarizes distribution data for an OTU

  # is display-based rather than id based- literal text is used as symbols

  # [:type_status]* [:country][:state][:county][:repository][:sex][:count] [ids]* [type status]*
  
  # assumes all states have countries, and all counties have states
  
   attr_reader :me # the gi-normous hash
   attr_reader :total_specimens

#   attr_reader :holotype
#   attr_reader :paratypes
#   attr_reader :syntypes
#   attr_reader :lectotype
#   attr_reader :paralectotypes
#   attr_reader :other_material

  attr_reader :otu
  attr_reader :specimens
#  attr_reader :lots

  # attr_writer :otu_id

 def initialize(options = {})
   opt = {
      :otu_id => nil,
      :include_specimen_identifiers => :most_recent, # :most_recent, :all, :first
      :include_distributions => false, # true might not work now
      :include_lots => false,          # true might not work now
      :include_specimens => true
   }.merge!(options.symbolize_keys)

   return false if opt[:otu_id].blank?

   @otu = Otu.find(opt[:otu_id])
   @specimens = @otu.specimens 

   $MATERIAL_CATEGORIES = %w/holotype lectotype neotype syntype paratype paralectotype/ # "other" is added via a method 

   # @otu.specimenstype_specimens.with_type_status('holotype')

   @me = HashFactory.call # see Proc in environment.rb
   o = Otu.find(opt[:otu_id])
  
   $total_specimens = 0
   
   _from_distributions(o) if opt[:include_distributions]
   _from_lots(o) if opt[:include_lots]
   _from_specimens(o) if opt[:include_specimens]
 end

  # return the hash^hashes
  def me
   @me
  end
   
  def total_specimens
    $total_specimens
  end

  def full_me_for_specimens
    # handles specimens in $MATERIAL_CATEGORIES
      
     specimens = {}
     $MATERIAL_CATEGORIES.map{|c| specimens[:c] == []}
     $MATERIAL_CATEGORIES.each do |c|
       if @otu.taxon_name.blank? 
         specimens.merge!(c.to_sym => Specimen.determined_as_otu(@otu).with_type_status(c)) # IMPORTANT: this returns specimens that might be presently identified as ANOTHER OTU (i.e. it retains historical dets)
       else # We make assume that if Otu#taxon_name is present that we'll restrict by that scope
         specimens.merge!(c.to_sym => Specimen.determined_as_otu(@otu).with_type_assignment_for_taxon_name(@otu.taxon_name).with_type_status(c))
       end
     end

    # run some checks
    raise "err in data, > 1 Holotype for #{taxon}" if specimens[:holotype].size > 1
    raise "err in data, > 1 Lectotype for #{taxon}" if specimens[:lectotype].size > 1
    raise "err in data, > 1 Neotype for #{taxon}" if specimens[:neotype].size > 1
    raise "err in data, both Holotype and Lectotype designations present for #{taxon}" if specimens[:lectotype].size == 1 && specimens[:holotype].size == 1
    raise "err in data, both Holotype and Neotype designations present for #{taxon}" if specimens[:neotype].size == 1 && specimens[:holotype].size == 1
    raise "err in data, both Neotype and Lectotype designations present for #{taxon}" if specimens[:neotype].size == 1 && specimens[:lectotype].size == 1

    # run some more checks	
    raise "err in data, Syntypes and Holo/Lecto/Neo/Para types found in combination for #{taxon}" if specimens[:syntype].size == 1 && (specimens[:paratype].size > 0 || specimens[:lectotype].size > 0 || specimens[:neotype].size > 0 || specimens[:holotype].size > 0) 

    # note this does not take into account a most recent determination, i.e. it is historically accurate!
    specimens[:other] = Specimen.determined_as_otu(@otu).without_type_assignment

    # begin to construct the string 
    s = '' 

    # there can be only one of these
    s << specimens[:holotype].first.verbose_material_examined_string(:otu => @otu) if specimens[:holotype].size > 0
    s << specimens[:lectotype].first.verbose_material_examined_string(:otu => @otu) if specimens[:lectotype].size > 0
    s << specimens[:neotype].first..verbose_material_examined_string(:otu => @otu) if specimens[:neotype].size > 0

    # countr_str includes trailing period
    s << " Paratypes (#{sex_str(specimens[:paratype])}): #{country_str(specimens[:paratype])}" if specimens[:paratype].size > 0
    s << " Syntypes (#{sex_str(specimens[:syntype])}): #{country_str(specimens[:syntype])}" if specimens[:syntype].size > 0
    s << " Paralectotypes (#{sex_str(specimens[:paralectotype])}): #{country_str(specimens[:paralectotype])}" if specimens[:paralectotype].size > 0
    s << " Other material (#{sex_str(specimens[:other])}): #{country_str(specimens[:other])}" if specimens[:other].size > 0

    s 
  end

  # pass an array of specimens
  def sex_str(specimens)
    v = {}
    specimens.each do |s|
      v[s.sex] = 0 if !v[s.sex]
      v[s.sex] += 1
    end
    sx = []
    v.keys.sort.each do |k|
      sx << (v[k] == 1 ? "1 #{k}" : "#{v[k]} #{k}s")
    end
   
    sx.join(", ")
  end

  def id_str(specimens)
    v = {}
    v["mx_id"] = [] 
    specimens.each do |s|
      if s.identifiers.count == 0
        v["mx_id"] << s.id.to_i
      else
        if v[s.identifiers.first.namespace.name].nil? ## IMPORTANT - we're only = handling the first identifier her, reorder them if need be
          v[s.identifiers.first.namespace.name] = [s.identifiers.first.identifier]
        else
          v[s.identifiers.first.namespace.name] << s.identifiers.first.identifier
        end
      end
    end
   v.delete("mx_id") if v["mx_id"] == []  
    ns = []
    v.keys.sort.each do |n|
      s = ''
      s += "#{n} "
      s += ArrayHelper::array_as_range(v[n])
      ns.push(s)
    end

    ns.join("; ")
  end

  # pass an array of specimens
  def inst_str(specimens)
    is = []
    v = {}
    v["unknown"] = []
    specimens.each do |s|
      if !s.repository.blank? && !s.repository.coden.blank?
        if v[s.repository.coden].nil?
            v[s.repository.coden] = [s]
        else
          v[s.repository.coden] << s
        end
      else
        v["unknown"] << s
      end
    end
    v.delete("unknown") if v["unknown"].size == 0 
    ls = []
     v.keys.each do |r|
      s = ''
      s += id_str(v[r])
      s += " (#{r})"
      ls << s
    end 
     ls.join("; ")
  end

  # pass an array of specimens
  def country_str(specimens)
   v = {} 
   v["country not specified"] = []
    specimens.each do |s|
      if !s.ce.blank? && !s.ce.geog.blank? && !s.ce.geog.country.blank? && !s.ce.geog.country.name.blank?
        if v[s.ce.geog.country.name].nil?
          v[s.ce.geog.country.name] = [s]
        else
          v[s.ce.geog.country.name] << s
        end
      else
        v["country not specified"] << s
      end
    end
    v.delete("country not specified") if v["country not specified"].size == 0 
    is = []
    v.keys.sort.each do |c|
     txt = "#{c.upcase}: "
     txt << sex_str(v[c])
     txt += ". "
     txt += inst_str(v[c]) + "."
     is << txt
    end
    is.join(" ") 
  end


  ## The methods below this are summaries

  # render a quick display (should move to a helper likely)
   def display_quick
     s = ''
     for i in @me.keys
        s << " <b>#{i}.</b><br/>"   # country
        for j in @me[i].keys
          s << "&nbsp;<b>#{j}:</b><br/>" if not j == 'unknown'  # state
          for k in @me[i][j].keys
            s << "&nbsp;&nbsp;#{k}<br/>" if not k == 'unknown'  # county
            for l in @me[i][j][k].keys
              s <<  ("&nbsp;&nbsp;" + (l == 'unknown' ? "<i>repository not given</i>"  : "&nbsp;&nbsp;#{l}") + "<br/>") if not l == nil  # repository
              s << "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" + @me[i][j][k][l].keys.collect{|m| 
                ("#{@me[i][j][k][l][m]} " +
                  case m    # the count
                  when 'female'
                     "&#9792;"
                  when 'male'
                     "&#9794"
                  when 'gynadropmorph'
                     "[&#9792;&#9794;]"
                  else
                     "unknown sex"
                 end)}.join(",")      
               s << "<br/>"        
            end
          end
        end
      end
     s
   end

   # female: &#9792; 
   # male: &#9794;
 
 protected

  # crude and somewhat duplicated- could be simplified for sure
  def _from_distributions(otu)
    ds = otu.distributions

      sex = 'unknown'
      rep = 'unknown'

    if not ds == nil
      for d in ds
        if d.geog_id

          country = d.geog.country ? d.geog.country.name : 'unknown'
          state = d.geog.state ? d.geog.state.name : 'unknown'
          county = d.geog.county ? d.geog.county.name : 'unknown'

          # ug-leee
          @me[country][state][county][rep][sex] == {} ?
          @me[country][state][county][rep][sex] = d.num_specimens :  
          @me[country][state][county][rep][sex] += d.num_specimens
        else  
          @me[:unknown][:unknown][:unknown][rep][sex]  == {} ?
          @me[:unknown][:unknown][:unknown][rep][sex]  = d.num_specimens :  
          @me[:unknown][:unknown][:unknown][rep][sex]  += d.num_specimens
        end
          $total_specimens +=  d.num_specimens
      end 
    end
  end

  def _from_lots(otu)
    ls = otu.lots
    sex = 'unknown'
  
    if not ls == nil
      for l in ls
        l.repository_id ? rep = l.repository.coden : repository = 'unknown'
        if l.ce
          if l.ce.geog_id
            country = l.ce.geog.country.name
            state = l.ce.geog.state ? l.ce.geog.state.name : 'unknown'
            county = l.ce.geog.county ? l.ce.geog.county.name : 'unknown'

            # ug-leee
            @me[country][state][county][rep][sex] == {} ?
            @me[country][state][county][rep][sex] = l.key_specimens + l.value_specimens :  
            @me[country][state][county][rep][sex] += l.key_specimens + l.value_specimens    
      
          else  
            @me[:unknown][:unknown][:unknown][rep][sex]  == {} ?
            @me[:unknown][:unknown][:unknown][rep][sex]  = l.key_specimens + l.value_specimens :  
            @me[:unknown][:unknown][:unknown][rep][sex]  += l.key_specimens + l.value_specimens
        
          end
         else
          # just add one to the Unknown
            @me[:unknown][:unknown][:unknown][rep][sex] == {} ?
            @me[:unknown][:unknown][:unknown][rep][sex] = l.key_specimens + l.value_specimens :  
            @me[:unknown][:unknown][:unknown][rep][sex] += l.key_specimens + l.value_specimens
          end
          $total_specimens += l.key_specimens + l.value_specimens
       end     
     end
  end


  def _from_specimens(otu)
    ss = otu.specimens
    if  ss.size > 0
      for s in ss 
        s.repository_id ? rep = s.repository.coden : sex = 'unknown'
        s.sex ? sex = s.sex : sex = 'unknown'
        
        if s.ce
          if s.ce.geog_id
            country = s.ce.geog.country ? s.ce.geog.country.name : 'unknown'
            state = s.ce.geog.state ? s.ce.geog.state.name : 'unknown'
            county = s.ce.geog.county ? s.ce.geog.county.name : 'unknown'

            # ug-leee
            @me[country][state][county][rep][sex] == {} ?
            @me[country][state][county][rep][sex] = 1 :  
            @me[country][state][county][rep][sex] += 1    
          else  
            @me[:unknown][:unknown][:unknown][rep][sex]  == {} ?
            @me[:unknown][:unknown][:unknown][rep][sex]  = 1 :  
            @me[:unknown][:unknown][:unknown][rep][sex]  += 1
          end
        else
          # just add one to the unknown
            @me[:unknown][:unknown][:unknown][rep][sex]  == {} ?
            @me[:unknown][:unknown][:unknown][rep][sex]  = 1 :  
            @me[:unknown][:unknown][:unknown][rep][sex]  += 1
        end
        $total_specimens += 1
      end
    end
 end
 
end
