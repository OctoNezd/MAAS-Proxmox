#!/bin/bash -ex
#
# cloud-img-setup-curtin.sh - Set up curtin curthooks
#
# Copyright (C) 2022 Canonical
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

echo "Setting up curtin hooks for MAAS deployment"

mkdir -p /curtin

# Copy curtin-hooks (handles custom kernel AND Proxmox network configuration)
FILENAME=curtin-hooks
if [ -f "/tmp/${FILENAME}" ]; then
    mv "/tmp/${FILENAME}" /curtin/
    chmod 750 "/curtin/${FILENAME}"
    echo "Installed curtin-hooks"
else
    echo "WARNING: /tmp/${FILENAME} not found!"
    exit 1
fi

# Copy CUSTOM_KERNEL file if it exists (for custom kernel support)
if [ -f "/curtin/CUSTOM_KERNEL" ]; then
    echo "Custom kernel configuration detected"
fi
