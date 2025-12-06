# CantinaOS

This repository contains instructions, assets and tips for building, running
and developing an image for amnesic tor linux.

Some basic assumption are:

- this is only a script around
  [stimages](https://git.glasklar.is/system-transparency/core/stimages) project
- the image is debian
- docker is not mandatory, but really reccomanded for building

What to expect from this repo:

- build the image for **stboot**
- build the image for the real live **OS** (aka **CantinaOS**)

## TODOs

- [ ] smaller stboot kernel conf
- [ ] automatic set up all devices to able to detect connected cables

## Basic setup

Setup root pwd

```console
echo "my root pwd" >> config/cantina/pw.root
```

Pick up [patela](https://github.com/osservatorionessuno/patela) patela build
and place in `config/cantina/overlays/vanilla/usr/sbin/patela`.

In `Makefile` the `NETBOOT_URL` is used for fetching the os image.

## Dev setup

There are some deps to install, if you are on debian you can run

```console
apt-get -qq update
apt-get install -qqy ca-certificates make cpio mmdebstrap libsystemd-shared

go install system-transparency.org/stmgr@v0.4.1
go install system-transparency.org/stboot@v0.4.1
```

Or there is a pre-build docker image that you can compile with

```console
docker buildx build -t osservatorionessuno/stimage .
```

Now move the patela-client in place

```console
cp <YOUR PATELA DIRECTORY>/target/x86_64-unknown-linux-gnu/release/patela-client config/cantina/overlays/base/usr/sbin/patela-client
```

## Dev

Build the image

```console
docker run --rm -it -v $PWD:/stimages osservatorionessuno/stimage:latest make -f <YOUR_MAKE_FILE>
```

Build the stboot live image

Download last kernel

```
curl https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.17.7.tar.xz | tar xJf - && mv linux-6.17.7 linux
```

Configure and make the kernel

```console
cp contrib/stboot/linuxboot.defconfig linux/.config
cd linux
make # if you don't know accept default values
cp vmlinux ../contrib/stboot/linuxboot.vmlinuz
cd ..
```

```console
docker run --rm -it -v $PWD:/stimages osservatorionessuno/stimage:latest make stboot-iso
```

Then to share the image for simulating a real-world scenario

```console
docker run --name stboot -v $PWD/build:/usr/share/nginx/html -d -p 8080:80 nginx
```

In order to test with qemu you need `edk2-ovmf`.

```console
qemu-system-x86_64 \
    -m 8G \
    -accel kvm \
    -accel tcg \
    -pidfile qemu.pid \
    -no-reboot \
    -nographic \
    -rtc base=localtime \
    -drive if=pflash,format=raw,file=/usr/share/OVMF/x64/OVMF_CODE.4m.fd,readonly=on \
    -drive if=pflash,format=raw,file=/usr/share/OVMF/x64/OVMF_VARS.4m.fd \
    -object rng-random,filename=/dev/urandom,id=rng0 \
    -device virtio-rng-pci,rng=rng0 \
    -drive file="stimages/build/stboot.iso",format=raw,if=none,media=cdrom,id=drive-cd1,readonly=on \
    -device ahci,id=ahci0 -device ide-cd,bus=ahci0.0,drive=drive-cd1,id=cd1,bootindex=1
```

Se vuoi invece testare solo l'immagine

```console

qemu-system-x86_64 \
    -m 8G \
    -accel kvm \
    -accel tcg \
    -pidfile qemu.pid \
    -no-reboot \
    -nographic \
    -kernel stimages/build/debian-bookworm-amd64.vmlinuz \
    -initrd stimages/build/debian-bookworm-amd64.cpio.gz \
    -append "console=ttyS0,115200n8 ro rdinit=/lib/systemd/systemd systemd.log_level=debug"
```
