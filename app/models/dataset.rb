# == Schema Information
# Schema version: 20090930163041
#
# Table name: datasets
#
#  id           :integer(4)      not null, primary key
#  parent_id    :integer(4)
#  content_type :string(255)
#  filename     :string(1024)
#  size         :integer(4)
#  proj_id      :integer(4)      not null
#  creator_id   :integer(4)      not null
#  updator_id   :integer(4)      not null
#  updated_on   :timestamp       not null
#  created_on   :timestamp       not null
#

class Dataset < ActiveRecord::Base
  has_standard_fields

  has_many :data_sources, :dependent => :nullify

  has_attachment  :content_type => ['text/plain', 'text/rtf', 'application/octet-stream'], # could add eps etc. too?
                  :storage => :file_system,
                  :size => 0.kilobytes..200000.kilobytes, 
                  :max_size => 20.megabytes,
                  :path_prefix => "public/files/datasets"
  
  validates_as_attachment

  def display_name(options = {})
    filename
  end

  # converts the file to a nexus file
  def nexus_file
    begin
      parse_nexus_file(self.ds_file.to_s) 
    rescue NexusParser::ParseError => e
      puts "#{e}" # debugger 
      raise 
    end
  end

  # takes a Mesquite NexusFile object and translates it to mx
  # it uses 'raise' to pass errors up, so wrap it in begin, rescue, end!
  def convert_nexus_to_db(options = {})
    @opt = {
        :title => false, 
        :generate_short_chr_name => false,
        :generate_otu_name_with_ds_id => false, # data source, not dataset
        :generate_chr_name_with_ds_id => false,
        :match_otu_to_db_using_name => false,
        :match_otu_to_db_using_matrix_name => false,
        :match_chr_to_db_using_name => false,
        :generate_chr_with_ds_ref_id => false, # data source, not dataset
        :generate_otu_with_ds_ref_id => false,
        :generate_tags_from_notes => false,
        :generate_tag_with_note => false
      }.merge!(options)

    # run some checks on options
    raise if @opt[:generate_otu_name_with_ds_id] && !DataSource.find(@opt[:generate_otu_name_with_ds_id])
    raise if @opt[:generate_chr_name_with_ds_id] && !DataSource.find(@opt[:generate_chr_name_with_ds_id])
    raise if @opt[:generate_chr_with_ds_ref_id] && !Ref.find(@opt[:generate_chr_with_ds_ref_id])
    raise if @opt[:generate_otu_with_ds_ref_id] && !Ref.find(@opt[:generate_otu_with_ds_ref_id])
    raise ':generate_tags_from_notes must be true when including note' if @opt[:generate_tag_with_note] && !@opt[:generate_tags_from_notes] 

    @nf = self.nexus_file # THIS MUST BE @!!

    raise 'Problem parsing the Nexus file.' if !@nf

    new_otus = []
    new_chrs = []
    new_states = []

    @note_kw = Keyword.find(:first, :conditions => {:keyword => 'note', :proj_id => self.proj_id})
    
    begin
      # wrap everything in a transaction, doesn't matter what kind
      Mx.transaction do

        # create a new matrix 
        @m = Mx.new(
          :name => @opt[:title] ? @opt[:title] : "Converted matrix created #{Time.now().to_formatted_s(:long)} by #{Person.find($person_id).display_name}."
         )
        @m.save!

        # create the necessary keyword if it doesn't exist
        if !@note_kw 
          @note_kw = Keyword.new(:keyword => 'note')
          @note_kw.save! # appends creator etc., rather than .create!
        end

        # create OTUs, add them to the matrix as we do so, 
        # and add them to an array for reference during coding
        @nf.taxa.each_with_index do |o, i|
          @otu = nil
          if @opt[:match_otu_to_db_using_name] || @opt[:match_otu_to_db_using_matrix_name]
            sql = []
            sql.push "name = '#{o.name}'" if @opt[:match_otu_to_db_using_name] # sanitize() was removed in 2.2, but see http://wonko.com/post/sanitize
            sql.push "matrix_name = '#{o.name}'" if @opt[:match_otu_to_db_using_matrix_name] # sanitize()
            sql_txt = "(" + sql.join(" or ") + ") AND otus.proj_id = #{self.proj_id}"
            @otu = Otu.find(:first, :conditions => sql_txt)
          end

          if !@otu
            name = ( @opt[:generate_otu_name_with_ds_id] ? "#{o.name} [dsid:#{@opt[:generate_otu_name_with_ds_id]}]" : o.name )
            @otu = Otu.new(:name => name,
                          :source_ref_id => (@opt[:generate_otu_with_ds_ref_id] ? @opt[:generate_otu_with_ds_ref_id] : nil)
                          )
            @otu.save!
          end

          # add Tags
          if @opt[:generate_tags_from_notes] && o.notes.size > 0
            o.notes.each do |n|
              txt = n.note + ( @opt[:generate_tag_with_note] ? " [" + @opt[:generate_tag_with_note] + "]"  : ''   )
              Tag.create!(:addressable_id => @otu.id, :addressable_type => 'Otu', :notes => txt, :keyword_id => @note_kw.id)
            end
          end

          new_otus << @otu # add the Otu in order, links the NexusFile to the db Otu
          @m.otus_plus << @otu
        end

        # create Chars
        @nf.characters.each_with_index do |o, i|
          @chr = nil
          new_states[i] = {}

          if @opt[:match_chr_to_db_using_name]
            if @chr = Chr.find(:first, :conditions => {:proj_id => self.proj_id, :name => o.name} )
              # a little trickier here, have to back match states as well
              # the operation will only pass if the state labels are are chr name are identical
              # other opterations are concievable, for instance updating the chr with the new states, but the
              # combinatorics gets very tricky very quickly

              @chr = nil if (o.state_labels != @chr.states)
              @chr.chr_states.each{|cs| new_states[i].update(cs.state => cs)} if @chr # link codings to sates
            end
          end

          if !@chr
            name = ( @opt[:generate_chr_name_with_ds_id] ? "#{o.name} [dsid:#{@opt[:generate_chr_name_with_ds_id]}]" : o.name )
         
            @chr = Chr.new(:name => name, 
                          :short_name => (@opt[:generate_short_chr_name] ? o.name[0..5] : ''),
                          :cited_in => (@opt[:generate_chr_with_ds_ref_id] ? @opt[:generate_chr_with_ds_ref_id] : nil)
                         ) 
            @chr.save!

            # add states
            o.state_labels.each do |cs|
              state = ChrState.new(:state => cs, :name => @nf.characters[i].states[cs].name)
              @chr.chr_states << state
			  
              state.save!
              new_states[i].update(cs => state) # link file to db    
            end
  
            # add Tags
            if @opt[:generate_tags_from_notes] && o.notes.size > 0
              o.notes.each do |n|
                txt = n.note + ( @opt[:generate_tag_with_note] ? " [" + @opt[:generate_tag_with_note] + "]"  : ''   )
                Tag.create!(:addressable_id => @chr.id, :addressable_type => 'Chr', :notes => txt, :keyword_id => @note_kw.id)
              end
            end

          end

          new_chrs << @chr # link file to db
          @m.chrs_plus << @chr # add it to the matrix
        end
        
        # create codings 
        
        @nf.codings[0..@nf.taxa.size].each_with_index do |y, i| # y is a rowvector of NexusFile::Coding
          y.each_with_index do |x, j| # x is a NexusFile::Coding
            x.states.each do |z| 
              if z != "?"
                c = Coding.create!(
                  :otu_id => new_otus[i].id,
                  :chr_id => new_chrs[j].id,
                  :chr_state_id => new_states[j][z].id )

                # since mx tags codings, not cells as Mesquite does, we tag every coding with the same Tag (for now)
                if @opt[:generate_tags_from_notes] && x.notes.size > 0
                  x.notes.each do |n|
                    txt = n.note + ( @opt[:generate_tag_with_note] ? " [" + @opt[:generate_tag_with_note] + "]"  : ''   )
                    Tag.create!(:addressable_id => c.id, :addressable_type => 'Coding', :notes => txt, :keyword_id => @note_kw.id)
                  end
                end

              end
            end
          end
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      #return false
      raise e # false
    end

    return @m.id # return the matrix id
  end

  protected

  def ds_file
    File.read("#{Rails.root.to_s}/public/#{self.public_filename}")
  end


end

