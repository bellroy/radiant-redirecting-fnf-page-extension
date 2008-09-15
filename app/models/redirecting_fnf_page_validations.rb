module RedirectingFnfPageValidations
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def validates_parts_as_yaml_hash(*parts_to_validate)
      configuration = parts_to_validate.extract_options!

      validates_each(:parts, configuration) do |record, attr, page_parts|
        page_parts.select {|pp| parts_to_validate.include?(pp.name.to_sym) }.each do |page_part|
          error_message = <<-ERR
The #{page_part.name} page part doesn't appear to be formatted correctly. I can't offer much in the way of guidance, but the part should look something like:
<pre>
  old-page: /new-page
  old-directory/old-page: /new-directory/new-page
</pre>
          ERR
          begin
            hash_from_yaml = YAML.load(page_part.content)
            unless hash_from_yaml.is_a?(Hash)
              record.errors.add_to_base(error_message)
              page_part.errors.add :content, error_message
            end
          rescue ArgumentError => e
            if e.message.match(/syntax/)
              record.errors.add_to_base(error_message)
              page_part.errors.add :content, error_message
            end
          end
        end
      end
    end
    def validates_parts_do_not_contain_duplicates(*parts_to_validate)
      configuration = parts_to_validate.extract_options!

      validates_each(:parts, configuration) do |record, attr, page_parts|
        hash = {}
        page_parts.select {|pp| parts_to_validate.include?(pp.name.to_sym) }.each do |page_part|
          page_part_arr =  normalized_array_from_page_part(page_part.content)
          page_part_arr.each do |key, val| 
            unless hash.has_key?(key)
              hash[key] = page_part.name
            else
              if hash[key] = page_part.name
                record.errors.add_to_base("You've defined what you want me to do with #{key} more than once in page part '#{page_part.name}'." ) 
              else
                record.errors.add_to_base("You've defined what you want me to do with #{key} in page part '#{page_part.name}' and in '#{hash[key]}'." ) 
              end
            end
          end
        end
      end
    end

    # its better to use a YAML library functionality to convert the YAML str to 2-D array below
    def normalized_array_from_page_part(str)
      main_arr = []
      str = str.gsub(/\r/, '')
      str_arr = str.split(/\n/)
      str_arr.each do |s|
         node = s.split(': ')
         sim_arr = [node[0].sub(%r[^/?],'/'), node[1].strip]     
         main_arr << sim_arr
      end
      return main_arr
    end
  end

end


__END__

  def validate
    hash = {}
    self.parts.each do |page_part|
      if page_part.name == 'temporary' or page_part.name == 'permanent'
        page_part_arr =  normalized_array_from_page_part(page_part.content)
        page_part_arr.each do |p| 
          unless hash.has_key?(p[0])
            hash[p[0]] = page_part.name
          else
            errors.add_to_base("Cannot save since there is duplication of rediecting urls" ) 
          end
        end
      end
    end
  end
  
  private

  # its better to use a YAML library functionality to convert the YAML str to 2-D array below
  def normalized_array_from_page_part(str)
    main_arr = []
    str = str.gsub(/\r/, '')
    str_arr = str.split(/\n/)
    str_arr.each do |s|
       node = s.split(': ')
       sim_arr = [node[0], node[1].strip]     
       main_arr << sim_arr
    end
    return main_arr
  end
