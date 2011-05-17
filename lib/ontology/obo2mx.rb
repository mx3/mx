
module Ontology
  module Obo2mx

    #== A wrapper integrating the obo_parser gem and mx ontology models.

    SYNONYM_TYPES = ['synonym', 'exact_synonym', 'related_synonym', 'narrow_synonym', 'broad_synonym']

    # Instantiates the mx components that are mappable to an OBO ontology, but does not save them (see also import).
    def self.compare(options = {}) # :yields: { }
      opt = {
        :file => nil,     # TEXT?
        :proj_id => nil #,
        #      :to_compare => [:terms, :typedefs]
      }.merge!(options.symbolize_keys)

      return false if (opt[:file].blank? || opt[:file].size == 0 )

      of = parse_obo_file(opt[:file])

      refs = {}
      labels = {}
      ontology_classes = {}
      sensus = {}
      object_relationships = {}
      ontology_relationships = {}

      of.typedefs.each do |td|
        if orel = ObjectRelationship.find_by_interaction_and_proj_id(td.name.value, opt[:proj_id])
          object_relationships.merge!(td.id.value => orel)
        else
          is_transitive = false
          is_symmetric = false

          v = td.tags_named('is_symmetric')
          if v.size > 0
            is_symmetric = true if  v.first.value == 'true'
          end

          v = td.tags_named('is_transitive')
          if v.size > 0
            is_transitive = true if  v.first.value == 'true'
          end

          os = ObjectRelationship.new(
            :interaction => td.id.value,
            :is_transitive => is_transitive,
            :is_symmetric => is_symmetric,
            :xref =>  (td.id.value =~ /:/ ? td.id.value : nil),            # may need to validate re mx model
            :notes => td.def.andand.value
          )
          object_relationships.merge!(td.id.value => os)                # for matching?! use name not id
        end

        # is_a and disjoint_with are built-ins - add if necessary
        ['is_a', 'disjoint_from'].each do |r|
          if !object_relationships[r]
            object_relationships.merge!(r =>  ObjectRelationship.new( :interaction => r) )
          end
        end

      end

      of.terms.each do |term|
        if term.def
          term.def.xrefs.each do |xref|
            if !refs[xref]
              if r = Ref.with_global_identifier(xref).andand.first
                refs.merge!(xref => r)
              else
                refs.merge!(xref => Ref.new) # build the Identifier on save using Key
              end
            end
          end

          Ontology::Obo2mx::SYNONYM_TYPES.each do |s|
            term.tags_named(s).each do |v|
              v.xrefs.each do |xref|
                if !refs[xref]
                  if r = Ref.with_global_identifier(xref).andand.first
                    refs.merge!(xref => r)
                  else
                    refs.merge!(xref => Ref.new) # build the Identifier on save using Key
                  end
                end
              end
            end
          end
        end

        if !labels[term.name.value]
          # Note: mx has more restrictions on label composition than OBO does (potentially)
          lbl = term.name.value
          if l = Label.find_by_name_and_proj_id(lbl, opt[:proj_id])
            labels.merge!(lbl => l)
          else
            labels.merge!(lbl => Label.new(:name => lbl))
          end
        end

        # TODO: deprecate sudo 1.0 support
        Ontology::Obo2mx::SYNONYM_TYPES.each do |s|
          term.tags_named(s).each do |v|
            lbl = v.value
            if !labels[lbl]
              if l = Label.find_by_name_and_proj_id(lbl, opt[:proj_id])
                labels.merge!(lbl => l)
              else
                labels.merge!(lbl => Label.new(:name => lbl))
              end
            end
          end
        end

        tmp_def = term.def.andand.value
        tmp_def ||= "This is a dummy definition for ontology class #{term.id.value}."
        if !ontology_classes[term.id.value]
          if o = OntologyClass.find_by_definition_and_proj_id(tmp_def, opt[:proj_id])
            ontology_classes.merge!(term.id.value => o)
          else
            ontology_classes.merge!(term.id.value => OntologyClass.new(:definition => tmp_def, :xref => term.id.value, :obo_label => labels[term.name.value] ))
            raise if ontology_classes[term.id.value].obo_label.class != Label
          end
        end
      end

      # Handle Sensus and OntologyRelationships
      of.terms.each do |term|
        if term.def
          sensus.merge!(term.id.value => [])
          term.def.xrefs.each do |xref|
            sensus[term.id.value].push(Sensu.new(
                :ref => refs[xref],
                :ontology_class => (ontology_classes[term.id.value]),
                :label => labels[term.name.value]
              )
            )
          end


          Ontology::Obo2mx::SYNONYM_TYPES.each do |s|
            term.tags_named(s).each do |v|
              lbl = v.value # .gsub(/[^\w\s]/, '_')
              if v.xrefs.size > 0
                v.xrefs.each do |xref|
                  sensus[term.id.value].push(Sensu.new(
                      :ref => refs[xref],
                      :ontology_class => (ontology_classes[term.id.value]),
                      :label => labels[lbl]
                    )
                  )
                end
              else
                sensus[term.id.value].push(Sensu.new(
                    :ref => nil,
                    :ontology_class => (ontology_classes[term.id.value]),
                    :label => labels[lbl]
                  )
                )
              end
            end
          end
        end

        ontology_relationships.merge!(term.id.value => [])
        (['is_a', 'disjoint_from'] + object_relationships.values.collect{|o| o.interaction} ).uniq.each do |rel|
          term.relationships.each do |r|
            ontology_relationships[term.id.value].push( OntologyRelationship.new(
                :ontology_class1 => ontology_classes[term.id.value],
                :ontology_class2 => ontology_classes[r[1]],
                :object_relationship => object_relationships[r[0]])
            )
          end
        end
        

      end
      {:ontology_classes => ontology_classes, :refs => refs, :labels => labels, :ontology_relationships => ontology_relationships, :sensus => sensus, :object_relationships => object_relationships} 

    end

    # Attempts to save all new records returned from self.compare
    def self.import(options = {})
      opt = {
        :compare_result => nil,
        :person_id => nil,
        :proj_id => nil
      }.merge!(options)

      return false if opt[:compare_result].nil? | opt[:person_id].nil? | opt[:proj_id].nil?

      # in case we are dumb and call within application
      incoming_person = $person_id
      incoming_proj = $proj_id

      $proj_id = opt[:proj_id]
      $person_id = opt[:person_id]

      proj = Proj.find($proj_id)

      begin
        ActiveRecord::Base.transaction do

          ref = nil
          if not ref = opt[:base_written_by_ref]
            ref = Ref.create!(:notes => 'Base written_by ref for OBO import.', :title => 'OBO import base written_by reference.')
            proj.refs << ref
          end

          opt[:compare_result][:refs].keys.each do |k|
            if opt[:compare_result][:refs][k].new_record?
              # puts "writing [#{k}] "
              r = opt[:compare_result][:refs][k]
              r.save!
              proj.refs << r

              identifier = Identifier.new(:proj_id => proj.id,
                :addressable_type => 'Ref',
                :addressable_id => r.id,
                :global_identifier => k,
                :global_identifier_type => 'xref')
              identifier.save!
            end
          
          end

          [:labels, :object_relationships].each do |i|
            opt[:compare_result][i].keys.each do |k|
              opt[:compare_result][i][k].save! if opt[:compare_result][i][k].new_record?
            end
          end

          # Handle ontology_classes
          definition_tracker = []
          opt[:compare_result][:ontology_classes].keys.each do |k|
            if opt[:compare_result][:ontology_classes][k].new_record?
              while !OntologyClass.find(:first, :conditions => {:proj_id => opt[:proj_id], :definition =>  opt[:compare_result][:ontology_classes][k].definition}).nil?
                opt[:compare_result][:ontology_classes][k].definition << " IMPORT DUPLICATE."
              end

              while definition_tracker.include?(  opt[:compare_result][:ontology_classes][k].definition )
                opt[:compare_result][:ontology_classes][k].definition << " IMPORT DUPLICATE."
              end

              #  puts "writing [#{k}] - #{opt[:compare_result][:ontology_classes][k].definition}"

              opt[:compare_result][:ontology_classes][k].obo_label_id = opt[:compare_result][:ontology_classes][k].obo_label.id
              opt[:compare_result][:ontology_classes][k].written_by = ref
              opt[:compare_result][:ontology_classes][k].save!
            end
          end
          #        puts "ontology_classes written."

          opt[:compare_result][:ontology_relationships].keys.each do |i|
            opt[:compare_result][:ontology_relationships][i].each do |j|
              if j.new_record?
                # print j.ontology_class1.definition
                j.ontology_class1_id = j.ontology_class1.id
                j.ontology_class2_id = j.ontology_class2.id
                j.object_relationship_id = j.object_relationship.id

                if !OntologyRelationship.find(:first,
                    :conditions => {
                      :proj_id => opt[:proj_id],
                      :ontology_class1_id => j.ontology_class1.id,
                      :ontology_class2_id => j.ontology_class2.id ,
                      :object_relationship_id => j.object_relationship.id})
                  j.save!
                  #  print "...saved\n\n"
                end
              end
            end
          end
          #        puts "ontology_relationships written."

          opt[:compare_result][:sensus].keys.each do |i|
            opt[:compare_result][:sensus][i].each do |j|
              if j.new_record?
                j.label_id = j.label.id
                j.ref_id = j.ref.id if j.ref
                j.ref_id ||= ref.id
                j.ontology_class_id = j.ontology_class.id

                j.save! if !Sensu.find(:first, :conditions => {:proj_id => opt[:proj_id], :ontology_class_id => j.ontology_class.id, :label_id => j.label_id, :ref_id => j.ref_id})
              end
            end
          end
          #        puts "sensus written."
        end

      rescue
        raise
      end

      # reset to application values
      $person_id = incoming_person
      $proj_id = incoming_proj

      true
    end

  end


end