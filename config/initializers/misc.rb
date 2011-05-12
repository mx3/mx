# Be sure to restart your server when you modify this file.
# stolen (once removed) from http://blog.mauricecodik.com/2006/04/hash-auto-vivification.html
HashFactory = lambda { Hash.new {|h,k| h[k] = HashFactory.call} } # via Perl goodness 
# HashOfArrays = Hash.new{|hash, key| hash[key] = Array.new}


