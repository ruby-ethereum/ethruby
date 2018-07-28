begin
  require "bundler/gem_tasks"
rescue LoadError
  puts "bundler not installed, use 'gem install bundler' to install"
end

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
  task :default => :spec
rescue LoadError
  nil
end

SUB_COMPONENTS = %w{ciri-utils ciri-rlp ciri-crypto}

desc 'run tests'
task :test do
  exit(1) unless check_env
  exit $?.exitstatus unless system("rspec -t ~slow_tests")
  SUB_COMPONENTS.each do |dir|
    puts `cd #{dir} && rake`
  end
end

desc 'run all tests, include extreme slow tests'
task :"test:all" do
  exit(1) unless check_env
  exit $?.exitstatus unless system("rspec")
  SUB_COMPONENTS.each do |dir|
    puts `cd #{dir} && rake`
  end
end

namespace :docker do
  base_image = 'ciriethereum/base'

  desc 'pull docker image'
  task :pull do
    system("docker pull #{base_image}:latest")
    exit $?.exitstatus
  end

  desc 'build docker image, rerun this task after updated Gemfile or Dockerfile'
  task :build do
    system("git submodule init && git submodule update")
    system("docker build . -f docker/Dockerfile -t #{base_image}:latest")
    exit $?.exitstatus
  end

  desc 'open Ciri develop container shell'
  task :shell do
    container_name = 'ciri-develop'
    if system("docker inspect #{container_name} > /dev/null")
      system("docker start -i #{container_name}")
    else
      puts "start a new develop container: #{container_name}"
      system("docker run -v `pwd`:/app -it --name #{container_name} #{base_image}:latest bash")
    end
  end

  desc 'run tests in docker'
  task :test do
    system("docker run -v `pwd`:/app --rm #{base_image}:latest rake test")
    exit $?.exitstatus
  end

  desc 'run all tests(include slow tests) in docker'
  task :"test:all" do
    system("docker run -v `pwd`:/app --rm #{base_image}:latest rake test:all")
    exit $?.exitstatus
  end

  def default_stack_size
    52428800
  end

  def check_env
    pass = false
    if ENV['RUBY_THREAD_VM_STACK_SIZE'].to_i < default_stack_size
      warn "Ruby stack size is not enough: set env 'RUBY_THREAD_VM_STACK_SIZE' to #{default_stack_size} and try again"
      warn "export RUBY_THREAD_VM_STACK_SIZE=#{default_stack_size}"
    else
      pass = true
    end
    pass
  end

  def default_env
    {'RUBY_THREAD_VM_STACK_SIZE' => ENV['RUBY_THREAD_VM_STACK_SIZE'] || default_stack_size.to_s}
  end
end
