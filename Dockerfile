FROM ghcr.io/whitewater-guide/postgres:2.0.0

ARG AWS_VERSION=2.34.24

ENV S3_PREFIX="v3/"

# Install build tools
RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install --no-install-recommends -y \
    curl \
    unzip \
    python3 \
    python3-psycopg2 \
    python-is-python3 \
    gcc \
    libpq-dev \
    postgresql-server-dev-18

# Install AWS CLI tools
RUN cd /tmp \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_VERSION}.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf ./*

# Remove build tools
RUN apt-get remove --purge -y \
    unzip \
    gcc \
    libpq-dev \
    postgresql-server-dev-18 \
    && rm -rf /var/lib/apt/lists/*

# Check the installation
RUN aws --version \
    && python3 --version \
    && python3 -c "import psycopg2; print('psycopg2', psycopg2.__version__)"

WORKDIR /app

COPY ./*.sh ./
