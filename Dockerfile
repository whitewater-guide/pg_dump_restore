FROM whitewaterguide/postgres:1.1.0

ARG AWS_VERSION=2.2.41

ENV S3_PREFIX="v3/"

# Install build tools
RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install --no-install-recommends -y \
    curl \
    unzip \
    python2 \
    python2-dev \
    python-is-python2 \
    gcc \
    libpq-dev \
    postgresql-server-dev-13

# Install pip2, since bullseye no longer provides it
RUN curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py \
    && python2 get-pip.py \
    && rm get-pip.py

# Install AWS CLI tools
RUN cd /tmp \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_VERSION}.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf ./*

# Install psycopg2 which is required for partmans scripts 
RUN pip install -U pip \
    && pip install --upgrade setuptools \
    && pip install --upgrade wheel \
    && pip install psycopg2

# Remove build tools
RUN apt-get remove --purge -y \
    unzip \
    python2-dev \
    gcc \
    libpq-dev \
    postgresql-server-dev-13 \
    && rm -rf /var/lib/apt/lists/*

# Check the installation
RUN aws --version \
    && python2 --version

WORKDIR /app

COPY ./*.sh ./
