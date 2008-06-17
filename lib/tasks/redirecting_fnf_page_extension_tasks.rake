namespace :radiant do
  namespace :extensions do
    namespace :redirecting_fnf_page do
      
      desc "Runs the migration of the File Not Found Ext extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          RedirectingFnfPageExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          RedirectingFnfPageExtension.migrator.migrate
        end
      end
      
      desc "Copies public assets of the File Not Found Ext to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        Dir[RedirectingFnfPageExtension.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(RedirectingFnfPageExtension.root, '')
          directory = File.dirname(path)
          puts "Copying #{path}..."
          mkdir_p RAILS_ROOT + directory
          cp file, RAILS_ROOT + path
        end
      end

      desc "Update page table references to RedirectingFnfPage from FileNotFoundExtPage class types"
      task :rename_classes => :environment do
        ActiveRecord::Base.connection.execute(<<-SQL)
        update pages set class_name = 'RedirectingFnfPage' where class_name = 'FileNotFoundExtPage'
        SQL
      end
    end
  end
end
