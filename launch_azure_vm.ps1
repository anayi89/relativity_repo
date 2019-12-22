# Install-Module Az -Force -AllowClobber

Import-Module -Name Az
Connect-AzAccount

# Define the following parameters for the virtual machine.
$vmAdminUsername = "LocalAdminUserName"
$vmAdminPassword = ConvertTo-SecureString "LocalAdminP@ssword" -AsPlainText -Force
$vmComputerName = "BS-SRV-SQL02"
 
# Define the following parameters for the Azure resources.
$azureLocation              = "EastUS2"
$azureResourceGroupName     = "BSDomain-RG"
$azureVmName                = "BS-SRV-SQL02"
$azureVmOsDiskName          = "BS-SRV-SQL02-OS"
$azureVmSize                = "Standard_E4s_v3"
 
# Define the networking information.
$azureNicName               = "BS-SRV-SQL02-NIC"
$azurePublicIpName          = "BS-SRV-SQL02-IP"
$azureSecurityGroupName     = "BS-SRV-SQL02-SG"
 
# Define the existing VNet information.
$azureVnetName              = "BSDomain-Vnet"
$azureVnetSubnetName        = "default"
 
# Define the VM marketplace image details.
$azureVmPublisherName       = "MicrosoftWindowsServer"
$azureVmOffer               = "WindowsServer"
$azureVmSkus                = "2019-Datacenter"

# Create a resource group.
$azureResourceGroup = New-AzResourceGroup -Name $azureResourceGroupName -Location $azureLocation

# Create a virtual network and subnet.
$azureVnetSubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $azureVnetSubnetName -AddressPrefix '192.168.1.0/24'
$azureVnet = New-AzVirtualNetwork -ResourceGroupName $azureResourceGroupName -Location $azureLocation -Name $azureVnetName -AddressPrefix '192.168.0.0/16' -Subnet $azureVnetSubnetConfig

# Create a security group and inbound rules.
$AllowedPorts = @(22, 80)
$Priority = 1000
foreach ($AllowedPort in $AllowedPorts)
{
    $Rule = New-AzNetworkSecurityRuleConfig -Name "Allow_Port$AllowedPort" -Protocol Tcp -Direction Inbound -Priority $Priority -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange $AllowedPort -Access Allow
    $Priority++
    $NsgRules += $Rule
}
$NSG = New-AzNetworkSecurityGroup -ResourceGroupName $azureResourceGroupName -Location $azureLocation -Name $azureSecurityGroupName -SecurityRules $NsgRules

# Create the public IP address.
$azurePublicIp = New-AzPublicIpAddress -Name $azurePublicIpName -ResourceGroupName $azureResourceGroupName -Location $azureLocation -AllocationMethod Static
 
# Create the NIC and associate the public IP address.
$azureVnetSubnetId = (Get-AzVirtualNetwork | where {$_.name -eq $azureVnetName} | Get-AzVirtualNetworkSubnetConfig).Id
$azureNIC = New-AzNetworkInterface -Name $azureNicName -ResourceGroupName $azureResourceGroupName -Location $azureLocation -SubnetId $azureVnetSubnetId -PublicIpAddressId $azurePublicIp.Id
 
# Store the credentials for the local admin account.
$vmCredential = New-Object System.Management.Automation.PSCredential ($vmAdminUsername, $vmAdminPassword)
 
# Define the parameters for the new virtual machine.
$VirtualMachine = New-AzVMConfig -VMName $azureVmName -VMSize $azureVmSize
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $vmComputerName -Credential $vmCredential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $azureNIC.Id
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $azureVmPublisherName -Offer $azureVmOffer -Skus $azureVmSkus -Version "latest"
$VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable
$VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -StorageAccountType "Premium_LRS" -Caching ReadWrite -Name $azureVmOsDiskName -CreateOption FromImage
 
# Create the virtual machine.
New-AzVM -ResourceGroupName $azureResourceGroupName -Location $azureLocation -VM $VirtualMachine -Verbose

# Retrieve information about the newly created virtual machine.
$azVirtualMachineStatus = Get-AzVM -ResourceGroupName $azureResourceGroupName -Status
$azVirtualMachineSettings = (Get-AzVm -ResourceGroupName $azureResourceGroupName -Name $azureVmName).OsProfile
Write-Output "Virtual Machine Name:" $azVirtualMachineStatus.Name
Write-Output "Location:" $azVirtualMachineStatus.Location
Write-Output "Type of OS:" $azVirtualMachineStatus.OsType
Write-Output "Status:" $azVirtualMachineStatus.Provisioning
Write-Output "Power State:" $azVirtualMachineStatus.PowerState
Write-Output "Public IP Address:" (Get-AzPublicIpAddress -Name $azurePublicIpName).IpAddress
Write-Output "Computer Name:" $azVirtualMachineSettings.ComputerName
Write-Output "Admin Username:" $azVirtualMachineSettings.AdminUsername
Write-Output "Admin Password:" $vmAdminPassword
