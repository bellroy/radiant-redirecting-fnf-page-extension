class RedirectingFnfPage < FileNotFoundPage

  class PageConfigError < StandardError; end

  include RedirectingFnfPageValidations
  validates_parts_do_not_contain_duplicates :temporary, :permanent

  description %{
    A "File Not Found Ext" page is like a "File Not Found" page, extended.
    
    Adding a page part called "temporary" allows you to define temporary redirections
    (that will not be remembered by search engines or properly behaved tools) (strictly
    302 status codes). A page part called "permanent" allows permanent redirections 
    (strictly, 301 status codes).
  }
  
  def headers
    status = status_header
    if status.match(/^404/)
      { 'Status' => status_header }
    else
      { 'Status' => status_header, "Location" => location_header }
    end
  end

  def render
    if redirect = redirects[attempted_path]
      <<-HTML
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>#{status_header}</title>
</head><body>
<h1>Found</h1>
<p>The document has moved <a href="#{redirect}">here</a>.</p>
</body></html>
      HTML
    else
      super
    end
  end

  private

  def status_header
    if temporary_redirects[attempted_path]
      "302 Found"
    elsif permanent_redirects[attempted_path]
      "301 Moved Permanently"
    else
      "404 Not Found"
    end
  end

  def location_header
    temporary_redirects[attempted_path] || permanent_redirects[attempted_path]
  end

  def redirects
    temporary_redirects.merge(permanent_redirects) 
  end
  def temporary_redirects
    if temporary = part("temporary")
      redirect_hash(parse_object(temporary))
    else
      {}
    end
  end
  def permanent_redirects
    if permanent = part("permanent")
      redirect_hash(parse_object(permanent))
    else
      {}
    end
  end

  def redirect_hash(yaml)
    begin
      hash = {}
      hash_from_yaml = YAML.load(yaml)
      raise PageConfigError, "There is a problem with your temporary or permanent configuration page parts." unless hash_from_yaml.is_a?(Hash)
      hash_from_yaml.each_pair do |k,v|
        hash[path_without_lead_or_trailing_slash(k)] = path_without_lead_or_trailing_slash(v)
      end
      hash
    rescue RuntimeError => e
      puts e.inspect
      raise e
    end
  end
  def path_without_lead_or_trailing_slash(path)
    path[%r{^/?(.*)/?$}, 1]
  end

  def attempted_uri
    CGI.escapeHTML(request.request_uri) unless request.nil?
  end
  def attempted_path
    uri = attempted_uri
    case uri
    when %r{^\w+://[^/]+/}
      path_without_lead_or_trailing_slash(uri[%r{^\w+://[^/]+(.+)$}, 1])
    else
      path_without_lead_or_trailing_slash(uri)
    end
  end

end
