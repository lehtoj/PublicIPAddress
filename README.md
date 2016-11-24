# PublicIPAddress

PublicIPAddress is a PowerShell module for querying public IPv4/IPv6-address and save the IP-address to a file. Optionally can also create a scheduled task to do this periodically.

Most Internet-connections, especially wireless connections have dynamic IP-address that will change at times.

As such it may prove to be challenging to remotely connect to your computer from the Internet. One of the most popular ways to address the issue is to use a service such as DynDNS which provices a static hostname, eg myhomecomputer.domain.net.

But unless you actually need to use a static hostname, an alternative way is to leverage Dropbox, OneDrive, Google Drive or similar cloud service to store public IP-address of your computer in a file.

All you need is a way to periodically check current public IP-address and save that to a file located in a directory that will be synced to a cloud service, which you can then read on your phone or any other computer with access to the Internet.

This PowerShell module provides a function to check current public IP-address and write the IP-address to a file in specified directory. In addition to this, a scheduled task can be created to do this periodically.

If you intend to use a scheduled task, this module should be installed to %systemdrive%:\Program Files\WindowsPowerShell\Modules. Otherwise SYSTEM account cannot find this module and use its functions.

Administrator privileges will also be required to create a scheduled task.

When installing this module from the PowerShell Gallery, use "Install-Module -Name PublicIPAddress -Scope AllUsers" in order to install the module to Program Files.

Queries for IP-address should be limited to no more than once per five minutes. Otherwise your queries my be dropped.

## Download

[PowerShell Gallery](https://www.powershellgallery.com/packages/PublicIPAddress/)

## Examples

If you want to query for your public IP-address without saving it to a file, you can use Get-PublicIPAddress.

```PowerShell
Get-PublicIPAddress
```
Returns current public IPv4-address.

```PowerShell
Get-PublicIPAddress -IPv6
```
Returns current public IPv6-address.

Otherwise you should use Save-PublicIPAddress.

```PowerShell
Save-PublicIPAddress -Path C:\Users\User\Dropbox
```
Queries for current public IPv4-address and saves the IP-address to IPv4.txt in C:\Users\User\Dropbox.

```PowerShell
Save-PublicIPAddress -Path C:\Users\User\Dropbox -IPv6
```
Queries for current public IPv6-address and saves the IP-address to IPv6.txt in C:\Users\User\Dropbox.

```PowerShell
Save-PublicIPAddress -Path C:\Users\User\Dropbox -ScheduledTask
```
Creates a scheduled task to run "Save-PublicIPAddress -Path C:\Users\User\Dropbox" every 15 minutes.

```PowerShell
Save-PublicIPAddress -Path C:\Users\User\Dropbox -IPv6 -ScheduledTask
```
Creates a scheduled task to run "Save-PublicIPAddress -IPv6 -Path C:\Users\User\Dropbox" every 15 minutes.