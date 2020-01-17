profile=default

.PHONY: base-pkg-list _pkg-list _pkg-cache _patch-pacstrap hooks sha1sum grab \
patch _clean iso test-qemu test-qemu-offline test-qemu-clean test-vbox \
test-vbox-clean check-deps

iso: patch

base-pkg-list:
	pactree -u -l -s base > const/base_pkgs
	pactree -u -l -s linux >> const/base_pkgs

_pkg-list:
	mkdir -p tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/var/cache/pacman/pkg;
	bash var.sh base_pkgs > tmp/pkgs;
	bash var.sh additional_pkgs >> tmp/pkgs;
	sed 's/ /\n/g' >> tmp/pkgs <<< $$(bash pro.sh $(profile) Packages)
	bash msg.sh info $$'Creating dependency list\n'
	EPT=$$(echo ""); \
	cat tmp/pkgs | while read IPS; do \
		if [[ ! "$$ETP" == "$$IPS" ]]; then \
			pactree -u -l -s $$(echo $$IPS) > tmp/$$IPS.deps || (bash msg.sh error $$'Missing package: ';bash msg.sh error $$IPS;bash msg.sh error $$'\n' && false); \
		fi;\
	done;
	rm tmp/pkgs;
	cat tmp/*.deps | sort -u | tr '\n' ' '> tmp/$(profile)-pkgs
	rm tmp/*.deps;

_pkg-cache:
	@bash msg.sh info $$'Downloading pacman db\n'
	mkdir -p tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/var/cache/pacman/pkg
	mkdir -p tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/var/lib/pacman/
	sudo pacman -Syb tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/var/lib/pacman/
	@bash msg.sh info $$'Downloading packages\n'
	sudo pacman -Sw $$(cat tmp/$(profile)-pkgs) --cachedir tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/var/cache/pacman/pkg --noconfirm

_patch-pacstrap:
	# source at https://git.archlinux.org/arch-install-scripts.git/tree/pacstrap.in
	sed -e 's:$$pacmode:  --gpgdir /mnt/etc/pacman.d/gnupg -S :'  tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/usr/bin/pacstrap > tmp/pacstrap
	sudo cp tmp/pacstrap tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/usr/bin/pacstrap
hooks:
	mkdir hooks
	echo "#!/bin/bash" > hooks/grabbing.sh
	echo "#!/bin/bash" > hooks/grabed.sh
	echo "#!/bin/bash" > hooks/patching.sh
	echo "#!/bin/bash" > hooks/patched.sh


sha1sum:
	echo $$(bash var.sh iso_hash) $$(bash var.sh iso_name)-$$(bash var.sh iso_version).iso > $$(bash var.sh iso_name)-$$(bash var.sh iso_version).iso.sha1

grab: sha1sum
	@bash msg.sh info $$'Grabbing iso from the interwebs\n'
	if [ -f hooks/grabbing.sh ]; then bash hooks/grabbing.sh; fi
	if [ ! -f $$(bash var.sh iso_name)-$$(bash var.sh iso_version).iso ]; then curl -f -o $$(bash var.sh iso_name)-$$(bash var.sh iso_version).iso $$(bash var.sh iso_server)$$(bash var.sh iso_path)$$(bash var.sh iso_version)/archlinux-$$(bash var.sh iso_version)-x86_64.iso; fi
	if [ -f hooks/grabed.sh ]; then bash hooks/grabed.sh; fi
	sha1sum -c $$(bash var.sh iso_name)-$$(bash var.sh iso_version).iso.sha1


patch: grab _clean
	mkdir tmp
	mkdir tmp/arch-spawn-iso-$(profile)
	mkdir tmp/arch-spawn-iso-patching-$(profile)
	mkdir tmp/arch-spawn-iso-patched-$(profile)
	mkdir tmp/arch-spawn-iso-squashfs-$(profile)
	@bash msg.sh info $$'Mounting unpatched iso\n'
	sudo mount -o loop $$(bash var.sh iso_name)-$$(bash var.sh iso_version).iso tmp/arch-spawn-iso-$(profile)
	cp -r tmp/arch-spawn-iso-$(profile)/* tmp/arch-spawn-iso-patching-$(profile)
	sudo umount tmp/arch-spawn-iso-$(profile)
	@bash msg.sh info $$'Enabling syslinux autoboot\n'
	@echo DEFAULT arch64 > tmp/arch-spawn-iso-patching-$(profile)/isolinux/isolinux.cfg
	@echo  >> tmp/arch-spawn-iso-patching-$(profile)/isolinux/isolinux.cfg
	@echo LABEL arch64 >> tmp/arch-spawn-iso-patching-$(profile)/isolinux/isolinux.cfg
	@echo LINUX /arch/boot/x86_64/vmlinuz >> tmp/arch-spawn-iso-patching-$(profile)/isolinux/isolinux.cfg
	@echo INITRD /arch/boot/intel_ucode.img,/arch/boot/x86_64/archiso.img >> tmp/arch-spawn-iso-patching-$(profile)/isolinux/isolinux.cfg
	@echo APPEND archisobasedir=arch archisolabel=$$(bash var.sh iso_label) >> tmp/arch-spawn-iso-patching-$(profile)/isolinux/isolinux.cfg
	@bash msg.sh info $$'Unshquashing rootfs\n'
	cd tmp/arch-spawn-iso-squashfs-$(profile) && sudo unsquashfs ../arch-spawn-iso-patching-$(profile)/arch/x86_64/airootfs.sfs
	@bash msg.sh info $$'Patching\n'
	if [ -f hooks/patching.sh ]; then bash hooks/patching.sh; fi

	sudo cp scripts/initd.service tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/etc/systemd/system/;
	sudo ln -s /etc/systemd/system/initd.service tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/etc/systemd/system/multi-user.target.wants/initd.service
	if [ -f $$(bash pro.sh $(profile) On_Startup)"" ]; then \
		sudo mkdir tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/etc/init.d; \
		sudo cp $$(bash pro.sh $(profile) On_Startup)  tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/etc/init.d/arch-spawn-on_startup.sh; \
		sudo chmod +x tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/etc/init.d/arch-spawn-on_startup.sh; \
	else \
		bash msg.sh warn "Failed to copy "$$(bash pro.sh $(profile) On_Startup)": File not found!"; \
		bash msg.sh warn '\n'; \
	fi
	if [ -f $$(bash pro.sh $(profile) On_Login)"" ]; then \
		sudo cp $$(bash pro.sh $(profile) On_Login)  tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/etc/profile.d/arch-spawn-on_login.sh; \
		sudo chmod +x tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/etc/profile.d/arch-spawn-on_login.sh; \
	else \
		bash msg.sh warn "Failed to copy "$$(bash pro.sh $(profile) On_Login)": File not found!"; \
		bash msg.sh warn '\n'; \
	fi
	if [ -f $$(bash pro.sh $(profile) After_Install)"" ]; then \
		sudo cp $$(bash pro.sh $(profile) After_Install)  tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/root/after_install.sh; \
	else \
		bash msg.sh warn "Failed to copy "$$(bash pro.sh $(profile) After_Install)": File not found!"; \
		bash msg.sh warn '\n'; \
	fi

	if [[ "1" -eq $$(bash pro.sh $(profile) Auto_Install) ]]; then \
		sudo bash -c "echo 'bash /root/install.sh' >>  tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/root/.zshrc;" \
		sudo chmod +x tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/root/.bashrc; \
	fi

	make _pkg-list

	if [[ "1" -eq $$(bash pro.sh $(profile) Installer) ]]; then \
		sudo cp pro.sh tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/root/pro.sh; \
		sudo mkdir tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/root/profiles; \
		sudo cp profiles/default.ini tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/root/profiles/default.ini; \
		sudo cp profiles/$(profile).ini tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/root/profiles/profile.ini; \
		sudo cp installer/install.sh tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/root/install.sh; \
		sudo cp installer/chroot.sh tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/root/chroot.sh; \
		sudo cp tmp/$(profile)-pkgs tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/root/pkgs; \
	fi

	if [[ "1" -eq $$(bash pro.sh $(profile) Offline) ]]; then \
		make _pkg-cache; \
		make _patch-pacstrap; \
		sudo pacman-key --init         --gpgdir /tmp/arch-spawn-iso-squashfs-$(profile)/gnupg; \
		sudo pacman-key --populate     --gpgdir /tmp/arch-spawn-iso-squashfs-$(profile)/gnupg; \
		sudo pacman-key --refresh-keys --gpgdir /tmp/arch-spawn-iso-squashfs-$(profile)/gnupg; \
		sudo rm -rf tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/etc/pacman.d/gnupg; \
		sudo mv /tmp/arch-spawn-iso-squashfs-$(profile)/gnupg tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/root/; \
	fi

	#sudo cp $$(ls -rt /var/cache/pacman/pkg/s-nail* | tail -n1) tmp/arch-spawn-iso-squashfs-$(profile)/squashfs-root/var/cache/pacman/pkg

	if [[ "1" -eq $$(bash pro.sh $(profile) Halt_For_Patching) ]]; then bash msg.sh warn "Halted for manual patching (hit enter when done)";bash -c 'read'; fi

	if [ -f hooks/patched.sh ]; then bash hooks/patched.sh; fi
	@bash msg.sh info $$'Squashing rootfs\n'
	cd tmp/arch-spawn-iso-squashfs-$(profile) && sudo mksquashfs squashfs-root airootfs.sfs
	mv tmp/arch-spawn-iso-squashfs-$(profile)/airootfs.sfs tmp/arch-spawn-iso-patching-$(profile)/arch/x86_64/airootfs.sfs
	sha512sum tmp/arch-spawn-iso-patching-$(profile)/arch/x86_64/airootfs.sfs > tmp/arch-spawn-iso-patching-$(profile)/arch/x86_64/airootfs.sha512

	@bash msg.sh info $$'Making iso\n'
	mkisofs -R -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -V $$(bash var.sh iso_label) -o tmp/arch-spawn-iso-patched-$(profile)/$$(bash var.sh iso_name)-$$(bash var.sh iso_version)-patched-$(profile).iso tmp/arch-spawn-iso-patching-$(profile)
	mv tmp/arch-spawn-iso-patched-$(profile)/$$(bash var.sh iso_name)-$$(bash var.sh iso_version)-patched-$(profile).iso ./$$(bash var.sh iso_name)-$$(bash var.sh iso_version)-patched-$(profile).iso

	@bash msg.sh info $$'Cleaning up\n'
	make _clean


	@bash msg.sh success $$'Done!\n'

_clean:
	sudo umount tmp/arch-spawn-iso-$(profile) || true
	rm -rf tmp/arch-spawn-iso-$(profile)
	rm -rf tmp/arch-spawn-iso-patching-$(profile)
	rm -rf tmp/arch-spawn-iso-patched-$(profile)
	sudo rm -rf tmp/arch-spawn-iso-squashfs-$(profile)
	rm -rf tmp

clean: _clean test-qemu-clean test-vbox-clean

test-qemu:
	mkdir qemu || true
	qemu-img create -f raw qemu/hda-$(profile).raw 4G
	qemu-system-x86_64 -enable-kvm -net nic -net user -m 1024 -boot cd -cdrom $$(bash var.sh iso_name)-$$(bash var.sh iso_version)-patched-$(profile).iso -drive file=qemu/hda-$(profile).raw,format=raw,index=0,media=disk

test-qemu-offline:
	mkdir qemu || true
	qemu-img create -f raw qemu/hda-$(profile).raw 4G
	qemu-system-x86_64 -enable-kvm -nic none -m 1024 -boot cd -cdrom $$(bash var.sh iso_name)-$$(bash var.sh iso_version)-patched-$(profile).iso -drive file=qemu/hda-$(profile).raw,format=raw,index=0,media=disk

test-qemu-clean:
	rm qemu/hda-$(profile).raw || true

test-vbox:
	mkdir vbox || true
	VBoxManage createvm --name $$(bash pro.sh $(profile) Name) --ostype "ArchLinux_64" --register
	VBoxManage  createhd --size 4000 --format VDI --filename vbox/$(profile).vdi
	VBoxManage storagectl $$(bash pro.sh $(profile) Name) --name "IDE Controller" --add ide
	VBoxManage storageattach $$(bash pro.sh $(profile) Name) --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $$(bash var.sh iso_name)-$$(bash var.sh iso_version)-patched-$(profile).iso
	VBoxManage storageattach $$(bash pro.sh $(profile) Name) --storagectl "IDE Controller" --port 1 --device 0 --type hdd --medium vbox/$(profile).vdi
	VBoxManage modifyvm $$(bash pro.sh $(profile) Name) --ioapic on
	VBoxManage modifyvm $$(bash pro.sh $(profile) Name) --boot1 dvd
	VBoxManage modifyvm $$(bash pro.sh $(profile) Name) --memory 1024 --vram 128
	#VBoxManage modifyvm $$(bash pro.sh test Name) --nic1 bridged --bridgeadapter1 $$(route | grep '^default' | grep -o '[^ ]*$$')
	#@bash msg.sh info $$'Nic is set to '$$(route | grep '^default' | grep -o '[^ ]*$$')'\n'
	VBoxManage modifyvm $$(bash pro.sh $(profile) Name) --nic2 nat
	#VBoxManage modifyvm $$(bash pro.sh test Name) --natpf1 "guestssh,tcp,,$$(bash pro.sh $(profile) SshPort),,22"
	VBoxManage modifyvm $$(bash pro.sh $(profile) Name) --boot1 disk
	VBoxManage modifyvm $$(bash pro.sh $(profile) Name) --boot2 dvd
	VBoxManage startvm $$(bash pro.sh $(profile) Name)
	@bash msg.sh warn $$'Waiting for machine '$$(bash pro.sh $(profile) Name)' to poweroff...\n'
	until $$(VBoxManage showvminfo --machinereadable $$(bash pro.sh $(profile) Name) | grep -q ^VMState=.poweroff.); do sleep 1; done;
	until $$(VBoxManage unregistervm $$(bash pro.sh $(profile) Name) --delete 2> /dev/null); do sleep 1; done;

test-vbox-clean:
	VBoxManage unregistervm $$(bash pro.sh $(profile) Name) --delete || true
	vboxmanage closemedium  disk vbox/$(profile).vdi --delete || true

check-deps:
	which make
	which pacman
	which pactree
	which unsquashfs
	which mksquashfs
	which mkisofs
	which sha512sum
	which sudo
