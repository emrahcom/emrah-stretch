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
- [Requirements](#requirements)

---

Usage
=====

Download the installer, run it with a template name as an argument and drink a
coffee. That's it.

```bash
wget https://raw.githubusercontent.com/emrahcom/emrah-stretch/master/installer/es
bash es <TEMPLATE_NAME>
```

Example
=======

To install a containerized PowerDNS system, login a Debian Stretch host as
`root` and

```bash
wget https://raw.githubusercontent.com/emrahcom/emrah-stretch/master/installer/es
bash es es-powerdns
```

Available templates
===================

es-base
-------

Install only a containerized Debian Stretch.

### To install es-base

```bash
wget https://raw.githubusercontent.com/emrahcom/emrah-stretch/master/installer/es
bash es es-base
```

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
