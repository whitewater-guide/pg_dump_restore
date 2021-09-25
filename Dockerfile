FROM whitewaterguide/db-docker:1.0.5

ARG AWS_VERSION=2.2.41

# Install build tools
RUN apt-get update \
    && apt-get upgrade \
    && apt-get install --no-install-recommends -yy \
    curl \
    unzip \
    python \
    python-pip \
    python-dev \
    gcc \
    libpq-dev \
    postgresql-server-dev-all

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
RUN apt-get remove --purge -yy \
    unzip \
    python-pip \
    python-dev \
    gcc \
    libpq-dev \
    postgresql-server-dev-all \
    && rm -rf /var/lib/apt/lists/*

# Check the installation
RUN aws --version \
    && python --version

WORKDIR /app

COPY ./*.sh ./
