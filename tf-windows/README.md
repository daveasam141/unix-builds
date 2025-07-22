Step 1: Create Base VM

Deploy new VM in vCenter:

Create VM with desired specs (CPU, RAM, disk size)
Mount Windows ISO
Configure network adapter
Boot and install Windows


Initial Windows Setup:
powershell# Disable Windows Defender real-time protection (optional)
Set-MpPreference -DisableRealtimeMonitoring $true

# Enable Remote Desktop
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Set timezone (adjust as needed)
tzutil /s "Eastern Standard Time"


Step 2: Install VMware Tools
This is critical for customization to work:

Install VMware Tools from vCenter (VM menu → Install VMware Tools)
Reboot after installation
Verify tools are running: Get-Service vm* in PowerShell

Step 3: Configure for Automation
Enable WinRM for remote management:
powershell# Configure WinRM
winrm quickconfig -q
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="2048"}'

# Set WinRM service to auto-start
Set-Service -Name WinRM -StartupType Automatic

# Configure firewall
New-NetFirewallRule -DisplayName "WinRM-HTTP" -Direction Inbound -LocalPort 5985 -Protocol TCP -Action Allow
Prepare for sysprep:
powershell# Remove any machine-specific configurations
# Clear event logs
wevtutil el | Foreach-Object {wevtutil cl "$_"}

# Clear temporary files
Remove-Item -Path $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue
Step 4: Create Unattend.xml (Optional but Recommended)
Create an unattend.xml file for automated Windows setup:
xml<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <ComputerName>*</ComputerName>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <AutoLogon>
                <Password>
                    <Value>your-password-here</Value>
                    <PlainText>true</PlainText>
                </Password>
                <Enabled>true</Enabled>
                <Username>Administrator</Username>
            </AutoLogon>
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <NetworkLocation>Work</NetworkLocation>
                <ProtectYourPC>1</ProtectYourPC>
            </OOBE>
        </component>
    </settings>
</unattend>



Step 5: Sysprep and Shutdown
powershell# Run sysprep to generalize the image
C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown /unattend:C:\path\to\unattend.xml
Step 6: Convert to Template

Wait for VM to shutdown completely
In vCenter: Right-click VM → Template → Convert to Template
Name your template descriptively (e.g., "Windows2022-Template-v1")


### set domain passwords
# vSphere Connection
$env:TF_VAR_vsphere_server = "vcenter.yourdomain.com"
$env:TF_VAR_vsphere_user = "administrator@vsphere.local"
$env:TF_VAR_vsphere_password = "YourVCenterPassword123!"

# Windows VM Configuration
$env:TF_VAR_admin_password = "WindowsAdminPassword123!"

# Domain Join Configuration
$env:TF_VAR_domain_name = "yourdomain.com"
$env:TF_VAR_domain_admin_user = "yourdomain\administrator"
$env:TF_VAR_domain_admin_password = "DomainAdminPassword123!"