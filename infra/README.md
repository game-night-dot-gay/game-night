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