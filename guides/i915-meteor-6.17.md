# Forcing `i915` on Fedora 43 (systemd-boot) when the kernel defaults to `xe`

*Note*: This write up was done by ChatGPT. The troubleshooting and process was done by me. Further commentary added by ChatGPT.

## Summary

After upgrading to **Fedora 43 (kernel ≥ 6.17)** on Intel **Meteor Lake / Arrow Lake** graphics, the Linux kernel **defaults to the `xe` driver** instead of `i915`. Note: It still needs ```xe.force_probe=7d41```, not quite a *default*. 

On this system:
- `xe` causes **hibernate resume kernel panics**
- Simply blacklisting `xe` results in **no GPU driver binding**
- The system falls back to **simpledrm**, causing:
  - no brightness control
  - poor graphics performance
  - “Dummy Output” audio

To restore full functionality, `i915` must be **explicitly forced and loaded early**.

---

## Root Cause

Kernel 6.17+ changes driver preference:

- **≤ 6.16** → `i915` auto-loads  
- **≥ 6.17** → `xe` auto-loads for this GPU (PCI ID `8086:7d41`)

Once `xe` is blocked, **`i915` no longer autoloads**, so it must be:
1. explicitly allowed  
2. explicitly loaded  
3. loaded during the **initramfs stage**

---

## Required Configuration

### 1. Force `i915` to bind to the GPU

Kernel argument:

```text
i915.force_probe=7d41
```

---

### 2. Prevent `xe` from binding (early and late)

Kernel arguments:

```text
module_blacklist=xe
rd.driver.blacklist=xe
```

- `module_blacklist=` → blocks `xe` after switch-root  
- `rd.driver.blacklist=` → blocks `xe` in initramfs

---

### 3. Force `i915` to load early (initramfs)

Kernel argument:

```text
rd.driver.pre=i915
```

---

### 4. Ensure `i915` is included in the initramfs

Create dracut config:

```bash
echo 'add_drivers+=" i915 "' | sudo tee /etc/dracut.conf.d/99-i915.conf
```

Rebuild initramfs:

```bash
sudo dracut -f
```

---

### 5. (Optional) Ensure `i915` loads in userspace

```bash
echo i915 | sudo tee /etc/modules-load.d/i915.conf
```

---

### 6. Update systemd-boot entry

Edit `/etc/kernel/cmdline`:

```text
i915.force_probe=7d41 rd.driver.pre=i915 rd.driver.blacklist=xe module_blacklist=xe
```

Regenerate boot entry:

```bash
sudo kernel-install add $(uname -r) /lib/modules/$(uname -r)/vmlinuz
```

---

## Verification

```bash
dmesg -T | grep -iE 'i915 0000:00:02.0|Initialized i915|fbcon: i915drmfb'
```

Expected:
- i915 initializes within ~1 second
- `fbcon: i915drmfb (fb0) is primary device`

Check binding:

```bash
lspci -k -s 00:02.0
```

---

## Result

- Full graphics acceleration restored  
- Brightness controls working  
- Audio devices appear correctly  
- Stable baseline for hibernate testing

---

## Notes

- This is **upstream kernel behavior**, not a Fedora bug
- `xe` is the future driver, but power management is not yet stable on all laptops
- Pinning `i915` is currently the safest option
