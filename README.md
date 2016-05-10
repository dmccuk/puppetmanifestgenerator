puppet manifest creator
=======================

* I'm developing this script with the main focus of trying to manage legacy servers that weren't built by puppet.

Use case
--------
 1. Quickly creating a manifest of your exisiting servers
 2. Locally apply the manifest back via cron from the apply.pp fine created (user setup required).
 3. Move the manifest (under the server name) into a puppet master. Set the role to the servername.
 4. Create/rebuild legacy servers based on this manifest

changelog
---------
[ Added hostname factorisation. All .erb files are checked for the hostname of the server and replaced by @hostname ]

Usage
-----

I assume you have git installed already and a newish version of puppet.

 1. Clone the Repo - git clone https://github.com/dmccuk/puppet_legacy_manifest.git
 2. cd into the cloned directory. Examples in each of the files described below:
      * Update "files.dm" with the name and location of what you want to manage.
      * Update "services_packages.dm" with the serivce name and the package name.
 3. To run:
      * ./manifest_creator.sh 
 4. The script will run and create the following directory tree:
      * /opt/HOSTNAME
      * The manifests will be created under this DIR.
      * an "apply.pp" script will be created that you can run to apply the maifest back to the server.

Development
===========

Plans are to add the following:

 * Data abstraction of IP addresses
  * Us facter to replace any host IP addresses so the modules could be run on any server.
  * Add a file_line option so not all files are managed by templates. This givs much greater flexibility in how to manage code with the manifest creator script.
  * Add metadata.json file

Please feel free to clone or update 
