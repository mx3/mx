require 'tempfile'

# Geo related tasks

namespace :mx do
  namespace :geo do

    task :iso_3116_report => [:environment] do
      # compares the Geogs table (specifically country records) against the /config/authority_files/iso_3166-1.tab file and reports discrepencies
      $USAGE = 'Call like: "rake mx:geo:iso_3116_report". Compares the geog table to /config/authority_file/iso_3166-1.txt and reports.'
      desc $USAGE
      iso_file =  FasterCSV.open("#{RAILS_ROOT}/config/authority_files/iso_3166-1.tab", :col_sep => "\t") 
      unmatched = {}

      iso_file.each do |l|
        next if l[0].size == 0
        c, code = l[0], l[1]
        country_name = c.split(/\s/).collect{|w| w == "AND" ? 'and' : w.downcase.capitalize}.join(" ").strip

        if g = Geog.find(:first, :conditions => {:name => country_name})
          puts "found #{g.name}, abbreviations #{g.iso_3166_1_alpha_2_code == code ? 'MATCH' : 'DO NOT MATCH'}"
        else
          puts "not found: #{country_name}"
          unmatched.merge!(country_name => code)
        end 
      end

      puts "\n\n-- UNMATCHED RECORDS (#{unmatched.keys.length}) --\n"
      unmatched.keys.sort.each do |k|
        puts "#{k} => #{unmatched[k]}"
      end
    end


    task :iso_3116_update => [:environment, :person] do
      # there are known errors with parens and encodings! - check your additions with a followup report
      $USAGE = 'Call like: "rake mx:geo:iso_3116_update person=2". Compares the geog table to /config/authority_file/iso_3166-1.txt and updates/adds where necessary. You should report first.'
      desc $USAGE

      puts "\nThere are known errors in capitalization with parenthesized names, check the output!\n"
      iso_file =  FasterCSV.open("#{RAILS_ROOT}/config/authority_files/iso_3166-1.tab", :col_sep => "\t") 
      geog_type = GeogType.find_by_name('Country')
      raise "no Country geog_type present" if !geog_type
      begin
        Geog.transaction do
          unmatched = {}

          iso_file.each do |l|
            next if l[0].size == 0
            c, code = l[0], l[1]
            country_name = c.split(/\s/).collect{|w| w == "AND" ? 'and' : w.downcase.capitalize}.join(" ").strip

            if g = Geog.find(:first, :conditions => {:name => country_name})
              if g.iso_3166_1_alpha_2_code != code
                g.iso_3166_1_alpha_2_code = code
                g.abbreviation = code
                g.save!
                puts "updated: #{country_name}"
              end
            else
              g = Geog.new(:name => country_name, :abbreviation => code, :iso_3166_1_alpha_2_code => code, :geog_type => geog_type)
              g.save!
              g.country_id = g.id
              g.save!
              puts "added: #{country_name}"
            end 
          end
        end
      rescue
        raise 
      end

    end # end update

  end # end geo
end
