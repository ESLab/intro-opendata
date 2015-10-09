Vagrant.configure(2) do |config|
  config.vm.box = "opendata"
  config.vm.box_url = "http://silent.cs.abo.fi/vagrant/trafi-vagrant.box"

  config.vm.network :forwarded_port, guest: 8787, host: 8080
  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--memory", "2048"]
    v.customize ["modifyvm", :id, "--cpus", "2"]
  end

  # config.vm.provision "docker" do |docker|
  #   docker.pull_images "stippeng/tokumx_trafi"
  #   #docker.pull_images "stippeng/rstudio_trafi"
  #   docker.build_image "/vagrant/",
  #     args: "-t rstudio"
  #  
  #   docker.run "trafi_db",
  #     image: "stippeng/tokumx_trafi",
  #     args: "-d"
  #   docker.run "rstudio", 
  #     image: "rstudio",
  #     args: "-p 8787:8787 -d -v /vagrant:/home/rstudio/data --link trafi_db:trafi_db"
  # end

  # Workaround to /vagrant being mounted after docker starts 
  config.vm.provision "shell",
     inline: "docker restart rstudio", run: "always", privileged: true

end
