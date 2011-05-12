# encoding: utf-8
module ColorHelper

  # ranged colors for css, v is a percentage from 0.0 to 1.0
  # wow division is odd in Ruby! (.to_f) 
  def self.ranged_color(v = 0.0, c = 'blue')
    n =  240 - (v * 240).to_i 
    case c
    when 'blue'
      "#{n}, #{n}, 240"
    when 'red'
      "240, #{n}, #{n}"
    when 'green'
      "#{n}, 240, #{n}"
    end
  end

  # from http://bytes.com/topic/perl/answers/693973-converting-hex-string-32-bit-signed-integer
  def self.hexstr_to_signed32int(hexstr) 
    #   return nil if hexstr =~ /^[0-9A-Fa-f]{1,8}$/
    num = hexstr.to_i(16)
    return (num > 31 ? num - 2 ** 32 : num)
  end
 
  # from http://bytes.com/topic/perl/answers/693973-converting-hex-string-32-bit-signed-integer
  def self.signed32int_to_hexstr (int) 
    return nil if int > 2147483647 || int < -2147483648
    unsigned = (int < 0 ? 2 ** 32 + int : int)
    return ("%x" % unsigned)
  end 
 
  # Map colors based on www.ColorBrewer.org, by Cynthia A. Brewer, Penn State.
  def self.colour(index) # canuck style
    case index
    when 1
      return 'rgb(165,0,38)'
    when 2
      'rgb(215,48,39)'
    when 3
      'rgb(244,109,67)'
    when 4
      'rgb(253,174,97)'
    when 5
      'rgb(254,224,139)'
    when 6
      'rgb(255,255,191)'
    when 7
      'rgb(217,239,139)'
    when 8
      'rgb(166,217,106)'
    when 9
      'rgb(102,189,99)'
    when 10
      'rgb(26,152,80)'
    when 11
      'rgb(0,104,55)'
    end
  end 
  def self.palette(options = {})
      opt = {
        :hex => false,
        :palette => :cb_qual_12,
        :index => 0
      }.merge!(options)

    raise if opt[:index].nil?

    palettes = {:heat_9 => %w(ffcccccc ff000000 ff0000cc ff00ffff ff00cc00 ffffff00 ffff9900 ffff0000 ffcc00cc),
                :blues_10 => %w(ffc1d6fd ffadc2e9 ff9aafd5 ff879bc1 ff7488ae ff61749a ff4d6186 ff3a4d73 ff27395f ff14264b ff011338), # 0xC1D6FD - 0x011338
                :grey_scale => %w(ff000000 ff111111 ff222222 ff333333 ff444444 ff555555 ff666666 ff777777 ff888888 ff999999 ffaaaaaa ffbbbbbb ffcccccc ffdddddd ffeeeeee ffffffff),
                :cb_qual_12 => %w(ff8dd3c7 ffffffb3 ffbebada fffb8072 ff80b1d3 fffdb462 ffb3de69 fffccde5 ffd9d9d9 ffbc80bd ffccebc5 ffffed6f),
                :cb_seq_9_mh_green => %w(fff7fcf5 ffeff5e0 ffc7e9c0 ffa1d99b ff74c476 ff41ab5d ff238b45 ff006d2c ff00441b),
                :cb_seq_9_mh_red => %w(fffff7ec fffee8c8 fffdd49e fffdbb84 fffc8d59 ffef6548 ffd7301f ffb30000 ff7f0000),
                :meh => %w(ff000000 ff000000 ff0000ff ff00ffff ff444444 ff888888 ff00ff00 ffcccccc ffff00ff ffffffff ff123456 ff654321 ffabcdef fffedcba),
                :blue_100 => %w(ffffffff fffcfcff fffafaff fff8f8ff fff6f6ff fff4f4ff fff2f2ff fff0f0ff ffeeeeff ffececff ffeaeaff ffe8e8ff ffe6e6ff ffe4e4ff ffe2e2ff ffe0e0ff ffdedeff ffdcdcff ffdadaff ffd8d8ff ffd6d6ff ffd3d3ff ffd1d1ff ffcfcfff ffcdcdff ffcbcbff ffc9c9ff ffc7c7ff ffc5c5ff ffc3c3ff ffc1c1ff ffbfbfff ffbdbdff ffbbbbff ffb9b9ff ffb7b7ff ffb5b5ff ffb3b3ff ffb1b1ff ffafafff ffadadff ffaaaaff ffa8a8ff ffa6a6ff ffa4a4ff ffa2a2ff ffa0a0ff ff9e9eff ff9c9cff ff9a9aff ff9898ff ff9696ff ff9494ff ff9292ff ff9090ff ff8e8eff ff8c8cff ff8a8aff ff8888ff ff8686ff ff8484ff ff8181ff ff7f7fff ff7d7dff ff7b7bff ff7979ff ff7777ff ff7575ff ff7373ff ff7171ff ff6f6fff ff6d6dff ff6b6bff ff6969ff ff6767ff ff6565ff ff6363ff ff6161ff ff5f5fff ff5d5dff ff5b5bff ff5858ff ff5656ff ff5454ff ff5252ff ff5050ff ff4e4eff ff4c4cff ff4a4aff ff4848ff ff4646ff ff4444ff ff4242ff ff4040ff ff3e3eff ff3c3cff ff3a3aff ff3838ff ff3636ff ff3434ff ff3232ff),
                :heat_10 => %w(ff000044 ff14003d ff280036 ff3d002f ff510028 ff660022 ff74001b ff8e0014 ffa3000d ffb70006 ffcc0000),
                :cb_div_5_blue_red => %w(ff2c7bb6 ffabd9e9 ffffffbf fffdae61 ffca373b),
                :cb_div_10_blue_red => %w(ff313695 ff4575b4 ff74add1 ffabd9e9 ff0f3ff8 fffee090 fffdae61 fff46d43 ffd73027 ffa50026),
                :primary_6 => %w(ffed1c24, fff26522, ffffde17, ff00a14b, ff21409a, ff7f3f98)
              }
    return nil if !palettes.keys.include?(opt[:palette])
    return nil if (palettes[opt[:palette]].size < opt[:index])
    opt[:hex] ? palettes[opt[:palette]][opt[:index]] : hexstr_to_signed32int(palettes[opt[:palette]][opt[:index]])
  end


end


