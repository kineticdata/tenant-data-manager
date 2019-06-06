require 'json'

require File.join(__dir__, "platform.rb")
require File.join(__dir__, "actions", "action_base.rb")
Dir["#{__dir__}/**/*.rb"].each { |file| require file }
