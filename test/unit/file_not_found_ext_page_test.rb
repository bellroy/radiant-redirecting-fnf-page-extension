require File.dirname(__FILE__) + '/../test_helper'

class FileNotFoundExtPageTest < Test::Unit::TestCase
  test_helper :page

  YAMLHASH = <<-YAML
a/page: http://example.com/a/page
/a-page: /a/different/page
last-page: the/last/page
    YAML

  def setup
    @root = Factory::setup_page(Factory::make_page!("Root"))
    @root.slug, @root.breadcrumb = "/", "/"
    @root.save!

    title = "Page Not Found"
    @page = FileNotFoundExtPage.find_or_create_by_title(title)
    @page.slug, @page.breadcrumb = title.downcase.tr(' ','-'), title
    @page.parts.find_or_create_by_name("body")
    @page.save!
    @root.children << @page
    @root.save!
  end

  # def find_by_url(url, live = true, clean = true)
  def test_that_find_by_url_finds_us_when_nothing_else_matches
    assert_equal @page, @root.find_by_url("a/page")
  end

  def test_that_body_part_is_rendered_when_urls_are_not_found_in_config_page_parts
    part = @page.parts.find_or_create_by_name("body")
    part.content = "HTML"
    part.save!; @page.reload

    assert_page_renders "HTML"
  end

  def test_that_appropriate_html_is_rendered_when_url_is_found_in_permanent_page_part
    part = @page.parts.find_or_create_by_name("permanent")
    part.content = YAMLHASH
    part.save!; @page.reload

    assert_page_renders(/<title>301/, '/a/page')
  end
  def test_that_location_is_rendered_in_headers_when_url_is_found_in_permanent_page_part
    part = @page.parts.find_or_create_by_name("permanent")
    part.content = YAMLHASH
    part.save!; @page.reload

    assert_headers({"Location"=>"http://example.com/a/page", "Status"=>"301 Moved Permanently"}, '/a/page')
  end

  def test_that_appropriate_html_is_rendered_when_url_is_found_in_temporary_page_part
    part = @page.parts.find_or_create_by_name("temporary")
    part.content = YAMLHASH
    part.save!; @page.reload

    assert_page_renders(/<title>302/, '/a/page')
  end
  def test_that_location_is_rendered_in_headers_when_url_is_found_in_temporary_page_part
    part = @page.parts.find_or_create_by_name("temporary")
    part.content = YAMLHASH
    part.save!; @page.reload

    assert_headers({"Location"=>"http://example.com/a/page", "Status"=>"302 Found"}, '/a/page')
  end

  def test_that_invalid_yaml_raises_appropriate_error
    part = @page.parts.find_or_create_by_name("temporary")
    part.content = "This is not a valid YAML hash"
    part.save!; @page.reload

    assert_raise(FileNotFoundExtPage::PageConfigError) { @page.render }
  end

end
