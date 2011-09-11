# not included in environment
# require 'breakpoint'
require 'tempfile'

$USAGE = 'Call like: "rake mx:load_languages file=db/languages.txt RAILS_ENV=production"' + "\nFile contents (languages.txt) should be EXACT content at http://www.iana.org/assignments/language-subtag-registry, including the header lines."

def load_meta(f)
  raise "Unable to read from file '#{f}'" if not File.readable?(f)
  meta = IO.read(f).split(/%%/m)
  meta ||= []
end

def new_language(meta)
  begin

    h = Hash.new { |hash, key| hash[key] = Array.new }

    for i in meta.split(/\n/m).map{|l| l.strip} do
      a = i.split(":")
      if a.size == 2
        h[a[0]] << a[1].strip
        @blah = a[0]
      elsif a.size == 1
        h[@blah] << a[0].strip
      end
    end

    @l = Language.new(
    :ltype => h["Type"].join(";"),
    :subtag => h["Subtag"].join(";"),
    :description => h["Description"].join("; "),
    :suppress_script => h["Suppress-Script"].join(";"),
    :preferred_value  => h["Preferred-Value"].join(";"),
    :tag => h["Tag"].join(";"),
    :added => ( h["Added"][0].to_date if h["Added"][0]),
    :deprecated => (h["Deprecated"][0].to_date if h["Deprecated"] and !h["Deprecated"][0].blank?), 
    :prfx => h["Prefix"].join(";"),
    :comments => h["Comments"].join(";")
    )
    #puts h.to_yaml
    #puts @l.to_yaml
    @l.save!

    # puts h.to_yaml 

  rescue ActiveRecord::RecordInvalid
      @l.errors.each_full {|msg| puts msg}
  
    raise
  end
  true
end

namespace :mx do
  desc $USAGE
  task :load_languages => [:environment] do

    @file = ENV['file']

    if not @file 
      puts "ERROR " + $USAGE
      abort # might be better way to do this
    end

    ActiveRecord::Base.transaction do
      meta = load_meta(@file)
      meta.shift # delete the Created on for the whole file
      # puts meta.join("\n---\n")
      i = 0
      for r in meta do
        if not new_language(r)
          puts "record #{r.to_s} failed"
        end
        puts(i += 1)
      end

    end
  end
end

