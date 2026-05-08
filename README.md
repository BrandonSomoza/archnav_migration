# ArchNav Cloud Migration

From-scratch replication guide for the Oracle ArchNav → Azure migration project.

> **Note:** This repository uses [Git Large File Storage (LFS)](https://git-lfs.github.com/) for large binary files (`.ear`, `.zip`, `.war`). You must install Git LFS before cloning or the application will not work.

---

## Prerequisites

- Azure account
- Git LFS installed on your machine

---

## Step 1 — Create Azure Database for MySQL

1. In the Azure Portal, create an **Azure Database for MySQL Flexible Server**
2. Configure it with the following settings:
   - **Server name:** `migration-db`
   - **Region:** West US 2
   - **MySQL version:** 8.0
   - **Tier/Size:** Burstable, B1ms (1 vCore, 2 GiB RAM, 20 GB storage)
   - **Admin username:** `archnav_admin`
   - **Password:** `Migration123!`
   - **SSL:** Disabled — set `require_secure_transport=OFF` under Server Parameters
3. Create a database named `archemy`
4. Under **Networking**, enable public access and set firewall rule to `0.0.0.0 – 255.255.255.255` (allow all)

---

## Step 2 — Create Azure VM

1. Create a VM with Operating System: **Linux (ubuntu 20.04)** VM 
2. Size: **Standard D2s v3 (2 vcpus, 8 GiB memory)**
3. Open the following inbound ports in the Network Security Group (NSG): Allow TCP 
   - `22`, `8080`, `9999`, `10389`, `4848`
4. Note the **public IP address** — you'll need it throughout

---

## Step 3 — Connect to VM and Install Dependencies

```bash
ssh azureuser@<VM_IP>
sudo apt-get update
sudo apt-get install -y docker.io docker-compose mysql-client git git-lfs unzip
sudo systemctl enable docker
sudo systemctl start docker
git lfs install
```

---

## Step 4 — Clone the Repository

```bash
git clone https://github.com/BrandonSomoza/archnav_migration.git ~
cd ~
```

---

## Step 5 — Import Database

```bash
mysql -h migration-db.mysql.database.azure.com -u archnav_admin -pMigration123! archemy < itp/DB_MODEL/schema.sql
mysql -h migration-db.mysql.database.azure.com -u archnav_admin -pMigration123! archemy < itp/DB_MODEL/procedures.sql
```

> The SQL files are located in `itp/DB_MODEL/` in this repository.

---

## Step 6 — Build and Start

```bash
cd ~/archnav && ./build.sh
```

---

## Step 7 — Access the Application

Once the build completes, the app is available at:

```
http://<VM_IP>:9999/archemy/faces/login.jspx
```

| Field    | Value               |
|----------|---------------------|
| Username | `admin@archemy.com` |
| Password | `Admin1234!`        |

---

## Day-to-Day Usage

```bash
./start.sh   # Start the application
./stop.sh    # Stop the application
./build.sh   # Full rebuild (use if something breaks)
```

---

## Repository Structure

```
~/
├── META-INF/
│   └── MANIFEST.MF
├── apacheds-fortress.ldif        # LDAP/Fortress configuration
├── archemy.ear                   # Pre-built deployable (tracked via Git LFS)
├── archnav/
│   ├── META-INF/
│   ├── WEB-INF/
│   ├── apacheds/
│   ├── fortress/
│   ├── glassfish/
│   │   └── adf-essentials/       # ADF JARs included in repo
│   ├── build.sh
│   ├── start.sh
│   ├── stop.sh
│   └── docker-compose.yml
└── itp/
    ├── App/                      # Glassfish deployment archives (tracked via Git LFS)
    ├── ArchNav_Installation_Instructions-1.pdf
    ├── DB_MODEL/                 # schema.sql, procedures.sql
    ├── FortressSecurity/
    ├── Installing_adf_essentials_in_glassfish.txt
    ├── Installing_fortress.md
    ├── LICENSE
    ├── archemy-webapp/
    └── mockups/
```

---

## Notes

- Large binary files (`.ear`, `.war`, `.zip`) are stored via **Git LFS**. Cloning without LFS installed will result in broken placeholder files instead of the actual binaries.
- SSL is disabled on the MySQL server for compatibility with the current ADF configuration.
- For detailed Fortress/LDAP setup, refer to `itp/Installing_fortress.md` and `itp/FortressSecurity/`.
- For detailed ADF Essentials setup, refer to `itp/Installing_adf_essentials_in_glassfish.txt`.
