# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains a Docker-based NGINX build with ModSecurity WAF and additional security modules. It's designed to create secure reverse proxy containers with automated version checking and building via GitHub Actions.

## Key Components

- **Dockerfile**: Multi-stage build that compiles NGINX from source with custom modules
- **VERSIONS.txt**: Tracks current component versions for automated update detection
- **GitHub Actions**: Automated workflows for building, testing, and publishing Docker images
- **Security Modules Included**:
  - ModSecurity v3 (Web Application Firewall)
  - OWASP Core Rule Set (CRS)
  - GeoIP2 module
  - Headers More module
  - Substitution filter module

## Build System

### Docker Image Building
```bash
# Build locally with specific NGINX version
docker build --build-arg NGINX_VERSION=1.29.0 -t nginx-with-modsecurity .

# Multi-platform build (requires buildx)
docker buildx build --platform linux/amd64,linux/arm64 -t nginx-with-modsecurity .
```

### GitHub Actions Workflows
- **docker-image.yml**: Main production workflow (builds on push to main, manual trigger, and scheduled daily runs)
- **test-new-build.yml**: Enhanced version with better tagging and Docker Hub description updates
- **scout-cve-scan.yml**: Basic security scanning workflow
- **enhanced-vuln-scan.yml**: Advanced vulnerability scanning with auto-rebuild capabilities
- **test-update-dockerhub-description.yml**: Test workflow for Docker Hub description updates

### Version Management
The build system automatically:
1. Fetches latest versions of NGINX, ModSecurity, OWASP CRS, and Alpine Linux
2. Compares with versions in `VERSIONS.txt`
3. Only builds if newer versions are available
4. Updates `VERSIONS.txt`, `README.md`, and Docker Hub descriptions post-build

## Architecture Details

### Multi-Stage Docker Build
1. **Builder Stage**: Compiles NGINX with modules from source on Alpine Linux
2. **Runtime Stage**: Creates minimal production image with only runtime dependencies

### Custom NGINX Compilation
The Dockerfile configures NGINX with:
- Standard HTTP/2 and SSL modules
- Dynamic module loading for ModSecurity, GeoIP2, Headers More, and Substitution Filter
- Custom server identification (changes "nginx" to "Reynholm Industries")

### Security Configuration
- ModSecurity configured with OWASP CRS rules
- Rules engine enabled by default (`SecRuleEngine On`)
- ModSecurity configuration files located in `/etc/nginx/modsecurity/`

### Vulnerability Management
- **enhanced-vuln-scan.yml**: Automated daily vulnerability scanning with rebuild triggering
- **Post-build scanning**: New images automatically scanned for vulnerabilities after build
- **Loop prevention**: 24-hour cooldown prevents repeated rebuilds for same vulnerabilities
- **Security issue creation**: Critical vulnerabilities automatically create GitHub issues
- **SARIF integration**: Vulnerability reports uploaded to GitHub Security tab

## File Structure
```
├── Dockerfile              # Multi-stage build definition
├── README.md              # Main documentation with version placeholders
├── VERSIONS.txt           # Current component versions
├── docker-hub-description.md  # Docker Hub page content
└── .github/workflows/     # Automated CI/CD workflows
```

## Development Commands

### Testing Builds
```bash
# Test build with current versions from VERSIONS.txt
source VERSIONS.txt && docker build --build-arg NGINX_VERSION=$CURRENT_NGINX_VERSION .

# Manual workflow triggers (requires GitHub CLI)
gh workflow run test-new-build.yml                    # Normal build (version check)
gh workflow run test-new-build.yml -f force_build=true # Force build
gh workflow run enhanced-vuln-scan.yml               # Vulnerability scan + rebuild
gh workflow run enhanced-vuln-scan.yml -f force_rebuild=true # Force vuln rebuild

# Check workflow status
gh workflow list
gh run list --workflow=test-new-build.yml
gh run list --workflow=enhanced-vuln-scan.yml
```

### Security and Vulnerability Management
```bash
# Trigger vulnerability scan (will rebuild if critical/high vulns found)
gh workflow run enhanced-vuln-scan.yml

# Force vulnerability-based rebuild (bypasses 24h cooldown)
gh workflow run enhanced-vuln-scan.yml -f force_rebuild=true

# Check security issues
gh issue list --label security,vulnerability

# Manual vulnerability check with Docker Scout CLI
docker scout cves [IMAGE_NAME]:latest --only-severity critical,high
```

### Version Checking
```bash
# Check current versions
cat VERSIONS.txt

# Manually fetch latest versions (similar to GitHub Actions)
wget -qO- http://nginx.org/en/download.html | grep -oP 'nginx-\K[0-9]+\.[0-9]+\.[0-9]+' | head -1
curl -s https://api.github.com/repos/coreruleset/coreruleset/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")'
```

## Important Notes

- The build process modifies NGINX source code to change server identification strings
- Version placeholders in README.md and docker-hub-description.md are automatically updated by workflows
- The repository uses semantic versioning for component tracking
- Multi-architecture support (AMD64 and ARM64) is built into the workflows
- SBOM (Software Bill of Materials) generation is included in the build process