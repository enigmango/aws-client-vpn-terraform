## Pricing information

* Client VPN
* 2 NAT gateways
* 2 EIPs

Estimated cost: Base infra cost is about $190. Cost for usage is $0.05/hour + $0.05 per GB processed by the NAT. Could be lower if only deploying 1 NAT.

## What does this do?

- Creates a VPC with...
  - 2 public subnets, 2 private subnets, spread across 2 AZs
  - 2 NAT gateways, 1 per subnet
  - Route tables
- Imports local certs to ACM for use with Client VPN
- Creates AWS client VPN:
  - Mutual (cert-based) authentication
  - Full-tunnel
  - Google and Quad9 DNS
  - Open access to internet for all clients
- Creates a client config file (ovpn)

## What doesn't this do?

Create TLS certs for you. Other implementations use the TLS cert provider and that's a great idea. I didn't do that though, to simulate a situation where PKI already exists.


### How do I create these certs?

I used [easy-rsa](https://github.com/OpenVPN/easy-rsa)

After installing easy-rsa, from the easy-rsa directory:

```bash
./easyrsa init-pki
./easyrsa build-ca
./easyrsa gen-req client.example.com
./easyrsa gen-req server.example.com
./easyrsa sign-req client client.example.com
./easyrsa sign-req server server.example.com

# Decrypt private keys so they can be imported and used in client config
openssl rsa -in pki/private/ca.key > /tmp/ca.key
openssl rsa -in pki/private/client.example.com.key > /tmp/client.key
openssl rsa -in pki/private/server.example.com.key > /tmp/server.key

# Copy certs to same location for reference. AWS accepts these as-is. Renaming to PEM for consistency
cp pki/issued/ca.crt /tmp/ca.pem
cp pki/issued/client.example.com.crt /tmp/client.pem
cp pki/issued/server.example.com.crt /tmp/server.pem
```

Then from this project directory:

```bash
mv /tmp/ca.pem certs/ca.pem
mv /tmp/client.pem certs/client.pem
mv /tmp/server.pem certs/server.pem

mv /tmp/ca.free.key certs/keys/ca.key
mv /tmp/client.key certs/keys/client.key
mv /tmp/server.key certs/keys/server.key
```

Then you're good to go.


