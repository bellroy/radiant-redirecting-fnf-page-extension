require File.dirname(__FILE__) + '/../spec_helper'

describe 'GoneTags' do
  dataset :home_page
  before do
    create_page("File not found", :class_name => "RedirectingFnfPage")
    @page = pages(:file_not_found)
  end
  describe 'unless gone' do
    it 'should not yield content if gone?' do
      @page.stub!(:gone?).and_return true
      @page.should render('Be<r:unless_gone>gone</r:unless_gone>!').as('Be!')
    end
    it 'should yield content if not gone?' do
      @page.stub!(:gone?).and_return false
      @page.should render('Be<r:unless_gone>gone</r:unless_gone>!').as('Begone!')
    end
  end
  describe 'if gone' do
    it 'should yield content if gone?' do
      @page.stub!(:gone?).and_return true
      @page.should render('Be<r:if_gone>gone</r:if_gone>!').as('Begone!')
    end
    it 'should not yield content if not gone?' do
      @page.stub!(:gone?).and_return false
      @page.should render('Be<r:if_gone>gone</r:if_gone>!').as('Be!')
    end
  end
end
