namespace :radiant do
  namespace :extensions do
    namespace :file_not_found_ext do
      
      desc "Runs the migration of the File Not Found Ext extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          FileNotFoundExtExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          FileNotFoundExtExtension.migrator.migrate
        end
      end
      
      desc "Copies public assets of the File Not Found Ext to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        Dir[FileNotFoundExtExtension.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(FileNotFoundExtExtension.root, '')
          directory = File.dirname(path)
          puts "Copying #{path}..."
          mkdir_p RAILS_ROOT + directory
          cp file, RAILS_ROOT + path
        end
      end  
    end
  end
end
