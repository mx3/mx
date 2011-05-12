# you must restart the server when changes are made to this file

module Ontology::Visualize::Svg

  # renders an SVG file
  # just messing around
  # should obviously use xml builder to do this
  def self.visualize_svg(proj_id)

    @xy = {}

    s = '<?xml version="1.0" standalone="no"?>
    <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" 
    "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
    <svg width="100%" height="100%" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">'

    @x_offset = 10
    @y_offset = 10
    @x_grid = 20
    @y_grid = 20
    @groups_of = 50

    @ontology_classes = Proj.find(proj_id).ontology_classes #[300..500] #[0..400]

    @crh = {} # current radius hash - used to additively create concentric rings

    # map the co-ordinates of the x,y positions for future use, we do this several times, so calculate up front regardless of cost
    @ontology_classes.in_groups_of(@groups_of, false).each_with_index do |grp,y|
      grp.each_with_index do |p,x|
        @xy[p.id] = {:x => x * @x_grid + @x_offset, :y => y * @y_grid + @y_offset}
        @crh[p.id] = 8 # initialize the hash
      end
    end

    # draw links  
    s += '<g stroke="indigo" stroke-width="1" stroke-linecap="round" fill="none" stroke-opacity="0.4">'
    @ontology_classes.each do |p|
      p.primary_relationships.each do |pr|
        if @xy[pr.id]
          @xoff = (@xy[p.id][:x] - @xy[pr.id][:x]).abs.to_f/3.5
          @yoff = (@xy[p.id][:y] - @xy[pr.id][:y]).abs.to_f/3.5
          # the IF is a terrible excuse for not solving 
          s += "<path d = \"M #{@xy[p.id][:x]+5} #{@xy[p.id][:y]+5} Q
          #{(@xy[p.id][:x] > @xy[pr.id][:x] ? (@xy[pr.id][:x] + @xoff) : (@xy[p.id][:x] + @xoff).to_f)  + 5}
          #{(@xy[p.id][:y] > @xy[pr.id][:y] ? (@xy[pr.id][:y] + @yoff) : (@xy[p.id][:y] + @yoff).to_f)  + 5}
          #{@xy[pr.id][:x] + 5} #{@xy[pr.id][:y] + 5}  \" />"
        end
      end
    end
    s += '</g>'

    # radius graphics, each in context of previous size
    # relationships
    s += '<g stroke="cornflowerblue" fill="none" stroke-opacity="0.4">'
    @ontology_classes.each do |p|
      # TODO: relationshps method doesn't exist  
      w = p.relationships.size
      if w > 0
        s+= "<circle cx =\"#{@xy[p.id][:x] + 5}\" cy =\"#{@xy[p.id][:y]+5}\" r=\"#{(@crh[p.id].to_f + (w/2).to_f)}\" stroke-width = \"#{w}\" />"
        @crh[p.id] += w
      end
    end
    s += '</g>'

    # tags
    s += '<g stroke="orange" fill="none" stroke-opacity="0.7">'
    @ontology_classes.each do |p|
      w = p.tags.count
      if w > 0
        s+= "<circle cx = \"#{@xy[p.id][:x] + 5}\" cy = \"#{@xy[p.id][:y]+5}\" r=\"#{(@crh[p.id].to_f + (w/2).to_f)}\" stroke-width = \"#{w}\"/>"
        @crh[p.id] += w # stroke adds to radius on either side!
      end
    end
    s += '</g>'

    # figures
    s += '<g stroke="purple" fill="none" stroke-opacity="0.6">'
    @ontology_classes.each do |p|
      w = p.figures.size
      if w > 0
        s+= "<circle cx =\"#{@xy[p.id][:x] + 5}\" cy =\"#{@xy[p.id][:y]+5}\" r=\"#{(@crh[p.id].to_f + (w/2).to_f)}\" stroke-width = \"#{w}\" />"
        @crh[p.id] += w
      end
    end
    s += '</g>'

    # draw the clickable obj, we have the x,y from Part.id
    s += '<g stroke="white" fill="none" stroke-width="1" stroke-opacity="0.9">'
    @ontology_classes.each do |p|
      s+= "<a xlink:href=\"/projects/#{proj_id}/ontology/show_term/#{p.id}\" xlink:title=\"#{p.definition}\">" # TODO: switch to first label or OBO_label
      if p.definition.blank?
        s+= "<rect x=\"#{@xy[p.id][:x]}\" y=\"#{@xy[p.id][:y]}\" width=\"10\" height=\"10\" style=\"fill:red;\"/>"
      else
        s+= "<circle cx =\"#{@xy[p.id][:x] + 5}\" cy =\"#{@xy[p.id][:y] +5}\" r=\"5\" style=\"fill:green;\" />"
      end
      s+= "</a>"
    end
    s += '</g>'

    s += '</svg>' # close the page
    s
  end



end

