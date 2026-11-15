files = ENV["FILE_LIST"] ? File.read(ENV["FILE_LIST"]).split : (Dir["test/cases/**/*_test.rb"].reject { |x| x.include?("/adapters/") || x.include?("/encryption/performance") } + Dir["test/cases/adapters/sqlite3/**/*_test.rb"]).sort
files |= ["test/cases/unconnected_test.rb"]
files.each { |f| require File.expand_path(f) }
