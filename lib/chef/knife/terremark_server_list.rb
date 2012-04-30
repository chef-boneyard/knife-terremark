#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require 'fog'
require 'highline'
require 'chef/knife'
require 'chef/json_compat'
require 'tempfile'

class Chef
  class Knife
    class TerremarkServerList < Knife

      banner "knife terremark server list (options)"

      option :terremark_password,
        :short => "-K PASSWORD",
        :long => "--terremark-password PASSWORD",
        :description => "Your terremark password",
        :proc => Proc.new { |key| Chef::Config[:knife][:terremark_password] = key } 

      option :terremark_username,
        :short => "-A USERNAME",
        :long => "--terremark-username USERNAME",
        :description => "Your terremark username",
        :proc => Proc.new { |username| Chef::Config[:knife][:terremark_username] = username } 

      def h
        @highline ||= HighLine.new
      end

      def run 
        server_name = @name_args[0]

        terremark = Fog::Terremark::Vcloud.new(
          :terremark_vcloud_username => Chef::Config[:knife][:terremark_username],
          :terremark_vcloud_password => Chef::Config[:knife][:terremark_password]
        )

        $stdout.sync = true

        server_list = [
            h.color('ID', :bold), 
            h.color('Name', :bold),
            h.color('PublicIP', :bold),
            h.color('PrivateIP', :bold),
            h.color('OperatingSystem', :bold)
        
        ]
        terremark.servers.all.each do |server|
          server_list << server.id.to_s
          server_list << server.name.to_s
          server_list << server.PublicIpAddress.to_s if server.PublicIpAddress
          server_list << server.IpAddress.to_s
          server_list << server.OperatingSystem["Description"].to_s

        end
        puts h.list(server_list, :columns_across, 8)

      end
    end
  end
end


