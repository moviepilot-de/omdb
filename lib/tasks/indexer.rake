# Copyright (c) 2007 Benjamin Krause, Jens Kraemer
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Rake Task to rebuild the whole ferret index. This may take a very long time.
# If you're just checked out a fresh copy of omdb, you need to run 
#
# bash$ rake omdb:test:reindex
#
# at least once to build the test ferret infrastructure.

namespace :omdb do
  desc "re-index all indexable classes - use carefully"
  task :reindex => :environment do
    Indexer.reindex
  end

  namespace :test do
    desc "rebuild test index"
    task :reindex do
      Rake::Task["testing"].invoke              # switch to testing
      Rake::Task["db:fixtures:load"].invoke     # load fixtures
      Rake::Task["omdb:reindex"].invoke         # reindex
      FileUtils.touch Indexer.index_status_file # and recreate the ferret status file
                                                # (local_search.rb needs that file)
    end
  end
end