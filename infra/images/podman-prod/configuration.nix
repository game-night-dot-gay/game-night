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
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJbcXYsCa/TwoWMbx6GCQQV4vKWuSjQy0gri0+ZFuvVC" ];
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
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHbsshvL0pffEZaxTWkIGpCqkrjtyC2l2M8oFEMJk4Ss" ];
    hashedPassword = "$6$CRroCRvTrQrTn2lb$03JdjYx4it5qZR7aMAXchC1negv.RHpwScDhgSd4ik8IdRvH4AhsViDwsTSOwAu0uyPNfHUkDK43nTE..Iu7S.";
  };

  users.users.nginx = {
    extraGroups = [ "acme" ];
  };

  users.users.postgres = {
    isNormalUser = true;
    extraGroups = [ ];
  };

  users.users.game-night-prod = {
    isNormalUser = true;
    extraGroups = [ ];
  };

  users.users.game-night-staging = {
    isNormalUser = true;
    extraGroups = [ ];
  };

  security.sudo.extraRules = [
    { users = [ "automation" ]; 
      commands = [ { 
        command = "/run/current-system/sw/bin/podman"; 
        options = [ "NOPASSWD" ]; }
        { 
        command = "/run/wrappers/bin/mount"; 
        options = [ "NOPASSWD" ]; } 
        { 
        command = "/run/current-system/sw/bin/tee"; 
        options = [ "NOPASSWD" ]; } 
      ]; 
    }
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    jq
    git
    htop
    direnv
    sqlx-cli
  ];

  virtualisation = {
    podman = {
     enable = true;
  
     dockerCompat = true;
    };
  };

 

  services.nginx = {
    enable = true;

    # Use recommended settings
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    # Only allow PFS-enabled ciphers with AES256
    sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

    commonHttpConfig = ''
      # Add HSTS header with preloading to HTTPS requests.
      # Adding this header to HTTP requests is discouraged
      map $scheme $hsts_header {
          https   "max-age=31536000; includeSubdomains; preload";
      }
      add_header Strict-Transport-Security $hsts_header;

      # Enable CSP for your services.
      #add_header Content-Security-Policy "script-src 'self'; object-src 'none'; base-uri 'none';" always;

      # Minimize information leaked to other domains
      add_header 'Referrer-Policy' 'origin-when-cross-origin';

      # Disable embedding as a frame
      add_header X-Frame-Options DENY;

      # Prevent injection of code in other mime types (XSS Attacks)
      add_header X-Content-Type-Options nosniff;

      # Enable XSS protection of the browser.
      # May be unnecessary when CSP is configured properly (see above)
      add_header X-XSS-Protection "1; mode=block";

      # This might create errors
      proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";
    '';

    
 
    virtualHosts = let gameNightConfig = {
      useACMEHost = "gamenight.gay";
      forceSSL = false;
      addSSL = true;
      sslCertificate = "/var/lib/acme/gamenight.gay/cert.pem";
      locations."/.well-known/acme-challenge/" = {
          root = "/var/lib/acme/acme-challenge";
          extraConfig =
            "if ($scheme = 'https') { rewrite ^ http://$http_host$request_uri? permanent; }";
      };
      locations."/" = {
        proxyPass = "http://127.0.0.1:2727";
        proxyWebsockets = true; # needed if you need to use WebSocket
        extraConfig =
          # required when the target is also TLS server with multiple hosts
          "proxy_ssl_server_name on;" +
          # required when the server wants to use HTTP Authentication
          "proxy_pass_header Authorization;";

          #"if ($scheme = 'http') { rewrite ^ https://$http_host$request_uri? permanent; }";
          
        };
      }; 
    in {
      "gamenight.gay" = gameNightConfig;
      "www.gamenight.gay" = gameNightConfig;
      "prod.gamenight.gay" = gameNightConfig;
    };
  };

  security.acme.acceptTerms = true;
  security.acme.certs = {
    "gamenight.gay" = {
      webroot = "/var/lib/acme/acme-challenge";
      extraDomainNames = [ "www.gamenight.gay" "prod.gamenight.gay" ];
      email = "admin@gamenight.gay";
    };
  };
    

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    banner = "Be Gay, Do Crime. But not cyber crime, because that's not cool. Authorized users only.\n\n";
    permitRootLogin = "no";
    passwordAuthentication = false;
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
  # networking.firewall.allowedUDPPorts = [ ... ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
