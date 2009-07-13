require_dependency 'application_controller'

class RedirectingFnfPageExtension < Radiant::Extension
  version "1.0"
  description "FileNotFound page type that can serve 301 or 302 redirects for moved pages."
  url "http://github.com/tricycle/radiant-redirecting-fnf-page-extension/"
  
  def activate
    FileNotFoundPage
    RedirectingFnfPage
    admin.page.edit.add(:form, "part_errors", :before => "edit_page_parts")
  end

  def deactivate
    
  end
  
end
