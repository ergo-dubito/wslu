#!/usr/bin/env bash
ORI_PATH="$(pwd)"

if [[ ! -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
	echo "Your distro do not support WSL Interopability. Installation Aborted."
	exit 1
fi

cat << EOF
WSLU
---------------
Windows 10 Linux Subsystem Utilities
EOF

distro="$(cat /etc/os-release | head -n1 | sed -e 's/NAME="//g')"
if [[ "$distro" == Ubuntu* ]]; then
	distro="ubuntu"
elif [[ "$distro" == *Debian* ]]; then
	distro="debian"
elif [[ "$distro" == *Kali* ]]; then
	distro="kali"
elif [[ "$distro" == openSUSE* ]]; then
	distro="opensuse"
elif [[ "$distro" == SLES* ]]; then
	distro="sles"
fi

echo "You are using: $distro"

echo "Installing dependencies...."
case "$distro" in
	'ubuntu')
		sudo apt install -y git build-essential bc ppa-purge wget unzip lsb-release
		;;
	'debian'|'kali')
		sudo apt install -y git build-essential bc wget unzip lsb-release
		;;
	'opensuse')
		sudo zypper -n install git bc lsb-release hostname wget unzip
		;;
	'sles')
		sudo zypper -n install git bc lsb-release wget unzip
		;;
esac

echo -e "\nWSL Interopability\n*********************"
cat /proc/sys/fs/binfmt_misc/WSLInterop
echo ""

echo -e "\ntesting powershell.exe..."
powershell.exe Get-Host
if [[ $? -eq 0 ]]; then
	echo "powershell.exe can be invoked."
else
	echo "powershell.exe failed to launch."
	exit 1
fi
ppep="`powershell.exe Get-ExecutionPolicy 2>&1 | tail -n1 | sed 's/\r$//'`"
echo -e "Powershell Execution Policy: $ppep"
if [[ "$ppep" = "Restricted" ]]; then
	cat << EOF
***************************************
               WARNING
***************************************
The execution policy for powershell.exe
is set to Restricted. You should set P-
owershell Execution Policy to Unrestri-
cted with a Powershell Prompt with Adm-
inistrator right:
   Set-ExecutionPolicy Unrestricted
Due to the limitation, it is not possi-
ble to invoke this command from Bash P-
rompt.
EOF
fi

echo -e "\ntesting cmd.exe..."
cmd.exe /c ver
if [[ $? -eq 0 ]]; then
	echo "cmd.exe can be invoked."
else
	echo "cmd.exe failed to launch."
	exit 1
fi

echo -e "\ntesting reg.exe..."
reg.exe /? 
if [[ $? -eq 0 ]]; then
	echo "reg.exe can be invoked."
else
	echo "reg.exe failed to launch."
	exit 1
fi

if [ `pwd | grep wslu` ]; then
	cd ../
	CURRENT_PATH="$(pwd)"
else
	git clone https://github.com/patrick330602/wslu.git 
	cd wslu
	CURRENT_PATH="$(pwd)"
fi

make
chmod +x $CURRENT_PATH/out/*

PATH="$CURRENT_PATH/src:$CURRENT_PATH/out:$PATH"  
git submodule init
git submodule update
extras/bats/libexec/bats tests/header.bats tests/wslsys.bats tests/wslusc.bats tests/wslupath.bats tests/wslfetch.bats 
PATH=$(getconf PATH)

for f in out/wsl*; do
	bname="$(basename $f)"
   		sudo ln -s $CURRENT_PATH/$f /usr/bin/$bname;
	echo "exec $f linked to /usr/bin/$bname";
done

sudo cp $CURRENT_PATH/src/mime/* /usr/lib/mime/packages/
[ -d /usr/share/wslu ] || sudo mkdir /usr/share/wslu 
sudo cp $CURRENT_PATH/src/etc/* /usr/share/wslu

sudo update-mime
sudo update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/wslview 100
sudo update-alternatives --install /usr/bin/www-browser www-browser /usr/bin/wslview 100

cat <<EOF
Installation Completed. 

Keep in remind that the installation method is different from installing from the package; DO NOT INSTALL PACKAGE VERSION AFTERWARDS. IT WILL BREAK YOUR INSTALLATION.
EOF

cd $ORI_PATH
