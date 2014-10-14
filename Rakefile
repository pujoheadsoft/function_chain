require "bundler/gem_tasks"

task default: :spec

task quality: [:flog, :flay]

Dir.glob("tasks/*.rake").each { |each| import each }
