# one-off translation of Paroffit to mx 

# select * from con_img where con_img.tax_id in (select t.tax_id from tax t inner join tax_proj p on t.tax_id = p.tax_id where p.name = "paroffit" or p.name = 'olivefly') INTO OUTFILE '/users/matt/big/con_tax.txt'  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n';

# con_img      [con_id, img_id, fig_num, caption, rec_created, rec_updated, user]  
# con          [con_id, text, rec_created, rec_updated, user, author, web_ok]     
# con_tax      [tax_id, con_type_id, con_id] 
# con_type     [con_type_id, name, con_order, context ("taxon page", "key")]    
# geog_tax     [tax_id, ref_id, geog_id, country, first_pu, distribution_type, opiine_id]    
# geog         [geog_id, name, geog_type, country, state, county, biogeo, current]      
# img          [img_id, file_md5]        
# ref          [ref_id, author, year, full_citation, year_letter]         
# tax_link     [link_id id1 id2] (higher class chain)       
# tax_working  [
# 0  tax_id
# 1  name
# 2  author
# 3  year
# 4  iczn group
# 5  tax_rank
# 6  orig_genus
# 7  orig_subgenus
# 8  orig_species
# 9 valid_id
# 10 opiine_db
# 11 wrk_parent_id 
# 12 wrk_parrent_name
# 13 wrk_parrent_iczn_group
# 14 wrk_parent_rank
# 15 wrk_species_id
# 16 wrk species
# 17 wrk subgenus_id
# 18 wrk subgenus
# 19 wrk_genus_id
# 20 wrk_genus
# 21 wrk subfamily_id
# 22 wrk subfamily
# 23 wrk_family_id
# 24 wrk family
# 25 wrk_superfamily_id
# 26 wrk_superfamily] 
# tax          [tax_id, name, author, year, iczn_group, orig_genus, orig_subgenus, orig_species, valid_id, opiine_db] (318)

$USAGE = 'Call like: "rake mx:load_big RAILS_ENV=production"' 

namespace :mx do
  desc $USAGE

  task :read_big_files => [:environment] do
    @con = get_fastercsv( "#{File.dirname(__FILE__)}/big/con.csv", true) # embedded " is translated to QQQQ in this file
    @con_img = get_csv( "#{File.dirname(__FILE__)}/big/con_img.csv")
    @con_tax = get_csv( "#{File.dirname(__FILE__)}/big/con_tax.csv")
    @con_type = get_csv( "#{File.dirname(__FILE__)}/big/con_type.csv")
    @geog_tax = get_csv( "#{File.dirname(__FILE__)}/big/geog_tax.csv")
    @geog = get_csv( "#{File.dirname(__FILE__)}/big/geog.csv")
    @img = get_csv( "#{File.dirname(__FILE__)}/big/img.csv")
    @ref = get_fastercsv( "#{File.dirname(__FILE__)}/big/ref.csv", true) # embedded " is translated to QQQQ in this file 
    @tax_working = get_csv( "#{File.dirname(__FILE__)}/big/tax_working.csv")
    @tax = get_csv( "#{File.dirname(__FILE__)}/big/img.csv") # reference only
    @tax_link = get_csv( "#{File.dirname(__FILE__)}/big/tax_link.csv") # reference only
  end

  # rake mx:load_big project=8 person=35 --trace

  task :load_big => [:environment, :project, :person, :read_big_files] do

   @refs = {} 
   @otus = {}
   @content = {}
   @content_types = {}
   @figures = {}
   @newly_generated_refs = []

   @distributions = []

   @proj = Proj.find(8, :include => :refs)

   begin
     ActiveRecord::Base.transaction do
       # create OTUs for all the @tax_working
       # possibly attempt to add taxonomic names here as well
       generate_otus

       # first handle the references, create new ones for all, map to old with a hash by old ID
       generate_refs
       
       # handle the content
       setup_content_types
       generate_content

       # create the figures
       generate_figures

       # create the distribution records 
       generate_distributions 

       # place all the OTUs in a Paroffit OTU group
       og = OtuGroup.find(341)
       @otus.keys.each do |k|
        og.add_otu(@otus[k])
       end

     end
    rescue 
      puts "FAIL."
    end
   
   puts "DONE!"
  end # end task

  def generate_distributions
    puts "generating distributions ..."
      # index the geog table
      geog = {}
      @geog.each do |g|
        geog.merge!(g[0] => g[1])
      end

      not_found = {}
      Distribution.transaction do 
        @geog_tax.each do |gt|
          print "bigid #{gt[0]} "
          if g = Geog.find_by_name(geog[gt[2]])

            if !@otus[gt[0]]
             print "big OTU #{gt[0]} NOT FOUND\n"
              break
            end

            if !@refs[gt[1]]
              print "big ref #{gt[1]} NOT FOUND\n"
              break
            end

            # this is backasswards, reversed via the DB after the fact (native = 0, introduced = 1)
            case gt[5]
             when "native"
              int = 1
             when "introduced"
              int = 0
             else
              int = nil
            end 

            d = Distribution.new(:geog_id => g.id, :otu_id => @otus[gt[0]].id, :ref_id => @refs[gt[1]].id, :introduced => int, :verbatim_geog => geog[gt[2]] )
            d.save! # save
            @distributions.push(d) 

            print " mx_otu_id: #{@otus[gt[0]].id}, mx_ref_id: #{@refs[gt[1]].id}, status: #{int} "
          else
            not_found.merge!(geog[gt[2]] => nil)
            print " CAN'T FIND geog #{geog[gt[2]]} in mx" 
          end        
          print "\n" 
        end
      end 

    puts "... done. Could not find #{not_found.keys.size} (#{not_found.keys.join(", ")}) geog records." 
  end

  def generate_figures
    puts "generating figures ..."
    # index the images
    images = {}
    @img.each do |i|
     images.merge!(i[0] => i[1]) # id => hash
    end 

    Figure.transaction do 
      @con_img.each do |ci|
        print "fig for content big:#{ci[0]} hash:#{images[ci[1]]} "
    
        if @content[ci[0]] 
          print "mx:#{@content[ci[0]].id} " 
          if img = Image.find_by_file_md5(images[ci[1]]) 
            print "img: #{img.id}" 
            f = Figure.new(:addressable_type => "Content", :addressable_id => @content[ci[0]].id, :caption => ci[3], :position => ci[2], :image_id => img.id  ) 
            f.save! 
          else
           print "FAILED TO FIND IMAGE"
          end
        else  
          print "FAILED TO FIND CONTENT (likely figure for other project)"
        end 
          print "\n"
      end
    end 
    
    puts "... done"
  end

  def setup_content_types
    # select c.con_id, c.text from con c  inner join con_tax ct  on c.con_id = ct.con_id where ct.con_type_id = 10; 
 
    # old id => mx id 
    @content_types = {1 => 145, 2 => 139, 4 => 142, 6 => nil, 7 => nil, 18 => 140, 8 => 138, 9 => 138, 10 => 143, 11 => nil, 12 => 143, 13 => 140, 15 => 137, 5 => 223, 14 => 224, 3 => 225, 16 => 226 }

    #  1 | Description ------id no 145
    #  2 | Biology - Hosts-----id no 139

    #  4 | Biology & Behavior, Including Host Stages Attacked-----id no 142

    #  6 | Native Distribution----id no 140
    #  7 | Introduced Distribution------id no 140
    # 18 | Distribution Discussion----combine with id no 140
    
    #  8 | Diagnosis-----id no 138
    #  9 | Relationships-----can be combined with Diagnosis to = mx id no 138
    # 10 | Remarks-----id no 143

    # 11 | Temp---I think this can be deleted
    # 12 | General---I think this can be deleted; if there's anything in here for any of the pages, put it under Remarks (mx id no 143)
    # 13 | Distribution------id no 140

    # 15 | Synonyms and Other Name Changes-------id no 137

    #  5 | Biological Control------NEW ONE --- 223
    # 14 | Identification of Species and Subspecies----NEW ONE ---  224
    #  3 | Biology - Host Range Testing ------NEW ONE --- 225
    # 16 | Included Taxa OR Taxonomic Links ---NEW ONE? --- 226
  end

  def generate_content
    puts "generating content ..."

    # index the content
    content = {} 
    @con.each do |con|
      content.merge!(con[0] => con[1])
    end

    Content.transaction do 
      @con_tax.each do |c|
        print "processing #{c.join(", ")} :"
      if @content_types[c[1].to_i].nil?
        print " SKIPPING"   
        next
      end
        con = Content.new(:otu_id => @otus[c[0]].id, :content_type_id => @content_types[c[1].to_i], :text => massage_content(content[c[2]])) 
        @content.merge!(c[2] => con)
        con.save! 
        print "\n"
      end
      puts "... done."
    end
    true
  end

  def massage_content(text)
    # update the ref_ids to the real ones
    text.gsub!(/QQQQ/, '"')
    text.gsub!(/XXXX/, "\n")
  
    # update the ref_ids to mx ids 
    text.scan(/<ref id="\d*">/).each do |m|
      i = m.scan(/\d+/).first # probably doable in cleaner fashion 
      print "(#{i}:#{@refs[i].id}) ";
      text.gsub!(/<ref id=\"#{i.to_s}\"\>/, "<ref id=\"#{@refs[i].id}\">") 
    end 
   
    text 
  end

  # minimal field parsing 
  def generate_refs
    puts "generating Refs ... "
    found = 0
    existing_refs = @proj.refs
      Ref.transaction do 
        @ref.each do |r|
          if ref = Ref.find_by_cached_display_name(r[3])
            puts "Found: mxid: #{ref.id} - #{r[3]}."
            # do a little updating, just because we can
            ref.year_letter = r[4] if ref.year_letter.blank? && !r[4].blank? 
            ref.namespace_id = 5 
            ref.external_id == r[0] 
            found += 1
          else
            ref = Ref.new(:namespace_id => 5, :external_id => r[0], :author => r[1], :year => r[2], :full_citation => r[3].gsub(/QQQQ/, "\""), :year_letter => r[4])
           @newly_generated_refs.push(ref)
          end
        ref.save!
      
        @proj.refs << ref unless existing_refs.include?(ref)
        @refs.merge!(r[0] => ref)
      end 
    end
      # make sure to add the ref to the project if it doesn't already exist there
    puts "... done. \n Found #{found} existing references based on exact matches. Generated #{@newly_generated_refs.size} new references. \n"
  end

  def generate_otus
    puts "generating OTU ..."
    unmatched_names = []
    Otu.transaction do 
      @tax_working.each do |t|
        name = name_from_working(t) 
        print name
        o = Otu.new(:name => name, :notes => "Paroffit import tax_id #{t[0]}.")
        if tax = TaxonName.find(:first, :conditions => "name = '#{name}' OR cached_display_name = '#{name_from_working(t, true)}'")
            o.taxon_name = tax 
            print " - matches #{tax.display_name}" 
        else
          print " - FAILS to match either of #{name_from_working(t)} / #{name_from_working(t, true)}"   
        end
        print "\n" 
        o.save!
        @otus.merge!(t[0] => o) 
      end
      puts "UNMATCHED TaxonNames: " + unmatched_names.join("; ")
      puts "... done."
    end 
    true
  end

  def name_from_working(array, italics = false)
    if !italics
      case array[5]
      when 'family'
        array[1]
      when 'genus'
        array[1]
      when 'species'
        [array[20], array[18],array[1], array[2]].reject{|i| i.nil? || i == ""}.join(" ") + ((array[3].nil? || array[3] == "0" || array[3] == "") ? "" : ", #{array[3]}")
      when 'subspecies'
        [array[20], array[18], array[16], array[1], array[2]].reject{|i| i.nil? || i == ""}.join(" ") + ((array[3].nil? || array[3] == "0" || array[3] == "") ? "" : ", #{array[3]}")
      else
        array[1]
      end
    else
      case array[5]
      when 'family'
        array[1]
      when 'genus'
        "<i>#{array[1]}</i>"
      when 'species'
        "<i>" + [array[20], array[18],array[1]].reject{|i| i.nil? || i == ""}.join(" ") + '</i> ' # + [array[2], ((array[3].nil? || array[3] == "0" || array[3] == "") ? nil : array[3]) ].reject{|i| i.nil?}.join(", ")
      when 'subspecies'
        "<i>" + [array[20], array[18], array[16], array[1]].reject{|i| i.nil? || i == ""}.join(" ") + '</i> ' # + [array[2], ((array[3].nil? || array[3] == "0" || array[3] == "") ? nil : array[3])].reject{|i| i.nil?}.join(", ")
      else
        array[1]
      end
    end
  end
end # end namespace
