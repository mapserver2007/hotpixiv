#!/usr/bin/ruby
require 'test/unit/testsuite'
require 'crawler_test'
require 'util_test'

class AllTests
  def self.suite
    suite = Test::Unit::TestSuite.new( "all tests." )
    suite << CrawlerTest.suite
    suite << UtilTest.suite
    return suite
  end
end
