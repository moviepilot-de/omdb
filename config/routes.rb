# matcht controller die unterhalb von /encyclopedia eingehaengt sind
ENCYCLOPEDIA_CONTROLLERS = /(job|category|country|year|company|character)/ unless defined?(ENCYCLOPEDIA_CONTROLLERS)
IMAGE_FILENAME = /^(\d+)(_(\d+))?\.(pjpg|pjpeg|bmp|jpg|jpeg|png|gif)$/i unless defined?(IMAGE_FILENAME)

ActionController::Routing::Routes.draw do |map|
  # Add your own custom routes here.
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Here's a sample route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  # map.connect '', :controller => "welcome"

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  map.connect "test/coverage/*path",  :controller => "test", 
                                      :action     => "coverage"
  
  # Rails 1.2 only, before that '.' will be eaten up by :action
  #map.connect '/image/:id/:action.:format', :controller => 'image', 
  #                                  :id => /\d+/, 
  #                                  :action => 'index',
  #                                  :format => 'jpg'

#  map.connect 'image/:id/copyright', :controller => 'image', 
#                                     :action     => 'page',
#                                     :page       => 'copyright'

  map.connect 'image/:fname', :controller => 'image', 
                              :action => 'index',
                              :fname => IMAGE_FILENAME
  map.connect 'image/:action/:fname', :controller => 'image', 
                                      :action => 'index',
                                      :fname => IMAGE_FILENAME

  map.connect 'logout', :controller => "account", :action => "logout"

  map.connect 'movie/latest.xml', :controller => 'movie', :action => 'latest', :type => 'rss'
  map.connect 'movie/:id/cast/:edit', :controller => 'movie', :action => 'cast', :id => /\d+/, :edit => /(edit_cast|edit_crew)/

  map.connect 'encyclopedia/:controller/:id/:action/:page', :controller => ENCYCLOPEDIA_CONTROLLERS
  map.connect ':controller/:id/:action/:page', :id   => /\d+/

  map.connect ':controller/:id/view_diff/:page/:from/to/:to', :id => /\d+/,
                                               :action => 'view_diff',
                                               :from => /\d+/,
                                               :to => /\d+/
  map.connect 'content/:page/view_diff/:from/to/:to', 
                                               :controller => 'generic_page',
                                               :action => 'view_diff',
                                               :from => /\d+/,
                                               :to => /\d+/
  map.connect 'content/:page/:action', :controller => 'generic_page', :action => 'page'

  map.connect 'encyclopedia/:controller/:id/:action', :controller => ENCYCLOPEDIA_CONTROLLERS

  map.connect ':controller/:id/:action/:view', :id => /\d+/

  map.connect ':controller/:id/:action', :id => /\d+/
  map.connect ':controller/:id/:action/:page', :id => /\d+/, :page => /\d+/
  map.connect ':controller/:id/trackback/:language', :id => /\d+/, :action => "trackback"
  map.connect 'user/my_profile', :controller => 'user', :action => 'my_profile'
  map.connect 'user/add_movie', :controller => 'user', :action => 'add_movie'
  map.connect 'user/delete_movie', :controller => 'user', :action => 'delete_movie'
  map.connect 'user/:id/:action', :controller => 'user'
  map.connect 'user/:id/:action/:page', :controller => 'user', :page => /\d+/
  map.connect ':controller/:action'
  map.connect ':controller/:action/:id'
end
