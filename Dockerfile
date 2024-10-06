FROM ubuntu:jammy

# Maintainer information
# MAINTAINER mostafa <M@HAVARI.ME>

# Use bash with pipefail for better error handling
SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Set locale to UTF-8
ENV LANG=C.UTF-8

# Set non-interactive mode for tzdata to avoid prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary system dependencies and PostgreSQL client
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        tzdata \
        dirmngr \
        fonts-noto-cjk \
        gnupg \
        libssl-dev \
        node-less \
        npm \
        python3-num2words \
        python3-pip \
        python3-phonenumbers \
        python3-pyldap \
        python3-qrcode \
        python3-renderpm \
        python3-setuptools \
        python3-slugify \
        python3-vobject \
        python3-watchdog \
        python3-xlrd \
        python3-xlwt \
        python3-wheel \
        xz-utils \
        build-essential \
        autoconf \
        libtool \
        pkg-config \
        python3-dev \
        libldap2-dev \
        libsasl2-dev \
        postgresql-client \
        libpq-dev \
        wkhtmltopdf \
    && ln -fs /usr/share/zoneinfo/Europe/Istanbul /etc/localtime \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install rtlcss globally
RUN npm install -g rtlcss

# Copy Odoo files to /opt/odoo directory
COPY ./odoo-18.0.post20241005 /opt/odoo

# Add the odoo user
RUN useradd -m odoo && echo odoo:odoo | chpasswd

# Upgrade pip and install Python dependencies for Odoo
RUN pip3 install --upgrade pip \
    && pip3 install wheel psycopg2-binary \
    && pip3 install -r /opt/odoo/requirements.txt

# Set up the Odoo binary
RUN cp /opt/odoo/setup/odoo /opt/odoo/odoo-bin && chmod +x /opt/odoo/odoo-bin

# Copy entrypoint and configuration files
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/

# Set permissions and prepare directories for Odoo
RUN chown odoo /etc/odoo/odoo.conf \
    && mkdir -p /mnt/extra-addons /var/lib/odoo \
    && chown -R odoo /mnt/extra-addons /var/lib/odoo

# Set volumes for Odoo
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8071 8072

# Set the default config file
ENV ODOO_RC=/etc/odoo/odoo.conf

# Copy wait-for-psql.py script and install additional Python dependencies
COPY wait-for-psql.py /usr/local/bin/wait-for-psql.py
RUN pip3 install simplejson

# Copy additional addons source
COPY ./addon_source /opt/addons

# Set default user to 'odoo'
USER odoo

# Entrypoint and CMD
ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
