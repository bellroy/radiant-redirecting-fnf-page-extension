# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class FileNotFoundExtExtension < Radiant::Extension
  version "1.0"
  description "FileNotFound page type that can serve 301 or 302 redirects for moved pages."
  url "http://code.trike.com.au/svn/radiant/extensions/redirecting_file_not_found"
  
  def activate
    FileNotFoundExtPage
  end
  
end
