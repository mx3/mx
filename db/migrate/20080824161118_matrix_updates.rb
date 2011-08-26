class MatrixUpdates < ActiveRecord::Migration

  # THIS REALLY ISN'T REVERSIBLE BACK TO TRUE ORIGINAL FORM
  # but that's ok, you don't want to go back

  # see also magic here: http://www.redhillonrails.org/foreign_key_migrations.html
  
  # major changes to matrix handling

  # chr+/chr-/chr_groups are duplicated for OTUs, BUT, inclusion in the matrix is now based on a single table
  # which will be reset and updated by update filters
  # the same approach is duplicated for OTUs
  def self.up
    # chr_groups_mxes (exists unchanged)
    # mxes_plus_chrs (exists as chrs_mxes)
  
    execute %{ alter table chrs_mxes drop foreign key chrs_mxes_ibfk_1;} 
    execute %{ alter table chrs_mxes drop foreign key chrs_mxes_ibfk_2;} 

    remove_column :chrs_mxes, :creator_id 
    remove_column :chrs_mxes, :updator_id 
    remove_column :chrs_mxes, :created_on 
    remove_column :chrs_mxes, :updated_on 

    rename_table  :chrs_mxes, :mxes_plus_chrs 
   
    # mxes_minus_chrs (exists as is)
    rename_table :mx_minus_chrs, :mxes_minus_chrs   
    execute %{ alter table mxes_minus_chrs drop primary key;}
    execute %{ alter table mxes_minus_chrs add column id int(11) auto_increment not null primary key;}

    # mxes_plus_chrs (exists as is)
    execute %{ alter table mxes_plus_chrs drop primary key;}
    execute %{ alter table mxes_plus_chrs add column id int(11) auto_increment not null primary key;}

    # mxes_chrs (exists as chrs_mxes but with different functionality)
    
    rename_table :mx_chr_sorts, :chrs_mxes
    add_column :chrs_mxes, :notes, :text
    add_column :chrs_mxes, :creator_id, :integer, :references => :people
    add_column :chrs_mxes, :updator_id, :integer, :references => :people
    add_column :chrs_mxes, :updated_on, :timestamp
    add_column :chrs_mxes, :created_on, :timestamp
    
    # now update the Character Data
    # characters are all in chr_plus and may or not may be also in mx.chrs depending on the legacy sort codes

    # add plus
    MxesPlusChr.find(:all, :order => 'mx_id').each do |o|
      m = Mx.find(o.mx_id)
      $proj_id = m.proj_id
      $person_id = m.creator_id
      o.save
    end

    # add chrs in groups
    Mx.find(:all).each do |m|
      m.chr_groups.each do |g|
        g.chrs.each do |c|
         $proj_id = m.proj_id
         $person_id = c.creator_id
         m.chrs_mxes.create!(:chr_id => c.id, :mx_id => m.id, :creator_id => c.creator_id, :updator_id => c.updator_id) if !ChrsMx.find_by_chr_id_and_mx_id(c.id, m.id)
        end
      end
    end

    # add minus
    MxesMinusChr.find(:all, :order => 'mx_id').each do |o|
      m = Mx.find(o.mx_id)
      $proj_id = m.proj_id
      $person_id = m.creator_id
      o.save
    end

    # end chrs --------

    # OTUs

    # mxes_plus_otus (doesn't exist)
    create_table :mxes_plus_otus do |t|
     t.integer :mx_id, :null => false
     t.integer :otu_id, :null => false 
    end 
     
    # mxes_minus_otus (doesn't exist)
    create_table :mxes_minus_otus do |t|
     t.integer :mx_id, :null => false
     t.integer :otu_id, :null => false 
    end 

    # mxes_otu_groups (doesn't exist)
    # FAILS WITH ID!!
    create_table :mxes_otu_groups, :id => false do |t|
     t.integer :mx_id, :null => false
     t.integer :otu_group_id, :null => false 
    end 
    
    remove_column :mxes_otus, :foo_id
    execute %{ alter table mxes_otus add column id int(11) auto_increment not null primary key;}
  
    # ADD ALL THE OTUS TO mxes_otus_plus here
    MxesOtu.find(:all, :order => 'mx_id, position').each do |o|
      Mx.find(o.mx_id).otus_plus << Otu.find(o.otu_id)
    end

    # need to update otu_groups_otus to a full model to allow for observers/filters
    # Mysql unfortunately, but gets closer to DB agnostic
    execute %{ alter table otu_groups_otus drop primary key;}
    execute %{ alter table otu_groups_otus add column id int(11) auto_increment not null primary key;}
   
    execute %{ alter table chr_groups_chrs drop primary key;}
    execute %{ alter table chr_groups_chrs add column id int(11) auto_increment not null primary key;}
  end


  # should work, but not confirmed
  def self.down   
    drop_table :chrs_mxes
    drop_table :mxes_plus_otus
    drop_table :mxes_minus_otus
    drop_table :mxes_otu_groups

    # mxes_otus
    remove_column :mxes_otus, :id
    add_column :mxes_otus, :foo_id, :integer # not quite a true return

    rename_table :mxes_plus_chrs, :chrs_mxes
    add_column :chrs_mxes, :creator_id, :integer, :references => :people # meh, the plugin appears to be borked
    add_column :chrs_mxes, :updator_id, :integer, :references => :people
    add_column :chrs_mxes, :created_on, :timestamp
    add_column :chrs_mxes, :updated_on, :timestamp

    # likely need to remove the index.
    remove_column :chrs_mxes, :id

    rename_table :mxes_minus_chrs, :mx_minus_chrs
    remove_column :mx_minus_chrs, :id # we're not adding the index back on here

    # not adding the primary key back here.
    remove_column :otu_groups_otus, :id
    remove_column :chr_groups_chrs, :id
  end
end
