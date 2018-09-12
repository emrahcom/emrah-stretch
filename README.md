About
=====

`emrah-stretch` is an installer to create the containerized systems on Debian
Stretch host. It built on top of LXC (Linux containers).

Table of contents
=================

- [About](#about)
- [Usage](#usage)
- [Example](#example)
- [Available templates](#available-templates)
    - [es-base](#es-base)
        - [To install es-base](#to-install-es-base)
    - [es-livestream](#es-livestream)
        - [Main components of es-livestream](#main-components-of-es-livestream)
        - [To install es-livestream](#to-install-es-livestream)
        - [After install es-livestream](#after-install-es-livestream)
        - [Related links to es-livestream](#related-links-to-es-livestream)
    - [es-gogs](#es-gogs)
        - [Main components of es-gogs](#main-components-of-es-gogs)
        - [To install es-gogs](#to-install-es-gogs)
        - [After install es-gogs](#after-install-es-gogs)
        - [SSL certificate for es-gogs](#ssl-certificate-for-es-gogs)
        - [Related links to es-gogs](#related-links-to-es-gogs)
    - [es-ring-node](#es-ring-node)
        - [To install es-ring-node](#to-install-es-ring-node)
        - [Related links to es-ring-node](#related-links-to-es-ring-node)
- [Requirements](#requirements)

---

Usage
=====

Download the installer, run it with a template name as an argument and drink a
coffee. That's it.

```bash
wget https://raw.githubusercontent.com/emrahcom/emrah-stretch/master/installer/es
wget https://raw.githubusercontent.com/emrahcom/emrah-stretch/master/installer/<TEMPLATE_NAME>.conf
bash es <TEMPLATE_NAME>
```

Example
=======

To install a streaming media system, login a Debian Stretch host as `root` and

```bash
wget https://raw.githubusercontent.com/emrahcom/emrah-stretch/master/installer/es
wget https://raw.githubusercontent.com/emrahcom/emrah-stretch/master/installer/es-livestream.conf
bash es es-livestream
```

Available templates
===================

es-base
-------

Install only a containerized Debian Stretch.

### To install es-base

```bash
wget https://raw.githubusercontent.com/emrahcom/emrah-stretch/master/installer/es
wget https://raw.githubusercontent.com/emrahcom/emrah-stretch/master/installer/es-base.conf
bash es es-base
```

---

es-livestream
-------------

Install a ready-to-use live streaming media system.

### Main components of es-livestream

-  Nginx server with nginx-ts-module and nginx-rtmp-module as a stream origin.
   It gets the (MPEG-TS or RTMP) stream and convert it to HLS and DASH.

-  Nginx server with standart modules as a stream edge.
   It publish the HLS and DASH stream.

-  Web based HLS video player.

-  Web based DASH video player.

### To install es-livestream

```bash
wget https://raw.githubusercontent.com/emrahcom/emrah-stretch/master/installer/es
wget https://raw.githubusercontent.com/emrahcom/emrah-stretch/master/installer/es-livestream.conf
bash es es-livestream
```

### After install es-livestream

-  `http://<IP_ADDRESS>:8000/livestream/publish/<CHANNEL_NAME>` to push
    an MPEG-TS stream.

-  `rtmp://<IP_ADDRESS>/livestream/<CHANNEL_NAME>` to push
    an RTMP stream.

-  `http://<IP_ADDRESS>/livestream/hls/<CHANNEL_NAME>/index.m3u8` to pull
   the HLS stream.

-  `http://<IP_ADDRESS>/livestream/dash/<CHANNEL_NAME>/index.mpd` to pull
   the DASH stream.

-  `http://<IP_ADDRESS>/livestream/hlsplayer/<CHANNEL_NAME>` for
   the HLS video player page.

-  `http://<IP_ADDRESS>/livestream/dashplayer/<CHANNEL_NAME>` for
   the DASH video player page.

-  `http://<IP_ADDRESS>:8000/livestream/status` for the RTMP status page.

-  `http://<IP_ADDRESS>:8000/livestream/cloner` for the stream cloner page.
   Thanks to [nejdetckenobi](https://github.com/nejdetckenobi)

### Related links to es-livestream

-  [nginx-ts-module](https://github.com/arut/nginx-ts-module)

-  [nginx-rtmp-module](https://github.com/arut/nginx-rtmp-module)

-  [video.js](https://github.com/videojs/video.js)

-  [videojs-contrib-hls](https://github.com/videojs/videojs-contrib-hls)

-  [dash.js](https://github.com/Dash-Industry-Forum/dash.js/)

---

es-gogs
--------

Install a ready-to-use self-hosted Git service. Only AMD64 architecture is
supported for this template.

### Main components of es-gogs

- Gogs
- Git
- Nginx
- MariaDB

### To install es-gogs

```bash
wget https://raw.githubusercontent.com/emrahcom/emrah-stretch/master/installer/es
wget https://raw.githubusercontent.com/emrahcom/emrah-stretch/master/installer/es-gogs.conf
bash es es-gogs
```

### After install es-gogs

-  Access `https://<IP_ADDRESS>/` to finish the installation process. Easy!

-  **Password**: There is no password for the database. So, leave it blank!
   Don't worry, only the local user can connect to the database server.

-  **Domain**: Write your host FQDN or IP address. Examples:   
   *git.mydomain.com*   
   *123.2.3.4*

-  **SSH Port**: Leave the default value which is the SSH port of the
   container.

-  **HTTP Port**: Leave the default value which is the internal port of Gogs
   service.

-  **Application URL**: Write your URL. HTTP and HTTPS are OK. Examples:   
   *https://git.mydomain.com/*    
   *https://123.2.3.4/*

-  The first registered user will be the administrator.


### SSL certificate for es-gogs

To use Let's Encrypt certificate, connect to es-gogs container as root and

```bash
FQDN="your.host.fqdn"

certbot certonly --webroot -w /var/www/html -d $FQDN

chmod 750 /etc/letsencrypt/{archive,live}
chown root:ssl-cert /etc/letsencrypt/{archive,live}
mv /etc/ssl/certs/{ssl-es.pem,ssl-es.pem.bck}
mv /etc/ssl/private/{ssl-es.key,ssl-es.key.bck}
ln -s /etc/letsencrypt/live/$FQDN/fullchain.pem \
    /etc/ssl/certs/ssl-es.pem
ln -s /etc/letsencrypt/live/$FQDN/privkey.pem \
    /etc/ssl/private/ssl-es.key

systemctl restart nginx.service
```


### Related links to es-gogs

- [Gogs](https://gogs.io/)
- [Git](https://git-scm.com/)
- [Nginx](http://nginx.org/)
- [MariaDB](https://mariadb.org/)
- [Let's Encrypt](https://letsencrypt.org/)
- [Certbot](https://certbot.eff.org/)

---

es-ring-node
-------------

Install a ready-to-use public Ring node.

### To install es-ring-node

```bash
wget https://raw.githubusercontent.com/emrahcom/emrah-stretch/master/installer/es
wget https://raw.githubusercontent.com/emrahcom/emrah-stretch/master/installer/es-ring-node.conf
bash es es-ring-node
```

### Related links to es-ring-node

-  [OpenDHT](https://github.com/savoirfairelinux/opendht)

-  [Ring](https://ring.cx/)

---

Requirements
============

`emrah-stretch` requires a Debian Stretch host with a minimal install and
Internet access during the installation. It's not a good idea to use your
desktop machine or an already in-use production server as a host machine.
Please, use one of the followings as a host:

-  a cloud host from a hosting/cloud service
   ([Digital Ocean](https://www.digitalocean.com/?refcode=92b0165840d8)'s
   droplet, [Amazon](https://console.aws.amazon.com) EC2 instance etc)

-  a virtual machine (VMware, VirtualBox etc)

-  a Debian Stretch container

-  a physical machine with a fresh installed [Debian Stretch](https://www.debian.org/distrib/netinst)
