#!/bin/bash

apt update && apt autoclean && apt -dy dist-upgrade && \
    apt dist-upgrade && apt autoremove --purge
