module DRG
  module Tasks
    class Updater
      attr_reader :gemfile, :failures, :bundler

      def initialize
        @gemfile = Gemfile.new
        @failures = Set.new
        @bundler = Bundler::CLI.new [], debug: true, current_command: OpenStruct.new
        @versions = {}
      end

      # Updates the projects outdated gems listed in the Gemfile
      #
      # @todo Incrementally update the gem using +versions+
      # @todo Cleanup old gems when finished
      # @note `bundle outdated` returns lines that look like 'slop (newest 4.2.0, installed 3.6.0) in group "default"'
      def perform
        `bundle outdated`.scan(/\s\*\s(.+)\s/).flatten.each do |item|
          name = item[/([\-\w0-9]+)\s/, 1]
          gem = gemfile.find_by_name(name)
          next unless gem
          latest_version = item[/newest\s([\d.\w]+)/, 1]
          current_version = item[/installed\s([\d.\w]+)/, 1]
          log(%Q[Trying to update gem "#{gem.name}" from #{current_version} to #{latest_version}])
          try_update(gem, latest_version)
        end
        if $?.to_i.nonzero?
          fail Bundler::GemNotFound, "Failed to load the environment. Maybe do `bundle` and try again"
        end
      end

      # @param [GemfileLine] gem
      def try_update(gem, latest_version)
        gemfile.remove_version gem
        bundler.update(gem.name)
        if $0.to_i.zero?
          log(%Q[Succeeded in installing "#{gem.name}" (#{latest_version})])
          if system('rake')
            log(%Q[Tests passed! Updating Gemfile with ... "#{gem.name}" (#{latest_version})])
            gemfile.update(gem, latest_version)
          else
            failures << gem.name
          end
        else
          fail StandardError, %Q[Failed to update "#{gem.name}"]
        end
      rescue Bundler::GemNotFound, Bundler::InstallError
        log %Q[Failed to find "#{gem.name}" (#{latest_version})]
      rescue Bundler::VersionConflict
        # @todo retry it later
        failures << gem.name
        log %Q(Failed to find a compatible version of "#{gem.name}")
      end

      # @note not used
      # @param [String] name of the gem
      # @param [String] current_version of the gem
      def new_versions(name, current_version)
        versions(name).select { |version| version > current_version }
      end

      # @note not used
      # @param [String] name of the gem
      # @return [Array] a list of available versions (e.g. ['1.2.0', '1.1.0'])
      def versions(name)
        @versions[name] ||= `gem query -radn ^#{name}$`.scan(/([\d.]+),/).flatten
      end

      private

      def log(msg = nil)
        puts %Q(  * #{msg})
      end
    end
  end
end
