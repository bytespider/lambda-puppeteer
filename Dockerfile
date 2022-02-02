ARG FUNCTION_DIR="/var/task"
ARG DISTRO_VERSION="3.15"

# Build AWS Lambda Runtime Interface Client seperately to avoid recompilation during development
FROM alpine:${DISTRO_VERSION} as build-aws
ARG FUNCTION_DIR

WORKDIR ${FUNCTION_DIR}

RUN apk update \
  && apk --no-cache add \
    g++ \
    make \
    cmake \
    autoconf \
    automake \
    libtool \
    libexecinfo-dev \
    zlib-dev \
    openssl-dev \
    curl \
    python3 \
    npm
RUN npm install aws-lambda-ric

# Build our function
FROM alpine:${DISTRO_VERSION} as build
ARG FUNCTION_DIR
ENV NODE_ENV=production \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

WORKDIR ${FUNCTION_DIR}

COPY package*.json ./

RUN apk update \
  && apk --no-cache add \
    npm
RUN npm install

# Copy AWS Lambda RIC last as npm install overwrites node_modules
COPY --from=build-aws ${FUNCTION_DIR}/node_modules/ ./node_modules/

# Deploy our function and it's dependencies
FROM alpine:${DISTRO_VERSION}
ARG FUNCTION_DIR

ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

WORKDIR ${FUNCTION_DIR}

RUN apk update \
  && apk --no-cache add \
    nss \
    chromium \
    chromium-swiftshader \
    freetype \
    ttf-freefont \
    font-noto-emoji \
    font-noto-cjk \
    nodejs-current \
    npm \
  && adduser -D puppeteer

USER puppeteer

COPY --from=build --chown=puppeteer:puppeteer ${FUNCTION_DIR} ./
COPY src/* ./

ENTRYPOINT ["/usr/bin/npx", "aws-lambda-ric"]
CMD ["app.handler"]