#!/bin/bash

UEFIDracutUpdate() { 
	# MAIN FUNCTION TO CREATE / UPDATE BOOTABLE EFI FILES
	#
	# Inputs are kernel versions to update the bootable efi files for (same format as $(uname -r))
	#	   If no (non-flag) inputs, all kernel versions will be updated 
	#
	# This can be called with no arguments and **should** figure them all out for you using information from current mounts.
	#	 ** It works well for me, but has only tested on configurations ive had on my system.  This means:
	#
	#	   FIlesystems: ext4 and ZFS (on root) have been tested. XFS will probably work too. 
	#		  brtfs probably wont work without a little modification (though maybe it will, idk)
	#
	#	   GPU: tested with nvidia GPU using nvidia (not nouveau) drivers. integrated graphics probably works too.
	#		  no special cases have been setup for AMD gpus.
	#
	#	   Other: LUKS should be handled appropriately. LVM and DM/MD RAID support has not been explicitly added.
	#
	#	   This code has been used successfully on most Fedora versions between 29 - 35. I imagine it works with others, but idk for sure.
	#
	# Including files in the initramfs: 3 directories will be automatically added to the initramfs (if they exist and contain files):
	#
	#	   /usr/local/bin/my-services - this is intended for files that support the custom systemd services
	#
	#	   /usr/local/bin/my-scripts - this is intended for general scripts, including functions you might find 
	#			useful should you end up in the dracut emergency shell for whatever reason.
	#
	#	/etc/systemd/personal - optional directory to store personal systemd services
	#
	#	Additionally, files needed for TPM2 decryption via TPM2_unseal, if tpm2-tss and tpm2-tools are installed
	#       The kernel modules in the "extra" folder (e.g., the ones used by ZFS and nvidia) are included and installed as well
	# 
	# NOTE: because this sets up the BOOT and ROOT devices in the kernel commandline, these devices need not be listed in /etc/fstab 
	# 	(nor, if using LUKS, in /etc/crypttab). However, any other devices should still be listed in /etc/{fs,crypt}tab.
	#	   if you do have them listed there is can, in some instances, lead to issues 
	#	   # example: it might ask you a 2nd time for a password to decrypt an already-decrypted drive
	#
	# FLAGS: unless you use either of the flags '-na' or '--no-ask', you will be asked for 
	#	   confirmation that the parameters it has determined automatically are correct.
	#	   if it is getting something wrong, it *should* accept any manual hardcoded entries of the following parameters:
	#	   ${luksUUID} ${bootDisk} ${rootDisk} ${rootFSType} ${rootFlags} ${usrDisk} ${usrFSType} ${usrFlags}
	# 
	# IMPORTANT NOTE: the variable 'kernelCmdline_static' is for all the "extra" kernel command line parameters you want to add.
	#		I left what Im using in there, as an example, though this likely wont be ideal for most systems.
	#		You should probably set this manually, or remove it / comment it out it entirely if you arent sure how to set up.
	#
	# IMPORTANT NOTE: I have found that things work best if you specify the root mount here (via kernel cmdline) and then specify any other zfs subvolume mounts (e.g., /home, /usr, whatever) in /etc/fstab. BUT, DO NOT SPECIFY THE ROOT MOUNT (/) ZFS DATASET IN /ETC/FSTAB. Specifying it both there and in the kernel cmdline breaks things.
	#
	# NOTE: most of these codes require root privileges to run.  I recommend, if possible, to run this as the root user (e.g., call 'su' then run it)
	#
	# MANUAL OVERRIDES: set variable useHardcodedZFSInfoFlag=1 to hard-code info about the root/boot disk, root FS/flags, luks UUID, ...
        #	 	 	    put these in bit just after the line containing `if (( ${useHardcodedZFSInfoFlag} == 1 )); then`
        # 			    note that if the flag is set to 0, these parameters should be determined automatically. This is just in case something goes wrong		    
	# 		    set usrMountFLag=1 to add usr mount disk info into kernel cmdline. not reccomended - specify this iin /etc/fstab instead
	# 		    set addTPMFlag={0,1} to not include / indlude the stuff needed to unseal a password from the TPM in the initramfs. If this flag is not manually set, default is to include it if both if tpm2-tss and tpm2-tools are installed 
	
	# set local variables

	local rootDisk="";
	local bootDisk="";
	local luksUUID="";
	local rootFSType="";
	local rootFlags="";
	local userResponse="";
	local noAskFlag="";
	local nn=""
 	local kernelCmdline_static="";
 	local kernelCmdline_static="";
 	local kernelCmdline_static="";
 	local dracutArgsExtra=""
 	local dracutArgsNoRescue=""
 	local dracutArgsRescue=""
	local mm=""
	local ll=""
	local usrDisk=""
	local usrFSType=""
	local usrFlags=""
	local usrMountFlag=""
	local kernelCmdline_spectreMeltdownMitigations=""
	local -a kernels
	local kernelsAvailable
	local -a dracutArgsExtraKmod
	local usrMountFlag=""
	local useHardcodedZFSInfoFlag=""
	local addTPMFlag=""

	useHardcodedZFSInfoFlag=0
	addTPMFlag=1
	usrMountFlag=0

	# disable selinux when running from a live os
	[[ -n "$(findmnt / | grep '/dev/mapper/live')" ]] && setenforce 0

	kernelCmdline_static='rd.driver.pre=tpm rd.timeout=60 rd.locale.LANG=en_US.UTF-8 rd.udev.log-priority=info rd.lvm=0 rd.lvm.conf=0 rd.md=0 rd.md.conf=0 rd.dm=0 rd.dm.conf=0 systemd.unified_cgroup_hierarchy gpt intel_pstate=per_cpu_perf_limits zswap.enabled=1 zswap.compressor=lzo-rle transparent_hugepages=madvise panic=60 init=/usr/lib/systemd/systemd rd.skipfsck pcie_bus_perf'

	kernelCmdline_spectreMeltdownMitigations='mitigations=auto spec_store_bypass_disable=auto noibrs noibpb spectre_v2=auto spectre_v2_user=auto pti=auto retbleed=auto tsx=auto' 
	
	dracutArgsExtra='--persistent-policy "by-id" --nostrip --hostonly-cmdline --early-microcode --nohardlink  --install /bin/vim --install /bin/tee --install /bin/seq --install /bin/find --install /bin/env --install /bin/wc --install /bin/tail --install /bin/head --force-add crypt --force-add dm --force-add zfs --force-add bash --force-add dracut-systemd --force-add systemd --force-add uefi-lib --force-add kernel-modules --force-add kernel-modules-extra --force-add iscsi --force-add plymouth --include /etc/iscsi/initiatorname.iscsi /etc/iscsi/initiatorname.iscsi --include /run/cryptsetup /run/cryptsetup'

	dracutArgsNoRescue='--hostonly --hostonly-i18n --hostonly-mode sloppy'
	dracutArgsRescue='--no-hostonly --no-hostonly-i18n -a "rescue"'


	# parse inputs
	noAskFlag=0
	kernelsAvailable="$(myFindInstalledKernels)"
	for nn in "${@}"; do
		[[ ${nn,,} =~ ^(.+\ )?-+no?-?a(sk)?(\ .+)?$ ]] && noAskFlag=1 && continue 
		echo "${kernelsAvailable}" | grep -q "${nn}" && kernels[${#kernels[@]}]="${nn}";
	done
	[[ -z "${kernels[*]}" ]] && kernels=( ${kernelsAvailable} )
	[[ -z "${kernels[*]}" ]] && echo "ERROR: no kernels could be found at /usr/lib/modules/*" >&2 && return 1

	if [[ -z ${addTPMFlag} ]]; then
		(( $(rpm -qa | grep -E 'tpm2\-((tools)|(tss))' | wc -l) == 2 )) && addTPMFlag=1 || addTPMFlag=0
	fi

	# ensure EFI is mounted
	cat /proc/mounts | grep -q "$(myFindEFIDev)" || mount "$(myFindEFIDev)" 2>&1

	# set parameters for root / boot / usr / luks disk information

	# example of manually set parameters. Note that the leading '[param]=' part is auto added, and doesnt need to be included (though can be)

	if (( ${useHardcodedZFSInfoFlag} == 1 )); then
		rootDisk='ZFS=FEDORA/ROOT'
		rootFSType='zfs'
		rootFlags='zfsutil,rw,relatime,xattr,posixacl'
		bootDisk='/dev/disk/by-id/<...>'
		luksUUID='luks-<...>'
		#usrDisk='ZFS=FEDORA/ROOT/USR'
		#usrFSType='zfs'
		#usrFlags='zfsutil,rw,relatime,xattr,posixacl'
	fi

	# automatically find parameters for root, boot and luks if they are empty (i.e., not hard-coded)

	[[ -z "${rootDisk}" ]] && [[ -n "$(mount -l | grep 'on / type' | sed -E s/'^(.*) on \/ type .*$'/'\1'/)" ]] && rootDisk="$(mount -l | grep 'on / type' | sed -E s/'^(.*) on \/ type .*$'/'\1'/)";
	
	[[ -z "${bootDisk}" ]] && bootDisk="$(myFindEFIDev)"
	
	[[ -z "${luksUUID}" ]] && luksUUID="$(myDevToID -u "$(echo "$(for nn in /dev/mapper/*; do [[ $(su -c 'cryptsetup status '"$nn"' 2>&1') != *"not found" ]] && su -c 'cryptsetup status '"$nn"' 2>/dev/null'; done)" | grep 'device: ' | sed -E s/'^.*(\/dev\/.*)$'/'\1'/)" | sed -E s/'^UUID='/'luks-'/ | grep -vE '^luks-$')"
	[[ -z "${luksUUID}" ]] && [[ -n "$(find /dev/mapper -name 'luks-*')" ]] && luksUUID="$(find /dev/mapper -name 'luks-*' | sed -E s/'^\/dev\/mapper\/'//)"
	(( $(echo "${luksUUID}" | wc -l) > 1 )) && (( ${useHardcodedZFSInfoFlag} == 0 )) && luksUUID="$(echo "${luksUUID}" | while read -r nn; do [[ -n "$(dmsetup table "${nn}" | grep 'logon')" ]] && echo "${nn}"; done)"

	[[ -z "${rootFSType}" ]] && [[ -n "$(mount -l | grep 'on / type' | sed -E s/'^.* on \/ type ([^ ]*) .*$'/'\1'/)" ]] && rootFSType="$(mount -l | grep 'on / type' | sed -E s/'^.* on \/ type ([^ ]*) .*$'/'\1'/)";
	[[ "${rootDisk}" == "ZFS="* ]] && rootFSType='zfs'
	[[ ${rootFSType#*=} =~ ^[Zz][Ff][Ss]$ ]] && rootFSType="zfs" && [[ -n "${rootDisk}" ]] && rootDisk="ZFS=$(echo "${rootDisk}" | sed -E s/'^[Zz][Ff][Ss]=(.*)'/'\1'/)"
	
	[[ -z "${rootFlags}" ]] && [[ -n "$(mount -l | grep 'on / type' | sed -E s/'^.* on \/ type [^ ]* \(([^\)]*)\).*$'/'\1'/)" ]] && rootFlags="$(mount -l | grep 'on / type' | sed -E s/'^.* on \/ type [^ ]* \(([^\)]*)\).*$'/'\1'/)";
	[[ ${rootFSType#*=} =~ ^[Zz][Ff][Ss]$ ]] && rootFlags="${rootFlags//'seclabel'/}" && [[ ! ${rootFlags#'rootFlags='} =~ ^(.+,)?zfsutil(,.+)?$ ]] && rootFlags="zfsutil,${rootFlags#'rootFlags='}"
	[[ -n "${rootFlags}" ]] && rootFlags="${rootFlags//,,/,}"

	# add in leading '[param]='

	[[ -n "${rootDisk}" ]] && rootDisk="root=$(myDevToID "${rootDisk#'root='}") rw";
	[[ -n "${bootDisk}" ]] && bootDisk="boot=$(myDevToID "${bootDisk#'boot='}")";
	[[ -n "${luksUUID}" ]] && luksUUID="${luksUUID,,}" && luksUUID="${luksUUID#'*luks.uuid='}" && luksUUID="luks-${luksUUID#'luks-'}" && luksUUID="rd.luks.uuid=${luksUUID#'*luks.uuid='}" # && [[ "${luksUUID}" == "rd.luks.uuid=UUID" ]] && luksUUID="";
	[[ -n "${rootFSType}" ]] && rootFSType="rootfstype=${rootFSType#'rootfstype='}";
	[[ -n "${rootFlags}" ]] && rootFlags="rootflags=${rootFlags#'rootflags='}";
	
	# same steps as above, but for a separate /usr mount (if it exists)

	[[ -z ${usrMountFlag} ]] && { [[ -n "$(cat /etc/mtab | grep ' /usr ')" ]] || [[ -n "${usrDisk}${usrFSType}${usrFlags}" ]]; } && usrMountFlag=1

	if (( $usrMountFlag == 1 )); then
		
		[[ -z "${usrDisk}" ]] && [[ -n "$(mount -l | grep 'on /usr type' | sed -E s/'^(.*) on \/usr type .*$'/'\1'/)" ]] && usrDisk="$(mount -l | grep 'on /usr type' | sed -E s/'^(.*) on \/usr type .*$'/'\1'/)";
	
		[[ -z "${usrFSType}" ]] && [[ -n "$(mount -l | grep 'on /usr type' | sed -E s/'^.* on \/usr type ([^ ]*) .*$'/'\1'/)" ]] && usrFSType="$(mount -l | grep 'on /usr type' | sed -E s/'^.* on \/usr type ([^ ]*) .*$'/'\1'/)";
		[[ "${usrDisk}" == 'ZFS='* ]] && usrFSType='zfs'	
		[[ ${usrFSType#*=} =~ ^[Zz][Ff][Ss]$ ]] && usrFSType="zfs" && [[ -n "${usrDisk}" ]] && usrDisk="ZFS=$(echo "${usrDisk}" | sed -E s/'^[Zz][Ff][Ss]=(.*)'/'\1'/)"
	
		[[ -z "${usrFlags}" ]] && [[ -n "$(mount -l | grep 'on /usr type' | sed -E s/'^.* on \/usr type [^ ]* \(([^\)]*)\).*$'/'\1'/)" ]] && usrFlags="$(mount -l | grep 'on /usr type' | sed -E s/'^.* on \/usr type [^ ]* \(([^\)]*)\).*$'/'\1'/)";
		[[ ${usrFSType#*=} =~ ^[Zz][Ff][Ss]$ ]] && [[ ! ${usrFlags#'mount.usrflags='} =~ ^(.+,)?zfsutil(,.+)?$ ]] && usrFlags="zfsutil,${usrFlags#'mount.usrflags='}"

		[[ -n "${usrDisk}" ]] && usrDisk="mount.usr=$(myDevToID "${usrDisk#'mount.usr='}")";
		[[ -n "${usrFSType}" ]] && usrFSType="mount.usrfstype=${usrFSType#'mount.usrfstype='}";
		[[ -n "${usrFlags}" ]] && usrFlags="mount.usrflags=${usrFlags#'mount.usrflags='}";
	fi

	# automatically make additions to the command line that are specific to using a nvidia gpu, using LUKS, and using ZFS

	rpm -qa | grep -q 'nvidia' && kernelCmdline_static+=" rd.driver.blacklist=nouveau rd.modprobe.blacklist=nouveau rd.driver.pre=nvidia rd.driver.pre=nvidia_uvm rd.driver.pre=nvidia_drm rd.driver.pre=drm rd.driver.pre=nvidia_modeset driver.blacklist=nouveau modprobe.blacklist=nouveau driver.pre=nvidia driver.pre=nvidia_uvm driver.pre=nvidia_drm driver.pre=drm driver.pre=nvidia_modeset nvidia-drm.modeset=1" && dracutArgsExtra+=" --include /etc/modprobe.d/nvidia.conf /etc/modprobe.d/nvidia.conf --install /etc/modprobe.d/nvidia.conf"
	
	[[ -n "${luksUUID}" ]] && kernelCmdline_static+=" rd.driver.pre=dm_crypt driver.pre=dm_crypt rd.luks.allow-discards rd.luks.timeout=60 rd.luks.options=${luksUUID}=allow-discards,no-read-workqueue,no-write-workqueue luks.allow-discards luks.timeout=60 luks.options=${luksUUID}=allow-discards,no-read-workqueue,no-write-workqueue"
		
	rpm -qa | grep -q 'zfs' && kernelCmdline_static+=" zfs.zfs_flags=0x1D8 zfs_ignorecache=1"

	[[ ${rootFSType#*=} =~ ^[Zz][Ff][Ss]$ ]] && kernelCmdline_static+=" rd.driver.pre=zfs driver.pre=zfs zfs_force=1" && dracutArgsExtra+=" --force-drivers zfs --nofsck"

	kernelCmdline_static+=" systemd.show_status rd.info rd.shell rd.driver.pre=vfat rhgb"

	kernelCmdline="${luksUUID} ${bootDisk} ${rootDisk} ${rootFSType} ${rootFlags} ${usrDisk} ${usrFSType} ${usrFlags} ${kernelCmdline_spectreMeltdownMitigations} ${kernelCmdline_static}";
	kernelCmdline="$(echo "${kernelCmdline}" | sed -E s/'^[ \t]*([^ \t].*[^ \t])[ \t]*$'/'\1'/ | sed -E s/'[ \t]+'/' '/g)";

	# include "extra" kernel modules
	for nn in "${!kernels[@]}"; do 
		[[ -d "/usr/lib/modules/${kernels[$nn]}" ]] && for mm in /usr/lib/modules/${kernels[$nn]}/extra/{,*/}*.{ko,ko.xz}; do
			[[ "${mm}" != *'*'* ]] && dracutArgsExtraKmod[$nn]+=" --include ${mm} ${mm} --install ${mm} --add-drivers $(echo "${mm##*/}" | sed -E s/'\.ko(\.xz)?'//) "; 
		done
	
		echo "${dracutArgsExtraKmod[$nn]}" | grep -q '.ko.xz' && dracutArgsExtraKmod[$nn]+=" --include /bin/xz /bin/xz --install /bin/xz --xz"; 
		
		dracutArgsExtraKmod[$nn]="${dracutArgsExtraKmod[$nn]//  / }"
	done

	# include stuff needed to use tpm2_unseal
	if (( ${addTPMFlag} == 1 )); then
		for mm in {/usr/bin/tpm2*,/usr/lib*/*tcti*,/usr/lib/systemd/systemd}; do
			dracutArgsExtra+=" --include ${mm} ${mm} --install ${mm}";
		done
	fi

	# include items from /usr/local/my-{scripts,services}
	for nn in /etc/systemd/personal/ /usr/local/bin/my-{scripts,services}/ /usr/local/bin/my-{scripts,services}/*.sh /etc/systemd/personal/*{.sh,.service}; do		
		[[ -e "${nn}" ]] && dracutArgsExtra+=" --include ${nn} ${nn}"
	done

	# include scripts from ~/.bash{rc,_aliases,_functions}
	for nn in {'.bashrc','.bash_functions','.bash_aliases'}; do
		[[ -f ~/${nn} ]] && dracutArgsExtra+=" --include $(realpath ~/${nn}) /usr/local/bin/homedir_scripts/${nn}"
	done

	# include [+install?] items from /etc/systemd/personal into both /etc/systemd/personal and /etc/systemd/system in the initrd
	if [[ -d "/etc/systemd/personal" ]]; then
		for nn in /etc/systemd/personal/*{.sh,.service}; do 
			[[ "${nn}" == *.service ]] && chmod -x "${nn}" || chmod +x "${nn}"
			\cp -f "${nn}" "/usr/lib/systemd/system/"; 

			dracutArgsExtra+=" --include ${nn} ${nn//\/personal\//\/system\/}";
			dracutArgsExtra+=" --include ${nn} ${nn//\/personal\//\/user\/}";

			#dracutArgsExtra="${dracutArgsExtra} --install ${nn}"; 			
			#[[ -e "${nn//\/personal\//\/system\/}" ]] && dracutArgsExtra="${dracutArgsExtra} --install ${nn//\/personal\//\/system\/}"; 
			#[[ -e "${nn//\/personal\//\/user\/}" ]] && dracutArgsExtra="${dracutArgsExtra} --install ${nn//\/personal\//\/user\/}"; 
		done
	fi

	# include /etc/hostid and /etc/machine-id
	( [[ -f /etc/hostid ]] && [[ -z $(find /etc/hostid -empty) ]] ) || hostid > /etc/hostid
	dracutArgsExtra+=" --include /etc/hostid /etc/hostid"
	[[ -f /etc/machine-id ]] && dracutArgsExtra+=' --include /etc/machine-id  /etc/machine-id'

	# manually specify boot stub location
	[[ -e "/usr/lib/systemd/boot/efi/linuxx64.efi.stub" ]] && dracutArgsExtra+=" --uefi-stub /usr/lib/systemd/boot/efi/linuxx64.efi.stub"

	# include extra dependencies, just in case
	dracutArgsExtra+=" --include /bin/sort /bin/sort --install /bin/sort"
	[[ -n "${luksUUID}" ]] && dracutArgsExtra+=" --include /sbin/cryptsetup /sbin/cryptsetup --install /sbin/cryptsetup"
	
	# Print info to screen about the parsed parameters. 
	# If '--no-ask' flag is set, pause for 10 seconds then continue. 
	# Otherwise, pause for a minute and request user feedback. 
	#	 Note: if no feedbback is received in 1 minute, the code will continue running.


	# ensure kernel module info is up to date
	sudo depmod -a

	sudo systemctl daemon-reload;
	#sudo systemctl daemon-reload --global --user;
	#sudo systemctl daemon-reload --global --system;
	#sudo systemctl daemon-reexec --global --system;


	UEFIBootUpdate	

	
	for ll in ${!kernels[@]}; do
		echo -e "\n\n||---------- THE FOLLOWING SETTINGS HAVE BEEN SET ----------||\n"
		(( $noAskFlag == 0 )) && echo -e "Do these look correct? \n----> An empty/null response or a response of y[es] will be taken as \"yes\" \n----> Any other non-empty response will be taken as \"no\" \n----> Timeout is 60 seconds. Default response upon timeout is \"yes\" \n"
		echo -e "  ${rootDisk} $( [[ -n "${rootDisk}" ]] && echo '\n  ' )${rootFSType}$( [[ -n "${rootFSType}" ]] && echo '\n  ' )${rootFlags}$( [[ -n "${rootFlags}" ]] && echo '\n  ' )${bootDisk}$( [[ -n "${bootDisk}" ]] && echo '\n  ' )${luksUUID}$( [[ -n "${luksUUID}" ]] && echo '\n  ' )${usrDisk}$( [[ -n "${usrDisk}" ]] && echo '\n  ' )${usrFSType}$( [[ -n "${usrFSType}" ]] && echo '\n  ' )${usrFlags}$( [[ -n "${usrFlags}" ]] && echo '\n' ) \nADDITIONAL DRACUT PARAMATERS: -fvM --uefi ${dracutArgsExtra} ${dracutArgsExtraKmod[$ll]} \n\nKERNEL COMMAND LINE: \n\n${kernelCmdline} \n";
	
		(( $noAskFlag == 0 )) && read -iE -t 60 -p "Response ( <null>/y[es] --> yes  |  anything else --> no ):  " userResponse && [[ -n "${userResponse}" ]] && [[ ! ${userResponse,,} =~ ^y(es)?$ ]] && [[ ! ${userResponse} =~ ^[\ \t]*$ ]] && return 1;
		(( $noAskFlag == 1 )) && echo "The code will proceed in 10 seconds..." && sleep 10;
		
		# shift efi files and ensure systemd and module info are up to date systemd
		UEFIBootUpdate --shift-efi "${kernels[$ll]}"
	
		# generate rescue, if needed	
		UEFIBootUpdate --check-rescue "${kernels[$ll]}" || { su -c 'dracut -fvM --uefi --kernel-cmdline "'"${kernelCmdline}"' rd.cmdline=ask" --kver '"${kernels[$ll]}"' '"${dracutArgsExtra}"' '"${dracutArgsRescue}"' '"${dracutArgsExtraKmod[$ll]}"; sleep 2; sync; UEFIBootUpdate --shift-efi-rescue "${kernels[$ll]}"; }
		# generate EFI executable boot image with dracut
		su -c 'dracut -fvM --uefi --kernel-cmdline "'"${kernelCmdline}"'" --kver '"${kernels[$ll]}"' '"${dracutArgsExtra}"' '"${dracutArgsNoRescue}"' '"${dracutArgsExtraKmod[$ll]}";


		
	done

	sleep 2; sync

	UEFIBootUpdate	

}
																

UEFIBootUpdate() { 
	# Generates new EFI boot menu entries for new .efi files detected in <ESP_MOUNT_POINT>/**/Linux/linux-*.efi
	#
	# 	FLAGS: use flag '--shift-efi' to instead rotate the current efi files (for a given kernel) into "*_OLD.efi" versions.
	#		Existing "*_OLD.efi" versions will be overwritten. 
	#		NOTE: this flag must be the 1st input to UEFIBootUpdate. 
	#
	# 		---------- NOTES ----------
	#
	#	BACKUPS: By default, the current .efi file (for a given kernel) will be copied into "*_RESCUE.efi" to serve as a working backup IFF this file doesnt yet exist. 
	#		Additionally, before anything is deleted, the entire ESP will be copied to <ESP_MOUNT_POINT>_BACKUP 
	#
	#	FILE LOCATIONS: All efi files on the ESP are automatically consolidated into <ESP_MOUNT_POINT>/Linux
	#		If there are files  of the same backup type (standard, _OLD, _RESCUE) for a given kernel in multiple locations 
	#		(e.g., <ESP_MOUNT_POINT>/Linux and <ESP_MOUNT_POINT>/EFI/Linux) the newest will be copied and moved to <ESP_MOUNT_POINT>/Linux, and the rest will be deleted
	#	
	#	EXTRA INPUTS: Any additional inputs are interpreted as a list of valid kernels to operate on, formatted as in $(uname -r). 
	#		If no (valid) kernels are given then there are no restrictions for which kernel's efi files to operate on.
	#		This is particularly important with the '--shift-efi' option to avoid shifting an EFI file into the "*_OLD.efi" group if you arent planning to regenerate the bootable EFI file for that kernel
	#
	# 	WARNING: This code will not work correctly if the "BUILD-ID" is included in the .efi file names. 
	#		It will, however, work with or without the "MACHINE-ID" included in the .efi file names.

	local nn="";
	local mm="";
	local efiMount="";
	local efiDev0="";
	local efiDev="";
	local efiPart="";
	local efiPartUUID=""
	local efiFileList=""; 
	local -a efiFileListA ;
	local efiFileListTemp=""
	local efiFileListTemp0=""; 
	local -a efiFileListTemp0a;
	local -a efiFileListTempOLDa;
	local -a efiFileListTempRESCUEa;
	local efiFileListTempKeep="";
	local kverKernel="";
	local -a kverKernelA
	local -a kverKernelValid;
	local shiftEFIFlag=0;
	local checkRescueFlag=0;

	# remove duplicate and nonexistent entries
	UEFIAutoRemove

	# parse inputs

	for nn in "${@}"; do
		[[ "${nn,,}" =~ ^-+s(hift)?-?(e(fi)?)?$ ]] && shiftEFIFlag=1 && continue
		[[ "${nn,,}" =~ ^-+s(hift)?-?(e(fi)?)?-r(escue)?$ ]] && shiftEFIFlag=2 && continue
		[[ "${nn,,}" =~ ^-+c(heck)?-?(r(escue)?)?$ ]] && checkRescueFlag=1 && continue
		{ [[ -d "/usr/lib/modules/${nn}" ]] || [[ "${nn}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\-[0-9]+\.fc[0-9]+\..+$ ]]; } && kverKernelValid[${#kverKernelValid[@]}]="${nn}"
	done

	# get various device + partition info

	efiMount="$(myFindEFIMount)"
	efiDev0="$(myDevToID "$(myFindEFIDev)")"
	efiPart="${efiDev0##*-part}"
	efiDev="${efiDev0%-part*}"
	efiPartUUID="$(myDevToID --type=partuuid "${efiDev0}")"
	efiPartUUID="${efiPartUUID##*/}"

	echo "${efiDev}" | grep -q 'nvme' && efiDev="${efiDev%p}"
	
	echo -e "\nThe following properties have been identified for the EFI system partition: \n	Mount Point: \t ${efiMount} \n	Device Name: \t ${efiDev} \n	Partition:	 \t ${efiPart} \n"
	sleep 1

	efiFileList="$(su -c 'find '"${efiMount}"' -type f -name '"'"'linux-*.efi'"'" | grep -E '\/Linux\/[^\/]+$' | sort -V)"
	[[ -z "${efiFileList}" ]] && echo "No .efi files found on the EFI Partition at '${efiMount}/EFI/Linux/linux-*.efi'" >&2 && return 1

	kverKernel="$(echo "$(echo "${efiFileList}" | sed -E s/'^.*\/linux-(.*'"$(uname -m)"').*\.efi$'/'\1'/ | sort -u; printf '%s\n' "${kverKernelValid[@]}"; myFindInstalledKernels)" | sort -u | grep -E '[0-9a-zA-Z]+')"

	#(( ${#kverKernelValid[@]} > 0 )) && kverKernel="$(echo "${kverKernel}" | while read -r nn; do for mm in "${kverKernelValid[@]}"; do echo "${nn}" | grep -q "${mm}" && echo "${nn}";  done; done)"
	(( ${#kverKernelValid[@]} > 0 )) && kverKernel="$(echo "${kverKernel}" | grep -E '(('"$(echo ${kverKernelValid[@]} | sed -E s/' '/')|('/g)"'))')"

	(( ${checkRescueFlag} == 1 )) && (( $(echo "${kverKernel}" | wc -l) > 1 )) && echo "WARNING: the --check-rescue flag can only be evaluated for a single kernel. Multiple kernels were specified. The FIRST kernel listed ($(echo "${kverKernel}" | head -n 1)) will be evaluated" >&2

	mapfile -t kverKernelA < <(echo "${kverKernel}" | grep -E '[0-9a-zA-Z]+')
	kverKernelA=("${kverKernelA[@]}")

	if { (( ${shiftEFIFlag} > 0 )) || (( ${checkRescueFlag} == 1 )); }; then
		for nn in "${kverKernelA[@]}"; do
                	efiFileListTemp="$(echo "${efiFileList}" | grep "${nn}")"
                	efiFileListTemp0="$(echo "${efiFileListTemp}" | grep -E "${nn}(-[0-9a-zA-Z]{32})?\.efi")"

                	# Copy into _OLD if shiftEFIFlag=1
                	# skip if no "current" EFI file found for given kernel
                	if (( $shiftEFIFlag > 0 )) && [[ -n ${efiFileListTemp0} ]]; then
				echo "${efiFileListTemp0}" | while read -r efiFileListTemp00; do 
					(( $shiftEFIFlag == 1 )) && su -c '\mv -f '"${efiFileListTemp00}"' '"${efiFileListTemp00//$(uname -m)/$(uname -m)_OLD}" && echo "Moving ${efiFileListTemp00} into ${efiFileListTemp00//$(uname -m)/$(uname -m)_OLD} \n" >&2
					(( $shiftEFIFlag == 2 )) && su -c '\mv -f '"${efiFileListTemp00}"' '"${efiFileListTemp00//$(uname -m)/$(uname -m)_RESCUE}" && echo "Moving ${efiFileListTemp00} into ${efiFileListTemp00//$(uname -m)/$(uname -m)_RESCUE} \n" >&2
				done
			fi
			
		       	if (( ${checkRescueFlag} == 1 )); then
				echo "${efiFileListTemp}" | grep -q "_RESCUE" && return 0 || return 1
			fi
			
		done
		return
	fi

	# make backup of ESP
	sudo rsync -a "${efiMount}" "${efiMount}_BACKUP"

	# consolidate files into "${efiMount}/EFI/Linux"
	# if multiple versions exist (*.efi, *_OLD.efi, *_RESCUE.efi) for a given kernel, keep the newest
	for nn in "${kverKernelA[@]}"; do
		echo "${nn}" | grep -q -E '[0-9a-zA-Z]+' || continue

		efiFileListTemp="$(echo "${efiFileList}" | grep "${nn}")"
		efiFileListTemp="$(echo "${efiFileListTemp}" | grep "${efiMount}/EFI/Linux"; echo "${efiFileListTemp}" | grep -v "${efiMount}/EFI/Linux")"

		mapfile -t efiFileListTemp0a < <(echo "${efiFileListTemp}" | grep -E "${nn}(-[0-9a-zA-Z]{32})?\.efi")
		mapfile -t efiFileListTempOLDa < <(echo "${efiFileListTemp}" | grep -E "${nn}[^\-]*_OLD(-[0-9a-zA-Z]{32})?\.efi")
		mapfile -t efiFileListTempRESCUEa < <(echo "${efiFileListTemp}" | grep -E "${nn}[^\-]*_RESCUE(-[0-9a-zA-Z]{32})?\.efi")
		mapfile -t efiFileListTempOTHERa < <(echo "${efiFileListTemp}" | grep -v -E "${nn}(-[0-9a-zA-Z]{32})?\.efi" | grep -v -E "${nn}[^\-]*_OLD(-[0-9a-zA-Z]{32})?\.efi" | grep -v -E "${nn}[^\-]*_RESCUE(-[0-9a-zA-Z]{32})?\.efi")

		if (( ${#efiFileListTemp0a[@]} > 1 )); then
			efiFileListTempKeep="${efiFileListTemp0a[0]}"
		
			if (( ${#efiFileListTemp0a[@]} > 1 )); then
				echo "Duplicate \"STANDARD\" entries for kernel ${nn}..." >&2
				printf '%s\n' "${efiFileListTemp0a[@]}" | tail -n +2 | while read -r mm; do 
					echo "Deleting ${mm}" >&2
				   	su -c '[[ -f '"${mm}"' ]] && rm -f '"${mm}"
				done
			fi

			[[ "${efiFileListTempKeep}" =~ ^${efiMount}\/EFI\/Linux\/linux-[^\/]+\.efi$ ]] || ( su -c '\mv -f '"${efiFileListTempKeep}"' '"${efiMount}/EFI/Linux/${efiFileListTempKeep##*/}" && echo "Moved ${efiFileListTempKeep} to ${efiMount}/EFI/Linux/${efiFileListTempKeep##*/}" >&2 )
			echo "" >&2
		fi

		if (( ${#efiFileListTempOLDa[@]} > 1 )); then
			efiFileListTempKeep="${efiFileListTempOLDa[0]}"
		
			if (( ${#efiFileListTempOLDa[@]} > 1 )); then
				echo "Duplicate \"*_OLD.efi\" entries for kernel ${nn}..." >&2
				printf '%s\n' "${efiFileListTempOLDa[@]}" | tail -n +2 | while read -r mm; do 
					echo "Deleting ${mm}" >&2
				   	su -c '[[ -f '"${mm}"' ]] && rm -f '"${mm}"
				done
			fi
		
			[[ "${efiFileListTempKeep}" =~ ^${efiMount}\/EFI\/Linux\/linux-[^\/]+\.efi$ ]] || ( su -c '\mv -f '"${efiFileListTempKeep}"' '"${efiMount}/EFI/Linux/${efiFileListTempKeep##*/}" && echo "Moved ${efiFileListTempKeep} to ${efiMount}/EFI/Linux/${efiFileListTempKeep##*/}" >&2 )
			echo "" >&2
		fi

		if (( ${#efiFileListTempRESCUEa[@]} > 1 )); then
			efiFileListTempKeep="${efiFileListTempRESCUEa[0]}"

			if (( ${#efiFileListTempRESCUEa[@]} > 1 )); then
				echo "Duplicate \"*_RESCUE.efi\" entries for kernel ${nn}..." >&2
				printf '%s\n' "${efiFileListTempRESCUEa[@]}" | tail -n +2 | while read -r mm; do
					echo "Deleting ${mm}" >&2
				   	su -c '[[ -f '"${mm}"' ]] && rm -f '"${mm}"
				done
			fi

			[[ "${efiFileListTempKeep}" =~ ^${efiMount}\/EFI\/Linux\/linux-[^\/]+\.efi$ ]] || ( su -c '\mv -f '"${efiFileListTempKeep}"' '"${efiMount}/EFI/Linux/${efiFileListTempKeep##*/}" && echo "Moved ${efiFileListTempKeep} to ${efiMount}/EFI/Linux/${efiFileListTempKeep##*/}" >&2 )
			echo "" >&2
		fi

		if (( ${#efiFileListTempOTHERa[@]} > 1 )); then
			efiFileListTempKeep="${efiFileListTempOTHERa[0]}"
		
			if (( ${#efiFileListTempOTHERa[@]} > 1 )); then
				echo "Duplicate \"OTHER\" entries for kernel ${nn}..." >&2
				printf '%s\n' "${efiFileListTempOTHERa[@]}" | tail -n +2 | while read -r mm; do 
					echo "Deleting ${mm}" >&2
				   	su -c '[[ -f '"${mm}"' ]] && rm -f '"${mm}"
				done
			fi

			[[ "${efiFileListTempKeep}" =~ ^${efiMount}\/EFI\/Linux\/linux-[^\/]+\.efi$ ]] || ( su -c '\mv -f '"${efiFileListTempKeep}"' '"${efiMount}/EFI/Linux/${efiFileListTempKeep##*/}" && echo "Moved ${efiFileListTempKeep} to ${efiMount}/EFI/Linux/${efiFileListTempKeep##*/}" >&2 )
			echo "" >&2
		fi

	done

	UEFIAutoRemove

	# regenerate efiFileList
	efiFileList="$(su -c 'find '"${efiMount}"' -type f -name '"'"'linux-*.efi'"'" | grep -E '\/EFI\/Linux\/linux-[^\/]+\.efi$' | sort -V)";
	[[ -z "${efiFileList}" ]] && echo "No .efi files found on the EFI Partition at '${efiMount}/EFI/Linux/linux-*.efi'" >&2 && return 1

	# sort efiFileList(-[0-9a-zA-Z]{32})?\.efi"
	efiFileList="$(cat <(echo "${efiFileList}" | grep -v '_RESCUE' | grep -v '_OLD' | grep -v -E "$(uname -m)"'(-[0-9a-zA-Z]{32})?\.efi' | sort -V) <(echo "${efiFileList}" | grep '_RESCUE' | sort -V) <(echo "${efiFileList}" | grep '_OLD' | grep -v '_RESCUE' | sort -V) <(echo "${efiFileList}" | grep -v '_OLD' | grep -v '_RESCUE'  | grep -E "$(uname -m)"'(-[0-9a-zA-Z]{32})?\.efi' | sort -V))"

	mapfile -t efiFileListA < <(echo "${efiFileList}")

	# update efi boot entries with efibootmgr
	for nn in "${efiFileListA[@]}"; do
		efibootmgr -v 2>&1 | grep "${efiPartUUID}" | grep -q "$(echo -n 'File('"${nn##"$efiMount"}" | sed -E s/'\/'/'\\\\'/g)" || { echo "Adding boot entry for ${nn}" >&2 && su -c 'efibootmgr -c -d '"${efiDev}"' -p '"${efiPart}"' -l '"$(echo -n "${nn##"$efiMount"}")"' -L '"Fedora-EFI_$(echo -n "${nn##*linux-}" | sed -E s/'^([^-]*-[^-]*)(-[0-9a-zA-Z]{32})?\.efi$'/'\1'/)"' 1>/dev/null'; }
	done

	# remove duplicate and non-existant entries
	UEFIAutoRemove

	# auto sort efi entries
	UEFIBootOrderAutoSort

	# print new boot order (unless using --shift-efi)
	UEFIBootOrderList -v


}

UEFIBootOrderAutoSort() {

	local efiMount
	local efiFileList
	local -a efiFileListA
	local efiMenu
	local bootOrderInd

	efiMount="$(myFindEFIMount)"
	efiFileList="$(su -c 'find '"${efiMount}"' -type f -name '"'"'linux-*.efi'"'" | grep -E '\/Linux\/[^\/]*$' | sort -Vr)"
	efiFileList="$(cat <(echo "${efiFileList}" | grep -v '_RESCUE' | grep -v '_OLD' | grep -E "$(uname -m)"'(-[0-9a-zA-Z]{32})?\.efi' | sort -Vr) <(echo "${efiFileList}" | grep '_OLD' | grep -v '_RESCUE' | sort -Vr) <(echo "${efiFileList}" | grep '_RESCUE' | sort -Vr) <(echo "${efiFileList}" | grep -v '_RESCUE' | grep -v '_OLD' | grep -v -E "$(uname -m)"'(-[0-9a-zA-Z]{32})?\.efi' | sort -Vr) | sed -E s/'^\/efi'//)"
	mapfile -t efiFileListA < <(echo "${efiFileList}")

	efiMenu="$(efibootmgr -v | grep -E '^Boot[0-9a-fA-F]{4}')"
	efiMenu="${efiMenu//\\/\/}"
	bootOrderInd="$(echo "$(efibootmgr | grep -E '^BootOrder\:' | sed -E s/'^BootOrder\: '// | myuniq | sed -E s/','/'\n'/g)")"

	bootOrderInd="$(echo $(echo "$(for nn in "${efiFileListA[@]}"; do echo "${efiMenu}" | grep "${nn}" | sed -E s/'^Boot([0-9A-Fa-f]{4}).*$'/'\1'/; done && echo "${bootOrderInd}")" | my-uniq) | sed -E s/' '/'\,'/g)"

	su -c 'efibootmgr -o '"${bootOrderInd}"' 2>&1 1>/dev/null'

}

UEFIBootOrderList() { 
	# prints a "nice" list of active and inactive boot entries. Basically, a pretty alternative to the output of efibootmgr
	#
	# FLAGS
	#
	# use flag '-v' or '--verbose' to give additional output (including info on what disk/partition/file the boot entry represents)
	#
	# use flag '-m' or '--mod[ify]' to reorder the default boot list order
	# This will cause the boot list to be displayed, after which you will be interactively asked to choose entries to:
		#	a) deactivate   	b) send to the top of the active list
	#	  NOTE: you can give multiple numbers as input. e.g. giving "1 5 3" for (b) would reorder the boot entries so that #1 is first, #5 is second, #3 is third, and everything else is in the same order behind these 

	local nn="";
	local EFImenu="";
	local -a bootOrderVal;
	local -a bootOrderIsActive;
	local -a bootOrderInd;
	local -a bootOrderReMap;
	local activeIndList="";
	local inactiveIndList="";
	local bootCurTemp="";
	local kk=0;
	local kk1=0;

	mapfile -t bootOrderInd < <(echo "$(efibootmgr | grep -E '^BootOrder\:' | sed -E s/'^BootOrder\: '// | myuniq | sed -E s/','/'\n'/g)")
	[[ ${*,,} =~ ^(.+ )?-+no?-?d(edup)?( .+)?$ ]] || su -c 'efibootmgr -o '"$(echo ${bootOrderInd[@]} | sed -E s/' '/','/g)"' 2>&1 1>/dev/null'
	EFImenu="$(efibootmgr $( [[ ${*,,} =~ ^(.+ )?-+v(erbose)?( .+)?$ ]] && echo '-v' ) | grep -E '^Boot[0-9a-fA-F]{4}')"

	kk=0
	for nn in "${bootOrderInd[@]}"; do
		bootCurTemp="$(echo "${EFImenu}" | grep --color=auto -E '^Boot'"${nn}"'[\* ] ')"
		bootOrderVal[$kk]="$(echo "${bootCurTemp}" | sed -E s/'^Boot[^\* ]*[\* ] (.*)$'/'\1'/)";	
		[[ "${bootCurTemp%% *}" == *\* ]] && bootOrderIsActive[$kk]=1 && activeIndList="${activeIndList} ${kk}"
			[[ ! "${bootCurTemp%% *}" == *\* ]] && bootOrderIsActive[$kk]=0 && inactiveIndList="${inactiveIndList} ${kk}" 
		((kk++))
	done

	echo -e "\n||----------------------------------------------------------||\n||-------------------- EFI BOOT ENTRIES --------------------||\n||----------------------------------------------------------||\n"
	echo -e "\n||------------------------- ACTIVE -------------------------||\n"

	kk1=0
	for kk in ${activeIndList}; do
		echo "(${kk1}) ${bootOrderVal[$kk]}"
		bootOrderReMap[$kk1]=${kk}
		((kk1++))
	done

	echo -e "\n\nNOTE: The above list is ordered by boot priority. The 1st listing is the \"default\" boot entry. \n	  The default behavior is to try these in order until a valid/working boot image is found."

	echo -e "\n\n||------------------------ INACTIVE ------------------------||\n"

	for kk in ${inactiveIndList}; do
		echo "(${kk1}) ${bootOrderVal[$kk]}"
		bootOrderReMap[$kk1]=${kk}
		((kk1++))
	done;
	[[ ${*,,} =~ ^(.+ )?-+m(od(ify)?)?( .+)?$ ]] || echo -e "\n\nNOTE: To activate/deactivate/reorder efi boot menu entries, run 'UEFIBootOrderList -m [-v]'\n\n"

	if [[ ${*,,} =~ ^(.+ )?-+m(od(ify)?)?( .+)?$ ]]; then
		local userResponse=""

		echo -e "\nRespond to the following questions with a {space,comma,newline}-seperated list of indicies from the above listing. \nThe index is the number shown in (#) at the start of each line. \nNote: Non-numeric characters (except for spaces, commas and newlines) will be filtered out of the response and ignored. \n\nTimeout is 30 seconds\n"
		
		read -ie -t 60 -p "Select boot entries to deactivate: " userResponse
		
		userResponse="$(echo "${userResponse}" | sed -E s/'[ \t\n\,]+'/' '/g | sed -E s/'[^0-9 ]'//g | sed -E s/' +'/' '/g | sed -E s/'^ $'//)"

		if [[ -n "${userResponse}" ]]; then
			for kk in ${userResponse}; do
				(( $kk < ${#bootOrderReMap[@]} )) && su -c 'efibootmgr -A -b '"${bootOrderInd[${bootOrderReMap[$kk]}]}"' 2>&1 1>/dev/null'
			done
		fi

		userResponse=""
		read -ie -t 60 -p "Select boot entries to place at the top of the \"active\" list: " userResponse
		
		userResponse="$(echo "${userResponse}" | sed -E s/'[ \t\n\,]'/' '/g | sed -E s/'[^0-9 ]'//g | sed -E s/' +'/' '/g | sed -E s/'^ $'//)"

		if [[ -n "${userResponse}" ]]; then
			local bootOrderNew=""
			local -a bootOrderNewTemp
			bootOrderNewTemp=("${bootOrderInd[@]}")
			for kk in ${userResponse}; do
				if (( ${kk} < ${#bootOrderReMap[@]} )); then
					su -c 'efibootmgr -a -b '"${bootOrderInd[${bootOrderReMap[$kk]}]}"' 2>&1 1>/dev/null'			
					bootOrderNew="${bootOrderNew} ${bootOrderInd[${bootOrderReMap[$kk]}]}"
					bootOrderNewTemp[${bootOrderReMap[$kk]}]=""
				fi
			done
			
			bootOrderNew="$(echo "${bootOrderNew} ${bootOrderNewTemp[*]}" | sed -E s/'[ \t\n\,]+'/' '/g | sed -E s/'^ *([^ ].*[^ ]) *$'/'\1'/ | myuniq | sed -zE s/'\n'/','/g | sed -E s/'^(.*[^.])\,+$'/'\1\n'/)"
			su -c 'efibootmgr -o '"${bootOrderNew%,}"' 2>&1 1>/dev/null'
		fi

		echo -e "\n\n||----------------- NEW BOOT MENU ORDERING -----------------|| \n\n"
		UEFIBootOrderList $( [[ ${*,,} =~ ^(.+ )?-+v(erbose)?( .+)?$ ]] && echo '-v' )
	fi
}


myuniq() {
	# returns unique elements in a list
	# replacement for 'uniq', which is straight broken on my system
	# input should be list separated by newlines/spaces/tabs/commas
	# output is newline-separated list

	local inAll="";
	local outCur="";

	(( ${#} > 0 )) && inAll="$(printf '%s\n' "${@}")" || inAll="$(cat <&0 | sed -E s/'[ \t\,]+'/'\n'/g)"
	while [[ -n "${inAll}" ]]; do
		outCur="$(echo "${inAll}" | head -n 1)"
		inAll="$(echo -n "${inAll}" | grep -v -F "${outCur}")"
		echo "${outCur}"
	done

}


my-uniq() {
	# returns unique elements in a list
	# replacement for 'uniq', which is straight broken on my system
	# input should be list separated by newlines/spaces/tabs/commas
	# output is newline-separated list

	local inAll=""
	local outAll=""

	(( $# > 0 )) && inAll="${*}" || inAll="$(cat <&0)"
	inAll="$( echo -n "${inAll}" | sed -zE s/'[\ \,\t]'/'\n'/g | sed -zE s/'\n+'/'\n'/g )"

	while [[ -n "${inAll}" ]]; do
		outAll="$( echo "${outAll}" && echo "${inAll}" | head -n 1 )"
		inAll="$( echo -n "${inAll}" | grep -v -F "$(echo -n "${inAll}" | head -n 1)" )"
	done

	outAll="$(echo "${outAll}" | grep -E '^.+$')"
	echo "${outAll}"
}


UEFIKernelPostInstallSetup() {
        # setup kernel post install script to automatically re-make the bootable efi files after a kernel update

        cat<<'EOF' | tee "/etc/kernel/postinst.d/postinst_dracutUEFI"
#!/usr/bin/bash 

inst_kern="${1}"
[[ -e "/usr/lib/modules/${inst_kern}" ]] || inst_kern="$(/bin/ls -1 /usr/lib/modules | /bin/sort -V | /bin/tail -n 1)"

/bin/systemctl daemon-reload

# start building nvidia kernel modules
/bin/rpm -qa | /bin/grep -q 'akmod' && /bin/systemctl restart --no-block akmods@${inst_kern}.service >/dev/null 2>&1
/bin/sleep 1 

# extract full vmlinux kernel from vmlinuz and symlink it into modules/build. Depending how it was configured, some parts of zfs need vmlinux here
/usr/src/kernels/${inst_kern}/scripts/extract-vmlinux /lib/modules/${inst_kern}/vmlinuz > /lib/modules/${inst_kern}/vmlinux
/bin/chmod +x /lib/modules/${inst_kern}/vmlinux
/bin/ln -s /lib/modules/${inst_kern}/vmlinux /lib/modules/${inst_kern}/build/vmlinux
/bin/ln -s /lib/modules/${inst_kern}/vmlinuz /lib/modules/${inst_kern}/build/vmlinuz
/bin/sleep 3 

# build all dkms modules for the new kernel (including zfs)
/sbin/dkms autoinstall --kernelver "${inst_kern}" 2>&1 1>/dev/null
/bin/sleep 3 

/bin/systemctl daemon-reload && /sbin/depmod -a 

EOF

        cat << EOF | tee -a "/etc/kernel/postinst.d/postinst_dracutUEFI"

. "$(realpath "${BASH_SOURCE[0]}")" && UEFIDracutUpdate --no-ask "\${inst_kern}"

exit 0

EOF

        chmod 755 "/etc/kernel/postinst.d/postinst_dracutUEFI"

}


myFindEFIDev() {
	# attempts to automatically find the block device the system EFI partition is on
	# scans /etc/fstab and /etc/mtab for any vfat filesystem mounts on /boot, /boot/efi, or /efi
	
	local -a efiDev;
	local nn=0;
	local kk;

	mapfile -t efiDev < <(cat <(cat /etc/fstab /etc/mtab /proc/mounts | grep 'vfat' | grep -E '[ \t](((\/[Bb][Oo][Oo][Tt])?\/[Ee][Ff][Ii])|\/[Bb][Oo][Oo][Tt])[ \t]' | sed -E s/'^[ \t]*([^ \t]*)[ \t].*$'/'\1'/) <(findmnt -n -o SOURCE "$(bootctl -p)") | sort -u)

	for nn in ${!efiDev[@]}; do
		[[ ${efiDev[$nn]} == 'UUID='* ]] && efiDev[$nn]="/dev/disk/by-uuid/${efiDev[$nn]#UUID=}" 
		
		[[ -e "${efiDev[$nn]}" ]] || efiDev[$nn]=""

		[[ ${efiDev[$nn]} =~ ^\/dev\/disk\/by-.+\/.+$ ]] && efiDev[$nn]="$(realpath "${efiDev[$nn]}")" 
		[[ ${efiDev[$nn]} =~ ^\/dev\/disk\/by-.+\/.+$ ]] && efiDev[$nn]="$(ls -ld1 /dev/disk/by-*/* | grep "${efiDev[$nn]}" | sed -E s/'^.*\.\.\/\.\.\/(.*)$'/'\/dev\/\1'/)"
	done

	mapfile -t efiDev < <(printf '%s\n' "${efiDev[@]}" | grep -E '^.+$' | sort -u)

	(( ${#efiDev[@]} == 0 )) && echo -e "WARNING: The EFI Block device could not be determined. \n		 Returning NULL output." >&2
	(( ${#efiDev[@]} > 1 )) && echo -e "WARNING: The EFI Block device could not be uniquely determined. \n		 Returning ALL possible EFI block devices found." >&2

	printf '%s\n' "${efiDev[@]}"

	(( ${#efiDev[@]} == 1 )) && return 0 || return 1

}


myFindEFIMount() {
	# finds the mount point for the ESP partition
	local efiMount="";

	efiMount="$(cat <(cat /etc/fstab /etc/mtab /proc/mounts | grep 'vfat' | grep -E '[ \t](((\/[Bb][Oo][Oo][Tt])?\/[Ee][Ff][Ii])|\/[Bb][Oo][Oo][Tt])[ \t]' | sed -E s/'^[ \t]*[^ \t]*[ \t]*([^ \t]*)[ \t].*$'/'\1'/) <(bootctl -p) | sort -u)"
	
	if ! ( [[ "$(echo "${efiMount}" | wc -l)" == '1' ]] && [[ -d "${efiMount}" ]] ); then
		if ( [[ -d "/efi/EFI/Linux" ]] || [[ -d "/efi/Linux" ]] ) && [[ -z "$(mountpoint "/efi" | grep 'not')" ]]; then
			efiMount="/efi";
		elif ( [[ -d "/boot/efi/EFI/Linux" ]] || [[ -d "/boot/efi/Linux" ]] ) && [[ -z "$(mountpoint "/boot/efi" | grep 'not')" ]]; then
			efiMount="/boot/efi";
		elif ( [[ -d "/boot/EFI/Linux" ]] || [[ -d "/boot/Linux" ]] ) && [[ -z "$(mountpoint "/boot" | grep 'not')" ]]; then
			efiMount="/boot";
		elif [[ -d "/efi" ]]; then
			efiMount="/efi";
		elif [[ -d "/boot/efi" ]]; then
			efiMount="/boot/efi";
		elif [[ -d "/boot" ]]; then
			efiMount="/boot";
		else
			efiMount="$(bootctl -p)"
		fi
	fi

	su -c 'efiMount='"${efiMount}"'; ( [[ -z "${efiMount}" ]] || ! [[ -d "${efiMount}" ]] ) && echo "Cannot properly determine EFI mount point. Aborting." >&2' && exit 1 || echo "${efiMount}"
	
}


myDevToID() {
	# find a unique block device name from /dev/disk/by-id or a unique uuid for the device
	# input is block device ( /dev/<...> )
	# output is the (full path of the) matching entry in /dev/disk/by-id/<...>, UNLESS using uuid flag
	# if flag '-u' or '--uuid' is used as 1st input, output will instead be 'UUID=<deviceUUID>'
	# if flag --type=<...> is used, where <...>=[by-]{partuuid,partlabel,path,id,label,uuid}; then the corresponding folder in /dec/disk will be used. Note that using 'uuid' here outputs the path in /dev/disk/uuid, NOT 'UUID=<deviceUUID>'
	
	local uuidFlag=0;
	local matchType="";
	local -a inAllA;
	local inAll="";
	local nn="";

	inAllA=("${@}")

	for nn in ${!inAllA[@]}; do
		
		if [[ ${inAllA[$nn],,} =~ ^-+u(uid)?$ ]]; then
			uuidFlag=1
			matchType='uuid'
			inAllA[$nn]=""

		elif [[ ${inAllA[$nn],,} =~ ^-+type=(by-)?(id|uuid|partuuid|partlabel|label|path)$ ]]; then
			matchType="$(echo "${inAllA[$nn],,}" | sed -E s/'^-+type=["'"'"']?(by-)?(id|uuid|partuuid|partlabel|label|path)["'"'"']?$'/'\2'/)"
			inAllA[$nn]=""
		fi
	done

	inAll="$(printf '%s\n' "${inAllA[@]}" | grep -vE '^$')"
	
	[[ -z "${inAll}" ]] && return

	[[ -z "${matchType}" ]] && matchType='id'

	if (( $(echo "${inAll}" | wc -l) > 1 )); then

		echo "${inAll}" | while read -r nn; do
			myDevToID $( (( ${uuidFlag} == 1 )) && echo '-u') "${nn}"
		done

	else

		[[ "${inAll}" == '/dev/mapper/'* ]] && echo "${*}" && return

		[[ "${inAll^^}" =~ ^ZFS=.+$ ]] && echo "ZFS=${*##*=}" && return

		(( ${uuidFlag} == 1 )) && [[ "${inAll}" == /dev/disk/by-uuid/* ]] && [[ -e "${inAll}" ]] && ( [[ -z "${*##*/}" ]] && echo "" || echo "UUID=${*##*/}" ) && return
		(( ${uuidFlag} == 0 )) && [[ "${inAll}" == /dev/disk/by-${matchType}/* ]] && [[ -e "${inAll}" ]] && echo "${inAll}" && return

		(( ${uuidFlag} == 0 )) && [[ "${inAll}" == /dev/disk/* ]] && [[ ! "${inAll}" == /dev/disk/by-${matchType}/* ]] && inAll="$(realpath "${inAll%/*}/$(ls -l1 ${inAll%/*} | grep -vE '(^nvme-eui|^nvme-nvme|^wwn)' | grep -F "${inAll##*/}" | sed -E s/'^.* [^ ]* -> (.*)$'/'\1'/ | sort -u | head -n 1)")"

		(( ${uuidFlag} == 1 )) && echo "UUID=$(ls -l1 /dev/disk/by-uuid | grep -F "/${inAll##*/}" | head -n 1 | sed -E s/'^.* ([^ ]*) -> .*$'/'\1'/)"
		(( ${uuidFlag} == 0 )) && echo "/dev/disk/by-${matchType}/$(ls -l1 /dev/disk/by-${matchType} | grep -v -E '(nvme\-eui|nvme\-nvme|wwn)' | grep -F "/${inAll##*/}" | head -n 1 | sed -E s/'^.* ([^ ]*) -> .*$'/'\1'/)"

	fi
}

myFindInstalledKernels() {

	local nn
	local kk
	local availableKernels
	local -a availableKernelsA
	local -a emptyKernels

	availableKernels="$(find /usr/lib/modules -maxdepth 1 -mindepth 1 -type d )"
	mapfile -t emptyKernels < <(find /usr/lib/modules -maxdepth 1 -mindepth 1 -type d -empty)

	for nn in "${emptyKernels[@]}"; do
		availableKernels="$(echo "${availableKernels}" | grep -v "${nn}")"
	done

	mapfile -t availableKernelsA< <(echo "${availableKernels}")

	for kk in "${!availableKernelsA[@]}"; do
		find "${availableKernelsA[$kk]}" -maxdepth 1 -mindepth 1 | grep -qvE '(extra)|(vmlinux)$' || availableKernelsA[$kk]=''
	done

	printf '%s\n' "${availableKernelsA[@]##*/}" | grep -E '^.+$' | sort -Vu

	
}

UEFIRemoveDuplicateBootEntries() {
	# Remove duplicate entries from the EFI boot table

	local efiList;
	local x=0;
	local kk
	local mm
	local nn

	su -c 'efibootmgr '"$([[ ${*} =~ ^-[qv]$ ]] && echo ${*})"' -D'

	efiList="$(efibootmgr -v | grep -E '^Boot[0-9A-F]{4}')"
	
	echo "${efiList}" | sort -u -k 2 | while read -r nn; do 
		x=0
		echo "${efiList}" | while read -r mm; do 
			if [[ "$(echo "${mm#* }" | sed -E s/'^ ?(.*)$'/'\1'/)" == "$(echo "${nn#* }" | sed -E s/'^ ?(.*)$'/'\1'/)" ]]; then 
				(( ${x} == 0 )) && x=1 || echo "${mm%% *}"
			fi
		done
	done | sed -E s/'Boot([0-9A-F]{4}).*$'/'\1'/ | while read -r kk; do 
		su -c 'efibootmgr -B -b '"${kk}"; 
	done

}


UEFIRemoveNonExistantBootEntries() {
	# removes boot entries that refer to an on-disk EFI file that doesnt exist

	local efiMount;
	local efiPathCur;
	local efiBootCur;
	local -a efiAllCur;
	local nn;
	local efibootmgrFlag=""
	local -a removalType;
	local keepFlag
	local kernelCheckRegex

	for nn in "${@}"; do
		[[ "${nn}" =~ ^-[qv]$ ]] && efibootmgrFlag="${nn}"
		[[ "${nn}" =~ ^-+((efi)|(kernel))$ ]] && removalType[${#removalType[@]}]="${nn##*-}"
	done

	if (( ${#removalType[@]} == 0 )); then
		removalType=(efi kernel)
	else
		mapfile -t removalType < <(printf '%s\n' "${removalType[@]}" | sort -u)
	fi

	efiMount="$(myFindEFIMount)"

	mapfile -t efiAllCur < <(efibootmgr -v | grep 'HD(' | grep 'File(')

	kernelCheckRegex="$(echo '(('$(myFindInstalledKernels)'))' | sed -E s/' '/')|('/g)"

	for nn in "${efiAllCur[@]}"; do 
		efiPathCur="${nn#*File(}"
		efiPathCur="${efiPathCur%)}"
		efiPathCur="${efiPathCur//\\/\/}"
		efiPathCur="${efiMount%/}/${efiPathCur#/}"

		keepFlag=1

		printf '%s\n' "${removalType[@]}" | grep -q 'efi' && su -c '[[ -f '"${efiPathCur}"' ]]' || keepFlag=0
		printf '%s\n' "${removalType[@]}" | grep -q 'kernel' && echo "${efiPathCur}" | grep -q -E "${kernelCheckRegex}" || keepFlag=0

		(( ${keepFlag} == 1 )) && continue

		efiBootCur="${nn%% *}"
		efiBootCur="${efiBootCur%\*}"
		efiBootCur="${efiBootCur#Boot}"
		(( ${keepFlag} == 0 )) && su -c 'efibootmgr '"${efibootmgrFlag}"' -B -b '"${efiBootCur}"
	done
}

UEFIRemoveBootFilesForNonExistantKernels() {
	local efiFileList
	local -a installedKernels
	local ker
	local nn

	efiFileList="$(su -c 'find '"$(myFindEFIMount)"' -type f -name '"'"'linux-*.efi'"'")"
	mapfile -t installedKernels < <(myFindInstalledKernels)

	for ker in "${installedKernels[@]}"; do
		efiFileList="$(echo "${efiFileList}" | grep -v "${ker}")"
	done

	echo "${efiFileList}" | while read -r nn; do
		su -c 'rm -f '"${nn}"
	done
	
}

UEFIBootFilesForExactOLDDuplicates() {
	# remove *_OLD.efi files on EFI partition that are exact duplicates of the current *.efi file

	local efiFileList
	local efiFileListKer
	local -a efiFileListKerCUR
	local -a efiFileHashKerCUR
	local -a efiFileListKerOLD
	local -a efiFileHashKerOLD
	local -a installedKernels
	local ker
	local nnCUR
	local nnOLD

	efiFileList="$(su -c 'find '"$(myFindEFIMount)"' -type f -name '"'"'linux-*.efi'"'" | grep -v '_RESCUE')"
	mapfile -t installedKernels < <(myFindInstalledKernels)

	for ker in "${installedKernels[@]}"; do
		efiFileListKer="$(echo "${efiFileList}" | grep "${ker}")"
		(( $(echo "${efiFileListKer}" | wc -l) > 1 )) || continue
		mapfile -t efiFileListKerCUR < <(echo "${efiFileListKer}" | grep -v '_OLD') 
		mapfile -t efiFileListKerOLD < <(echo "${efiFileListKer}" | grep '_OLD')
		(( ${#efiFileListKerCUR[@]} >= 1 )) || continue
		(( ${#efiFileListKerOLD[@]} >= 1 )) || continue

		# compute hashes
		mapfile -t efiFileHashKerCUR < <(printf '%s\n' "${efiFileListKerCUR[@]}" | xargs -L 1 sha256sum | awk '{print $1}')
		mapfile -t efiFileHashKerOLD < <(printf '%s\n' "${efiFileListKerOLD[@]}" | xargs -L 1 sha256sum | awk '{print $1}')

		# check for duplicates
		for nnCUR in ${!efiFileListKerCUR[@]}; do
			for nnOLD in ${!efiFileListKerOLD[@]}; do
				[[ "${efiFileHashKerCUR[${nnCUR}]}" == "${efiFileHashKerOLD[${nnOLD}]}" ]] && \rm -f "${efiFileListKerOLD[${nnOLD}]}"
			done
		done
	done

}


UEFICleanUpLibModules() {

	local -a libModulesKernelsList
	local libModulesKernelsHave
	local -a libModulesKernelsRemove

	mapfile -t libModulesKernelsList < <(find /usr/lib/modules -mindepth 1 -maxdepth 1 -type d | grep -vF "$(uname -r)")
	libModulesKernelsHave='('"$(myFindInstalledKernels|sed -zE s/'\n[^$]'/')|('/g)"')'
	mapfile -t libModulesKernelsRemove < <(for ker in "${libModulesKernelsList[@]}"; do echo "${ker}" | grep -vE "${libModulesKernelsHave}"; done)

	(( ${#libModulesKernelsRemove[@]} > 0 )) && echo -e "\n\nRemoving remnants of the following kernels from /usr/lib/modules: \n\n$(printf '%s\n' "${libModulesKernelsRemove[@]}") \n\n TO PREVENT THIS ACTION, ABORT CODE EXECUTION IN THE NEXT 10 SECONDS!!! \n\n" && sleep 10 && rm -rf "${libModulesKernelsRemove[@]}"

}

UEFIAutoRemove() {
	UEFICleanUpLibModules
	UEFIRemoveDuplicateBootEntries
	UEFIRemoveNonExistantBootEntries -efi -kernel
	UEFIRemoveBootFilesForNonExistantKernels
#	UEFIBootFilesForExactOLDDuplicates
}

