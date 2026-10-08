# HelloMeet

![HelloMeet](Web/img/hellomeet-logo.png)

HelloMeet is HelloPixels LLC's application for booking meeting rooms, desks,
and shared equipment. It supports recurring reservations, approval workflows,
resource permissions, QR booking shortcuts, calendars, and usage reports.

## Getting started

1. Administrators configure working hours under **Application Management > Schedules**.
2. Add bookable rooms, individual desks, and equipment under **Resources**.
3. Create users and groups, and assign resource permissions.
4. Users book an available time under **Schedule > Bookings**.
5. Use **My Account** to update your profile, password, and notification preferences.

See the [administration guide](docs/source/ADMINISTRATION.rst) for booking rules,
approvals, blackouts, quotas, and resource administrators.

## Deploy with Coolify

Connect `https://github.com/HelloPixels-LLC/hellomeet.git`, select `develop`,
choose the **Docker Compose** build pack, and use `/docker-compose.coolify.yml`.

The stack builds HelloMeet from this repository using `Dockerfile.hellomeet`.
The PHP/Apache runtime is based on the pinned upstream 7.0.0 image.
MariaDB, application configuration, and uploaded files use persistent volumes.
The application and scheduler run the same branded source.

Follow the [Coolify guide](docs/source/COOLIFY.rst) for environment variables,
domain routing, installation, email setup, and backups. Clear the installation
password after initial setup. Email requires a configured SMTP account.

## Branding

The supplied HelloMeet logo is used in the navigation, login, and help pages.
Browser favicons, Apple touch icons, and home-screen icons use the matching
artwork. The default interface uses the logo's purple primary color.
Translated product text, email templates, API documentation, and calendar
exports use HelloMeet. Production artwork lives under `Web/img/hellomeet/`
and `Web/img/hellomeet-logo.png`. Original design exports are not deployed.

`LB_APP_TITLE=HelloMeet` and `LB_ADMIN_EMAIL_NAME='HelloMeet Administrator'`
are applied to both services, including deployments with an existing config
volume. Database names, `LB_` environment keys, and PHP namespaces retain their
compatibility identifiers so existing installations continue to work.

## Development

PHP 8.2 or newer, Composer, and MySQL 8.0 or MariaDB 10.6 or newer are required.
Frontend tooling requires Node.js 20.19.0 or newer.

```sh
composer install
composer config-dist:check
composer env-example:check
composer phpunit
npm ci
npm run lint:frontend
```

See [CONTRIBUTING.md](CONTRIBUTING.md) and [AGENTS.md](AGENTS.md) for repository
conventions. The active branch is `develop`.

## Credits and license

HelloMeet is a branded fork of [LibreBooking](https://github.com/LibreBooking/librebooking),
which originated from Booked Scheduler. Original copyright notices,
[contributors](CONTRIBUTORS.md), and the [GPL v3 license](LICENSE.md) are retained.
Upstream development history is recorded in [CHANGELOG.md](CHANGELOG.md).
