module GoneTags
  include Radiant::Taggable
  
  desc 'Evaluate the content inside the double tag if the page status is GONE'
  tag 'if_gone' do |tag|
    tag.expand if gone?
  end
  desc 'Evaluate the content inside the double tag unless the page status is GONE'
  tag 'unless_gone' do |tag|
    tag.expand unless gone?
  end
end
