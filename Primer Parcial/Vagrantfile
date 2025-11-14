Vagrant.configure("2") do |config|
  
  config.vm.box = "bento/ubuntu-22.04"

  config.vm.define "maestro" do |maestro|
    maestro.vm.hostname = "maestro"
    maestro.vm.network "private_network", ip: "192.168.50.3"
    
    maestro.vm.provider "virtualbox" do |vb|
      vb.memory = 1024
      vb.cpus = 1
    end
  end

  config.vm.define "esclavo" do |esclavo|
    esclavo.vm.hostname = "esclavo"
    esclavo.vm.network "private_network", ip: "192.168.50.2"
    
    esclavo.vm.provider "virtualbox" do |vb|
      vb.memory = 1024
      vb.cpus = 1
    end
  end

  config.vm.define "cliente" do |cliente|
    cliente.vm.hostname = "cliente"
    cliente.vm.network "private_network", ip: "192.168.50.4"
    
    cliente.vm.provider "virtualbox" do |vb|
      vb.memory = 1024
      vb.cpus = 1
    end
  end

end
