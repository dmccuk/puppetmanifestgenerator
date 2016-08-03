puppet manifest creator
=======================
This is a generic script that creates a complete puppet manifest based on input from the user. Add files, services, packages and users (adding more soon) to the config files as well as control configuration files with file_line (may need to install stdlib). This script will generate all the required puppet code to either apply locally back to your node or move it to a puppet master using the server_name role created when the script runs. It enables quick configuration management of your legacy servers as well as providing a way to manage the code once it's been generated. Generates manifests for all your legacy servers so you can bring them under puppet management.

Use case
--------
 1. Quickly creating a manifest of your exisiting servers.
 2. Locally apply the manifest back from the apply.pp script generated by the script.
 3. Move the manifest (under the server name) into a puppet master. Set the role and manage with your master.
 4. Create/rebuild legacy servers based on the manifest you create.

Changelog
---------
 * [ Added hostname factorisation. All .erb files are checked for the hostname of the server and replaced by local fact @hostname ]
 * [ Created a role that can be run on a puppet master based on the files managed by the script ]
 * [ Added the ability to create a "file_line" managed config file in addition to a template ]
 * [ catered for hostnames with - and changed them to _ ]
 * [ Added fstab (mount) as a defualt option. It doesn't need to be added to any configs ]
 * [ Added option to manage users. Add list of users to the config file to generate a manifets for them ]
 * [ The manifest structure is now generated by the "puppet module generator" command. This sets up each manifest with all required files ]

Compatibility
-------------
The script is written in bash and has been tested on Redhat/Centos versions 6&7. It should work on other OS's but if you would like to contribute I would appreciate your help for a debian based update.

Dependencies
------------
 * Puppet version 3.0 or above.
 * Directory Environments.
 * Git.
 * Clone it into the /tmp directory. If not, please update the FILE_HOME variable with your install location.
 * For local "Puppet apply" Install puppetlabs-stdlib to the /opt/HOST_/modules/build directory (may be required).
 * If you are running the code as a role on your puppet master AND you are managing the contents of files using "file_line", you will need to install puppetlabs-stdlib into the module/build directory.

Usage
-----
 1. Clone the Repo in /tmp - git clone https://github.com/dmccuk/puppetmanifestgenerator.git
 2. cd into the cloned directory. Examples in each of the files described below:
      * Update "files_managed_by_templates.dm" with the name and location of what you want to manage.
      * Update "services_packages.dm" with the serivce name and the package name.
      * update "files_managed_by_file_line.dm" with the files you wish to create a "file_line" output for.
 3. To run:
      * ./manifest_creator.sh 
 4. The script will run and create the following directory tree:
      * /opt/$hostname/{manifests,modules,environment.conf}
      * The ROLE and BUILD directories will be created under modules.
      * For Local running, an "apply.pp" script will be created so that you can apply the manifest back to the server. See the apply.pp for more information once run.
 5. To run the role on a puppet master, move the "$hostname" tree to your puppet master under the /etc/puppet/environment directory.

Development
===========
Plans are to add the following:

  * Data abstraction of IP addresses where appropiate.

Issues:
------
[1]
If you see this when running puppet apply:

    Error: Evaluation Error: Error while evaluating a Resource Statement, Invalid resource type file_line at /opt/server_name/sshd_config/manifests/init.pp:3:3 on node server1

You need to download and install puppetlabs-stdlib to your working directory. In this case it's /opt/$HOST_. The file_line type requires stdlib is installed.

    # puppet module install -i . -f  puppetlabs-stdlib
    Notice: Preparing to install into /opt/fedora_22 ...
    Notice: Downloading from https://forgeapi.puppetlabs.com ...
    Notice: Installing -- do not interrupt ...

Now run puppet apply or the apply.pp script again.

[2]
If you are running the role from your puuppet master and you can't see any file_line updates in the output, make sure you have installed puppetlabs-stdlib into the directory here: /modules/build.

I appreciate any feedback and contributions.

