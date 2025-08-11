---
sidebar_position: 3
title: Setup API key for Proxmox
description: This task guides you through setting up an API key for your cluster that OpenTofu can use.
---

:::warning
You should use a trusted certificate on your Proxmox node.  
See this guide for reference:  
https://3os.org/infrastructure/proxmox/lets-encrypt-cloudflare/#installation-and-configuration
:::

## Step 1: Create a user
1. Log in to Proxmox.  
2. Go to **Data center > Permissions > Users > Add**.  
3. Enter:
   - **Username:** `opentofu`  
<!-- vale off -->
   - **Realm:** Proxmox VE authentication.  
<!-- vale on -->
4. Press **Add**.

---

## Step 2: Create a role
1. Go to **Data center > Permissions > Roles**.  
2. Press **Create**.  
3. Enter:
   - **Name:** `opentofu-role`  
   - **Privileges:**
     - `Datastore.AllocateSpace`  
     - `Datastore.Audit`  
     - `VM.Allocate`  
     - `VM.Audit`  
     - `VM.Clone`  
     - `VM.Config.CDROM`  
     - `VM.Config.CPU`  
     - `VM.Config.Cloudinit`  
     - `VM.Config.Disk`  
     - `VM.Config.HWType`  
     - `VM.Config.Memory`  
     - `VM.Config.Network`  
     - `VM.Config.Options`  
     - `VM.Monitor`  
     - `VM.PowerMgmt`  

---

## Step 3: Create an API token
1. Go to **Data center > Permissions > API Tokens**.  
2. Press **Add**.  
3. Select:
   - **User:** the user you just created (`opentofu`).  
   - **Token ID:** `opentofu-token`  
   - **Privilege Separation:** _unchecked_.  
4. You now see a screen with the secrets.  
   **Copy them now and store them.**

---

## Step 4: Prepare `terraform.tfvars`

For many Proxmox clusters, configure each cluster in the map format:

```hcl
proxmox = {
  host3 = {
    name         = "host3"
    cluster_name = "host3"
    endpoint     = "https://host3.pc-tips.se:8006"
    insecure     = false
    username     = "root"
    api_token    = "root@pam!terraform2=313a1w3551awd5a1wd3a1wd5"
  }
  nuc = {
    name         = "nuc"
    cluster_name = "nuc"
    endpoint     = "https://nuc.pc-tips.se:8006"
    insecure     = false
    username     = "root"
    api_token    = "opentofu@pve!opentofu-token=313a1w3551awd5a1wd3a1wd5"
  }
}
```

:::tip
- Each cluster needs its own API token configured in Proxmox
- The `name` field should match the Proxmox node name
- The `cluster_name` can match the `name` field for clusters with only one node.
- Use the format: `username@realm!token_id=token_secret`
:::


<!-- vale off -->
:::info Next Step
After configuring API tokens, set up SSH key access for each Proxmox node.  
See: [Setup SSH Keys for Proxmox Nodes](setup-ssh-keys)
:::

<!-- vale on -->