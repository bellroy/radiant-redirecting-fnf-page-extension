require File.dirname(__FILE__) + '/../spec_helper'

describe RedirectingFnfPage do 
    scenario :users, :home_page

    TEMPYAMLHASH = <<-YAML
a/page: http://example/new/page
/a-page: /a/different/page
last-page: the/last/page
                    YAML

    PERMYAMLHASH = <<-YAML
a1/page: http://example.com/new1/page
/a1-page: /a1/different/page
last1-page: the1/last/page
                    YAML

    before do
        create_page "Gallery", :body => 'Hello World'
        create_page "File not found", :class_name => "RedirectingFnfPage", :slug => ' ', :breadcrumb => '-' do
              create_page_part "body", :content => "<span>File not found</span>", :id => 100
        end        
    end

    it "should not redirect to file not found if requested page is present" do  
      pages(:home).find_by_url("/gallery").should_not == pages(:file_not_found)
    end

    it "should redirect to the file not found if requested page is not present" do  
      pages(:home).find_by_url("/missing_url").should == pages(:file_not_found)
    end

    it "should render the 'body' part when there are no temporary or permanent part" do
       pages(:file_not_found).should render('<r:content />').as('<span>File not found</span>')
    end

    it "should raise error if the YAML specified in temporary page part content is invalid" do
       page = pages(:file_not_found)
       create_page_part "temporary", :content => "Not an hash", :page_id => page.id
       lambda { render_header(page, '/a') }.should raise_error(RedirectingFnfPage::PageConfigError)
    end

    it "should raise error if the YAML specified in permanent page part content is invalid" do
       page = pages(:file_not_found)
       create_page_part "permanent", :content => "Not an hash", :page_id => page.id
       lambda { render_header(page, '/a') }.should raise_error(RedirectingFnfPage::PageConfigError)
    end

    it "should render the 'body' part of file_not_found when the missing url does not match any url's provided in temporary part" do
       page = pages(:file_not_found)
       create_page_part "temporary", :content => TEMPYAMLHASH, :page_id => page.id
       render_header(page, '/missing_url').should == {"Status"=>"404 Not Found"}
       page.render.should == '<span>File not found</span>'
    end

    it "should render the 'body' part of file_not_found when the missing url does not match any url's provided in permanent part" do
       page = pages(:file_not_found)
       create_page_part "permanent", :content => PERMYAMLHASH, :page_id => page.id
       render_header(page, '/missing_url').should == {"Status"=>"404 Not Found"}
       page.render.should == '<span>File not found</span>'
    end

    describe "temporary redirects" do

       before  do
	  create_page_part "temporary", :content => TEMPYAMLHASH, :page_id => pages(:file_not_found).id
       end

       TEMPYAMLHASH.each do |y|
          yaml_arr = y.split(': ')
	     it "should render header with location and status 302 when temporary part exists (for missing url #{yaml_arr[0]})" do 
	        page = pages(:file_not_found)
		render_header(page, yaml_arr[0]).should == {"Location" => process_location(yaml_arr[1]), "Status"=>"302 Found"}
	      end
             it "should render appropriate html when temporary part exists (for missing url #{yaml_arr[0]}" do
                page = pages(:file_not_found)
                page = setup_page(page, yaml_arr[0])
                page.render.should match(/<title>302/)
             end
        end
#not valid specs below...need changes by checking validation to avoid below scenario...working on it
=begin
       TEMPYAMLHASH.each do |y|
          yaml_arr = y.split(': ')
             it "should render temporary redirect if there is both temporary and permanent redirects for same url and temporary preceeds permanent" do
                page = pages(:file_not_found)
                create_page_part "permanent", :content => TEMPYAMLHASH, :page_id => page.id
		render_header(page, yaml_arr[0]).should == {"Location" => process_location(yaml_arr[1]), "Status"=>"302 Found"}
             end
        end
=end
    end

    describe "permanent redirects" do

       before  do
	  create_page_part "permanent", :content => PERMYAMLHASH, :page_id => pages(:file_not_found).id
       end

       PERMYAMLHASH.each do |y|
          yaml_arr = y.split(': ')
             it "should render header with location and status 301 when permanent part exists (for missing url #{yaml_arr[0]})" do
                page = pages(:file_not_found)
                render_header(page, yaml_arr[0]).should == {"Location" => process_location(yaml_arr[1]), "Status"=>"301 Moved Permanently"}
             end
             it "should render appropriate html when permanent part exists (for missing url #{yaml_arr[0]}" do
                page = pages(:file_not_found)
                page = setup_page(page, yaml_arr[0])
                page.render.should match(/<title>301/)
             end
        end
#not valid specs below...need changes by adding validations to avoid below scenario...working on it
=begin
       PERMYAMLHASH.each do |y|
          yaml_arr = y.split(': ')
             it "should render temporary redirect if there is both temporary and permanent redirects for same url and permanent preceeds temporary" do
                page = pages(:file_not_found)
                create_page_part "temporary", :content => PERMYAMLHASH, :page_id => page.id
                render_header(page, yaml_arr[0]).should == {"Location" => process_location(yaml_arr[1]), "Status"=>"302 Found"}
             end
        end
=end
    end

   private

    def render_header(page, url)
      page = setup_page(page, url)
      headers = page.headers
    end

    def setup_page(page, url)
      page.request = ActionController::TestRequest.new
      page.request.request_uri = url
      page.response = ActionController::TestResponse.new
      return page
    end

    def process_location(loc)
      loc.strip!
      loc.slice!(0,1) if loc.slice(0,1) == '/'        
      loc.chomp
    end
end
