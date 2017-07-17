#!/bin/bash

apt update && apt autoclean && apt -dy full-upgrade && \
    apt full-upgrade && apt autoremove --purge
