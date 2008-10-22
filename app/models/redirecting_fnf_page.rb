class RedirectingFnfPage < FileNotFoundPage

  class PageConfigError < StandardError; end

  include RedirectingFnfPageValidations
  validates_parts_as_yaml_hash :temporary, :permanent
  validates_parts_do_not_contain_duplicates :temporary, :permanent, :if => Proc.new { |page| page.errors.on_base.blank? }
  validates_part_does_not_contain_duplicates :gone

  description %{
    A "File Not Found Ext" page is like a "File Not Found" page, extended.
    
    Adding a page part called "temporary" allows you to define temporary redirections
    (that will not be remembered by search engines or properly behaved tools) (strictly
    302 status codes). A page part called "permanent" allows permanent redirections 
    (strictly, 301 status codes).
  }

  def headers
    if redirect?
      { 'Status' => status_header, "Location" => location_header }
    else
      { 'Status' => status_header }
    end
  end

  def render
    if redirect?
      <<-HTML
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>#{status_header}</title>
</head><body>
<h1>Found</h1>
<p>The document has moved <a href="#{location_header}">here</a>.</p>
</body></html>
      HTML
    elsif gone?
      ""
    else
      super
    end
  end

  private

  def redirect?
    temporary_redirect? || permanent_redirect?
  end

  def temporary_redirect?
    temporary_redirects[attempted_path]
  end

  def permanent_redirect?
    permanent_redirects[attempted_path]
  end
  
  def gone?
    gone_list[attempted_path]
  end

  def status_header
    if temporary_redirect?
     "302 Found"
    elsif permanent_redirect?
     "301 Moved Permanently"
    elsif gone?
      "410 Gone"
    else
      "404 Not Found"
    end
  end

  def location_header
    redirects[attempted_path]
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

  def gone_list
    if gone = part("gone")
      hash = {}
      gone.content.each do |line|
        next if line.chomp.empty?
        hash[path_with_lead_without_trailing_slash(line.chomp)] = true
      end
      hash
    else
      {}
    end
  end

  def redirect_hash(yaml)
    @hash ||= begin
                hash = {}
                YAML.load(yaml).each_pair do |k,v|
                  hash[path_with_lead_without_trailing_slash(k)] = path_with_lead_without_trailing_slash(v)
                end
                hash
              end
  end
  def path_with_lead_without_trailing_slash(path)
    case path
    when %r{^\w+://}
      path.chomp('/')
    else
      "/" + path.to_s[%r{^/?(.*?)/?$}, 1]
    end
  end

  def attempted_uri
    CGI.escapeHTML(request.request_uri) unless request.nil?
  end
  def attempted_path
    uri = attempted_uri
    case uri
    when %r{^\w+://[^/]+/}
      path_with_lead_without_trailing_slash(uri[%r{^\w+://[^/]+(.+)$}, 1])
    else
      path_with_lead_without_trailing_slash(uri)
    end
  end

end
