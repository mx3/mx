$USAGE = 'Call like: "rake mx:load_lots file=~/Desktop/extractionUFdb.csv person=1 project=1'

## The CSV file provided must use ; as separator (or modify line 32), text delimiter should be empty (the default is " in openoffice)
## The columns shouldn't have any heading and must respect the following order
  #0  Master ID for the lots (variable name 'mid')
  #1  previous_numbers/field numbers
  #2  counts
  #3  class (probably not useful here)
  #4  family (probably not useful here)
  #5  taxon (in fact closer to OTU than taxon name)
  #6  id_by
  #7  station number
  #8  continent_ocean
  #9  country_archipelago
  #10 primary sub division
  #11 secondary sub division
  #12 locality
  #13 habitat
  #14 microhabitat
  #15 latitude
  #16 longitude
  #17 association (i.e. is there a subsample?)

## BE CAREFUL! Don't forget to change all the namespace IDs
$nid_mid = 1 # namespace ID for master/collection identifiers
$nid_fid = 2 # namespace ID for field identifiers

def load_lot_file(f)
  list_specimen = []
  raise "unable to read from file '#{f}'" if not File.readable?(f)

  IO.readlines(f).collect {  |l| l.chomp!; list_specimen.push(l.split(";"))}

  list_specimen
end

def check_unique_id(ln)
  # get list of IDs
  list_id = ln.collect { |aLot| aLot[0] }

  # make general test to detect if duplicates are present
  list_id.uniq!

  if list_id.length == ln.length
    puts "no duplicates found"
    return true
  else      # here starts the trouble
    pb_id = Array.new
    i_pb = 0
    list_id = ln.collect { |aLot| aLot[0] }

    # look for identical numbers
    for i in 0..list_id.length-1
      x = list_id.find_all {  |anID| anID == list_id[i] }
      if x.length > 1
        pb_id[i_pb] = x
        i_pb += 1
      end
    end

    # flatten and remove duplicates so it's easier to read
    pb_id = pb_id.flatten
    pb_id = pb_id.uniq

    puts "You have #{pb_id.length} duplicates in your database. Remove them before importing them. Here is their IDs:"
    pb_id.each { |x| puts x }
    return false
  end

end

def create_verbatim_label(lot)
  l_tmp = lot

  # subset just the elements of interest to make a collecting event label
  el = [ l_tmp[7], l_tmp[8], l_tmp[9], l_tmp[10], l_tmp[11], l_tmp[12], l_tmp[13], \
          l_tmp[14], l_tmp[15], l_tmp[16] ]

  ## TODO - how about creating collecting events from this?

  label = ""

  for i in el
    next if i.nil? or i.length == 0

    label << i
    label << ", "
  end

  label.squeeze!(" ") # remove extra space (just in case)
  label.strip!        # remove trailing space

  # remove ending comma
  label[label.length-1] = "" if(label[label.length-1] == 44)

  return label
end

def nbed_species(otu_nm)
  # test if the OTU name is a number species (e.g. Holothuria sp. 22)
  lot_nm = otu_nm.split(" ")
  lot_sp = lot_nm[lot_nm.length-1]

   if not lot_sp.to_i == 0
      lot_nb = lot_nm[lot_nm.length-2] + " " + lot_sp

      re = /^sp\.*\s[0-9]*/
      t = lot_nb =~ re
      raise "Don\'t know how to deal with species for Master ID #{mid}, I have #{otu}, fix it before to continue " if not t == 0

      sp_nb = true
    else
      sp_nb = false
    end
  return sp_nb
end

def get_par_name(t_nm)
  ## returns parent name(s) for a given taxon name
  t = TaxonName.find(:all, :conditions => ["name = ?", t_nm])

  t_par_id = t.collect { |eachT| eachT.parent_id}

  t_par_t = t_par_id.collect { |eachParID| TaxonName.find(:first, :conditions => ["id = ?", eachParID])}

  t_par_nm = t_par_t.collect { |eachParT| eachParT.name }
  return t_par_nm
end



def create_lots(lot)

  mid = lot[0]

  if mid == "" or mid.nil? or mid.length == 0
    raise "Need master identifier for all lots"
  end

  otu_nm = lot[5]

  #########    ---     Get OTU from taxon name   ---   #########
  ## OTU must be present in the data to import
  if not otu_nm.to_s.length > 0
    raise "no OTU provided for #{mid}"
  else

    lot_nm = otu_nm.split(" ")           # get the taxon name
    otu_sp = lot_nm[-1]                  # get last part of taxon name

    ## check if it's a numbered species like Holothuria sp 4
    sp_nb = nbed_species(otu_nm)

    tn = TaxonName.find(:all, :conditions => ["name = ?", otu_sp])

    ## if it's a numbered species it's normal/OK that it's not in the taxon name database
    ## but in all other cases it is not.
    raise "taxon #{otu_nm} doesn't exist in the database" if tn.length == 0 and not sp_nb

    ## deal with taxa having similar names:
    ##  1. like Synapta maculata and Laetmogone maculata
    ##  2. like Holothuria (Holothuria) holothuria (doesn't exist)

    if tn.length > 1
      ## detecting if case 1 or case 2
      ifsp = tn.find_all { |aTaxon| aTaxon.iczn_group == "species"}

      if ifsp.length > 1
        ## Case 1
        ## try to resolve this by looking at parents
        otu_par_nm = lot_nm[-2]   # here we get subgenus or genus
        raise "Not enough information to resolve this name: #{otu_nm}" if otu_par_nm.nil?

        tn_otu_par = TaxonName.find(:all, :conditions => ["name = ?", otu_par_nm])

        if tn_otu_par.length == 1
          tn = TaxonName.find(:all, :conditions => ["name = ? and parent_id = ?", \
                                                    otu_sp, tn_otu_par[0].id])
        else
          if tn_otu_par.length > 1
            ## last chance
            # get parents of parents (i.e. Genus of subgenus)
            otu_lik_par_nm = get_par_name(otu_sp)
            otu_par_par_nm = otu_lik_par_nm.collect { |e| get_par_name(e) }
            otu_nm_match = otu_par_par_nm.collect { |e| e == otu_par_nm.to_a }
            index_match = otu_nm_match.index(true)

            otu_par = TaxonName.find(:all, :conditions => ["name = ?", otu_lik_par_nm[index_match]])
            raise "Didn't solve this name" if not otu_par.length == 1

            tn = TaxonName.find(:all, :conditions => ["name = ? and parent_id =?", \
                                                          otu_sp, otu_par[0].id])
          else
            raise "Can't solve this name"
          end
        end

        raise "Problem with taxon name for: #{otu_nm}, first make sure that this taxon name is in the database" if not tn.length == 1

      else
        ## Case 2
        ## if there is 1 entry being a species use it
        if ifsp.length == 1
          tn = ifsp
        else
          ## otherwise let the user change the name
          raise "I don't know how to deal with this name #{otu_nm}, first check that this taxon name is in the database" if not tn.length == 1

        end
      end
    end

    ## Get OTU
    if tn.length == 1 ## get OTU from taxon name
      o = Otu.find(:all, :conditions => ["taxon_name_id = ?", tn[0].id])
    else
      o = nil
    end
  end

  ## Taxon name empty if numbered species or get taxon name id
  if ((tn.length == 0 or tn.nil?) and sp_nb)
    tn_nm_id = nil
  else
    tn_nm_id = tn.id
  end

  # If OTU doesn't exist, create it but first make sure it doesn't already exist
  if o.nil?
    o = Otu.find(:all, :conditions => ["name = ?", otu_nm])
    ### TODO make sure that with the :all empty query return nil object
    if o.length == 0
      puts "creating OTU for #{otu_nm}"
      o = Otu.create!(
             :name => otu_nm,
             :taxon_name_id => tn_nm_id,
             :proj_id => $project,
             :creator_id => $person,
             :updator_id => $person
                      ) or raise "couldn't create OTU #{otu_nm}"
      o.save
    end
  end

  o = o.to_a
  raise "Cannot associate name provided (#{otu_nm}) with OTU in database. This may be caused because I can't locate correctly the OTU based on the information provided (o.length == 0) or there are multiple OTU associated with this name (o.length > 1)" if not o.length == 1
  ########  --- End of OTU/taxon name craziness --- #########

  ## Determine if single specimen
  nb_spec = lot[2]

  if nb_spec == "" # if no specimen number defined set to 1 by default
    nb_spec = 1
    nt_spec = "Count unsure, "
  else
    nt_spec = ""
  end

  nb_spec = nb_spec.to_i

  if nb_spec == 1
    single_spec = 1
  else single_spec = 0
  end

  ## Check that mid not already in the database
  ## Be careful, change namespace_id accordingly...
  l = LotIdentifier.find(:first, :conditions => ["identifier = ? and namespace_id = ?", mid, $nid_mid])

  if not l.nil?
    puts "lot with UF ID #{mid} is already in the database"
  else

    ## Create verbatim label
    ce = create_verbatim_label(lot)

    ## create notes for lots
    ## put extraction number or presence of DNA subsample
    ## put who determined it if information available
    if not lot[6].to_s.length == 0
      nt = "Specimen IDed by #{lot[6].to_s}"
      nt = nt + ", #{lot[17].to_s}" if not lot[17].to_s.length == 0
    else
      if not lot[17].to_s == 0
        nt = lot[17].to_s
      else
        nt = ""
      end
    end

    nt = nt_spec + nt

    # put everything in the table
    lot_new = Lot.new(
                   :otu_id =>  o[0].id,
                   :key_specimens => nb_spec,
                   :ce_labels => ce.to_s,
                   :single_specimen => single_spec,
                   :repository_id => 1,
                   :notes => nt,
                   :rarity => "",
                   :source_quality => "",
                   :creator_id => $person,
                   :updator_id => $person,
                   :proj_id => $project)

    if not lot_new.save
      raise "couldn't create new lot for Master ID #{mid}"
    else
      lot_newID = LotIdentifier.new(
               :lot_id => lot_new.id,
               :identifier => mid,
               :namespace_id => $nid_mid,
               :creator_id => $person,
               :updator_id => $person
             )
      lot_newID.save or  raise "couldn't save identifier for Master ID #{mid}"
    end

    # create field id
    if lot[1].to_s.length > 0
      add_id = LotIdentifier.new(
                :lot_id => lot_new.id,
                :identifier => lot[1],
                :namespace_id => $nid_fid,
                :creator_id => $person,
                :updator_id => $person
               )
      add_id.save or raise "couldn't create new field ID for Master ID #{mid}"
    else
      return true
    end
  end
end


namespace :mx do
  desc $USAGE

  task :load_lots => [:environment, :project, :person] do
    @file = ENV['file']

    begin
      ActiveRecord::Base.transaction do
        ln = load_lot_file(@file)
        puts "file read"

        raise "IDs not unique" if not check_unique_id(ln)

        i = 0
        for l in ln do
          if not create_lots(l)
            puts "row #{i.to_s} failed"
          end
          puts(i += 1)
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      puts "something went wrong: #{e}"
    end

  end
end

