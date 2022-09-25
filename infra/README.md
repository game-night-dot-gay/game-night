# game-night Infrastructure

## Resources

- [DigitalOcean API Rerence](https://docs.digitalocean.com/reference/api/api-reference)
- API URL: `https://api.digitalocean.com/v2/`
- [Terraform with DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-use-terraform-with-digitalocean)
- [Terraform Project Structure](https://www.digitalocean.com/community/tutorials/how-to-structure-a-terraform-project)

## Terraform Cloud Notes

Terraform Cloud is used for remote state management to both allow multiple people to interact with the state
as well as providing locking capability so that only one person can apply a change at a time.

- Terraform Cloud Org: `be-gay-do-crime`
- [Digital Ocean Terraform Cloud Tutorial](https://www.digitalocean.com/community/tutorials/how-to-use-terraform-within-your-team)

## Terraform Notes

- Preface Terraform environment variables with `TF_VAR_` so a TF variable of `do_token` would be `export TF_VAR_do_token=123456`

## Digital Ocean Custom Image From Scratch Notes

1. Create new VM with QEMU/KVM/Libvirt/Virt-Manager from NixOS ISO
2. Configure `configuration.nix` as needed.
3. Run updates and garbage collection
4. Shutdown virtual machine
5. Compress qcow2 VM image file using gzip command
6. Upload image through DigitalOCean web interface Custom Images page
7. Deploy a new Droplet off the image and login via the Recovery Console. You won't have networking.
8. Run `nixos-generate-config --force` to get a new `hardware-configuration.nix` file with the hardware running on DigitalOcean, and a new `configuration.nix` with the network interfaces that need DHCP enabled
9. Add missing packages from the above step to the local VM `hardware-configuration.nix` and add the NICs to `configuration.nix`
10. Then `nixos-rebuild switch`, update, garbage collect, gzip and upload to DigitalOcean again
11. Launch Droplet and confirm networking works
12. Delete the initial image and use `packer` to manage image changes going forward

## Packer Notes

- Set environment variables by prefixing them with `PKR_VAR_` such as `PKR_VAR_ssh_username` (case sensitive)
- [DigitalOcean Packer Builder Documentation](https://www.packer.io/plugins/builders/digitalocean)
- For custom images you can't use the name, you have to use the id.

### List custom images and see the id

```sh
curl -X GET \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $DO_TOKEN" \
"https://api.digitalocean.com/v2/images?private=true" | jq
```

### How to get the latest image ID

```sh
latest_id=`curl -s -X GET \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $DO_TOKEN" \
"https://api.digitalocean.com/v2/images?private=true" | jq '.images | max_by(.id) | .id'`

echo $latest_id
```

### List all available Droplet images

```sh
curl -X GET \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $DO_TOKEN" \
  "https://api.digitalocean.com/v2/images | jq

```

### Manual Cert update process

1. SSH to a running instance
1. `nano /etc/nixos/nginx.nix`
1. Uncomment the commented out config lines

```nix
virtualHosts = let gameNightConfig = {
    useACMEHost = "gamenight.gay";
    forceSSL = false;
    addSSL = true;
#    sslCertificate = "/mnt/game-night-prod/certificates/acme/gamenight.gay/fullchain.pem";
#    sslCertificateKey = "/mnt/game-night-prod/certificates/acme/gamenight.gay/key.pem";
    locations."/.well-known/acme-challenge/" = {
       root = "/var/lib/acme/.challenges";
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
    in {
    "gamenight.gay" = gameNightConfig;
    "www.gamenight.gay" = gameNightConfig;
    "prod.gamenight.gay" = gameNightConfig;
    };
};

  # TODO - Commented out until we can get this to not get us rate limited by LE
  # Cert is copied and available on the volume
   security.acme.acceptTerms = true;
   security.acme.renewInterval = "weekly";
   security.acme.preliminarySelfsigned = true;
   security.acme.certs = {
     "gamenight.gay" = {
 #      directory = "/mnt/game-night-prod/certificates/acme/gamenight.gay";
       webroot = "/var/lib/acme/.challenges";
       extraDomainNames = [ "www.gamenight.gay" "prod.gamenight.gay" ];
       email = "admin@gamenight.gay";
     };
   };
```

1. Apply the nix config `nixos-rebuild switch`
1. Make sure new cert is copied to the mounted volume

```sh
mv /mnt/game-night-prod/certificates/acme /mnt/game-night-prod/certificates/acme.bak
cp -R /var/lib/acme/ /mnt/game-night-prod/certificates/
chown -R acme:acme /mnt/game-night-prod/certificates/acme
```

1. Revert lines in `/etc/nix/nginx.nix` again so we don't get rate limited (revert to what's in the repo) and `nixos-rebuild switch
1. Test to verify cert is updated in the browser at <https://gamenight.gay>
1. ALLIE FIX THIS FOR THE LOVE OF RUST! --Sincerely Allie
