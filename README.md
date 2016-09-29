# DEPRECATED

The Terramark cloud has been deprecated so this knife plugin has also been deprecated

# Knife Terremark
[![Gem Version](https://badge.fury.io/rb/knife-terremark.svg)](https://rubygems.org/gems/knife-terremark) [![Build Status](https://travis-ci.org/chef/knife-terremark.svg?branch=master)](https://travis-ci.org/chef/knife-terremark) [![Dependency Status](https://gemnasium.com/chef/knife-terremark.svg)](https://gemnasium.com/chef/knife-terremark)

This is the official Chef Knife plugin for Terremark. This plugin gives knife the ability to create, bootstrap, and manage servers on the Terremark Cloud.

## Installation
If you're using [ChefDK](https://downloads.chef.io/chef-dk/), simply install the Gem:

```bash
$ chef gem install knife-terremark
```

If you're using bundler, simply add Knife Terremark to your `Gemfile`:

```ruby
gem 'knife-terremark'
```

If you are not using bundler, you can install the gem manually:

```bash
$ gem install knife-terremark
```

Depending on your system's configuration, you may need to run this command with root privileges.

## Configuration
In order to communicate with the Terremark Cloud API you will have to tell Knife about your Username and API Key. The easiest way to accomplish this is to create some entries in your <tt>knife.rb</tt> file:

```
knife[:terremark_username] = "Your Terremark Account Username"
knife[:terremark_password] = "Your Terremark Account Password"
```

If your knife.rb file will be checked into a SCM system (ie readable by others) you may want to read the values from environment variables:

```
knife[:terremark_username] = "#{ENV['TERREMARK_USERNAME']}"
knife[:terremark_password] = "#{ENV['TERREMARK_PASSWORD']}"
```

You also have the option of passing your Terremark Username/Password into the individual knife subcommands using the <tt>-A</tt> (or <tt>--terremark-username</tt>) <tt>-K</tt> (or <tt>--terremark-password</tt>) command options

```
# provision a new 2 Core 1GB Ubuntu 10.04 webserver
knife terremark server create --vcpus 2 -m 1024 -I 40 -A 'Your Terremark Username' -K "Your Terremark Password" -r 'role[webserver]'
```

Additionally the following options may be set in your `knife.rb`:
- image
- distro
- template_file

## Subcommands
This plugin provides the following Knife subcommands. Specific command options can be found by invoking the subcommand with a <tt>--help</tt> flag

### `knife terremark server create`
Provisions a new server in the Terremark Cloud and then perform a Chef bootstrap (using the SSH protocol). The goal of the bootstrap is to get Chef installed on the target system so it can run Chef Client with a Chef Server. The main assumption is a baseline OS installation exists (provided by the provisioning). It is primarily intended for Chef Client systems that talk to a Chef server. By default the server is bootstrapped using the {ubuntu10.04-gems}[[https://github.com/opscode/chef/blob/master/chef/lib/chef/knife/bootstrap/ubuntu10.04-gems.erb](https://github.com/opscode/chef/blob/master/chef/lib/chef/knife/bootstrap/ubuntu10.04-gems.erb)] template. This can be overridden using the <tt>-d</tt> or <tt>--template-file</tt> command options.

### `knife terremark server delete`
Deletes an existing server in the currently configured Terremark Cloud account by the server/instance id. You can find the instance id by entering 'knife terremark server list'. Please note - this does not delete the associated node and client objects from the Chef server.

### `knife terremark server list`
Outputs a list of all servers in the currently configured Terremark Cloud account. Please note - this shows all instances associated with the account, some of which may not be currently managed by the Chef server.

### `knife terremark image list`
Outputs a list of all available images available to the currently configured Terremark Cloud account. An image is a collection of files used to create or rebuild a server. Terremark provides a number of pre-built OS images by default. This data can be useful when choosing an image id to pass to the <tt>knife terremark server create</tt> subcommand.

## License and Authors
- Author:: Adam Jacob ([adam@chef.io](mailto:adam@chef.io))

```text
Copyright 2010-2015 Chef Software, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
