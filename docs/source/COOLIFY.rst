Deploying with Coolify
=====================

The repository includes ``docker-compose.coolify.yml`` for deploying the
HelloMeet source build, MariaDB 11.4, and the background scheduler.
The database, configuration, and uploaded files use persistent named volumes.
An Apache configuration redirects the site root to ``LB_SCRIPT_URL`` while
preserving HTTPS behind Coolify's proxy. This requires Docker Compose 2.23.1
or newer for inline configuration support.
Both the application and scheduler build from this repository using
``Dockerfile.hellomeet`` on the pinned upstream PHP/Apache 7.0.0 image.
Repository changes, including branding and templates, are included on redeploy.
``LB_APP_TITLE``, ``LB_ADMIN_EMAIL_NAME``, and ``LB_EMAIL_DEFAULT_FROM_NAME``
are set by the stack so existing configuration volumes also display HelloMeet.

Create the resource
-------------------

1. Commit and push ``docker-compose.coolify.yml`` to your fork.
2. In your Coolify project, select **New Resource** and connect your repository
   through its GitHub integration or **Public Repository** option.
3. Select the branch containing the Compose file, normally ``develop``.
4. Under **Configuration > General**, select **Docker Compose** as the build
   pack. Set the base directory to ``/`` and Docker Compose location to
   ``/docker-compose.coolify.yml``.
5. Assign only the ``app`` service a domain. For example, enter
   ``https://booking.example.com:8080``. Coolify uses the suffix to route to
   port 8080 inside the container; visitors use
   ``https://booking.example.com``.
6. Save the environment variables below and deploy.

The **Docker Compose Empty** resource is another supported route. Paste the
contents of ``docker-compose.coolify.yml`` into its editor before saving;
the word "Empty" means that you supply the definition yourself.

Environment variables
---------------------

Set these in Coolify's **Environment Variables** page:

* ``DB_PASSWORD``: a strong database application password.
* ``DB_ROOT_PASSWORD``: a separate strong database root password.
* ``LB_INSTALL_PASSWORD``: a password for the first-time installation wizard.
* ``LB_SCRIPT_URL``: the public application URL ending in ``/Web``, for
  example ``https://booking.example.com/Web``. Do not include ``:8080`` here.
* ``LB_DEFAULT_TIMEZONE``: defaults to ``Asia/Dubai``; change if required.

The database name is ``HelloMeet`` and the application database user is
``lb_user``. The database service is reachable internally as ``db``.

Email is disabled initially. To enable invitations and reminders, set
``LB_EMAIL_ENABLED=true`` and configure ``SMTP_HOST``, ``SMTP_PORT``,
``SMTP_SECURE``, ``SMTP_USERNAME``, ``SMTP_PASSWORD``, and
``SMTP_FROM_ADDRESS``. The default port is 587 and encryption is ``tls``.
The sender display name defaults to HelloMeet; optionally set
``SMTP_FROM_NAME`` to customize it. The web application and scheduler receive
the same email settings.

Initialize HelloMeet
-----------------------

1. Open ``https://booking.example.com/Web/install/`` and enter
   ``LB_INSTALL_PASSWORD``.
2. For the database installer credentials, enter user ``lb_user`` and the
   value of ``DB_PASSWORD``.
3. Leave **Create the database** and **Create the database user** unchecked;
   the MariaDB container has already created both. Run the installation to
   populate the schema and application data.
4. Follow the registration link to create the administrator account.
5. Clear ``LB_INSTALL_PASSWORD`` in Coolify and redeploy to disable the
   installation wizard. Set it again temporarily when a future upgrade needs
   the installer.

The scheduler starts with the stack. Jobs may report missing database tables
until the initial installation is complete.

Operations
----------

Back up the database and persistent configuration/upload volumes before an
upgrade. Changing the database password variable after the first deployment
does not change the existing MariaDB user's password; update the database
account and application environment together.

References
----------

* `Coolify Docker Compose documentation
  <https://coolify.io/docs/applications/builds/docker-compose>`_
* `HelloMeet Docker instructions
  <https://github.com/LibreBooking/docker/blob/master/RUN.md>`_
