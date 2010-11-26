require 'sinatra'
require 'active_record'
require 'haml'
require 'bluecloth'
require 'cgi'
require 'rack/csrf'
require 'logger'

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => 'production.sqlite3'
)

ActiveRecord::Base.logger = Logger.new("./database.log")

#ActiveRecord::Migrator.migrate("migrate/", nil)


class Page < ActiveRecord::Base
  def html
    BlueCloth.new(self.body).to_html rescue "<pre>#{self.body}</pre>"
  end
end

configure do
  set :logging, false
  set :app_file, __FILE__
  use Rack::Session::Cookie, :secret => 'fsdjkfhsjkhr23f8fhsdjkvhnsdjhrfuiscflaaadn8or'
  use Rack::Csrf, :raise => true
end

get '/' do
  @page = Page.where(:name => "index").order("created_at desc").first
  redirect '/edit/index' unless @page
  haml :page
end

get '/edit/:id' do
  @page = Page.where(:name => params[:id]).order("created_at desc").first
  @page = Page.new if @page == nil
  haml :edit
end

get '/:id' do
  file = open("public/#{params[:id]}/index.html").read rescue nil
  return file if file
  @page = Page.where(:name => params[:id]).order("created_at desc").first
  redirect "/edit/#{params[:id]}" unless @page
  return haml :page
end

post '/update' do
  raise if Digest::MD5.hexdigest(params[:password]) != ""
  page = Page.new
  page.name = params[:id]
  page.body = params[:body]
  page.save
  redirect "/#{params[:id]}"
end

helpers do
  def h str
    CGI.escapeHTML str.to_s
  end

  def title
    if request.path_info == "/" or request.path_info == "/index"
      return "ssig33.com"
    else
      return "ssig33.com - #{@page.name}"
    end
  end
end

__END__
@@ page
<!DOCTYPE html>
%meta{:charset => "UTF-8"}
%title=h title
%link{:href => "http://ssig33.com/common.css", :media => "screen", :rel => "stylesheet", :type => "text/css"}
%meta{:name => "viewport", :content => "width=320, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"}
%div#all~@page.html

@@ edit
<!DOCTYPE html>
%meta{:charset => "UTF-8"}
%title=h "Edit - #{params[:id]}"
%link{:href => "http://ssig33.com/common.css", :media => "screen", :rel => "stylesheet", :type => "text/css"}
%meta{:name => "viewport", :content => "width=320, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"}
%div#all
  %form{:action => "/update", :method => "post"}
    =Rack::Csrf.csrf_tag(env)
    %input{:id => "id", :name => "id", :type => "hidden", :value => "#{params[:id]}"}
    %p
      %textarea{:cols => "80", :id => "bodY", :name => "body", :rows => "30"}=@page.body #rescue ""
    %p 
      %input{:id => "password", :name => "password", :type => "password"}
    %p
      %input{:name => "commit", :type => "submit", :value => "Save changes"}
