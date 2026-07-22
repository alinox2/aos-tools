FROM ubuntu:20.04

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /src

# Copy source code
COPY . .

# Build libaos
RUN cd libaos && make && cd ..

# Build tools
RUN cd tools && make && cd ..

# Create output directory
RUN mkdir -p /output && \
    cp tools/aos-* /output/ 2>/dev/null || true && \
    cp libaos/libaos.a /output/ 2>/dev/null || true

# Default to running aos-info
ENTRYPOINT ["/output/aos-info"]
CMD ["--help"]
