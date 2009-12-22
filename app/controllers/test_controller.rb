class TestController < ApplicationController
  
  require 'test/coverage'
  
  layout "admin"
  
  before_filter :admin_required
  
  def coverage
    @path = params[:path].to_s
    @files = []
    @directories = []
    @coverage = nil
    
    if File.file?("#{@path}")
      @coverage = Test::Unit::Coverage["#{@path}"]
    else
      Dir.glob("#{Test::Unit::Coverage.coverage_dir}/#{@path}/*") do |filename|
        name = File.basename(filename)
        if File.directory?(filename)
          @directories << name
        elsif File.file?(filename) and name[-3..-1] == "cov"
          @files << name[0..-4]
        end
      end
    end
  end

end
