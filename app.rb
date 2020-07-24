require File.join(__dir__, "lib", "provisioner")
require 'sinatra'

# set :bind, '0.0.0.0'
# set :port, 4567

VERSION = File.new(File.join(__dir__, "version.rb")).read.chomp

class Application < Sinatra::Base

  helpers do
    def protected!
      return if authorized?
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Authentication Required\n"
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? and 
        @auth.basic? and 
        @auth.credentials and 
        @auth.credentials == [ENV['BASIC_AUTH_USERNAME'], ENV['BASIC_AUTH_PASSWORD']]
    end
  end

  before do
    content_type :json
  end

  not_found do
    "Not Found\n"
  end

  # POST routes - provision actions

  post '/gravity-install' do
    protected!
    data = JSON.parse(request.body.read)
    data["action"] = "gravity_install"
    execute_post(Kinetic::Platform::GravityInstall.new(data))
  end

  post '/install' do
    protected!
    data = JSON.parse(request.body.read)
    data["action"] = "install"
    execute_post(Kinetic::Platform::Install.new(data))
  end

  post '/repair' do
    protected!
    data = JSON.parse(request.body.read)
    data["action"] = "repair"
    execute_post(Kinetic::Platform::Repair.new(data))
  end

  post '/upgrade' do
    protected!
    data = JSON.parse(request.body.read)
    data["action"] = "upgrade"
    execute_post(Kinetic::Platform::Upgrade.new(data))
  end

  post '/decommission' do
    protected!
    data = JSON.parse(request.body.read)
    data["action"] = "decommission"
    execute_post(Kinetic::Platform::Decommission.new(data))
  end

  post '/uninstall' do
    protected!
    data = JSON.parse(request.body.read)
    data["action"] = "uninstall"
    execute_post(Kinetic::Platform::Uninstall.new(data))
  end

  # GET routes - health / version

  get '/' do
    {
      :status => "Running\n"
    }.to_json
  end

  get '/version' do
    { 
      :application => "Kinetic Platform Tenant Data Manager\n",
      :version => "#{VERSION}\n"
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
