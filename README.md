# system_auto-update

Ansible playbook that:

1. Disables all existing yum/dnf repositories by moving every `*.repo` file
   under `/etc/yum.repos.d/` into a backup directory.
2. Downloads a `.repo` file from a local mirror with `get_url` (equivalent to
   `wget`) and installs it in `/etc/yum.repos.d/`.
3. Deploys a shell script (`/usr/local/sbin/system-auto-update.sh`) that runs
   `dnf`/`yum` update.
4. Schedules a cron job to execute that script on a configurable schedule.

## Layout

```
ansible.cfg
inventory.ini
playbook.yml
group_vars/all.yml             # defaults (mirror URL, schedule, paths)
group_vars/update_<day>.yml    # per-group schedule overrides
host_vars/<host>.yml           # per-host schedule overrides
files/system-auto-update.sh    # update script deployed to targets
```

## Configure

Edit `group_vars/all.yml`:

- `local_mirror_repo_url` — URL of the `.repo` file on your local mirror.
- `cron_minute` / `cron_hour` / `cron_weekday` — cron schedule (default:
  Tuesdays at 03:00).

Per-group overrides live in `group_vars/update_monday.yml`,
`update_wednesday.yml` and `update_saturday.yml`; per-host overrides in
`host_vars/`. Variable precedence: host_vars > group_vars/update_* >
group_vars/all.yml.

Add target hosts in `inventory.ini` under the group matching the desired
update day.

## Run

```bash
ansible-playbook playbook.yml
```

Logs of the update runs are appended to `/var/log/system-auto-update.log`.
