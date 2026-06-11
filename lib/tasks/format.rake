require 'shellwords'

namespace :format do
  desc "Format ERB files under app/views with htmlbeautifier (continues on errors)"
  task :erb do
    files = Dir.glob('app/views/**/*.html.erb')
    puts "Found #{files.size} ERB files"
    failures = []
    files.each do |file|
      puts "Formatting: #{file}"
      cmd = "bundle exec htmlbeautifier #{Shellwords.escape(file)}"
      success = system(cmd)
      unless success
        failures << file
        warn "Failed to format #{file}"
      end
    end

    if failures.any?
      puts "\n#{failures.size} files failed to format (see warnings above)."
      puts failures.join("\n")
    else
      puts "All files formatted."
    end
  end
end
