# encoding: utf-8
module ImageManipulation
  # RMagick was causing problems when I needed this,
  # so I just call the ImageMagick programs directly.
  
  # runs `convert` on the specified input, with the given options
  def im_make_jpg(input, output, options)
    options = {:quality => 80, :sharpen => ""}.merge(options)
    
    # configure in local_config.rb
    convert = "#{IMAGE_MAGICK_PATH}convert"
    
    cmd = "#{convert} -flatten -quality #{options[:quality]} -size #{options[:x]}x#{options[:y]}" + 
    " #{input} -scale #{options[:x]}x#{options[:y]}  #{options[:sharpen]} +profile \"*\" #{output}"
    # assume convert is in PATH for compatibility
    logger.info "Executing '#{cmd}'"
    system(cmd)
  end

  # returns a hash with the image type, width and height
  def im_identify(source_name)
    
    # configure in local_config.rb
    identify = "#{IMAGE_MAGICK_PATH}identify"

    #raise "Failed to find 'identify' binary on your system. Check your ImageMagick installation." unless `#{identify} --version`["ImageMagick"]
    
    # Finally figured out how to make identify fast (-ping)
    # assume identify is in PATH for compatibility
    cmd = "#{identify} -ping -format '%m:%w:%h' #{source_name}"
    # logger.info("$PATH is: " + `echo $PATH`)
    logger.info("Executing '#{cmd}'")
    
    res = `#{cmd}`.strip.gsub("'",'').split(":") # the gsub fixes a bug on PCs where additional characters were added
    {:type => res[0], :width => res[1], :height => res[2]}
  end
  
end
