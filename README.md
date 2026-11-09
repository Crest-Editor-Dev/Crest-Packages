# Crest Void Linux XBPS Repository (Crest-Packages)

Official Void Linux XBPS binary package repository for CrestEditor, featuring cryptographic RSA signing, GitHub Pages hosting, and automated index generation.

---

## 🏗️ Architecture & Directory Layout

The repository follows standard Void Linux XBPS repository specifications:

```text
Crest-Packages/
├── .github/
│   └── workflows/
│       └── publish-xbps-repo.yml  # GitHub Actions (RSA signing & GitHub Pages deployment)
├── aarch64/                       # Architecture package pool & repository repodata
│   └── aarch64-repodata           # Signed XBPS repository index
├── common/
│   └── repo-keys/                 # Void Linux repository public key plists
│       └── e9:2f:1c:ca:83:ea:7b:81:5e:e6:b0:57:f3:62:be:af.plist
├── keys/
│   ├── crest@crestcode.rsa.pub    # Public RSA key for client verification
│   └── e9:2f:1c:ca:83:ea:7b:81:5e:e6:b0:57:f3:62:be:af.plist
├── srcpkgs/
│   ├── chsh/                      # Package source template & files
│   └── cpm/                       # Crest Package Manager source template
├── scripts/
│   └── generate-xbps-repo.sh      # Repository metadata indexer and signing script
├── LICENSE
└── README.md
```

---

## 🚀 Client Setup (Void Linux / CrestEditor)

To use this repository inside Void Linux or the CrestEditor terminal:

### 1. Add Repository URL
Create a configuration file in `/etc/xbps.d/`:
```bash
echo "repository=https://cresteditor.github.io/Crest-Packages/aarch64" | sudo tee /etc/xbps.d/crest.conf
```

### 2. Sync Repository & Trust Public Key
Synchronize repository index with `xbps`:
```bash
sudo xbps-install -S
```
When prompted:
```text
https://cresteditor.github.io/Crest-Packages/aarch64 repository has been RSA signed by "CrestEditor"
Fingerprint: e9:2f:1c:ca:83:ea:7b:81:5e:e6:b0:57:f3:62:be:af
Do you want to import this public key? [Y/n]
```
Press **`Y`** to trust and import the key.

Alternatively, you can manually install the public key ahead of time:
```bash
sudo curl -sLo /var/db/xbps/keys/e9:2f:1c:ca:83:ea:7b:81:5e:e6:b0:57:f3:62:be:af.plist \
    https://cresteditor.github.io/Crest-Packages/keys/e9:2f:1c:ca:83:ea:7b:81:5e:e6:b0:57:f3:62:be:af.plist
```

### 3. Install Packages
```bash
sudo xbps-install -y chsh cpm
```

---

## 🛠️ Repository Index Generation & Signing

To generate or refresh the repository index locally using XBPS tools:

```bash
chmod +x scripts/generate-xbps-repo.sh
./scripts/generate-xbps-repo.sh
```

This script:
1. Scans `aarch64/` for `.xbps` binary packages.
2. Runs `xbps-rindex -a *.xbps` to build/update the `<arch>-repodata` index.
3. Signs each package with `xbps-rindex --sign-pkg`.
4. Cryptographically signs the repository index with `xbps-rindex --sign --signedby "CrestEditor"`.

---

## 🔐 Production Signing & GitHub Secrets

In production, repository indices are automatically signed inside the GitHub Actions pipeline:
* Secret Name: **`XBPS_PRIVATE_KEY`** (or `PRIVATE_PEM`)
* Value: Full contents of the private 4096-bit RSA key (`crest@crestcode.rsa`).
* Key Fingerprint: **`e9:2f:1c:ca:83:ea:7b:81:5e:e6:b0:57:f3:62:be:af`**

> [!SECURITY]
> Private keys (`*.rsa`, `*.pem`) are strictly git-ignored and must never be committed to the repository. Only public keys (`*.rsa.pub`, `*.plist`) are tracked.
