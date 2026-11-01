# Crest Alpine APK Repository (Crest-Packages)

Official Alpine Linux APK package repository for CrestEditor, featuring cryptographic RSA signing, GitHub Pages hosting, and automated index generation.

---

## 🏗️ Architecture & Directory Layout

The repository follows standard Alpine Linux APK repository specifications:

```text
Crest-Packages/
├── .github/
│   └── workflows/
│       └── publish-apk-repo.yml   # GitHub Actions (RSA signing & GitHub Pages deployment)
├── aarch64/                       # Architecture package pool & repository index
│   ├── APKINDEX.tar.gz            # Signed repository index archive
│   └── cpm-0.1.0-r0.apk           # CrestEditor Package Manager binary package
├── keys/
│   └── crest@crestcode.rsa.pub    # Public RSA key for client package verification
├── packages/
│   └── cpm/
│       └── APKBUILD               # Source packaging recipe for cpm
├── scripts/
│   └── generate-apk-repo.sh       # Repository metadata indexer and signing script
├── LICENSE
└── README.md
```

---

## 🚀 Client Setup (Alpine / CrestEditor)

To use this repository inside Alpine Linux or the CrestEditor terminal:

### 1. Trust Repository Public Key
Download the official repository public key into `/etc/apk/keys/`:
```bash
wget -O /etc/apk/keys/crest@crestcode.rsa.pub https://cresteditor.github.io/Crest-Packages/keys/crest@crestcode.rsa.pub
```

### 2. Add Repository URL
Add the repository to `/etc/apk/repositories`:
```bash
echo "https://cresteditor.github.io/Crest-Packages" >> /etc/apk/repositories
```

### 3. Sync & Install Packages
Using **CPM** (Crest Package Manager):
```bash
cpm update
cpm install cpm
```
Or using native Alpine `apk`:
```bash
apk update
apk add cpm
```

---

## 🛠️ Development & Local Index Generation

To generate or refresh the repository index locally using Alpine tools:

```bash
chmod +x scripts/generate-apk-repo.sh
./scripts/generate-apk-repo.sh
```

This script:
1. Scans `aarch64/` for `.apk` packages.
2. Runs `apk index` to construct `APKINDEX.tar.gz`.
3. Signs `APKINDEX.tar.gz` with the CrestEditor RSA private key.

---

## 🔐 Production Signing & GitHub Secrets

In production, repository indices are automatically signed inside the GitHub Actions pipeline:
* Secret Name: **`APK_PRIVATE_KEY`**
* Value: Full contents of the private RSA key (`crest@crestcode.rsa`).

> [!SECURITY]
> Private keys (`*.rsa`) are strictly git-ignored and must never be committed to the repository. Only public keys (`*.rsa.pub`) are tracked.
