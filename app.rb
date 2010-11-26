require 'sinatra'
require 'haml'
require 'bluefeather'
require 'cgi'
require 'dm-core'
require 'digest'

SITE_NAME = "site name"
PASSWD = "" #how to make password : ruby -e "require 'digest';puts Digest::MD5.hexdigest('your passwd')"

DataMapper.setup(:default, "appengine://auto")

class Page
  include DataMapper::Resource
  property :id, Text, :key => true
  property :body, Text
  property :name, Text
  property :created_at, Time

  def html
    BlueFeather.parse(self.body) rescue "<pre>#{self.body}</pre>"
  end
end

configure do
  set :logging, false
  set :app_file, __FILE__
  use Rack::Session::Cookie, :secret => 'fsdjkfhsjkhr23f8fhsdjkvhnsdjhrfuiscflaaadn8or'
end

get '/' do
  p Page.all
  @page = Page.first(:conditions => {:id => "index"}, :order => [:created_at.desc])
  redirect '/edit/index' unless @page
  haml :page
end

get '/edit/:id' do
  @page = Page.first(:conditions => {:name => params[:id]}, :order => [:created_at.desc])
  @page = Page.new if @page == nil
  haml :edit
end

get '/:id' do
  @page = Page.first(:conditions => {:id => params[:id]}, :order => [:created_at.desc])
  redirect "/edit/#{params[:id]}" unless @page
  return haml :page
end

post '/update' do
  raise if Digest::MD5.hexdigest(params[:password]) != PASSWORD
  page = Page.new
  page.name = params[:id]
  page.id = params[:id]
  page.body = params[:body]
  page.created_at = Time.now
  page.save
  redirect "/#{params[:id]}"
end

helpers do
  def h str
    CGI.escapeHTML str.to_s
  end

  def title
    if request.path_info == "/" or request.path_info == "/index"
      return SITE_NAME
    else
      return "#{SITE_NAME} - #{@page.name}"
    end
  end
end
