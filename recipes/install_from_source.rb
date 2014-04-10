#
# Author:: Marius Ducea (marius@promethost.com)
# Cookbook Name:: nodejs
# Recipe:: source
#
# Copyright 2010-2012, Promet Solutions
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "paths"

include_recipe "build-essential"

case node['platform_family']
  when 'rhel','fedora'
    package "openssl-devel"
  when 'debian'
    package "libssl-dev"
  when 'smartos'
    package 'pkg-config'
end

nodejs_tar = "node-v#{node['nodejs']['version']}.tar.gz"
nodejs_tar_path = nodejs_tar
if node['nodejs']['version'].split('.')[1].to_i >= 5
  nodejs_tar_path = "v#{node['nodejs']['version']}/#{nodejs_tar_path}"
end
# Let the user override the source url in the attributes
nodejs_src_url = "#{node['nodejs']['src_url']}/#{nodejs_tar_path}"

case node['platform_family']
  when 'smartos'
    build_dir = Chef::Config[:file_cache_path]
  else
    build_dir = "/usr/local/src"
end

remote_file "#{build_dir}/#{nodejs_tar}" do
  source nodejs_src_url
  checksum node['nodejs']['checksum']
  mode 0644
  action :create_if_missing
end

# --no-same-owner required overcome "Cannot change ownership" bug
# on NFS-mounted filesystem
execute "tar --no-same-owner -zxf #{nodejs_tar}" do
  cwd build_dir
  creates "#{build_dir}/node-v#{node['nodejs']['version']}"
end

make_jobs = [node['nodejs']['make_threads'], 2].max
configure_options = node['nodejs']['configure_options'].join(' ')
nodejs_helper = NodeJS::Helper.new(node)


bash "compile node.js (on #{make_jobs} cpu)" do
  # OSX doesn't have the attribute so arbitrarily default 2
  cwd "#{build_dir}/node-v#{node['nodejs']['version']}"
  code <<-EOH
    PATH="/usr/local/bin:$PATH"
    ./configure --prefix=#{node['nodejs']['dir']} #{configure_options} && \
    make -j #{make_jobs}
  EOH
  environment nodejs_helper.build_environment
  creates "#{build_dir}/node-v#{node['nodejs']['version']}/node"
end

execute "nodejs make install" do
  environment({"PATH" => node['paths']['bin_path']})
  command "make install"
  cwd "#{build_dir}/node-v#{node['nodejs']['version']}"
  environment nodejs_helper.build_environment
  not_if {::File.exists?("#{node['nodejs']['dir']}/bin/node") && `#{node['nodejs']['dir']}/bin/node --version`.chomp == "v#{node['nodejs']['version']}" }
end
