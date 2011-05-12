class BerkeleyMapperResultController < ApplicationController

  def map
    if params[:specimen_id] # map a single specimen
      @specimens = [Specimen.find(params[:specimen_id])]
    end
    
    # presently also view all specimens in an OTU group
    if not params[:otu_group_id].blank?
      if og = OtuGroup.find(params[:otu_group_id])
        @specimens ||= Specimen.find(:all, 
        :include => [:ce, :otus, :repository, :most_recent_determination], 
        :joins => "LEFT JOIN otu_groups_otus og ON otus.id = og.otu_id", 
        :conditions => ["og.otu_group_id = ? AND ces.geog_id IS NOT NULL", og.id])
      else
        flash[:notice] = "hmm, that's odd, quit playing with custom urls"
        redirect_to :action => 'list', :controller => 'specimens'
      end
    end
    
    if @specimens.size == 0
      flash[:notice] = 'No specimens found to map.'
      redirect_to :action => 'list', :controller => 'specimens' and return
    end
    
    tabfile = @specimens.collect{|s|
      [s.id,
       s.most_recent_determination.display_name[3..-5],
       s.ce.geog.country.name,
       s.ce.geog.state.blank? ? '' : s.ce.geog.state.name,
       s.ce.geog.county.blank? ? '' : s.ce.geog.county.name,
       s.ce.locality,
       s.repository.blank? ? '' : s.repository.coden,
       s.ce.sd_y,
       s.most_recent_determination.determiner,
       s.ce.collectors,
       s.ce.host_genus + " " + s.ce.host_species, 
       s.ce.latitude,
       s.ce.longitude,
       s.ce.dc_coordinate_uncertainty_in_meters, "WGS84" ].join("\t") 
    }.join("\n")
      
    bmr = BerkeleyMapperResult.create!(:tabfile => tabfile)
    
    # can't have any spaces!
    # note we have to use the public controller to render the results, because, surprise surprise, the 
    # BerkeleyMapper isn't logged in!
    url = "http://berkeleymapper.berkeley.edu/run.php" + 
    "?ViewResults=tab" + 
    "&tabfile=http://#{HOME_SERVER}/projects/#{@proj.id}/public/berkeley_mapper_result/show/#{bmr.id}" + 
    "&configfile=http://#{HOME_SERVER}/xml/berkeleymapper.xml" + 
    "&sourcename=mx+Specimen+resultset"

    # not needed? &queryvalue=-180+-90+180+90
    
    redirect_to url
  end
  
  
end
