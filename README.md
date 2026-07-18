# Capacity Manager (CE)

> By downloading, installing, or using Capacity Manager (CE), you agree to the terms of the [End User Licence Agreement](capman-ce-eula.md).

This bundle runs Capacity Manager (CE) locally on a single machine with Docker.

Capacity Manager (CE) is the Community Edition of the product. It is provided under
a free licence and offers a standalone tool for forecast development
and analytics, including Compute and People resource forecasting.

Capacity Manager (Pro) is the commercially licensable product available from
Silicon Insights Limited. It is targeted at enterprise-level use cases,
including integration into agentic systems and the operational
integration of Capacity Manager into wider enterprise demands for capacity
planning and management across product development roadmaps and
enterprise resource estates.

It starts:

- `capman` on `http://localhost:8070/home` by default
- `postgres` for the application databases

## Prerequisites

Install these before running Capacity Manager (CE):

- Git, for cloning and updating the `capman-ce` repository.
- Docker Engine or Docker Desktop, for running the Capacity Manager (CE) containers.
- Docker Compose, available as `docker compose`.
- A POSIX-compatible shell for running `install-capman.sh`, `start-capman.sh`, and `update-capman.sh`.
- Network access to `github.com`, `raw.githubusercontent.com`, and `ghcr.io`.
- Outbound HTTPS access to Silicon Insights licensing and registration services if Capacity Manager (CE) licence activation is enabled for your release.

Supported local environments:

- macOS with Docker Desktop.
- Linux with Docker Engine and Docker Compose.
- Windows with Docker Desktop and Git Bash. This is the recommended Windows path.
- Windows with WSL2 and Docker Desktop WSL integration. This is optional.

## Install And Run

Clone the Capacity Manager (CE) repository:

```bash
git clone https://github.com/Silicon-Insights/capman-ce.git
cd capman-ce
sh ./install-capman.sh
```

On Windows, run these commands in **Git Bash**. You do not need to use
WSL just to run the Capacity Manager (CE) installer. If Docker Desktop itself
requires WSL2 on your machine, follow the Docker Desktop setup steps
first and then return to Git Bash for the Capacity Manager (CE) install.

`install-capman.sh` creates `.env` from `.env.example` if needed, prompts
for the local Capacity Manager (CE) settings it needs, stores them in `.env`, and
then starts Capacity Manager (CE).

`install-capman.sh` checks for Docker and Docker Compose before it starts. If they are not installed, it stops and prints setup guidance for the current operating system.

Capacity Manager does not support mobile platforms. Larger screens are preferable.
Use on a smaller tablet-type screen may be acceptable in some cases,
but the application is not optimized for that form factor.

Then open:

```text
http://localhost:8070/home
```

## Restart An Existing Installation

If Capacity Manager (CE) is already configured and you just want to start it again:

```bash
cd capman-ce
sh ./start-capman.sh
```

`start-capman.sh` uses the existing `.env` values and starts the
containers without prompting for setup questions again.

## Licence Activation

If licence activation is enabled for your Capacity Manager (CE) release, the app opens on an activation screen before the main UI.

To request a key:

1. Open `http://localhost:8070/home`.
2. In `Request a Key`, enter your name and email address. Company and intended use are optional.
3. Submit the request.
4. Capacity Manager (CE) should email your licence key automatically to the address you entered.
5. If the key does not arrive after a short delay, check your spam folder and then contact Silicon Insights support.

The Capacity Manager (CE) licence granted for this edition is a free licence. It is
still subject to the Capacity Manager (CE) EULA and any activation or usage limits
defined for the release.

To activate:

1. Return to the activation screen.
2. Enter the licence key from the email.
3. Enter the same email address used for the request.
4. Click `Activate`.

After a successful activation, Capacity Manager (CE) stores the local licence state in the Capacity Manager settings directory and should reopen normally on the same machine and browser without asking you to activate again.

Other activation actions:

- `Retry Validation` revalidates the stored key against the Silicon Insights licensing service.
- `Request Renewal` submits a renewal request from the activation screen and notifies both Silicon Insights support and the requester so the renewal can be actioned from the Capacity Manager admin dashboard.
- `Sign out` in Capacity Manager (CE) standalone mode releases the saved local licence state where the release endpoint is enabled and returns the app to the activation screen so a different request or key can be used.

## Upgrade To The Latest Release

To upgrade an existing local installation to the latest release:

```bash
cd capman-ce
git pull origin main
sh ./update-capman.sh
```

`update-capman.sh` updates `CAPMAN_IMAGE` in `.env` to the latest build
from `.env.example`, then pulls and recreates the containers.

This keeps your existing:

- `.env`
- `./capman-data`
- `postgres_data`

## Roll Back To A Build

Pass the required numeric build number to the rollback script:

```bash
sh ./rollback-capman.sh 2949
```

The script keeps the current CE version, changes only its build number, pulls
the requested image before replacing the running application container, and
restores `.env` if that image cannot be pulled. Database and workspace data are
not removed.

## Stop

```bash
docker compose down
```

## Uninstall

To remove the local Capacity Manager (CE) stack and its local data from this bundle directory:

```bash
sh ./uninstall-capman.sh
```

`uninstall-capman.sh` stops and removes the Compose project, deletes the local `./capman-data` directory, removes the default Postgres volume for the bundle, and deletes `.env` after confirmation.

## Files

- `docker-compose.yml`
- `.env.example`
- `install-capman.sh`
- `start-capman.sh`
- `update-capman.sh`
- `rollback-capman.sh`
- `uninstall-capman.sh`
- `postgres-init/01-capman-databases.sql`
- `capman-ce-eula.md`

## Notes

- `CAPMAN_LICENSE_API_BASE` points Capacity Manager (CE) at the Silicon Insights licensing/admin service for licence request, activation, validation, and optional deactivation.
- Where Capacity Manager (CE) online registration and licence activation are enabled, the app may make outbound HTTPS requests to Silicon Insights licensing and registration services.
- Some local firewalls, endpoint protection tools, or corporate proxy environments may require outbound allow-listing for those licensing and registration requests.
- After successful activation, a release may continue to run using cached local licence state for a limited grace period if the licensing service is temporarily unreachable.
- A successful activation is tied to the local Capacity Manager (CE) runtime on that machine. Moving the installation to another machine or clearing the local Capacity Manager data may require reactivation.
- The app runs in local standalone mode and serves the main UI directly from `/`.
- Change `CAPMAN_HOST_PORT` in `.env` if you want to use a different host port.
- The Capacity Manager workspace is stored in `./capman-data`.
- The Postgres database is stored in the Docker volume `capman-ce_postgres_data` when using the default Compose project name `capman-ce`.
- Docker Scout currently reports two high-severity advisories for the pinned `ollama==0.6.2` dependency in the Capacity Manager (CE) runtime image: `CVE-2025-66959` and `CVE-2025-66960`. At the time of writing there is no confirmed fixed upstream release, so treat this as a temporary accepted risk unless you can remove or isolate the Ollama-backed feature set from the runtime image.
