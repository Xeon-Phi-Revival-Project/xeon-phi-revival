# Returning To Stock MPSS

Rollback means returning `mic0` to the original MPSS configuration and stock
card userspace. XPR-OS does not flash firmware or change persistent card
storage.

The canonical runner rolls back automatically only after a failed or ordinary
non-interactive test. A successful boot started with `--leave-running` remains
up so that you can use XPR-OS. When you are done, run the following commands on
the **MPSS host** to return `mic0` to the unchanged stock MPSS configuration:

```bash
sudo systemctl stop mpss || true
sleep 4
sudo micctrl --shutdown mic0 || true
sleep 6
sudo micctrl --reset mic0 || true
sleep 12
sudo micctrl --updateramfs mic0
sudo systemctl start mpss

# If MPSS does not bring the card online on its own:
micctrl --status
if ! micctrl --status | grep -q 'mic0: online'; then
  sudo micctrl --boot mic0
fi
```

Wait for `mic0: online`, then verify the stock environment:

```bash
systemctl start mpss
micctrl --status
ssh mic0 'uname -m; cat /proc/1/comm'
sha256sum /etc/mpss/mic0.conf
```

Expected: `mic0: online`, stock `k1om`, `init`, and the configuration hash
saved before the XPR-OS run. If that does not occur, stop and collect the run
directory, `micctrl --status`, and MPSS service output before changing any
firmware or persistent settings.
