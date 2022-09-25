{ config, pkgs, ... }:

{
  users.users.nginx = {
    extraGroups = [ "acme" ];
  };

  users.users.acme = {
    extraGroups = [ "acme" ];
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
      # Note: This is breaking the site right now. TODO get HSTS working
      #
      # Add HSTS header with preloading to HTTPS requests.
      # Adding this header to HTTP requests is discouraged
      # map $scheme $hsts_header {
      #    https   "max-age=31536000; includeSubdomains; preload";
      # }
      # add_header Strict-Transport-Security $hsts_header;

      # Enable CSP for your services.
      #add_header Content-Security-Policy "script-src 'self'; object-src 'none'; base-uri 'none';" always;

      # Minimize information leaked to other domains
      add_header 'Referrer-Policy' 'origin-when-cross-origin';

      # Disable embedding as a frame
      add_header X-Frame-Options SAMEORIGIN;

      # Prevent injection of code in other mime types (XSS Attacks)
      add_header X-Content-Type-Options nosniff;

      # Enable XSS protection of the browser.
      # May be unnecessary when CSP is configured properly (see above)
      add_header X-XSS-Protection "1; mode=block";

      # This might create errors
      proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";
    '';



    virtualHosts =
      let
        gameNightConfig = {
          useACMEHost = "gamenight.gay";
          forceSSL = false;
          addSSL = true;
          sslCertificate = "/mnt/game-night-prod/certificates/acme/gamenight.gay/cert.pem";
          locations."/.well-known/acme-challenge/" = {
            root = "/mnt/game-night-prod/certificates/acme/acme-challenge";
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
          };
        };
      in
      {
        "gamenight.gay" = gameNightConfig;
        "www.gamenight.gay" = gameNightConfig;
        "prod.gamenight.gay" = gameNightConfig;
      };
  };

  # TODO - Commented out until we can get this to not get us rate limited by LE
  # Cert is copied and available on the volume
  # security.acme.acceptTerms = true;
  # security.acme.renewInterval = "weekly";
  # security.acme.preliminarySelfsigned = true;
  # security.acme.certs = {
  #   "gamenight.gay" = {
  #     directory = "/mnt/game-night-prod/certificates/acme/<name>";
  #     webroot = "/mnt/game-night-prod/certificates/acme/acme-challenge";
  #     extraDomainNames = [ "www.gamenight.gay" "prod.gamenight.gay" ];
  #     email = "admin@gamenight.gay";
  #   };
  # };
}
