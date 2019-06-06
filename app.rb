require File.join(__dir__, "lib", "provisioner")
require 'sinatra'

set :bind, '0.0.0.0'
set :port, 4567

APP = "Platform Tenant Provisioner"
VERSION = "0.1.0"
RELEASE_DATE = "2019-05-15"


before do
  content_type :json
end

not_found do
  "Not Found"
end

# POST routes - provision actions

post '/install' do
  data = JSON.parse(request.body.read)
  execute_post(Kinetic::Platform::Install.new(data))
end

post '/repair' do
  data = JSON.parse(request.body.read)
  execute_post(Kinetic::Platform::Repair.new(data))
end

post '/upgrade' do
  data = JSON.parse(request.body.read)
  execute_post(Kinetic::Platform::Upgrade.new(data))
end

post '/decommission' do
  data = JSON.parse(request.body.read)
  execute_post(Kinetic::Platform::Decommission.new(data))
end

post '/uninstall' do
  data = JSON.parse(request.body.read)
  execute_post(Kinetic::Platform::Uninstall.new(data))
end

# GET routes - health / version

get '/' do
  {
    :status => "Running"
  }.to_json
end

get '/version' do
  { 
    :application => APP,
    :version => VERSION,
    :release_date => RELEASE_DATE
  }.to_json
end

# execute the provisioner action and return the json data to respond with
def execute_post(provisioner)
  logger.info("Request to #{provisioner.action} #{provisioner.slug}")
  results = provisioner.execute
  {
    :action => provisioner.action,
    :space_slug => provisioner.slug,
    :results => results
  }.to_json
end
