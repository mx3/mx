# encoding: utf-8
module ArrayHelper

  # Handles floats, strings, integers, for floats and integers will return ranges, appends sorted strings
  def self.array_as_range(array = [])
    # remove the strings sort them at the end
    strings = [] 

    array.each_with_index do |v, i|
      if !Strings::is_float(v) && !Strings::is_int(v)
        strings.push v 
        array.delete_at(i)
      end
    end

    array.map!{|i| i =~ /\./ ? i.to_f : i.to_i}.sort!

    j = array.shift
    periods = false 
    str = "#{j}"

    array.each do |i|
      if i == j + 1
        periods = true
      else 
        if periods
          str << "-#{j}, #{i}"	
        else
          str << ", #{i}"	
        end
        periods = false
      end	
      j = i
    end

    if periods
      str << "-#{j}"
    end

    if str != ""
      strings.unshift(str).join(", ")
    else
      strings.join(", ")
    end
  end


  # Takes as input a string like "25-28,0,3,1-3" and returns a sorted
  # Array of Integers that the "range" describes. Input need not be sequential.
  def self.range_as_array(string = '')
    string.gsub!(/\s*/, '')
    return [] if string.size == 0
    array = []
    string.split(",").each do |p|
      i = p.split('-')
      if i.size == 1
        array += [i[0].to_i]
      elsif i.size == 2
        array.fill(i[0].to_i..i[1].to_i){|j| j} # fill adds a nil, strange
      else
        return nil
      end
    end
    array.compact.uniq.sort 
  end

end
