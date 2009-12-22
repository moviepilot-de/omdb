require "test/unit"

module Test
  module Unit
    
    class AutoRunner
    
      alias :old_run :run
      
      def run
        result = self.old_run
        Test::Unit::Coverage.save
        result
      end
    end
    
    class Tracing  
   
      def self.pattern
        @@pattern ||= nil
      end
      
      def self.pattern=(pattern)
        if pattern
          pattern = Regexp.new(pattern.to_s) unless pattern.kind_of?(Regexp)
          @@pattern = pattern
        end
      end
      
      def self.on
        set_trace_func self.trace_func
      end

      def self.off
        set_trace_func nil
      end
      
      private
    
      def self.trace_func
        if self.pattern
          @@trace_func ||= proc do |event, file, line, id, binding, classname|
            if event[1] != 45 && file =~ self.pattern
              #puts "#{file}:#{line}"
              Test::Unit::Coverage[file].increment(line)
            end
          end
        end
      end
    
    end

    class Coverage

      require "yaml"
      require "digest/sha1"

      Line = Struct.new("Line", :source, :calls)

      private
      def initialize(source)
        @digest = nil
        self.source = source
      end
      
      public
      
      def self.open(filename)
        filename = File.expand_path(filename, self.base_dir)
        coverage_filename = self.coverage_filename(filename)
        if File.exists?(coverage_filename)
          coverage = YAML.load(File.open(coverage_filename))
          coverage.source = filename if coverage
          coverage
        end
      end
      
      def coverage_filename
        self.class.coverage_filename(@source)
      end
      
      def self.coverage_filename(filename)
        "#{self.coverage_dir}/#{self.from_base_dir(filename)}cov"
      end
      
      def source=(source)
        @source = File.expand_path(source, self.class.base_dir)
        contents = File.read(@source)
        digest = self.class.digest(contents)          
        if self.digest != digest
          @digest = digest
          @lines = contents.split($/).collect! { |line| Line.new(line, 0) }
        end
      end
      
      attr_reader :source, :filename, :lines, :digest

      def increment(line)
        line = self.lines[line-1]
        line.calls += 1 if line
      end

      def save
        filename = self.coverage_filename
        self.class.mkdir(File.dirname(filename))
        open(filename, "w") do |file|
          file << YAML.dump(self)
        end
      end

      def self.base_dir
        @@base_dir ||= Dir.getwd
      end

      def self.base_dir=(dir)
        @@base_dir = dir
      end

      def self.from_base_dir(dir)
        dir[(self.base_dir.size+1)..-1]
      end

      def self.coverage_dir
        @@coverage_dir ||= "#{self.base_dir}/test/coverage"
      end

      def self.coverage_dir=(dir)
        @@coverage_dir = File.expand_path(dir, self.base_dir)
      end
      
      def self.[](source)
        coverage = self.coverages[source]
        if coverage.nil?
          coverage = self.coverages[source] = (self.open(source) or self.new(source))
        end
        #raise "CVFN #{coverage.inspect}"
        coverage
      end

      def self.coverages
        @@coverages ||= {}
      end

      def self.save
        self.coverages.each_value { |coverage| coverage.save }
      end

      def to_s
        self.lines.each_with_index do |line, i|
          printf("%6d%s| %s\n", i+1, (line.calls > 0 ? '*' : ' '), line.source)
        end
      end
      
      # Helper method that creates the specified directory path.
      # Intermediate directories are created as needed, similar to the 'mkdir -p' command.
      def self.mkdir(path)
        unless path.empty? || File.exists?(path)
          mkdir(File.dirname(path))
          Dir.mkdir(path)
        end
      end
      
      def self.digest(string)
        Digest::SHA1.hexdigest(string)
      end

    end

    class TestCase
      
      alias :old_run :run
      
      def run(result, &block)
        Test::Unit::Tracing.on
        old_run(result, &block)
        Test::Unit::Tracing.off
      end
      
    end

  end
end

