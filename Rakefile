desc "Run tests."
task :test do
  puts %x(ruby ./test/tests.rb)
end

desc "Build gem."
task :build do
  puts %x(gem build srsgem.gemspec)
end

desc "Install gem with specified version number."
task :install, [:vsn] do |t, args|
  version = args[:vsn]
  puts %x(gem install SRSGem-#{version}.gem)
end