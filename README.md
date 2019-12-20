# SSLVPN

This is a docker container that sets up a "VPN" that runs over SSL (TLS specifically).

What this really means is that and SSH server is exposed through port 443, and encapsulated in TLS using STunnel.
This is great because using a program like **sshuttle**, you can get a VPN-like service that will go through pretty much 
any firewall, including one that use Deep Packet Inspection (since the connection looks like a normal HTTPS connection).

The container contains the following services:
* [stunnel4](https://www.stunnel.org/)
* [sslh](https://github.com/yrutschle/sslh)
* [Apache](https://httpd.apache.org/)
* [OpenSSH](https://www.openssh.com/)

The container is built from an Ubuntu 18.04 image with systemd to manage the services.

Stunnel is responsible for being the TLS endpoint, and all connections to 443 in the container terminate at it. It then 
passes the decrypted connection to sslh, which forwards the connection to OpenSSH if it is an SSH connection, or to Apache if 
it's an http connection. This way, if someone were to access the container through a browser, they would be greeted with a 
normal webpage.

## Server Setup

This container uses port 80 and 443 (i.e you shouldn't have another webserver on the same machine). I recommend using a cheap cloud provider 
to run SSLVPN.

* Clone this repository.

```shell script
git clone https://github.com/Seshpenguin/sslvpn.git && cd sslvpn
```

* Create an "id_rsa.pub" file with your [SSH public key](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-on-ubuntu-1804#step-1-%E2%80%94-create-the-rsa-key-pair) in the repo folder.

```shell script
cp ~/.ssh/id_rsa.pub .
```

* Build the Docker image.
```shell script
docker build . -t seshpenguin/sslvpn
```

* Deploy the container:
```shell script
docker run -d --name sslvpn --restart always --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro seshpenguin/sslvpn
```


## Client Setup (w/ sshuttle) for Linux and macOS
Since the SSH server is behind a TLS proxy, you'll need to use a custom SSH config.

You'll need to install [sshuttle](https://sshuttle.readthedocs.io/en/stable/) first.

* Open your SSH Config
```shell script
Host SOME_NAME
User vpn
ProxyCommand openssl s_client -connect YOUR_IP:443 -quiet
```
Replace "SOME_NAME" with a friendly name for your server, and "YOUR_IP"

* Test your SSH Connection:
```shell script
ssh SOME_NAME
```

* Exit the SSH Command, and connect to your VPN!
```shell script
sshuttle -r SOME_NAME -x YOUR_IP:443 0/0
```

If all goes well, your system traffic should now be routed through the container!
