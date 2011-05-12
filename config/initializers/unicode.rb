# configure for unicode
# TODO: delete this file when 1.9.2 is complete
$KCODE = 'u' if RUBY_VERSION < '1.9'
# require 'jcode' # needed 
require 'jcode' if RUBY_VERSION < '1.9'


# for file prediction
# require 'cmess/guess_encoding'
