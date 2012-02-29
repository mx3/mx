# A mockup. 
# Search for 'trait' in layout_helper.rb and navigation helper to see how I configured the tabs. Ultimately we'll write some code that hides the rest of the world (you can select tabs to show in settings at present)
# http://127.0.0.1:3000/projects/12/trait

# There is no Trait model in the database. 

# These actions are specific to the trait-based data-capture workflow
# being developed in conjunection with NESCent projects.

class TraitController < ApplicationController

  # Maps to a splash page? 
  def index
  end

  # Match these methods to Cory's stories
  def start_from_an_otu
  end

  def now_do_something_lese
  end

end
