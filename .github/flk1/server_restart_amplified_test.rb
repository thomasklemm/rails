# frozen_string_literal: true

require "isolation/abstract_unit"
require "console_helpers"
require "rails/command"

# The restart test with `rails restart` replaced by an immediate touch in this process, which shortens the time
# between Puma recording restart.txt's mtime and the touch. FIX=1 adds the pre-dated restart.txt from the fix.
module ApplicationTests
  class ServerRestartAmplifiedTest < ActiveSupport::TestCase
    include ConsoleHelpers

    def setup
      build_app
    end

    def teardown
      teardown_app
    end

    Integer(ENV.fetch("N", "20")).times do |i|
      test "restart #{i}" do
        File.open("#{app_path}/config/boot.rb", "w") do |f|
          f.puts "ENV['BUNDLE_GEMFILE'] = '#{Bundler.default_gemfile}'"
          f.puts 'require "bundler/setup"'
        end

        if ENV["FIX"] == "1"
          FileUtils.mkdir_p("#{app_path}/tmp")
          FileUtils.touch("#{app_path}/tmp/restart.txt", mtime: Time.now - 60)
        end

        primary, replica = PTY.open
        pid = nil
        Bundler.with_original_env do
          pid = Process.spawn("bin/rails server -b localhost -P tmp/dummy.pid", chdir: app_path, in: replica, out: replica, err: replica)
          assert_output("Use Ctrl-C to stop", primary, 100)
          FileUtils.touch("#{app_path}/tmp/restart.txt")
          assert_output("Restarting", primary, 10)
          assert_output("Listening", primary, 100)
        ensure
          if pid
            Process.kill("TERM", pid)
            Process.wait(pid)
          end
        end
      end
    end
  end
end
