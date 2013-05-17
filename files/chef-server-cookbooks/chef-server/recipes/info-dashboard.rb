#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# License:: Apache License, Version 2.0
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

infoboard_dir = node['chef_server']['info-dashboard']['dir']
infoboard_etc_dir = File.join(infoboard_dir, "etc")
infoboard_working_dir = File.join(infoboard_dir, "working")
infoboard_log_dir = node['chef_server']['info-dashboard']['log_directory']
[
  infoboard_dir,
  infoboard_etc_dir,
  infoboard_working_dir,
  infoboard_log_dir
].each do |dir_name|
  directory dir_name do
    owner node['chef_server']['user']['username1']
    mode '0700'
    recursive true
  end
end

should_notify = OmnibusHelper.should_notify?("info-dashboard")
config_ru = File.join(infoboard_etc_dir, "config.ru")

link config_ru do
  to "/opt/chef-server/embedded/service/info-dashboard/config.ru"
end

unicorn_listen = node['chef_server']['info-dashboard']['listen']
unicorn_listen << ":#{node['chef_server']['info-dashboard']['port']}"

unicorn_config File.join(infoboard_etc_dir, "unicorn.rb") do
  listen unicorn_listen => {
    :backlog => node['chef_server']['info-dashboard']['backlog'],
    :tcp_nodelay => node['chef_server']['info-dashboard']['tcp_nodelay']
  }
  worker_timeout node['chef_server']['info-dashboard']['worker_timeout']
  working_directory infoboard_working_dir
  worker_processes node['chef_server']['info-dashboard']['worker_processes']
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, 'service[info-dashboard]' if should_notify
end

execute "chown -R dntmon:root /opt/chef-server/embedded/service/info-dashboard" do
  retries 20
end

runit_service "info-dashboard" do
  down node['chef_server']['info-dashboard']['ha']
  options({
    :log_directory => infoboard_log_dir,
  }.merge(params))
end

#if node['chef_server']['bootstrap']['enable']
#  execute "/opt/chef-server/bin/chef-server-ctl start gdash" do
#    retries 20
#  end
#end
