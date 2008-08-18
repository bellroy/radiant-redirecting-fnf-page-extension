require File.dirname(__FILE__) + '/../spec_helper'

describe RedirectingFnfPage do 
    scenario :home_page

    TEMP_YAML_HASH = <<-YAML
a/page: http://example/new/page
/a-page: /a/different/page
last-page: the/last/page
                    YAML

    PERM_YAML_HASH = <<-YAML
a1/page: http://example.com/new1/page
/a1-page: /a1/different/page
last1-page: the1/last/page
                    YAML

    DUP_YAML_HASH = <<-YAML
dupa1: http://example/new/page
dupa1: /a/different/page
last-page: the/last/page
                     YAML

    before do
        create_page "Gallery", :body => 'Hello World'
        create_page "File not found", :class_name => "RedirectingFnfPage" do
              create_page_part "body", :content => "<span>File not found</span>", :id => 100
        end        
    end

    it "should not redirect to file not found if requested page is present" do  
      pages(:home).find_by_url("/gallery").should_not == pages(:file_not_found)
    end

    it "should redirect to the file not found if requested page is not present" do  
      pages(:home).find_by_url("/missing_url").should == pages(:file_not_found)
    end

    it "should render the 'body' part of file_not_found page when there are no temporary or permanent part" do
       pages(:file_not_found).should render('<r:content />').as('<span>File not found</span>')
    end

    it "should render the 'body' part of file_not_found when the missing url does not match any url's provided in temporary part" do
       page = pages(:file_not_found)
       create_page_part "temporary", :content => TEMP_YAML_HASH, :page_id => page.id
       render_header(page, '/missing_url').should == {"Status"=>"404 Not Found"}
       page.render.should == '<span>File not found</span>'
    end

    it "should render the 'body' part of file_not_found when the missing url does not match any url's provided in permanent part" do
       page = pages(:file_not_found)
       create_page_part "permanent", :content => PERM_YAML_HASH, :page_id => page.id
       render_header(page, '/missing_url').should == {"Status"=>"404 Not Found"}
       page.render.should == '<span>File not found</span>'
    end

    describe "temporary redirects" do

       before  do
	  create_page_part "temporary", :content => TEMP_YAML_HASH, :page_id => pages(:file_not_found).id
       end

       TEMP_YAML_HASH.each do |y|
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
    end

    describe "permanent redirects" do

       before  do
	  create_page_part "permanent", :content => PERM_YAML_HASH, :page_id => pages(:file_not_found).id
       end

       PERM_YAML_HASH.each do |y|
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

    end

    describe "validations" do

      it "should be invaid if the same url to redirect is first added in temporary page part and then to permanent page part" do                
         page = pages(:file_not_found)
         create_page_part "temporary", :content => TEMP_YAML_HASH, :page_id => page.id
         create_page_part "permanent", :content => TEMP_YAML_HASH, :page_id => page.id
         page.should_not be_valid    
      end       

      it "should be invaid if the same url to redirect is first added in permanent page part and then to temporary page part" do                
         page = pages(:file_not_found)
         create_page_part "permanent", :content => PERM_YAML_HASH, :page_id => page.id
         create_page_part "temporary", :content => PERM_YAML_HASH, :page_id => page.id
         page.should_not be_valid             
      end   

      it "should be invalid if there are duplicate url's in the content of permanent page part" do
         page = pages(:file_not_found)
         create_page_part "permanent", :content => DUP_YAML_HASH, :page_id => page.id
         page.should_not be_valid  
      end

      it "should be invalid if there are duplicate url's in the content of temporary page part" do
         page = pages(:file_not_found)
         create_page_part "temporary", :content => DUP_YAML_HASH, :page_id => page.id
         page.should_not be_valid  
      end

      it "should be valid if there are different url's in temporary and permanent page parts" do
         page = pages(:file_not_found)
         create_page_part "temporary", :content => TEMP_YAML_HASH, :page_id => page.id
         create_page_part "permanent", :content => PERM_YAML_HASH, :page_id => page.id
         page.should be_valid
      end

      it "should be invalid if the YAML specified in temporary page part content is invalid" do
        page = pages(:file_not_found)
        page.stub!(:parts).and_return([mock('temporary part', :null_object => true,
                                            :name => "temporary", :content => invalid_yaml)])
        page.should_not be_valid
      end

      it "should be invalid if the YAML specified in permanent page part content is invalid" do
        page = pages(:file_not_found)
        page.stub!(:parts).and_return([mock('permanent part', :null_object => true,
                                            :name => "permanent", :content => invalid_yaml)])
        page.should_not be_valid
      end
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

    def invalid_yaml
      ":\n : :\n ::not valid YAML:: "
    end
end
