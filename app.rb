require File.join(__dir__, "lib", "provisioner")
require 'sinatra'

# set :bind, '0.0.0.0'
# set :port, 4567

VERSION = File.new(File.join(__dir__, "version.rb")).read.chomp

class Application < Sinatra::Base

  use Rack::Auth::Basic, "Authentication Required" do |username, password|
    username == ENV['BASIC_AUTH_USERNAME'] and password == ENV['BASIC_AUTH_PASSWORD']
  end

  before do
    content_type :json
  end

  not_found do
    "Not Found"
  end

  # POST routes - provision actions

  post '/gravity-install' do
    data = JSON.parse(request.body.read)
    data["action"] = "gravity_install"
    execute_post(Kinetic::Platform::GravityInstall.new(data))
  end

  post '/install' do
    data = JSON.parse(request.body.read)
    data["action"] = "install"
    execute_post(Kinetic::Platform::Install.new(data))
  end

  post '/repair' do
    data = JSON.parse(request.body.read)
    data["action"] = "repair"
    execute_post(Kinetic::Platform::Repair.new(data))
  end

  post '/upgrade' do
    data = JSON.parse(request.body.read)
    data["action"] = "upgrade"
    execute_post(Kinetic::Platform::Upgrade.new(data))
  end

  post '/decommission' do
    data = JSON.parse(request.body.read)
    data["action"] = "decommission"
    execute_post(Kinetic::Platform::Decommission.new(data))
  end

  post '/uninstall' do
    data = JSON.parse(request.body.read)
    data["action"] = "uninstall"
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
      :application => "Kinetic Platform Tenant Data Manager",
      :version => VERSION
    }.to_json
  end

  # execute the provisioner action and return the json data to respond with
  def execute_post(provisioner)
    logger.info("Request to #{provisioner.action} #{provisioner.slug}")

    # run the provision action in a separate thread so the initial request
    # doesn't have to wait for the entire provisioner action
    Thread.new do
      results = provisioner.execute
      provisioner.callback(results)
    end

    # return the initial results
    {
      :action => provisioner.action,
      :space_slug => provisioner.slug
    }.to_json
  end
end
