# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.define :servidorWeb do |servidorWeb|
    servidorWeb.vm.box = "bento/ubuntu-22.04"
    servidorWeb.vm.network :private_network, ip: "192.168.60.3"
    
    # Forwarded ports para acceder desde el host
    servidorWeb.vm.network "forwarded_port", guest: 80, host: 8080
    servidorWeb.vm.network "forwarded_port", guest: 443, host: 8443
    servidorWeb.vm.network "forwarded_port", guest: 3000, host: 3000  # Grafana
    servidorWeb.vm.network "forwarded_port", guest: 9090, host: 9090  # Prometheus
    
    # Configuración de recursos
    servidorWeb.vm.provider "virtualbox" do |vb|
      vb.memory = "4096"
      vb.cpus = 2
      vb.name = "TelematicosVM"
    end
    
    # Sincronizar directorio del proyecto
    servidorWeb.vm.synced_folder ".", "/vagrant"
    
    # Provisionar con script de instalación de Docker
    servidorWeb.vm.provision "shell", path: "scripts/provision-vm.sh"
    
    servidorWeb.vm.hostname = "servidorWeb"
  end
end
