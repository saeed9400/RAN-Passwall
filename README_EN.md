<img width="1408" height="630" alt="Image" src="https://github.com/user-attachments/assets/c92044ae-3565-410d-9a6c-eabf1e2bd694" />

<br>


<br>
<br>

--------------------------------------------

<br>

● Description:

→ This script installs the PassWall2 package easily on devices running the OpenWrt firmware.

→ With traffic separation, you can access Iranian domestic websites without using a proxy.

→ In the PassWall2 settings page, you can check the status of traffic separation, internet access, and censorship bypass.

------------------------------------------------------------------------

● Features:

-   Installs the PassWall2 package only from official sources
-   Installs traffic‑separation packages from trusted repositories
-   Includes complete GeoIP / Geosite databases for Iran
-   Sets Tehran timezone and public DNS
-   Creates smart routing rules for Iranian and global services
-   Builds Shunt nodes for user‑controlled traffic management
-   Includes a custom banner for Iranian PassWall2 users

● Requirements:

-   A router running OpenWrt
-   Active internet connection
-   SSH access with root privileges

------------------------------------------------------------------------

● Quick Installation

1. Open the SSH terminal:

    ssh root@192.168.1.1

2. Download and run the script:

   ```bash
    rm -f Passwall-IR.sh && wget https://raw.githubusercontent.com/saeed9400/IRAN_Passwall2/main/Passwall-IR.sh && chmod +x Passwall-IR.sh && sh Passwall-IR.sh
   ```

------------------------------------------------------------------------

● Manual Installation Steps:

1. On Windows, open Command Prompt and type:

   ```bash
    ssh root@192.168.1.1
   ```

— If your device uses a different IP, replace 192.168.1.1.
— If your device requires a password, enter it.
— Characters will not appear when typing the password.
— If successful, you will enter the SSH terminal and the prompt will
switch to OpenWrt.

2. Download the script:

   ```bash
    wget https://raw.githubusercontent.com/saeed9400/IRAN_Passwall2/main/Passwall-IR.sh -O Passwall-IR.sh
   ```

3. Run the script:

   ```bash
    chmod +x Passwall-IR.sh && ./Passwall-IR.sh
   ```

------------------------------------------------------------------------

● Important Notes:

-   The router must have internet access.
-   Backing up previous configurations is recommended.
-   Free for personal and non-commercial use.
-   <br>

--------------------------------------------

<br>

<a href="https://saeed9400.github.io/IRAN_Passwall2/">► Web Page ◄ </a>
<br>

-   <a href="https://github.com/saeed9400/IRAN_Passwall2/blob/main/README.md">◄ راهنما فارسی ► </a>
