#!/usr/bin/env bash

# Just run the playbook, defaults to included sample inventory.
# Pass in any regular ansible-playbook commands.
#
# For example, us another inventory, limit hosts and set extra args:
# ./run.sh --inventory ~/my_inventory --limit kvmhost,guests -e virt_infra_state=undefined

DIR="$(dirname "$(readlink -f "${0}")")"
source /etc/os-release

# Check for dependencies
if ! type ansible-playbook &>/dev/null ; then
	read -r -p "Ansible missing, install it? [y/N]: " answer
	if [[ "${answer,,}" != "y" && "${answer,,}" != "yes" ]] ; then
		echo "OK, please install it and retry."
		exit 1
	fi
	DISTRO=${ID_LIKE:-${ID}}
	case "${DISTRO,,}" in
		centos)
			if [[ "${VERSION_ID}" -eq "7" ]] ; then
				PKG_MGR=yum
			fi
			echo sudo ${PKG_MGR:-dnf} -y install epel-release
			sudo ${PKG_MGR:-dnf} -y install epel-release
			echo sudo ${PKG_MGR:-dnf} -y install ansible
			sudo ${PKG_MGR:-dnf} -y install ansible
			;;
		fedora)
			echo sudo dnf -y install ansible
			sudo dnf -y install ansible
			;;
		debian)
			echo "Installing Ansible from Ubuntu PPA..."
			echo sudo apt install -y gnupg2
			sudo apt install -y gnupg2
			echo "echo 'deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main' | sudo tee -a /etc/apt/sources.list"
			grep -q ansible /etc/apt/sources.list || echo 'deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main' | sudo tee -a /etc/apt/sources.list
			echo sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
			sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
			echo sudo apt update
			sudo apt update
			echo sudo apt install -y ansible
			sudo apt install -y ansible
			;;
		ubuntu)
			echo "Installing Ansible from PPA..."
			echo sudo apt install -y software-properties-common
			sudo apt install -y software-properties-common
			echo sudo apt-add-repository --yes --update ppa:ansible/ansible
			sudo apt-add-repository --yes --update ppa:ansible/ansible
			echo sudo apt install -y ansible
			sudo apt install -y ansible
			sudo apt install -y --no-install-recommends dnsmasq git genisoimage libguestfs-tools libosinfo-bin python3-libvirt python3-lxml qemu-utils virtinst
			;;
		opensuse|opensuse-leap)
			echo sudo zypper install -y ansible
			sudo zypper install -y ansible
			;;
		*)
			echo "${ID} not supported, please install manually"
			exit 1
			;;
	esac
	if [[ "$?" -ne 0 ]]; then
		echo "Something went wrong, sorry."
		exit 1
	fi
	echo "Continuing with Ansible playbook!"
fi

if [[ -z "$(ls -1 "${DIR}/roles/ansible-role-virt-infra/")" ]]; then
	echo "Role git submodule not found, pulling now.."
	git submodule init
	git submodule update
fi

exec ansible-playbook "${DIR}/virt-infra.yml" ${@}
