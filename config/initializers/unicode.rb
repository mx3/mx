# configure for unicode
# TODO: delete this file when 1.9.2 is complete
if RUBY_VERSION < '1.9'
$KCODE = 'u' 
# require 'jcode' # needed 
require 'jcode'
end


# for file prediction
# require 'cmess/guess_encoding'
