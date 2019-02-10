Vagrant.configure("2") do |config|
  config.vm.box = "debian/contrib-stretch64" # or "centos/7"
  config.vm.synced_folder ".", "/vagrant", type: "sshfs"
  config.vm.provision :shell, :path => "provision.sh"
end
