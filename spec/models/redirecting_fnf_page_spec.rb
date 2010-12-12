require File.dirname(__FILE__) + '/../spec_helper'

describe RedirectingFnfPage do 
  dataset :home_page

  REDIRECTS_YAML_HASH = <<-YAML
a/page: http://example/new/page
/a-page: /a/different/page
last-page: the/last/page
a/nother/page: /
                   YAML

  REDIRECTS_YAML_HASH_DIFFERENT = <<-YAML
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
    Page.find_by_url("/gallery").should_not == pages(:file_not_found)
  end

  it "should redirect to file not found if requested page is not present" do  
    Page.find_by_url("/missing_url").should == pages(:file_not_found)
  end

  it "should render the 'body' part of file_not_found page when there are no temporary or permanent parts" do
    pages(:file_not_found).should render('<r:content />').as('<span>File not found</span>')
  end

  it "should render the 'body' part of file_not_found when the missing url does not match any url's provided in temporary part" do
    page = pages(:file_not_found)
    create_page_part "temporary", :content => REDIRECTS_YAML_HASH, :page_id => page.id
    render_header(page, '/missing_url').should == {"Status"=>"404 Not Found"}
    page.render.should == '<span>File not found</span>'
  end

  it "should render the 'body' part of file_not_found when the missing url does not match any url's provided in permanent part" do
    page = pages(:file_not_found)
    create_page_part "permanent", :content => REDIRECTS_YAML_HASH, :page_id => page.id
    render_header(page, '/missing_url').should == {"Status"=>"404 Not Found"}
    page.render.should == '<span>File not found</span>'
  end

  describe "redirects", :shared => true do
    before do
      @page = pages(:file_not_found)
    end
    REDIRECTS_YAML_HASH.each do |y|
      redir, target = y.split(': ')
      location_part = target.chomp.sub(%r{^(/|http://)},'')
      it "should render header with appropriate keys when part exists " +
         "(for missing url #{redir})" do 
        render_header(@page, redir).keys.should == ["Status", "Location"]
      end
      it "should render header with appropriate status when part exists " +
         "(for missing url #{redir})" do 
        render_header(@page, redir)["Status"].should == @status[:text]
      end
      it "should render appropriate html when part exists (for missing url #{redir})" do
        @page = setup_page(@page, redir)
        @page.render.should match(/<title>#{@status[:code]}/)
      end
      if target.match(%r{^(/|http://)})
        it "should serve exact destinations when a leading \w+:// or / exists in destination" do
          render_header(@page, redir)["Location"].should == target.chomp
        end
      else
        it "should infer leading / when no leading \w+:// or / in destination" do
          render_header(@page, redir)["Location"].should match(Regexp.new("/" + location_part + "$"))
        end
      end
    end
  end

  describe "temporary redirects" do
    before  do
      @status = {:code => 302, :text => "302 Found"}
      create_page_part "temporary", :content => REDIRECTS_YAML_HASH, :page_id => pages(:file_not_found).id
    end
    it_should_behave_like "redirects"
  end

  describe "permanent redirects" do
    before  do
      @status = {:code => 301, :text => "301 Moved Permanently"}
      create_page_part "permanent", :content => REDIRECTS_YAML_HASH, :page_id => pages(:file_not_found).id
    end
    it_should_behave_like "redirects"
  end
  
  describe "concurrent lists" do
    before do
      @page = pages(:file_not_found)
      create_page_part "temporary", :content => "foo: bar", :page_id => @page.id
      create_page_part "permanent", :content => "fi: fo", :page_id => @page.id
      create_page_part "gone", :content => "baz", :page_id => @page.id
    end
    describe "for permanent" do
      it 'should be 301 Moved Permanently' do
        render_header(@page, "fi")["Status"].should == "301 Moved Permanently"
      end
    end
    describe "for temporary" do
      it 'should be 302 Found' do
        render_header(@page, "foo")["Status"].should == "302 Found"
      end
    end
    describe "for gone" do
      it 'should be 410 Gone' do
        render_header(@page, "baz")["Status"].should == "410 Gone"
      end
    end
  end

  describe "gone list" do
    before do
      @page = pages(:file_not_found)
      create_page_part "gone", :content => "/removed-page\nother-removed-page/", :page_id => @page.id
    end

    %w[removed-page other-removed-page].each do |slug|
      ["", "/"].each do |trail|
        it "should render header with status 410 when part exists, ignoring trailing slashes" do 
          render_header(@page, "/#{slug}#{trail}")["Status"].should == "410 Gone"
        end
        it "should not have a location in the header" do
          render_header(@page, "/#{slug}#{trail}").should_not include("Location")
        end
      end
    end
  end

  describe "trailing slashes" do
    before do
      @page = pages(:file_not_found)
      %w[permanent temporary].each do |part|
        create_page_part part, :content => "/this: /that\n/thing/: /other", :page_id => @page.id
      end
    end
    it "should ignore trailing slashes in keys when redirecting" do
      render_header(@page, "/this/")["Status"].should match(/30\d/)
      render_header(@page, "/thing")["Status"].should match(/30\d/)
    end
  end

  describe "validations" do

    it "should be invaid if the same url to redirect is first added in temporary page part and then to permanent page part" do                
      page = pages(:file_not_found)
      create_page_part "temporary", :content => REDIRECTS_YAML_HASH, :page_id => page.id
      create_page_part "permanent", :content => REDIRECTS_YAML_HASH, :page_id => page.id
      page.should_not be_valid    
    end       

    it "should be invaid if the same url to redirect is first added in permanent page part and then to temporary page part" do                
      page = pages(:file_not_found)
      create_page_part "permanent", :content => REDIRECTS_YAML_HASH, :page_id => page.id
      create_page_part "temporary", :content => REDIRECTS_YAML_HASH, :page_id => page.id
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

    describe "duplicated normalized urls" do
      before(:each) do
        @page = pages(:file_not_found)
      end

      it "should be valid if there are different url's in temporary and permanent page parts" do
        create_page_part "temporary", :content => REDIRECTS_YAML_HASH, :page_id => @page.id
        create_page_part "permanent", :content => REDIRECTS_YAML_HASH_DIFFERENT, :page_id => @page.id
        @page.should be_valid
      end

      fixture = [
        ["a-location: 1", "/a-location: 2"],
        ["a-location: 1", "a-location/: 2"],
      ]
      fixture.each do |fix|
        it "should not be valid if there are duplicated normalized urls in temporary and permanent page parts" do
          create_page_part "temporary", :content => fix.first, :page_id => @page.id
          create_page_part "permanent", :content => fix.last,  :page_id => @page.id
          @page.should_not be_valid                                                 
          @page.errors.on("base").should match(/You've defined what you want me to do .* more than once/)
        end
      end

      fixture = [ "a-location\na-location/", "/a-location/\na-location/" ]
      fixture.each do |fix|
        it "should not be valid if there are duplicated normalized urls in gone page part" do
          create_page_part "gone", :content => fix,  :page_id => @page.id
          @page.should_not be_valid                                                 
          @page.errors.on("base").should match(/You've included two versions of \/a-location/)
        end
      end
    end

    it "should be invalid if the YAML specified in temporary page part content is invalid" do
      page = pages(:file_not_found)
      page.stub!(:parts).and_return([mock('temporary part', :null_object => true,
                                          :name => "temporary", :content => invalid_yaml)])
      page.should_not be_valid
      page.errors.on("base").should match(/doesn't appear to be formatted correctly/)
    end

    it "should be invalid if the YAML specified in permanent page part content is invalid" do
      page = pages(:file_not_found)
      page.stub!(:parts).and_return([mock('permanent part', :null_object => true,
                                          :name => "permanent", :content => invalid_yaml)])
      page.should_not be_valid
      page.errors.on("base").should match(/doesn't appear to be formatted correctly/)
    end
    it "should be invalid if the YAML specified in permanent page part content is valid YAML, but not a properly formed hash" do
      page = pages(:file_not_found)
      page.stub!(:parts).and_return([mock('permanent part', :null_object => true,
                                          :name => "permanent", :content => "a: 1\ndave")])
      page.should_not be_valid
      page.errors.on("base").should match(/doesn't appear to be formatted correctly/)
    end
    it "should be valid if the YAML is valid and contains empty lines" do
      page = pages(:file_not_found)
      create_page_part "temporary", :content => "/a: /b\n\n/c: /d", :page_id => page.id
      page.should be_valid
    end

    describe "details" do
      it "should handle YAML type inferences in keys" do
        page = pages(:file_not_found)
        create_page_part "permanent", :content => "4: string", :page_id => page.id
        lambda { page.render }.should_not raise_error
      end
      it "should handle YAML type inferences in values" do
        page = pages(:file_not_found)
        create_page_part "permanent", :content => "string: 4", :page_id => page.id
        lambda { page.render }.should_not raise_error
      end
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

  def invalid_yaml
    ":\n : :\n ::not valid YAML:: "
  end
end
