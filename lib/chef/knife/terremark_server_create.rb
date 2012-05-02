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
require 'net/ssh/multi'
require 'readline'
require 'net/scp'
require 'chef/knife'
require 'chef/json_compat'
require 'tempfile'

class Chef
  class Knife
    class TerremarkServerCreate < Knife

      deps do
        require 'fog'
        require 'readline'
        require 'chef/json_compat'
        require 'chef/knife/bootstrap'
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife terremark server create NAME [RUN LIST...] (options)"

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


      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []

      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template; default is 'ubuntu10.04-gems'",
        :proc => Proc.new { |d| Chef::Config[:knife][:distro] = d },
        :default => "ubuntu10.04-gems"

      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use",
        :proc => Proc.new { |t| Chef::Config[:knife][:template_file] = t },
        :default => false

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node",
        :proc => Proc.new { |t| Chef::Config[:knife][:chef_node_name] = t }

      option :tcp_ports,
        :short => "-T X,Y,Z",
        :long => "--tcp X,Y,Z",
        :description => "TCP ports to be made accessible for this server",
        :proc => Proc.new { |tcp| tcp.split(',') },
        :default => []

      option :udp_ports,
        :short => "-U X,Y,Z",
        :long => "--udp X,Y,Z",
        :description => "UDP ports to be made accessible for this server",
        :proc => Proc.new { |udp| udp.split(',') },
        :default => []

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username; default is 'vcloud'",
        :default => "vcloud"

      option :server_name,
        :short => "-N NAME",
        :long => "--server-name NAME",
        :description => "The server name",
        :proc => Proc.new { |server_name| Chef::Config[:knife][:server_name] = server_name } 

      option :image,
        :short => "-I IMAGE",
        :long => "--terremark-image IMAGE",
        :description => "Your terremark virtual app template/image name",
        :proc => Proc.new { |template| Chef::Config[:knife][:image] = template }

      option :ssh_key_name,
        :short => "-S KEY",
        :long => "--ssh-key KEY",
        :description => "Your terremark SSH Key id",
        :proc => Proc.new { |key_name| Chef::Config[:knife][:ssh_key_name] = key_name } 
        
      option :identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication",
        :proc => Proc.new { |identity| Chef::Config[:knife][:identity_file] = identity } 

      option :no_of_vcpus,
        :short => "-v VCPUS",
        :long => "--vcpus VCPUS",
        :description => "Defines the number of virtual CPUs. Possible values are 1,2,4 or 8.",
        :proc => Proc.new { |vcpus| Chef::Config[:knife][:no_of_vcpus] = vcpus },
        :default => "1"

      option :memory,
        :short => "-m MEMORY",
        :long => "--memory MEMORY",
        :description => "Defines the number of MB of memory. Possible values are 512,1024,1536,2048,4096,8192,12288 or 16384.",
        :proc => Proc.new { |memory| Chef::Config[:knife][:memory] = memory },
        :default => "512"

      option :disks,
        :short => "-D D1,D2,D3",
        :long => "--disks D1,D2,D3",
        :description => "Define Disks with sizes(GBs). eg. --disks 25,50 ... 500(max 15 disks)",
        :proc => Proc.new { |disks| disks.split(',') },
        :default => []


      def h
        @highline ||= HighLine.new
      end
      
      def locate_config_value(key)
        key = key.to_sym
        Chef::Config[:knife][key] || config[key]
      end

      def tcp_test_ssh(hostname, port)
        tcp_socket = TCPSocket.new(hostname, port)
        readable = IO.select([tcp_socket], nil, nil, 5)
        if readable
          Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}")
          yield
          true
        else
          false
        end
      rescue Errno::ETIMEDOUT
        false
      rescue Errno::EPERM
        false
      rescue Errno::ECONNREFUSED
        sleep 2
        false
      rescue Errno::EHOSTUNREACH
        sleep 2
        false
      ensure
        tcp_socket && tcp_socket.close
      end

      def run

        $stdout.sync = true
	unless Chef::Config[:knife][:server_name]
          ui.error("Server Name cannot be empty")
          exit 1
        end

	unless Chef::Config[:knife][:ssh_key_name]
          ui.error("SSH Key Name cannot be empty")
          exit 1
        end

	unless Chef::Config[:knife][:terremark_username] && Chef::Config[:knife][:terremark_password]
	  ui.error("Missing Credentials")
	  exit 1
	end
        server_name = Chef::Config[:knife][:server_name]
        vapp_template = Chef::Config[:knife][:image]
        key_name = Chef::Config[:knife][:ssh_key_name]
        terremark = Fog::Terremark::Vcloud.new(
          :terremark_vcloud_username => Chef::Config[:knife][:terremark_username],
          :terremark_vcloud_password => Chef::Config[:knife][:terremark_password]
        )
  
        keys = terremark.get_keys_list(terremark.default_organization_id).body["Keys"]
        ssh_key = keys.find{|item| item["Name"] == key_name}
        if not ssh_key
            raise ArgumentError.new("SSH Key Name #{key_name} does not exist")
        end
        puts "Instantiating vApp #{h.color(server_name, :bold)}"
    
        server_spec = {
            :name =>  Chef::Config[:knife][:server_name], 
            :image => Chef::Config[:knife][:image], 
            :sshkeyFingerPrint => ssh_key["FingerPrint"],
            :vcpus => Chef::Config[:knife][:no_of_vcpus],
            :memory => Chef::Config[:knife][:memory]
        }
        server = terremark.servers.create(server_spec)
        print "Instantiated vApp named [#{h.color(server.name, :bold)}] as [#{h.color(server.id.to_s, :bold)}]"
        print "\n#{ui.color("Waiting for server to be Instantiated", :magenta)}"
    
        # wait for it to be ready to do stuff
        server.wait_for { print "."; ready? }
        puts("\n")

        #Configure Additional Disks
        disks = config[:disks]
        if disks.size > 0
          hardware = server.VirtualHardware
          server_spec = { "vcpus" => hardware["cpu"], "memory" => hardware["ram"], "virtual_disks" => disks }
          terremark.configure_vapp(server.id, server.name, server_spec)
        print "\n#{ui.color("Waiting for additional disks to be configured", :magenta)}"
          server.wait_for { print "."; ready? }
          sleep(10) # Sleep additionally, to ensure Terremark APIs are in sync
        end

        #Power On the server
        server.power_on(server.id)
        print "\n#{ui.color("Waiting for server to be Powered On", :magenta)}"
        server.wait_for { print "."; on? }
        
        print "\n#{ui.color("Creating Internet and Node Services for SSH and other services", :magenta)}"
        tcp_ports = config[:tcp_ports] + [22] # Ensure we always open the SSH Port
        udp_ports = config[:udp_ports]

        services_spec = {"TCP" => tcp_ports.uniq, "UDP" => udp_ports.uniq}
        server.create_internet_services(services_spec)

        #Fetch Updated information
        server = terremark.servers.get(server.id)
    
        puts "#{ui.color("Public IP Address", :cyan)}: #{server.PublicIpAddress}"
        puts "#{ui.color("Private IP Address", :cyan)}: #{server.IpAddress}"
        print "\n#{ui.color("Waiting for sshd.", :magenta)}"
        puts("\n")
        print(".") until tcp_test_ssh(server.PublicIpAddress, "22") { sleep @initial_sleep_delay ||= 10; puts("done") }
        puts "\nBootstrapping #{h.color(server_name, :bold)}..."
        bootstrap_for_node(server).run
      end

      def bootstrap_for_node(server)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = [server.PublicIpAddress]
        bootstrap.config[:run_list] = config[:run_list]
        bootstrap.config[:ssh_user] = config[:ssh_user] || "root"
        bootstrap.config[:identity_file] = config[:identity_file]
        bootstrap.config[:chef_node_name] = locate_config_value(:chef_node_name) || server.id
        bootstrap.config[:distro] = locate_config_value(:distro)
        bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
        bootstrap.config[:use_sudo] = true unless config[:ssh_user] == 'root'
        bootstrap.config[:template_file] = locate_config_value(:template_file)
        bootstrap
      end
    end
  end
end
