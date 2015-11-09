#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) 2009-2015 Chef Software, Inc.
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

class Chef
  class Knife
    class TerremarkServerDelete < Knife

      banner "knife terremark server delete SERVER (options)"

      def h
        @highline ||= HighLine.new
      end
      
      def msg_pair(label, value, color=:cyan)
        if value && !value.to_s.empty?
          puts "#{ui.color(label, color)}: #{value}"
        end
      end

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

      def run 
        $stdout.sync = true

	unless Chef::Config[:knife][:terremark_username] && Chef::Config[:knife][:terremark_password]
	  ui.error("Missing Credentials")
	  exit 1
	end

        terremark = Fog::Terremark::Vcloud.new(
          :terremark_vcloud_username => Chef::Config[:knife][:terremark_username],
          :terremark_vcloud_password => Chef::Config[:knife][:terremark_password]
        )


        @name_args.each do |vapp_id|
          server = terremark.servers.get(vapp_id)
          msg_pair("vApp ID", server.id)
          msg_pair("vApp Name", server.name)
          msg_pair("Public IP Address", server.PublicIpAddress)
          msg_pair("Private IP Address", server.IpAddress)

          puts "\n"
          confirm("Do you really want to delete this server")

          if server.PublicIpAddress
              server.delete_internet_services
              ui.warn("Released IP address #{server.PublicIpAddress}")  
          end
          server.destroy
          ui.warn("Deleted server #{server.id}")
        end
      end
    end
  end
end

