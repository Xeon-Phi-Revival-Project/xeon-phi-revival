# Stock Rollback Baseline

Public-safe rollback baseline captured before the first project-controlled
K1OM `/init` boot attempt. Stock MPSS files were inspected read-only.

## Baseline Files

| Role | Active path | SHA-256 |
|---|---|---|
| MPSS common config | `/etc/mpss/default.conf` | `55a3c946c23481a467cf46c814abafce26a834b1c0dc14126b065c30d9fdfb17` |
| `mic0` config | `/etc/mpss/mic0.conf` | `c241d140e9d8db95f808ce1732f85f1135820e4f347146db24693ea7e0e432c9` |
| Stock kernel symlink path | `/usr/share/mpss/boot/bzImage-knightscorner` | `ff85fbbcfb2de6cf67be8af27f10d325eecddb29fcd21405bf028ca0be119b1d` |
| Stock System.map symlink path | `/usr/share/mpss/boot/System.map-knightscorner` | `e1e901bc5b2a96508ea1bb56ac6d4043e908c82f572f1abd53384a214410b530` |
| Stock base initramfs symlink path | `/usr/share/mpss/boot/initramfs-knightscorner.cpio.gz` | `44ecb9b0dbfbe9c5d880cbfe85fe53b65b000e1b66d6c1e779821f4e36923acd` |
| Active generated stock ramfs | `/var/mpss/mic0.image.gz` | `35b3550417f56414f4d2b513fa05dc153fe1f7894dae23fe6d976d40fd1c4380` |

No `/etc/sysconfig/mpss.conf` override existed at capture time.

## Rollback Definition

Rollback means:

1. Stop or reset only `mic0`.
2. Boot `mic0` again using the default MPSS configuration directory:
   `/etc/mpss`.
3. Verify the stock kernel path reported by `micctrl --status` is:
   `/usr/share/mpss/boot/bzImage-knightscorner`.
4. Verify stock uOS reaches `online`.
5. Verify the stock card OS responds over SSH again.
6. Verify PID 1 is stock SysV init, not the project `/init`.

Expected stock runtime checks:

```sh
micctrl --status
ssh mic0 'uname -a; cat /proc/cmdline; ps -p 1 -o pid,ppid,comm,args; mount | sed -n "1,20p"'
```

Expected stock PID 1 shape:

```text
PID 1 COMMAND init
```

## Activation Boundary

The project PID 1 image has been prepared privately, but activation requires a
separate explicit approval because it will stop and reboot `mic0`.

The rollback plan must be available before activation:

```sh
micctrl --shutdown mic0 || true
micctrl --wait mic0 || true
micctrl --boot mic0
micctrl --wait mic0
micctrl --status
ssh -o BatchMode=yes mic0 'uname -a; ps -p 1 -o pid,ppid,comm,args'
```

The stock kernel and stock MPSS boot files must not be overwritten.

## Post-Attempt Rollback Note

During the first activation attempts, MPSS regenerated
`/var/mpss/mic0.image.gz` while restoring the stock service. That generated
ramfs hash is allowed to drift when MPSS rebuilds it from the unchanged stock
inputs.

Rollback is considered valid if these conditions hold:

- `/etc/sysconfig/mpss.conf` is restored to its previous state
- `/etc/mpss/default.conf` hash matches the baseline
- `/etc/mpss/mic0.conf` hash matches the baseline
- `/usr/share/mpss/boot/bzImage-knightscorner` hash matches the baseline
- `/usr/share/mpss/boot/initramfs-knightscorner.cpio.gz` hash matches the
  baseline
- `mic0` reaches `online`
- stock SSH works
- PID 1 is stock `init`
