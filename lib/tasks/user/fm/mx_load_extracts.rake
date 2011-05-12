$USAGE = "Call like: 'rake mx:load_extracts file=~/Desktop/extracts.csv person=1 project=1"

### The CSV file provided must use ; as separator (or modify line 28), text delimiter should be empty (the default is " in openoffice), the file can't have empty lines.
### The columns shouldn't have any heading and must respect the following order
  # 0: extract ID
  # 1: lot ID
  # 2: Genus
  # 3: Subgenus
  # 4: Species
  # 5: ID check
  # 6: Locality
  # 7: extract Date
  # 8: Origin of the tissue (subsample or whole animal)
  # 9: type of tissue
  # 10: protocol
  # 11: dilutions
  # 12: quality

### BE CAREFUL! Don't forget to change all the namespace IDs
### Here I use namespace for lots belonging to other collections (i.e. non UF)
### for which we extracted material.
$nid_autolot = 3



def load_extracts_file(f)
  list_extract = []
  raise "unable to read from file '#{f}'" if not File.readable?(f)

  IO.readlines(f).collect {  |l| l.chomp!; list_extract.push(l.split(";"))}

  list_extract
end

def ext_by(extid)
  ## returns person that did the extraction based on first letter of extraction identifier
  pid = extid.to_s[0..0]
  plist = {'a' => 'Visitor', 'c' => 'Chelsey', 'g' => 'Gustav', 'j' => "John Starmer",
           'k' => 'Kris', 'm' => 'Karim', 'n' => 'Francois', 't' => 'Tim',
           'x' => 'Max', 's' => 'Sarah'}

  if not plist[pid.downcase].nil?
    return plist[pid.downcase]
  else
    return "not sure"
  end

end

def prot(proto)
  ## match old names in spreadsheet with id for the protocols in MX
  prot_list = {
    'AE qia' => 4,
    'AE qia, Qiagen cleaned in TE' => 5,
    'ddH2O' => 1,
    'Puregene' => 6,
    'Puregene followed by Qiagen cleaned in TE' => 7,
    'Q(now, was: ddH2O)' => 3,
    'Qiagen cleaned in TE' => 3,
    'TE' => 2,
     '' => ""}
  p = prot_list[proto]
  raise "Unknown protocol" if p.nil?
  return p
end

def create_extracts(l)
  extid = l[0]
  lotid = l[1]
  gen = l[2]
  subg = l[3]
  spec = l[4]
  idcheck = l[5]
  loc = l[6]
  dt = l[7]
  orig = l[8]
  tissue = l[9]
  proto = l[10]
  dil = l[11]
  qua = l[12]


  raise "No identifier provided for extraction" if extid.empty?
  raise "No lot identifier provided for #{extid}" if lotid.empty?


  ## Check that extraction is not already in database
  ext = Extract.find(:first, :conditions => ["other_extract_identifier = ?", extid])
  raise "Extract #{extid} already in database" if not ext.nil?

  ## If ID for material (lot) not in database create it
  lotIdf = LotIdentifier.find(:all, :conditions => ["identifier = ?", lotid])
  raise "More than 1 lot have identifier #{lotid}" if lotIdf.length > 1
  lotIdf = lotIdf[0]

  if lotIdf.nil?

    otu_nm = gen + " " + spec
    raise "No OTU provided for ID #{lotid}" if otu_nm.length <= 1

    o = Otu.find(:all, :conditions => ["name = ?", otu_nm])
    raise "more than one OTU with the name #{otu_nm}" if o.length > 1
    o = o[0]

    ## Create OTU if it doesn't exist
    if o.nil?
      o = Otu.create(:name => otu_nm,
                      :proj_id => $project,
                      :creator_id => $person,
                      :updator_id => $updator) or raise "Couldn't create OTU for #{otu_nm}"
    end

    lot = Lot.new(:otu_id => o.id,
                  :key_specimens => 1,
                  :ce_labels => loc,
                  :single_specimen => 1,
                  :repository_id => 1,
                  :notes => "Lot created automatically during extractions import",
                  :rarity => "",
                  :source_quality => "",
                  :creator_id => $person,
                  :updator_id => $person,
                  :proj_id => $project)

    if not lot.save
      raise "couldn't create new lot for Master ID #{lotid}"
    else
      lotIdf = LotIdentifier.new(:lot_id => lot.id,
                                :identifier => lotid,
                                :namespace_id => $nid_autolot, # be careful, change appropriately
                                :creator_id => $person,
                                :updator_id => $person)
      lotIdf.save or raise "couldn't create identifier for extraction #{extid}"
    end
  end

  ext = Extract.new(:lot_id => lotIdf.lot_id,
                    :protocol_id => prot(proto),
                    :parts_extracted_from => orig,
                    :quality => qua,
                    :notes => dil,
                    :extracted_on => dt,
                    :extracted_by => ext_by(extid),
                    :other_extract_identifier => extid,
                    :proj_id => $project,
                    :creator_id => $person,
                    :updator_id => $person)
  ext.save or raise "cannot create extraction for #{extid}"

end

namespace :mx do
  desc $USAGE

  task :load_extracts => [:environment, :project, :person] do
    @file = ENV['file']

    begin
      ActiveRecord::Base.transaction do
        ln = load_extracts_file(@file)
        puts "file read"

        i = 0
        for l in ln do
          if not create_extracts(l)
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
