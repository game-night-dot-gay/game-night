# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/vda";

  # Set your time zone.
  time.timeZone = "America/New_York";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.ens3.useDHCP = true; # Digital Ocean NIC 1
  networking.interfaces.ens4.useDHCP = true; # Digital OCean NIC 2
  
  # Define a user accounts
  users.mutableUsers = false; # So we can blow away any set passwords

  users.users.root.hashedPassword = "!"; # Disables root login with password
  

  users.users.allie = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "podman" ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJbcXYsCa/TwoWMbx6GCQQV4vKWuSjQy0gri0+ZFuvVC allie@allie-laptop" ];
  };

  users.users.amy = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "podman" ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO/PY5G1vwrxu4agNvVaDixP6KlOGACxyaKwHjoZUfys" ];
  };

  # TODO - Remove from wheel, create new group and restrict sudoers access
  users.users.automation = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "podman" ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHbsshvL0pffEZaxTWkIGpCqkrjtyC2l2M8oFEMJk4Ss automation@game-night" ];
  };

  users.users.service-prod = {
    isNormalUser = true;
    extraGroups = [ ];
  };

  users.users.service-staging = {
    isNormalUser = true;
    extraGroups = [ ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    emacs
    wget
    curl
    jq
    git
    htop
  ];

  virtualisation = {
    podman = {
     enable = true;
  
     dockerCompat = true;
    };
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    banner = "Be Gay, Do Crime. But not cyber crime because that's not cool. Authorized users only.";
    permitRootLogin = "no";
    passwordAuthentication = false;
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 ];
  # networking.firewall.allowedUDPPorts = [ ... ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
