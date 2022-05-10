# game-night Infrastructure

## Resources
- [DigitalOcean API Rerence](https://docs.digitalocean.com/reference/api/api-reference)
- API URL: https://api.digitalocean.com/v2/
- [Terraform with DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-use-terraform-with-digitalocean)
- [Terraform Project Structure](https://www.digitalocean.com/community/tutorials/how-to-structure-a-terraform-project)

### Useful API Queries

```sh
# List all available Droplet images
curl -X GET \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $DO_TOKEN" \
  "https://api.digitalocean.com/v2/images | jq

```

## Terraform Setup Notes
Recommend `tfswitch` to manage Terraform version
- Install [tfswitch](https://tfswitch.warrensbox.com/Quick-Start/)
- Add `/home/$USER/bin` to your path. This is where tfswitch will install Terraform
- `cd game-night/infra/terraform` and run `tfswitch` which will read the `versions.tf` file and install the required version
- `which terraform` and `terraform version` to confirm what you're using
- Proceed to commit Terraform crimes


## NixOS Notes

1. [Disk Partitioning](https://nixos.org/manual/nixos/stable/#sec-installation-partitioning-UEFI)
2. 

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
12 . Delete the initial image and use `packer` to manage image changes going forward

## Image Cleanup TODO

- Get rid of passwords and only use SSH keys
- SSH don't allow password logins

## Packer Notes

- https://www.packer.io/plugins/builders/digitalocean
- Apparently for custom images you can't use the name you have to use the id. To list custom images and see the id:

```sh
curl -X GET \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $DO_TOKEN" \
"https://api.digitalocean.com/v2/images?private=true" | jq
```
- Set environment variables by prefixing them with `PKR_VAR_` such as `PKR_VAR_ssh_username` (case sensitive)

1. `cd infra/images/podman-prod` and run `packer init image.pkr.hcl`
2. 