# encoding: utf-8

# flexible Specimen and Lot importing, with lots of verification built in
module MaterialAccessions

  class MaterialAccessions::BatchParseError < ApplicationController::BatchParseError
  end

  # not used for verification yet
  # this is the master list of possibly parsed fields, see the wiki for explanation
  ALLOWED_COLUMN_HEADERS = %w(
    ce_id
    count
    data_entry_by
    det_basis
    det_name
    det_otu_id  
    det_year 
    determiner
    identifier
    notes
    otu_id
    otu_name 
    repository_coden
    repository_id
    sex
    stage
    taxon_name_id
    taxon_name_string
    type
    type_of_taxon_name_id
    verbatim_label
    latitude  
    longitude
    elev_min
    elev_max
    elev_unit
    geog_id
    method
    locality 
    sd_d
    sd_m
    sd_y
    ed_d
    ed_m
    ed_y
    collectors
    micro_habitat
    macro_habitat
    time_start
    time_end
  ).collect{|h| h.to_sym}
  # possible additions - Tags, expanding ces

  # for simplified reference
  COLLECTING_EVENT_FIELDS = [
    :latitude,
    :longitude,
    :elev_min,
    :elev_max,
    :elev_unit,
    :method,
    :locality,
    :sd_d,
    :sd_m,
    :sd_y,
    :ed_d,
    :ed_m,
    :ed_y,
    :collectors,
    :micro_habitat,
    :macro_habitat,
    :time_start,
    :time_end
  ]

  # only :file, :proj_id are required
  # see also approaches by the Nearctic Spider Database and the HOL databases OSU
  def self.read_from_batch(options = {})
    opt = {
      :expand_line_breaks => true,
      :line_break_symbol => '||',
      :new_label_symbol =>  '++',
      :col_sep => "\t",
      :proj_id => nil,
      :save => false
    }.merge!(options)

    raise MaterialAccessions::BatchParseError, "No file provided"  if opt[:file].blank?
    raise MaterialAccessions::BatchParseError, "No proj_id provided"  if opt[:proj_id].blank?

    @results = {:specimens => [], :lots => [], :ces => [], :unmatched_headers => [], :identifiers => {}}
   
    #   incoming_encoding = CMess::GuessEncoding::Automatic.guess(opt[:file])
    #   translated_file = Iconv.iconv('UTF-8', incoming_encoding, opt[:file]).first

    translated_file = opt[:file]

    #   # move to another method?
    #   case incoming_encoding
    #   when "UTF-16LE"
    #     translated_file = translated_file[3..translated_file.size] # KLUDGE - hacked to work, not broadly tested
    #   else
    #   end

    # New CSV automagically transcodes   
    # http://www.ruby-doc.org/stdlib/libdoc/csv/rdoc/index.html

    recs = CSV.parse(translated_file, :headers => true, :row_sep => :auto, :header_converters => nil, :col_sep => opt[:col_sep]) # reading from a string http://fastercsv.rubyforge.org/
    #, :encoding => 'UTF-8'   , :encoding => 'u's

    recs.headers.collect{|h| raise(MaterialAccessions::BatchParseError, "Header row invalid, with a blank column name or missing a header. Check also for missplaced column delimiters (typically tab characters).") if h.nil?}
    recs.headers.collect{|h| @results[:unmatched_headers].push(h) unless ALLOWED_COLUMN_HEADERS.include?(h.to_sym) }

    # first deal with validation
    # do all the checks that don't require database hits  
    identifiers = {} 
    recs.each_with_index do |r,x|
      i = x+1
      raise MaterialAccessions::BatchParseError, "Data row #{i} has both neither count (Lot) nor identifier (Specimen), add one." if r.fields('count').first.blank? && r.fields('identifier').first.blank?
      #  raise Specimen::SpecimenBatchParseError, "Data row #{i} has both count (Lot) and identifier (Specimen), remove one." if !r.fields('count').first.blank? && !r.fields('identifier').first.blank?
      raise MaterialAccessions::BatchParseError, "Data row #{i} has no taxon or otu reference" if r.fields('otu_id').first.blank? && r.fields('otu_name').first.blank? && r.fields('taxon_name_string').first.blank? && r.fields('taxon_name_id').first.blank?
      raise MaterialAccessions::BatchParseError, "Data row #{i} has both otu and taxon_name references, remove one." if (!r.fields('otu_id').first.blank? || !r.fields('otu_name').first.blank?) && (!r.fields('taxon_name_id').first.blank? || !r.fields('taxon_name_string').first.blank?)
      raise MaterialAccessions::BatchParseError, "Data row #{i} has both ce_id and verbatim label, remove one." if (!r.fields('ce_id').first.blank? && !r.fields('verbatim_label').first.blank?)
      raise MaterialAccessions::BatchParseError, "Data row #{i} has both repository_id and repository_coden, remove one." if !r.fields('repository_coden').first.blank? && !r.fields('repository_id').first.blank?
      raise MaterialAccessions::BatchParseError, "Data row #{i} has not enough information to define type status." if (!r.fields('type').first.blank? || !r.fields('type_of_taxon_name_id').first.blank?) && (r.fields('type').first.blank? || r.fields('type_of_taxon_name_id').first.blank?) 
      raise MaterialAccessions::BatchParseError, "Data row #{i} has an invalid count." if !r.fields('count').first.blank? && !(r.fields('count').first.to_i > 1)
      raise MaterialAccessions::BatchParseError, "Data row #{i} has both det_otu_id and det_name, remove one." if !r.fields('det_otu_id').first.blank? && !r.fields('det_name').first.blank?
      raise MaterialAccessions::BatchParseError, "Data row #{i} has valid count but no otu_id." if !r.fields('count').first.blank? && (r.fields('count').first.to_i > 1) && r.fields('otu_id').first.blank?

      raise MaterialAccessions::BatchParseError, "Data row #{i} has elev_max but not elev_min." if !r.fields('elev_max').first.blank? && r.fields('elev_min').first.blank?
      raise MaterialAccessions::BatchParseError, "Data row #{i} has elev_min but no elev_unit." if !r.fields('elev_min').first.blank? && r.fields('elev_unit').first.blank?

      raise MaterialAccessions::BatchParseError, "Data row #{i} has an identifier repeated in row #{identifiers[r.fields('identifier').first]}." if identifiers[r.fields('identifier').first]

      identifiers.merge!(r.fields('identifier').first => i) if !r.fields('identifier').first.blank?
      # validate additional determination
    end   

    # reloop and instantiate Specimens/Lots/Ces etc.
   
    @ces = {} # md5 => Ce (index duplicates so we don't create them 2x)
    begin
      Specimen.transaction do
        recs.each_with_index do |r,x|
          i = x + 1
        
          # find the Otu reference
          # via reference to TaxonName
          if r.fields('otu_id').first.blank? && r.fields('otu_name').first.blank? # it's a TaxonName
            @taxon_name = nil
            if !r.fields('taxon_name_id').first.blank? && !r.fields('taxon_name_string').first.blank?
              @taxon_name = TaxonName.find(r.fields('taxon_name_id').first)
              raise MaterialAccessions::BatchParseError, "Data row #{i} has a taxon_name_id that doesn't match the taxon_name_string." if taxon_name.display_for_list != r.fields('taxon_name_string').first
            elsif !r.fields('taxon_name_id').first.blank?
              @taxon_name = TaxonName.find(r.fields('taxon_name_id').first)
            else # must a taxon_name
              taxon_names = TaxonName.find(:all, :conditions => {:name => r.fields('taxon_name_string').first} ) # make this more complicated, break down names
              raise MaterialAccessions::BatchParseError, "Data row #{i} has a taxon_name_string that does not match a name in the DB." if taxon_names.blank? || taxon_names.size == 0
              raise MaterialAccessions::BatchParseError, "Data row #{i} has a taxon_name_string that matches more than one taxon name." if taxon_names.size > 1
              @taxon_name = taxon_names[0]
            end

            otus = Otu.find(:all, :conditions => {:taxon_name_id =>  @taxon_name.id, :proj_id =>  opt[:proj_id]})
            raise MaterialAccessions::BatchParseError, "Data row #{i} has a taxon_name_id that matches more than one Otu." if otus.size >  1
            raise MaterialAccessions::BatchParseError, "Data row #{i} has a taxon_name_id that has no matching Otu." if otus.size == 0
          
            @otu = otus[0]

            # via reference to Otu
          else
            if !r.fields('otu_id').first.blank? && !r.fields('otu_name').first.blank?
              @otu = Otu.find(r.fields('otu_id').first)
              raise MaterialAccessions::BatchParseError, "Data row #{i} has a otu_id with non-matching Otu name." if @otu.name != r.fields('otu_name').first
            elsif !r.fields('otu_id').first.blank?
              # throws not found to catch
              @otu = Otu.find(r.fields('otu_id').first, :conditions => {:proj_id => opt[:proj_id]})
            else
              otus = Otu.find(:all, :conditions => {:name => r.fields('otu_name').first, :proj_id => opt[:proj_id]})
              raise MaterialAccessions::BatchParseError, "Data row #{i} has no matching Otu for otu_name #{r.fields('otu_name').first}." if otus.nil? || otus.size == 0
              raise MaterialAccessions::BatchParseError, "Data row #{i} has an otu_name with 2 or more matching names in DB, include an otu_id or resolve in DB." if otus.size > 1
              @otu = otus[0]
            end
          end

          # at this point we have an @otu, or we've Raised

          # find a Person if requested
          @person = Person.find(:first, :conditions => {:login => r.fields('data_entry_by').first}) if !r.fields('data_entry_by').first.blank?

          # is it a lot or specimen?
          @specimen = nil
          @lot = nil

          if r.fields('count').first.blank? # a specimen
            @specimen = Specimen.new()
            @specimen.creator = @person if @person
            @specimen.updator = @person if @person

            # have to save before adding manys
            @specimen.save if opt[:save]
         
            # we create at least one determination
            @specimen.specimen_determinations << SpecimenDetermination.new(:otu => @otu, :det_on => Time.now)
          else # it's a lot
            @lot = Lot.new()
            @lot.creator = @person if @person
            @lot.updator = @person if @person
            @lot.key_specimens = r.fields('count').first # it has to have this if we are this far
            @lot.otu = @otu                              # has to have this too
            @lot.save if opt[:save]
          end

          # handle identifiers
          if !r.fields('identifier').first.blank?
            id_parts = r.fields('identifier').first.split
            raise MaterialAccessions::BatchParseError, "Data row #{i} has a malformed identifier (#{r.fields('identifier').first})." if id_parts.size != 2
            @namespace = Namespace.find(:first, :conditions => {:name => id_parts[0]})
            raise MaterialAccessions::BatchParseError, "Data row #{i} has an identifier whose namespace (#{id_parts[0]}) is not present in the DB." if @namespace.nil?

            identifier = Identifier.new(:namespace => @namespace, :identifier => id_parts[1])
            identifier.creator = @person if @person
            identifier.updator = @person if @person
            
            if !@specimen.blank?
              raise MaterialAccessions::BatchParseError, "Data row #{i} has a specimen identifier that already exists in the database: (#{@namespace.name} #{id_parts[1]})." if Identifier.find(:first, :conditions => {:namespace_id => @namespace.id, :identifier => id_parts[1]})
              identifier.addressable_id = @specimen.id
              identifier.addressable_type = 'Specimen'
              @results[:identifiers].merge!(@specimen => identifier)

            else
              identifier.addressable_type = 'Lot'
              identifier.addressable_id = @lot.id
              @results[:identifiers].merge!(@lot => identifier)
            end
          end


          # handle the repository
          @repository = Repository.find(r.fields('repository_id').first) if !r.fields('repository_id').first.blank?
      
          @repository = Repository.find(:first, :conditions => {:coden => r.fields('repository_coden').first}) if !r.fields('repository_coden').first.blank?
          raise MaterialAccessions::BatchParseError, "Data row #{i} has Repository which can not be found." if (!r.fields('repository_coden').first.blank? || !r.fields('repository_id').first.blank?) && @repository.nil?
          @lot.repository = @repository if @repository && @lot
          @specimen.repository = @repository if @repository && @specimen

          if !r.fields('type').first.blank?
            raise MaterialAccessions::BatchParseError, "Data row #{i} has an invalid type_of_taxon_name_id (#{r.fields('type_of_taxon_name_id')})." if !TaxonName.find(r.fields('type_of_taxon_name_id').first)
            @specimen.type_specimens << TypeSpecimen.new(:taxon_name_id => r.fields('type_of_taxon_name_id').first, :type_type => r.fields('type').first)
          end

          # handle determinations
          if !r.fields('det_otu_id').first.blank? || !r.fields('det_name').first.blank?
            sd = SpecimenDetermination.new()
            sd.det_on = Date.new( r.fields('det_year').first.to_i ) if !r.fields('det_year').first.blank?
            if !r.fields('det_otu_id').first.blank?
              o = Otu.find(r.fields('det_otu_id').first)
              raise MaterialAccessions::BatchParseError, "Data row #{i} has a det_otu_id which can not be found." if !o
              sd.otu = o
            else
              sd.name = r.fields('det_name').first
            end
            sd.determination_basis = r.fields('det_basis').first if !r.fields('det_basis').first.blank?
            sd.creator = @person if @person
            sd.updator = @person if @person
            @specimen.specimen_determinations << sd
          end
 
          # handle collecting events
          if !r.fields('verbatim_label').first.blank? || !r.fields('ce_id').first.blank?
            if !r.fields('verbatim_label').first.blank?
              l = r.fields('verbatim_label').first.split(opt[:new_label_symbol]).map{|i| i.strip.split(opt[:line_break_symbol]).map{|j| j.strip}.join("\n")}.join("\n\n")
              md5 = Ce.generate_md5(l)
           
              if @ce = Ce.find(:first, :conditions => {:verbatim_label_md5 => md5, :proj_id => opt[:proj_id] })
                COLLECTING_EVENT_FIELDS.each do |f|
                  if !r.fields(f.to_s).blank? && !@ce[f].blank? # handles various empty/nil combinations
                    raise MaterialAccessions::BatchParseError, "Data row #{i} has mx Ce with id #{@ce.id} matching, but field mismatch for field [#{f.to_s}] mismatch (proposed/existing): (#{r.fields(f.to_s)} / #{@ce[f]})." if r.fields(f.to_s) != @ce[f]
                  end
                end

              else # @ce is not found in existing
           
                if !@ces[md5]  # @ce has not been created in new
                  @ce = Ce.new(:verbatim_label => l)
                  COLLECTING_EVENT_FIELDS.each do |f|
                    @ce[f] = r.fields(f.to_s).first if !r.fields(f.to_s).first.blank?
                  end
                  @ces.merge!(md5 => @ce) # keep track of what we've added !! IMPORTANT: Uniqueness is determined solely by verbatim label
                
                else @ce # has been previously created or found and can be referenced
                  @ce = @ces[md5]
                end
            
              end

            else # reference to Ce in form of ID
              @ce = Ce.find(r.fields('ce_id').first)
              raise MaterialAccessions::BatchParseError, "Data row #{i} has ce_id which is not in the DB." if !@ce
            end
         
            @lot.ce = @ce if @lot
            @specimen.ce = @ce if @specimen
          end
        
          ## at this point we have either @specimen OR @lot instantiated or have raised
          ['sex', 'stage', 'notes'].each do |p|
            if !r.fields(p).first.blank?
              @lot[p] = r.fields(p).first if @lot
              @specimen[p] = r.fields(p).first if @specimen
            end
          end
         
          @results[:specimens].push @specimen if @specimen
          @results[:lots].push @lot if @lot
        end
   
        @results[:ces] = @ces.values

        # save the identifiers/ces etc.
        if opt[:save]
          [:ces, :specimens, :lots].each do |s| # REVISIT
            @results[s].map{|o| o.save!}
          end
          @results[:identifiers].values.map{|o| o.save!}
        end
       
      end # end the transaction

    rescue MaterialAccessions::BatchParseError
      raise
    rescue ActiveRecord::RecordInvalid => e
      raise "Error during saving a record (#{e})."
    end

    return @results
  end
 
end

