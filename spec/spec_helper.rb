require 'bundler/setup'

module Rails
  def env
    'test'
  end

  def root
    Dir.pwd
  end

  def logger
    @logger ||= Class.new do
      def info(*args); end
    end.new
  end

  module_function :env, :root, :logger
end

RSpec.configure do |config|
end
