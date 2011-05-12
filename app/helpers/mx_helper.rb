# encoding: utf-8
module MxHelper
  # this is Matrices, not mx the application

  # chrs is an array of Chr
  def vertical_char_text(chrs)
    s = "data:image/svg+xml,
          <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' xml:space='preserve' version='1.1' baseProfile='full'  height='500' >
          <g transform='translate(7,0) rotate(90)' font-size='12' font-family='Tahoma' fill='#000'>" 
    chrs.each_with_index do |c, i|
      s += "<text transform='translate(0, -#{i*15})'>#{c.display_name.gsub(/[^A-Za-z1-9\s_\)\(\=]/, "_")}</text>"
    end 

    s+= "</g></svg>" 
    html_escape(s)
  end


  # chrs is an array of Chr
  def angled_char_text(chrs)
      s = "data:image/svg+xml,
          <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' xml:space='preserve' version='1.1' baseProfile='full' width='#{chrs.size * 20}' height='47' >
            <g transform='translate(10,45)' font-size='12' font-family='Tahoma' fill='#000'>  "
         chrs.each_with_index do |c, i| 
           s += "<g transform='translate(#{i*15},0)'>
                    <g transform='rotate(-60)'><text>#{c.short_name}</text></g>
                 </g>"
           end 
        s += "</g>
          </svg>"
        html_escape(s)
  end

  def svg_radar(window, total_chrs, total_otus)
    s = "data:image/svg+xml,
            <svg xmlns='http://www.w3.org/2000/svg' width='#{(total_chrs / 2) + 10}' height='#{(total_otus /2 ) + 10}'>
           <g transform='scale(.5)'>
             <rect fill='#bbb' x='0' y='0' width='#{total_chrs}' height='#{total_otus}' />
             <rect fill='red' x='#{window[:chr_start]-1}' y='#{window[:otu_start]-1}' width='#{window[:chr_end] - window[:chr_start]}' height='#{window[:otu_end] - window[:otu_start]}'/>
           </g>
           </svg>" 
    html_escape(s)
  end

  def continuous_cell_value(chr, otu)
    c = Coding.find_by_chr_id_and_otu_id(chr.id, otu.id)
    c ? c.continuous_state : nil
  end

end
