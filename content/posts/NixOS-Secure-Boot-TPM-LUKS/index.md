---
title: NixOS, Secure Boot and TPM based Full Disk Encryption
date: 2024-11-21
lastmod: 2024-11-22
draft: false
description: How to set up NixOS with Secure Boot and TPM based Full Disk Encryption (LUKS)
summary: How to set up NixOS with Secure Boot and TPM based Full Disk Encryption (LUKS)
tags:
  - NixOS
  - Linux
  - LUKS
  - Guide
---

{{< alert >}}
**Info:** I won't go into detail what TPM or Secure Boot is, but rather just
explain how to set it up
{{</ alert >}}

I have been using NixOS for some months now
([dots](https://github.com/MrSom3body/dotfiles)), and I must say I love it
besides one or the other paint point, but I wondered for some time how I
can set it up with Secure Boot. I just kept putting it of until now, but here's
[the commit](https://github.com/MrSom3body/dotfiles/commit/7f6555a518dde45201cc9a3811b8264b57e7e031)!

The few prerequisites for this tutorial/guide is a **flake-enabled NixOS
configuration** and having **Secure Boot in Setup Mode[^1]**. Everything else
we'll set up together.

[^1]:
    this option may not be available but something along the lines of clearing
    "Platform Keys" should be possible

## Enabling Secure Boot

[Lanzaboote](https://github.com/nix-community/lanzaboote) is the flake we're
going to use to configure Secure Boot. Lanzaboote has a fantastic [Quick
Start](https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md)
that you can use instead of following the steps laid out below if you don't
trust me, but I'll write it down in this post to have everything in one place :)

### Generating Secure Boot Keys

First of all, we need to generate some Secure Boot
Keys that Lanzaboote can use. This can be done by using
[`sbctl`](https://search.nixos.org/packages?channel=unstable&show=sbctl&query=sbctl):

```sh
sudo nix run nixpkgs#sbctl create-keys
```

Now there should be some files and keys under `/etc/secureboot`:

```bash
$ tree /etc/secureboot
 /etc/secureboot
├──  keys
│   ├──  db
│   │   ├──  db.key
│   │   └──  db.pem
│   ├──  KEK
│   │   ├──  KEK.key
│   │   └──  KEK.pem
│   └──  PK
│       ├──  PK.key
│       └──  PK.pem
├──  files.db
└──  GUID
```

### Adding Lanzaboote to NixOS

Now we'll need to add Lanzaboote to our `flake.nix`:

```nix
# ...
inputs = {
  lanzaboote = {
    url = "github:nix-community/lanzaboote";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
# ...
```

Now we can do one of two things:

1. add all configuration directly into our `flake.nix`
2. add into a module we import somehow

I added a new module to my NixOS configuration that I can import because it
makes it easier to understand my config and makes it easier to keep everything
related to it out in another module. Here's my module:

```nix
{
  lib,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  environment.systemPackages = [
    # For debugging and troubleshooting Secure Boot.
    pkgs.sbctl
  ];

  boot = {
    # Lanzaboote currently replaces the systemd-boot module.
    # This setting is usually set to true in configuration.nix
    # generated at installation time. So we force it to false
    # for now.
    loader.systemd-boot.enable = lib.mkForce false;

    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
  };
}
```

After you added Lanzabootes configuration to your NixOS configuration, **rebuild
your system**. Next control if it really worked by checking if the keys were
signed by running:

```sh
$ sudo nix run nixpkgs#sbctl verify
Verifying file database and EFI images in /boot...
✓ /boot/EFI/BOOT/BOOTX64.EFI is signed
✓ /boot/EFI/Linux/nixos-generation-1013-ri3ncrqino2kv533utzhokre2e2jhghprn2g7x5k23336vvgniwa.efi is signed
✓ /boot/EFI/Linux/nixos-generation-1013-specialisation-ollamaNoGPU-mqpm5ulo76adzgn4rlk57q2hmy5756zkjkqghuc33uum73jog25q.efi is signed
✓ /boot/EFI/Linux/nixos-generation-1014-2knmqls4x5mxcjzvbshhpkkg2em6qv3itnqdnvuspb6ipj2xhyaa.efi is signed
✓ /boot/EFI/Linux/nixos-generation-1014-specialisation-ollamaNoGPU-kxnw4ou7ewmh5ganp4crgxnbax7zljplvoe46ifkisrvcnt5qpmq.efi is signed
✓ /boot/EFI/Linux/nixos-generation-1015-ri3ncrqino2kv533utzhokre2e2jhghprn2g7x5k23336vvgniwa.efi is signed
✓ /boot/EFI/Linux/nixos-generation-1015-specialisation-ollamaNoGPU-mqpm5ulo76adzgn4rlk57q2hmy5756zkjkqghuc33uum73jog25q.efi is signed
✗ /boot/EFI/nixos/kernel-6.11.8-qj7md4zvdijjzi2szevrvi3pnvszxkc4andpvr4aqxzmdcebysoa.efi is not signed
✓ /boot/EFI/systemd/systemd-bootx64.efi is signed
```

The output should look something like that. Don't worry about kernels not being
signed: that's normal.

### Enrolling Secure Boot Keys

Lanzaboote has added our Secure Boot Keys and signed every generation. Now we
can enroll the Keys to enable Secure Boot:

```sh
sudo nix run nixpkgs#sbctl enroll-keys --microsoft
```

### Verifying

This _should_ enable Secure Boot for you, but to really make sure run the
following command:

```sh
$ bootctl status
System:
      Firmware: UEFI 2.80 (American Megatrends 5.24)
 Firmware Arch: x64
   Secure Boot: enabled (user)
  TPM2 Support: yes
  Measured UKI: yes
  Boot into FW: supported
```

If your output looks like mine: congratulations! If not, please
make sure if you did everything I wrote and also check the [Quick
Start](https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md)
from Lanzaboote if something changed!

## Unlocking LUKS Disk with TPM

Enabling this is **extremely** easy. You need to add this config to your NixOS
configuration to run SystemD in Stage 1 (`initrd`):

```nix
# ...
boot.initrd.systemd.enable = true;
# ...
```

And finally, run this command to tell systemd to decrypt it with our TPM chip:

```sh
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+7+12 --wipe-slot=tpm2 <disk>
```

I think the command flags are pretty self-explanatory, besides
`--tpm2-pcrs=0+2+7+12`. This just tells systemd for what hashes to check before
using the TPM Chip to unlock our disk. Here's the table for the PCRs that I use:

| PCR | Use                                                 |
| --- | --------------------------------------------------- |
| 0   | Core System Firmware executable code (aka Firmware) |
| 2   | Extended or pluggable executable code               |
| 7   | Secure Boot State                                   |
| 12  | Overridden kernel command line, Credentials         |

You can see more PCRs on the
[Arch Wiki](https://wiki.archlinux.org/title/Trusted_Platform_Module#Accessing_PCR_registers).

Now you can just reboot and should not need to enter your LUKS Password :)

PS: If you find any mistakes or have suggestions, feel free to reach out to me!
