#
# Copyright (C) 2005-2015 Alfresco Software Limited.
#
# This file is part of Alfresco
#
# Alfresco is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Alfresco is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with Alfresco. If not, see <http://www.gnu.org/licenses/>.
#

case node['platform_family']
when 'windows'

  windows_zipfile node['loadbalancer']['unzipFolder'] do
    source node['loadbalancer']['url']
    action :unzip
    not_if { ::File.directory?(node['loadbalancer']['unzipFolder']) }
  end

  directory node['loadbalancer']['unzipFolder'] do
    rights :read, 'Administrator'
    rights :write, 'Administrator'
    rights :full_control, 'Administrator'
    rights :full_control, 'Administrator', applies_to_children: true
    group 'Administrators'
  end

  template "#{node['loadbalancer']['rootFolder']}/conf/httpd.conf" do
    source 'loadBalancer/httpd-win.erb'
    rights :read, 'Administrator'
    rights :write, 'Administrator'
    rights :full_control, 'Administrator'
    rights :full_control, 'Administrator', applies_to_children: true
    group 'Administrators'
    :top_level
  end

  batch 'Install httpd service' do
    code <<-EOH
#{node['loadbalancer']['rootFolder']}/bin/httpd.exe -k uninstall
#{node['loadbalancer']['rootFolder']}/bin/httpd.exe -k install
      EOH
    action :run
  end

  service 'Apache2.4' do
    supports status: true, restart: true, stop: true
    action [:start, :enable]
  end

else

  directory '/resources' do
    owner 'root'
    group 'root'
    mode '0775'
    action :create
  end

  package 'Install Apache' do
    case node['platform_family']
    when 'rhel'
      package_name 'httpd'
    when 'debian'
      package_name 'apache2'
    end
  end

  execute 'backup configuration' do
    case node['platform_family']
    when 'rhel'
      command 'cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.original'
    when 'debian'
      command 'cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.original'
    end
    action :run
  end

  link '/etc/apache2/modules' do
    to '/usr/lib/apache2/modules'
    only_if { node['platform_family'] == 'debian' }
  end

  execute 'backup configuration' do
    case node['platform_family']
    when 'rhel'
      command 'cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.original'
    when 'debian'
      command 'cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.original'
    end
    action :run
  end

  template 'configuration file' do
    if node['platform_version'] == '7.1'
      source 'loadBalancer/httpd24.conf.erb'
    else
      source 'loadBalancer/httpd.conf.erb'
    end
    case node['platform_family']
    when 'rhel'
      path '/etc/httpd/conf/httpd.conf'
    when 'debian'
      path '/etc/apache2/apache2.conf'
    end
    owner 'root'
    group 'root'
    mode '0755'
  end

  service 'loadbalancer' do
    case node['platform_family']
    when 'rhel'
      service_name 'httpd'
    when 'debian'
      service_name 'apache2'
    end
    supports status: true, restart: true, stop: true
    action [:start, :enable]
  end

end
