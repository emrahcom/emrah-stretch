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
