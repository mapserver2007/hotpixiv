# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{hotpixiv}
  s.version = "0.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["mapserver2007"]
  s.date = %q{2010-07-22}
  s.default_executable = %q{hotpixiv}
  s.description = %q{hotpixiv. Auto collection tool in pixiv.}
  s.email = %q{mapserver2007@gmail.com}
  s.executables = ["hotpixiv"]
  s.extra_rdoc_files = ["README.rdoc", "ChangeLog"]
  s.files = ["README.rdoc", "ChangeLog", "Rakefile", "bin/hotpixiv", "test/all_tests.rb", "test/crawler_test.rb", "test/util_test.rb", "lib/hotpixiv.rb"]
  s.homepage = %q{http://github.com/mapserver2007/hotpixiv}
  s.rdoc_options = ["--title", "hotpixiv documentation", "--charset", "utf-8", "--opname", "index.html", "--line-numbers", "--main", "README.rdoc", "--inline-source", "--exclude", "^(examples|extras)/"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{0.0.3}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{hotpixiv. Auto collection tool in pixiv.}
  s.test_files = ["test/crawler_test.rb", "test/util_test.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
