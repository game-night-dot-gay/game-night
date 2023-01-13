{ config, pkgs, ... }:

{

  # So we can blow away any set passwords
  users.mutableUsers = false;

  # Disables root login with password
  users.users.root.hashedPassword = "!";

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


  # Temporary until I can lock this down better
  security.sudo.wheelNeedsPassword = false;

  # Allow specific sudo commands without password
  security.sudo.extraRules = [
    {
      users = [ "automation" ];
      commands = [{
        command = "podman";
        options = [ "NOPASSWD" ];
      }
        {
          command = "mount";
          options = [ "NOPASSWD" ];
        }
        {
          command = "tee";
          options = [ "NOPASSWD" ];
        }
        {
          command = "nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
        {
          command = "nix-channel";
          options = [ "NOPASSWD" ];
        }
        {
          command = "nix-env";
          options = [ "NOPASSWD" ];
        }
        {
          command = "rm -f /nix/var/nix/gcroots/auto/*";
          options = [ "NOPASSWD" ];
        }
        {
          command = "nix-collect-garbage";
          options = [ "NOPASSWD" ];
        }
        {
          command = "sed";
          options = [ "NOPASSWD" ];
        }];
    }
  ];


}
