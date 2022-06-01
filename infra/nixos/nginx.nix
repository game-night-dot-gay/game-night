{ config, pkgs, ... }:

{
  # This is a basic default file so we don't have to use sed
  # This is replaced by nginx-prod.nix on deploy

  users.users.nginx = {
    extraGroups = [ "acme" ];
  };

  users.users.acme = {
    extraGroups = [ "acme" ];
    isSystemUser = true;
  };

  users.users.acme.group = "acme";

  users.groups = {
    acme = { gid = 995; };
  };
  
}
