#noinspection Rails3Deprecated
def load_one_name(name, parent, iczn_group)

  par = TaxonName.find(:first, :conditions => ["name = ?", parent] )

  n = TaxonName.create!(
         :name => name,
         :parent_id => par.id,
         :iczn_group => iczn_group,
         :creator_id => $person_id,
         :updator_id => $person_id
      ) or raise "cannot create entry"
  puts "#{parent} has ID #{par.id.to_s}"
end


namespace :mx do
  desc "test"
  task :load_one_name => [:environment, :project, :person] do

    @proj = Proj.find($proj_id)

    ActiveRecord::Base.transaction do
      load_one_name('Holothuroidea', 'Echinodermata', 'n/a')
    end


  end
end
