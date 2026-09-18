# ── Build Stage ──
FROM docker.io/library/debian:bookworm-slim

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system-level dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    make \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-fonts-recommended \
    latexml \
    ghostscript \
    inkscape \
    pdf2svg \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for security
ARG USER_ID=1000
ARG GROUP_ID=1000

RUN groupadd -g ${GROUP_ID} latexgroup && \
    useradd -m -u ${USER_ID} -g latexgroup -s /bin/bash latexuser

# Set the working directory inside the container
RUN mkdir -p /home/latexuser/app && chown -R latexuser:latexgroup /home/latexuser/app
WORKDIR /home/latexuser/app
# Switch to user context BEFORE copying files
USER latexuser

# Copy the rest of the project files
COPY --chown=latexuser:latexgroup . .

# Default command runs the Makefile pipeline
CMD ["make", "all"]