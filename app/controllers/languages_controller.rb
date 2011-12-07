class LanguagesController < ApplicationController

  def auto_complete_for_language
    value = params[:term]
    @languages = Language.find_for_auto_complete(value)
    render :json => Json::format_for_autocomplete_with_display_name(:entries => @languages, :method => params[:method])
  end

end
