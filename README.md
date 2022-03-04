# Private Endpoint with Azure Data Factory

## Description

Enabling Private endpoint with Azure Data Factory. Simulating a case scenario with the public access to the Data Factory, then using the Private endpoint while accessing the Data Factory. Demonstrating different DNS scenarios with Azure DNS and with the custom DNS servers on-premises.

Our architecture consists of:

- Azure VNET: **10.10.0.0/16**
- On-premises VNET: **172.16.0.0/16**
- Self Host Integration Runtime VM on-premises: **Onprem-shir**
- On-premises DNS server: **Onprem-dns**
- Azure DNS server level Forwarder: **az-dns**
- Azure SQL database: **netsqldbtcs**
- Azure Data Factory: **afdpe-training**
- Shared folder **"ADFTraining"** on the Onprem-shir VM with a file **Eng-list.txt**
- IPsec VPN connexion **Az-to-Onpremises** between Azure and On-premises

## Architecture

Below is the representation of the architecture that we'll be working with. Use the file **deploy.azcli** to deploy it.

![DataTrainingPOC](https://github.com/Tchimwa/Private-Endpoint-with-Azure-Data-Factory/blob/master/images/DataPrivateEndpoint_POC.png)

## Scenario

Here, we'll be using the Azure Data Factory to copy the content of the **Eng-list.txt** to the Azure SQL database **netsqldbtcs** while using the Public access and the Private link.

## Lab process

### From the Public Endpoint Access

On your SQL server, on the **Firewall and virtual networks** tab, make sure you have set up the Firewall to allow Azure service to access the server:

![SQLFwSetup](https://github.com/Tchimwa/Private-Endpoint-with-Azure-Data-Factory/blob/master/images/SQLserver%20FW%20setup.png)

Now, from your database, click on the Query editor and create a table **dbo.shir** with the parameters below:

```typescript
create table dbo.shir(EngID int, Alias varchar(100))
select * from dbo.shir
```
Install the Microsoft Integration Runtime on the **Onprem-shir** using the following link :  
<https://www.microsoft.com/en-us/download/details.aspx?id=39717>

Then, use one of the keys from the Self Hosted IR which is **"shir-training"** created on Azure Data Factory to register the VM :

```TypeScript
IR@cf617fa2-fd42-4cd3-88f0-0207fac43b87@afdpe-training-tcs@ServiceEndpoint=afdpe-training-tcs.eastus.datafactory.azure.net@2NmnbmKsPK1xBfR3EmwIvXg1r+JMj+VD/kCFI7yWsHg=
```

Just to make sure that we are still using the public endpoint access on our Azure Data Factory, please let's run the command below from any of the VMs on-premises: 

``` typescript
nslookup afdpe-training-tcs.eastus.datafactory.azure.net

Output:
PS C:\Users\Azure> nslookup afdpe-training-tcs.eastus.datafactory.azure.net
Server:  UnKnown
Address:  168.63.129.16

Non-authoritative answer:
Name:    aksfe-eu-prod-adms.cloudapp.net
Address:  40.78.229.99
Aliases:  afdpe-training-tcs.eastus.datafactory.azure.net
          eu.frontend.clouddatahub.net
          tm-eu-prod-adms-fe.trafficmanager.net
```
From "Omprem-shir", share the folder **"C:\ADFTraining**" and choose the first option from the sharing options "No, make the network ...". Then, copy the link of the sharing folder and paste it in Notepad.

![SharedFolder](https://github.com/Tchimwa/Private-Endpoint-with-Azure-Data-Factory/blob/master/images/SharingOptions.png)

From the Data Factory Studio, create a new Linked Service type **"File System"** with the following parameters.

- Self Host IR created with the deployment named **"shir-training"** 
- At the Host, we'll have the IP of the "Omprem-shir" VM which is **172.16.2.10** and the name of the folder **(\\172.16.2.10\ADFTraining)** we shared earlier as link. 
- The credentials will the same as the VM's. 

Please make sure you Test the connection before applying the configuration to make sure that the configuration is right.

(https://github.com/Tchimwa/Private-Endpoint-with-Azure-Data-Factory/blob/master/images/LInked%20Service.png)

From the Data Factory Studio:

- Create a new Pipeline type **"Copy Data"** 
- As **Source** we'll create a new dataset type **"File System"** , format **"DelimitedText"** which is based on the type of file. 
- The linked service will be the one we created earlier **shir-training**, same for the IR. The properties will look like the pic below: 

![SourceDelimitedText](https://github.com/Tchimwa/Private-Endpoint-with-Azure-Data-Factory/blob/master/images/Pipeline-SourceFileSystem.png)

As **Sink**, we will create a new dataset type **"Azure SQL database"**. Here, you will have to create a new Linked service with SQL database parameters. As properties, you will choose the table created in your database at the beginning **dbo.shir**.

- **Azure SQL Database linked service**:

![PipelineLinkedSQLservice](https://github.com/Tchimwa/Private-Endpoint-with-Azure-Data-Factory/blob/master/images/Pipeline-SQLLinkedService.png)

- **Sink Properties**:

![PipelineSinkConf](https://github.com/Tchimwa/Private-Endpoint-with-Azure-Data-Factory/blob/master/images/Sink%20SQLProperties.png)

When it comes to the mapping, we'll import the schema from our file and make sure the headers match with the variables set up in our SQL query.

![PipelineMapping](https://github.com/Tchimwa/Private-Endpoint-with-Azure-Data-Factory/blob/master/images/PipelineMapping.png)

From Azure Data Factory Studio, run the Copy Data debug and observe the results. Remember, we are still on the **Public endpoint** access of the Data Factory.

### Create the Private endpoint

On the Azure portal page for your data factory:

- Select the **Networking** blade and the **Network Access** tab, and then select **+ Private endpoint**.
- Select the **Networking** blade and the **Private endpoint connections** tab, and then select **+ Private endpoint**.
- Select the location hosting the Azure VNET and make sure you choose **"dataFactory" as *Target sub-resource*
![CustomDNS](https://github.com/Tchimwa/Private-Endpoint-with-Azure-Data-Factory/blob/master/images/dataFactory.png)
- The Private endpoint will be hosted by the subnet **Azure/az-pe** and will Integrate a Private Zone.
![PESubnet](https://github.com/Tchimwa/Private-Endpoint-with-Azure-Data-Factory/blob/master/images/PrivateEndpointSetUp.png)
- Create the Private endpoint and make sure its **"Connection State" is "Approved"** at the end of the creation.

From the Private endpoint page, select the **DNS configuration** tab and grab the FQDN and the private IP of the PE.

![PEDNSConf](https://github.com/Tchimwa/Private-Endpoint-with-Azure-Data-Factory/blob/master/images/pednsconf.png)

### Seamless operation using the Private Endpoint 

Now, we will be simulating the scenario where the customer has a custom DNS server on his VNET with the DNS server located located on premises. From a VM on-premises (onprem-shir), he is trying to run the same operation (Copy the content of the shared folder on the on-premises VM to the Azure SQL database) using the Private Endpoint access on his Data Factory.

- Azure & On-premises VNET - custom DNS : **172.16.2.10**
- On-premises VM: **Omprem-shir**

So, on both VNET configuration, change the DNS configuration as it's shown below: 

![CustomDNS](https://github.com/Tchimwa/Private-Endpoint-with-Azure-Data-Factory/blob/master/images/CustomDNS.png)

Then, restart all the VMs : **az-dns, onprem-dns, onprem-shir**to apply the DNS configuration.

#### Issue

From **Onprem-shir**, run the command below to make sure that it is using the new DNS configuration (172.16.2.10). Also, confirming that currently the VM still resolving on the public IP of the Data Factory. 

```typescript
nslookup afdpe-training-tcs.eastus.datafactory.azure.net

Output:
PS C:\Users\Azure> nslookup afdpe-training-tcs.eastus.datafactory.azure.net
Server:  UnKnown
Address:  172.16.2.10

Non-authoritative answer:
Name:    aksfe-eu-prod-adms.cloudapp.net
Address:  40.78.229.99
Aliases:  afdpe-training-tcs.eastus.datafactory.azure.net
          eu.frontend.clouddatahub.net
          tm-eu-prod-adms-fe.trafficmanager.net
```

Our goal here is to get the VM to resolve on the private IP address of the Private Endpoint, so the operation can run using the secure Private link.

#### Resolution

According to our public documentation, there is a need of the DNS level forwarder on Azure. The On-premises DNS server will be forwarding the queries of the Private Endpoint's FQDN to the Azure DNS forwarder, and it will relay them to the 168.63.129.16. So, on our Azure DNS server, we will set up a forwarder with the Azure IP: **168.63.129.16**. Then, we'll set up a conditional forwarder on the on-premises DNS server to relay all the DNS queries including the domain **"datafactory.azure.net"** to the Azure DNS forwarder **10.10.3.100**.

As Azure DNS level forwarder, we'll have **az-dns** with a DNS server installed, and configured with **168.63.129.16** as forwarder. 

![azdnsfwd](https://github.com/Tchimwa/Private-Endpoint-with-Azure-Data-Factory/blob/master/images/azdnsFwd.png)

On Onprem-dns, we'll have:

- Conditional Forwarder - domain: **"datafactory.azure.net"**
- Conditional Forwarder - DNS server: **10.10.3.100**

![OnpremDNScondFwd](https://github.com/Tchimwa/Private-Endpoint-with-Azure-Data-Factory/blob/master/images/onpremdnscondfwd.png)

With the new DNS server configured on Azure, we can change the custom DNS server on the Azure VNET to **10.10.3.100** for better efficiency in the future, and limitation of the load on the on-premise DNS server. Once it is done, please restart the VM **az-dns**.

![AzureCustomDNS](https://github.com/Tchimwa/Private-Endpoint-with-Azure-Data-Factory/blob/master/images/AzureVNETCustomDNS.png)

To test, the resolution, make sure the Microsoft IR service is started on Onprem-shir, then run the **nslookup** to see if we have a resolution on the private IP of the Private Endpoint.

```typescript
PS C:\Users\Azure> nslookup afdpe-training-tcs.eastus.datafactory.azure.net
Server:  UnKnown
Address:  172.16.2.100

Non-authoritative answer:
Name:    afdpe-training-tcs.eastus.privatelink.datafactory.azure.net
Address:  10.10.2.4
Aliases:  afdpe-training-tcs.eastus.datafactory.azure.net
```

Once we have validated the resolution, we can run the Copy Data debug from the Data Factory Studio and confirm that the operation is ran successfully.

![CopyData](https://github.com/Tchimwa/Private-Endpoint-with-Azure-Data-Factory/blob/master/images/CopyDataSuccess.png)

## Bonus - Private Endpoint Troubleshooting Flow

![TroubleshootingFlow](https://github.com/Tchimwa/Private-Endpoint-with-Azure-Data-Factory/blob/master/images/PE_NetworkingDU%20TB%20Flow.png)

I would like to say that using the DNS server level forwarder is not the only option to resolve the issue as we do have multiple like using an NVA or AzFW as DNS proxy, but it might be the cheapest among the recommended options.
