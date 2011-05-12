require 'fileutils'
namespace :mx do
  desc "Creates the directories mx uses for storing images, etc."
  task :setup_directories => :environment do
    list = [
      "chromatographs",
      "db_dumps",
      "gel_images/original",
      "gel_images/thumb",
      "images/original",
      "images/big",
      "images/medium",
      "images/thumb",
      "pdfs",
      "datasets"
    ].map { |path| FILE_PATH + path }
    
    # creates parent dirs as needed
    FileUtils.mkdir_p(list)
    
  end
end
