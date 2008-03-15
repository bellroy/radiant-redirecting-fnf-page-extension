require 'test/unit'
# # Load the environment
unless defined? RADIANT_ROOT
  ENV["RAILS_ENV"] = "test"
  require "#{File.expand_path(File.dirname(__FILE__) + "/../../../../")}/config/environment"
end
require "#{RADIANT_ROOT}/test/test_helper"

class Test::Unit::TestCase
  
  # Include a helper to make testing Radius tags easier
  test_helper :extension_tags
  
  # Add the fixture directory to the fixture path
  self.fixture_path << File.dirname(__FILE__) + "/fixtures"
  
  # Add more helper methods to be used by all extension tests here...

  def with(value)
    yield value
  end

  module Factory
    def self.setup_page(page)
      @page = page
      @context = PageContext.new(@page)
      @parser = Radius::Parser.new(@context, :tag_prefix => 'r')
      @page
    end

    def self.make_page!(title)
      p = Page.find_or_create_by_title(title)
      p.slug, p.breadcrumb = title.downcase, title
      p.parts.find_or_create_by_name("body")
      p.save!
      p
    end
    def self.make_kid!(page, title)
      kid = make_page!(title)
      page.children << kid
      page.save!
      kid
    end
    def self.make_kids!(page, *kids)
      kids.collect {|kid| make_kid!(page, kid) }
    end
  end

  def assert_renders(expected, input, url = nil, host = nil)
    output = get_render_output(input, url, host)
    message = "<#{expected.inspect}> expected but was <#{output.inspect}>"
    assert_block(message) { expected == output }
  end
  
  def assert_render_match(regexp, input, url = nil, host = nil)
    regexp = Regexp.new(regexp) if regexp.kind_of? String
    output = get_render_output(input, url, host)
    message = "<#{output.inspect}> expected to be =~ <#{regexp.inspect}>"
    assert_block(message) { output =~ regexp }
  end
  
  def assert_render_error(expected_error_message, input, url = nil, host = nil)
    output = get_render_output(input, url, host)
    message = "expected error message <#{expected_error_message.inspect}> expected but none was thrown"
    assert_block(message) { false }
  rescue => e
    message = "expected error message <#{expected_error_message.inspect}> but was <#{e.message.inspect}>"
    assert_block(message) { expected_error_message === e.message }
  end
  
  def assert_headers(expected_headers, url = nil, host = nil)
    setup_page(url, host)
    headers = @page.headers
    message = "<#{expected_headers.inspect}> expected but was <#{headers.inspect}>"
    assert_block(message) { expected_headers == headers }
  end
  
  def assert_page_renders(expected, url = nil, host = nil)
    setup_page(url, host)
    page = @page
    output = page.render
    message = "<#{expected.inspect}> expected, but was <#{output.inspect}>"
    if expected.respond_to?(:match)
      assert_block(message) { output.match(expected) }
    else
      assert_block(message) { expected == output }
    end
  end
  
  def assert_snippet_renders(expected, message = nil)
    snippet = @snippet
    output = @page.render_snippet(snippet)
    message = message || "<#{expected.inspect}> expected, but was <#{output.inspect}>"
    assert_block(message) { expected == output }
  end

  private
  
  def get_render_output(input, url, host = nil)
    setup_page(url, host)

    @page.send(:parse, input)
  end

  def setup_page(url = nil, host = nil)
    @page.request = ActionController::TestRequest.new
    @page.request.request_uri = 'http://testhost.tld' + (url || @page.url)
    @page.request.host = host unless host.nil?
    @page.response = ActionController::TestResponse.new
  end

end
