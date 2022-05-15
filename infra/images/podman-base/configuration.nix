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
  networking.interfaces.enp1s0.useDHCP = true; # Laptop Qemu/KVM NIC
  networking.interfaces.ens3.useDHCP = true; # Digital Ocean NIC 1
  networking.interfaces.ens4.useDHCP = true; # Digital OCean NIC 2
  
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.mutableUsers = false; # So we can blow away any set passwords
  
  users.users.root.hashedPassword = "$6$/Rkez4AJT4Dlsz2x$qQpfdUtAwuWJYH5tIlaxAhJp06JVlUA4rK4gDmfy7nwBHiHkJK1PtnGJa8xgv3o4fhtY0CxcuInIJ.41efWrM.";
  
  users.users.allie = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "podman" ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJbcXYsCa/TwoWMbx6GCQQV4vKWuSjQy0gri0+ZFuvVC allie@allie-laptop" ];
    hashedPassword = "$6$DE7QNygUHoo6fQY/$ImKkrRIDn1dRwsTx.d1VVHc9G2W5xplH5U3g22Eb/pC4vLHQoGtNAj521hb1G.oj4F9.prSnwJGzDiwv7UU.j.";
  };

  users.users.amy = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "podman" ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO/PY5G1vwrxu4agNvVaDixP6KlOGACxyaKwHjoZUfys" ];
    hashedPassword = "$6$5o.PJ3.Vl.t/CaqP$umqMOe8deOGAqruK0T0qGaU33CYJjuRYrRK.fxGOt5UBbUVt4hFhEGAen2iqJWZHqhK7bdSYEoO.pCzXTo.oz/";
  };

  # TODO - Remove from wheel, create new group and restrict sudoers access
  users.users.automation = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "podman" ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHbsshvL0pffEZaxTWkIGpCqkrjtyC2l2M8oFEMJk4Ss automation@game-night" ];
    hashedPassword = "$6$CRroCRvTrQrTn2lb$03JdjYx4it5qZR7aMAXchC1negv.RHpwScDhgSd4ik8IdRvH4AhsViDwsTSOwAu0uyPNfHUkDK43nTE..Iu7S.";
  };

  users.users.game-night-prod = {
    isNormalUser = true;
    extraGroups = [ ];
  };

  users.users.game-night-staging = {
    isNormalUser = true;
    extraGroups = [ ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
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
  services.openssh ={ 
    enable = true;
    permitRootLogin = "yes";
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
