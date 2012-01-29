# NOTE: This is a temporary API solution only!! Expect the solution to change.

class Public::BlogController < Public::BaseController

  layout "layouts/minimal"


  # shows an OTU page for iframe integration
  def otu_page
    @content_template = ContentTemplate.find(params[:content_template_id])
    if @otu = Otu.find(params[:otu_id])
      render :template => "/content_template/_page", :locals => {:content => @content_template.content_by_otu(@otu, true)}, :layout => 'otu_page_public_preview'
    else

    end
  end

end
