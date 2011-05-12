class LanguageController < ApplicationController

  def auto_complete_for_language
    @tag_id_str = params[:tag_id]
    value = params[@tag_id_str.to_sym]

    @languages = Language.find_for_auto_complete(value)
    render :inline => "<%= auto_complete_result_with_ids(@languages,
    'format_obj_for_auto_complete', @tag_id_str) %>"
  end

end
