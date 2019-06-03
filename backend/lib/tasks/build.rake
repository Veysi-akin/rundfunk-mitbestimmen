namespace :build do
  if Gem.loaded_specs.key?('rubocop')
    require 'rubocop/rake_task'

    desc 'Run RuboCop'
    RuboCop::RakeTask.new(:rubocop) do |task|
      # Make it easier to disable cops.
      task.options << '--display-cop-names'
    end
  end

  if Gem.loaded_specs.key?('rspec')
    require 'rspec/core/rake_task'
    desc 'Run test'
    RSpec::Core::RakeTask.new(:rspec) do |task|
      task.rspec_opts = '--format progress'
    end
  end

  desc 'Runs Brakeman'
  # based on https://brakemanscanner.org/docs/rake/
  task :brakeman, :output_files do |_task, args|
    # To abort on failures, set to true.
    EXIT_ON_FAIL = true

    require 'brakeman'

    files = args[:output_files].split(' ') if args[:output_files]

    # For more options, see source here:
    # https://github.com/presidentbeef/brakeman/blob/master/lib/brakeman.rb#L30
    options = {
      app_path: '.',
      exit_on_error: EXIT_ON_FAIL,
      exit_on_warn: EXIT_ON_FAIL,
      output_files: files,
      print_report: true,
      pager: false,
      summary_only: true
    }

    tracker = Brakeman.run options
    failures = tracker.filtered_warnings + tracker.errors

    # Based on code here:
    # https://github.com/presidentbeef/brakeman/blob/f2376c/lib/brakeman/commandline.rb#L120
    if EXIT_ON_FAIL && failures.any?
      puts 'Brakeman violations found. Aborting now...'
      exit Brakeman::Warnings_Found_Exit_Code unless tracker.filtered_warnings.empty?
      exit Brakeman::Errors_Found_Exit_Code if tracker.errors.any?
    end
  end
end
