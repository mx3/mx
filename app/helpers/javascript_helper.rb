module JavascriptHelper

 def bind_remote_link_to_spinner_tag(link_id, spinner_id)
   # content_for :head do
      content_tag :script, :type => 'text/javascript' do
        render :partial => '/shared/foo.js', :locals => {:link_id => link_id, :spinner_id => spinner_id}
      end
   # end
 end

end
