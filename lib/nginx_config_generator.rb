#! /usr/bin/env ruby
%w(erb yaml).each &method(:require)

def error(message) puts(message) || exit end
def file(file) "#{File.dirname(__FILE__)}/#{file}" end
def read_from_env env; env.to_s.strip.size.zero? ? nil : env; end

if ARGV.include? '--example'
  example = file :'config.yml.example'
  error open(example).read 
end

env_in  = read_from_env ENV['NGINX_CONFIG_YAML']
env_out = read_from_env ENV['NGINX_CONFIG_FILE']

error "Usage: generate_nginx_config [config file] [out file]" if ARGV.empty? && !env_in

overwrite = %w(-y -o -f --force --overwrite).any? { |f| ARGV.delete(f) }

config   = YAML.load(ERB.new(File.read(env_in || ARGV.shift || 'config.yml')).result)
template = if custom_template_index = (ARGV.index('--template') || ARGV.index('-t'))
  custom = ARGV[custom_template_index+1]
  error "=> Specified template file #{custom} does not exist." unless File.exist?(custom)
  ARGV.delete_at(custom_template_index) # delete the --argument
  ARGV.delete_at(custom_template_index) # and its value
  custom
else
  file :'nginx.erb'
end

if File.exists?(out_file = env_out || ARGV.shift || File.join(config['config_path'], 'nginx.conf')) && !overwrite
  error "=> #{out_file} already exists, won't overwrite it.  Quitting."
else
  open(out_file, 'w+').write(ERB.new(File.read(template), nil, '>').result(binding))
  error "=> Wrote #{out_file} successfully."
end
