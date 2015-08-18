module DRG
  module Tasks
    class Gemfile
      attr_accessor :file

      def initialize(file = ::Bundler.default_gemfile)
        @file = file
      end

      # Saves a copy of @lines before changing it (note that #dup and #clone weren't working)
      #
      # @param [GemfileLine] gem
      # @param [String] version to update the gem line with
      def update(gem, version)
        lines[gem] = gem.update version
        write
      end

      def find_by_name(name)
        lines.each_with_index.each do |line, index|
          next if line =~ /:?path:?\s*(=>)?\s*/
          next if line =~ /:?git(hub)?:?\s*(=>)?\s*/
          return GemfileLine.new line, index, name if line =~ /gem\s*['"]#{name}["']/
        end
        nil
      end

      def write
        File.open file, 'wb' do |f|
          lines.each do |line|
            f << line
          end
        end
      end

      def lines
        @lines ||= File.readlines file
      end
    end
  end
end