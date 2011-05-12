
# A One-off to load the NCSU legacy MS Access tables to mx

$USAGE = 'Call like: "rake mx:ncsu:load_ncsu RAILS_ENV=development" '

# there are 5 tables, Order, Family, Genus, Species, Synonym
# we're not parsing the Synonym table because there are so few records

# Order
#  OrderID
#  Ordername
#  OrdPinUnd
#  OrdVialUnd
#  OrdSlidUnd

# Family
#  FamilyID
#  Familyname
#  OrderID
#  FamPinUnd
#  FamVialUnd
#  FamSlidUnd

# Genus
#  GenusID	
#  Genusname
#  FamilyID
#  Subfamily
#  Tribe
#  GenPinUnd
#	 GenVialUnd 
#	 GenSlidUnd

# Species
#  SpCode
#  Genusname
#  Species
#  Subspecies
#  Author
#  Holotype
#  Allotype
#  Paratype
#  No_paratype
#  Vouchers
#  NoPinned
#  NoVials
#  NoSlides
#  NC_specimen
#  Spec_source
#  Syntype
#  NoSyntype

# Synonym
# JSynonyID
# SpCode
# Genusname
#	Species
# Subspecies
#	Author
#	Holotype
#	Allotype
#	Paratype
# No_Paratype
# Syntype
# No_Syntypes

namespace :mx do
  desc $USAGE

  namespace :ncsu do
    task :read_ncsu_files => [:environment]  do
      @order = get_fastercsv("#{File.dirname(__FILE__)}/NCSUdb/NCSU_tblOrder.csv")
      @family = get_csv( File.dirname(__FILE__) + '/NCSUdb/NCSU_tblFamily.csv')
      @genus = get_csv( File.dirname(__FILE__) + '/NCSUdb/NCSU_tblGenus.csv')
      @species = get_csv( File.dirname(__FILE__) + '/NCSUdb/NCSU_tblSpecies.csv')
      # @synonym = get_csv( File.dirname(__FILE__) + '/NCSUdb/NCSU_tblSynonym.csv')
    end

    task :load_ncsu => [:environment, :read_ncsu_files] do
      @person = nil
      @proj = nil
      $person_id = nil
      $proj_id = nil

    begin
      ActiveRecord::Base.transaction do
        initialize_ncsu_setup
        handle_orders
        handle_families
        handle_genera
        handle_species

        puts "reindexing, this will take some time ..."
        TaxonName.renumber_all # build the l,r indecies that are usually populated when you use TaxonName#create_new (too slow here for 30k names)
        puts "done!"
      end
     rescue # ActiveRecord::RecordInvalid => e 
      puts "FAIL!"
      raise 
     end
  end # end task

  def initialize_ncsu_setup
    @person = Person.create!(:last_name => "data", :first_name => "import", :login => 'data_import', :email => "stuff@things.com", :password => 'dummypassword', :is_admin => true)  
    $person_id = @person.id

    @proj = Proj.create!(:name => "NCSU Insect Collection") 
    @proj.people << @person
    @proj.save 
    
    $proj_id = @proj.id
    @root = TaxonName.create!(:name => 'root', :l => 1, :r => 2, :iczn_group => "n/a")

    # create some keywords 
    ["OrdPinUnd", "OrdVialUnd", "OrdSlidUnd", 
     "FamPinUnd", "FamVialUnd", "FamSlidUnd",
     "GenPinUnd", "GenVialUnd", "GenSlidUnd",
     "Holotype", "Allotype", "Paratype", "No_paratype", "Vouchers", "NoPinned", "NoVials", "NoSlides", "NC_Specimen", "Spec_source", "Syntype", "NoSyntype"
    ].each do |w|
      Keyword.create!(:keyword => w)
    end    
 
   @orders = {} # hash OrderID => TaxonName
   @families = {} 
   @genera = {}
   
    true 
  end

  def handle_orders
    @order.shift
    TaxonName.transaction do  
    @order.each do |o|
      t = TaxonName.create!(:name => o[1], :parent => @root, :iczn_group => "n/a")
      otu = Otu.new(:name => t.cached_display_name, :taxon_name => t) 
      
      t.save 
      otu.save
      @orders.merge!(o[0] => t) # index to TaxonName 
    
      Tag.create_new(:obj => otu, :keyword => Keyword.find_by_keyword("OrdPinUnd") , :notes => o[2])  if ( !o[2].blank? &&  o[2] != "FALSE"   )
      Tag.create_new(:obj => otu, :keyword => Keyword.find_by_keyword("OrdVialUnd") , :notes => o[3]) if ( !o[3].blank? &&  o[3] != "FALSE"   )
      Tag.create_new(:obj => otu, :keyword => Keyword.find_by_keyword("OrdSlidUnd") , :notes => o[4]) if ( !o[4].blank? &&  o[4] != "FALSE"   )
    end
  end

  def handle_families
    @family.shift
    TaxonName.transaction do  
      @family.each do |o|
        puts "adding #{o[1]}"
        t = TaxonName.create!(:name => o[1], :parent => @orders[o[2]], :iczn_group => "family")
        otu = Otu.new(:name => t.cached_display_name, :taxon_name => t) 
        t.save 
        otu.save

        @families.merge!(o[0] => t) # index to TaxonName 
        
        Tag.create_new(:obj => otu, :keyword => Keyword.find_by_keyword("FamPinUnd") , :notes => o[2]) if !o[2].blank? &&  o[2] != "FALSE" 
        Tag.create_new(:obj => otu, :keyword => Keyword.find_by_keyword("FamVialUnd") , :notes => o[3]) if !o[3].blank? &&  o[3] != "FALSE" 
        Tag.create_new(:obj => otu, :keyword => Keyword.find_by_keyword("FamSlidUnd") , :notes => o[4]) if !o[4].blank? &&  o[4] != "FALSE" 
      end
    end
  end

 def handle_genera
   @genus.shift
    TaxonName.transaction do  
      @genus.each do |o|
        # does it have a subfamily?
        if !o[3].blank?
         if subfam = TaxonName.find_by_name(o[3])
         else
          puts "adding #{o[3]}"

          subfam = TaxonName.create!(:name => o[3], :parent => @families[o[2]], :iczn_group => "family")
         end 
        end

        # does it have a tribe?
        if !o[4].blank?
         if tribe = TaxonName.find_by_name(o[4])
         else
           puts "adding #{o[4]}"
           tribe = TaxonName.create!(:name => o[4], :parent => (subfam ? subfam : @families[o[2]]), :iczn_group => "family")
         end 
        end

        puts "adding #{o[1]}"
        t = TaxonName.create!(:name => o[1], :parent => [tribe, subfam, @families[o[2]]].reject{|r| r.nil?}.first, :iczn_group => "genus" )
        otu = Otu.new(:name => t.cached_display_name, :taxon_name => t) 
        t.save 
        otu.save
        Tag.create_new(:obj => otu, :keyword => Keyword.find_by_keyword("GenPinUnd"), :notes => o[6]) if !o[6].blank? &&  o[6] != "FALSE" 
        Tag.create_new(:obj => otu, :keyword => Keyword.find_by_keyword("GenVialUnd"), :notes => o[7]) if !o[7].blank? &&  o[7] != "FALSE" 
        Tag.create_new(:obj => otu, :keyword => Keyword.find_by_keyword("GenSlidUnd"), :notes => o[8]) if !o[8].blank? &&  o[8] != "FALSE" 
      end
    end
  end

  def handle_species
    holotype = Keyword.find_by_keyword("Holotype")    
    allotype = Keyword.find_by_keyword("Allotype")    
    paratype = Keyword.find_by_keyword("Paratype")    
    no_paratype =  Keyword.find_by_keyword("No_paratype")
    vouchers =  Keyword.find_by_keyword("Vouchers")    
    nopinned = Keyword.find_by_keyword("NoPinned")    
    novials =  Keyword.find_by_keyword("NoVials")     
    noslides =  Keyword.find_by_keyword("NoSlides")    
    nc_specimen =  Keyword.find_by_keyword("NC_specimen") 
    spec_source =   Keyword.find_by_keyword("Spec_source") 
    syntype =  Keyword.find_by_keyword("Syntype")     
    nosyntype =  Keyword.find_by_keyword("NoSyntype")   

    @species.shift

    print "\n\n...on species...\n\n"
    TaxonName.transaction do  
      @species.each do |o|
        puts "processing: #{o[0]}"
        genus = TaxonName.find_by_name(o[1]) # genus, apparently they didn't track homonyms 
        
        if !genus
          puts  "FATAL: can not find genus name #{o[1]}" 
          raise
        end

        if !o[3].nil? # is it a subspecies?
          if parent = TaxonName.find_by_cached_display_name("<i>#{genus.name} #{o[2]}</i>") # there is a subpecies, get/find the species
            puts "found #{parent.cached_display_name} for #{o[3]}"
          else # can't find a potential parent, create the species
             # create the species
             puts "creating #{o[2]} for #{o[3]}"
             parent = TaxonName.create!(:name => o[2], :parent => genus, :iczn_group => "species")
             otu_species = Otu.new(:name => "#{genus.name} #{parent.cached_display_name}", :taxon_name => parent) 
             otu_species.save! 
          end

          # create the subspecies
          t = TaxonName.create!(:name => o[3], :parent => parent, :iczn_group => "species", :author => o[4])
          otu = Otu.new(:name => "#{genus.name} #{parent.name} #{t.cached_display_name}", :taxon_name => parent) 
          otu.save! 

        else # it's species alone 
          # create the species

          puts "creating #{o[2]} for #{genus.cached_display_name}"
          t = TaxonName.create!(:name => o[2], :parent => genus, :iczn_group => "species", :author => o[4])
          otu = Otu.new(:name => "#{genus.name} #{t.cached_display_name}", :taxon_name => t) 
          otu.save
        end 

        # the otu is the species or otu, tag that
        Tag.create_new(:obj => otu, :keyword => holotype    ,:notes => o[5])  if (!o[5].blank?  && o[5]  != "FALSE")
        Tag.create_new(:obj => otu, :keyword => allotype    ,:notes => o[6])  if (!o[6].blank?  && o[6]  != "FALSE")
        Tag.create_new(:obj => otu, :keyword => paratype    ,:notes => o[7])  if (!o[7].blank?  && o[7]  != "FALSE")
        Tag.create_new(:obj => otu, :keyword => no_paratype ,:notes => o[8])  if (!o[8].blank?  && o[8]  != "FALSE")
        Tag.create_new(:obj => otu, :keyword => vouchers    ,:notes => o[9])  if (!o[9].blank?  && o[9]  != "FALSE")
        Tag.create_new(:obj => otu, :keyword => nopinned    ,:notes => o[10]) if (!o[10].blank? && o[10] != "FALSE")
        Tag.create_new(:obj => otu, :keyword => novials     ,:notes => o[11]) if (!o[11].blank? && o[11] != "FALSE")
        Tag.create_new(:obj => otu, :keyword => noslides    ,:notes => o[12]) if (!o[12].blank? && o[12] != "FALSE")
        Tag.create_new(:obj => otu, :keyword => nc_specimen ,:notes => o[13]) if (!o[13].blank? && o[13] != "FALSE")
        Tag.create_new(:obj => otu, :keyword => spec_source ,:notes => o[14]) if (!o[14].blank? && o[14] != "FALSE")
        Tag.create_new(:obj => otu, :keyword => syntype     ,:notes => o[15]) if (!o[15].blank? && o[15] != "FALSE")
        Tag.create_new(:obj => otu, :keyword => nosyntype   ,:notes => o[16]) if (!o[16].blank? && o[16] != "FALSE")
      end
    end
  end
 
  end 
end # end namespace

end

