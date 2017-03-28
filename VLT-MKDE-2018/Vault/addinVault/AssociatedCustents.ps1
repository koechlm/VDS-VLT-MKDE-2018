#region disclaimer
#=============================================================================#
# PowerShell script sample for Vault Data Standard                            #
#                                                                             #
# Copyright (c) Autodesk - All rights reserved.                               #
#                                                                             #
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER   #
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES #
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.  #
#=============================================================================#
#endregion

Add-Type @'
public class mAssocCustent
{
	public string icon;
	public string name;
	public string title;
	public string description;
	public string customer;
	public string datestart;
	public string status;
	public string reminder;
	public string dateend;
	public string comments;
}
'@

function mGetAssocCustents($mIds)
{
	$dsDiag.Trace(">> Starting mGetAssocCustents($mIds)")
	$mCustEntities = $vault.CustomEntityService.GetCustomEntitiesByIds($mIds)
	$PropDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("CUSTENT")
	$propDefIds = @()
	$PropDefs | ForEach-Object {
		$propDefIds += $_.Id
	}
	$mAssocCustents = @()
	
	$mCustEntities | ForEach-Object { 
		$mCustEntProps = $vault.PropertyService.GetProperties("CUSTENT",@($_.Id),$propDefIds)
		$mAssocCustEnt = New-Object mAssocCustent
		
		#set custom icon
		$iconLocation = $([System.IO.Path]::GetDirectoryName($VaultContext.UserControl.XamlFile))
		$mIconpath = [System.IO.Path]::Combine($iconLocation,"Icons\Claim-Settings.ico")
		$exists = Test-Path $mIconPath
		$mAssocCustEnt.icon = $mIconPath
		
		#set system properties name, title, description
		$mAssocCustEnt.name = $_.Name
		$mtitledef = $PropDefs | Where-Object { $_.SysName -eq "Title"}
		$mtitleprop = $mCustEntProps | Where-Object { $_.PropDefId -eq $mtitledef.Id}
		$mAssocCustEnt.title = $mtitleprop.Val
		$mdescriptiondef = $PropDefs | Where-Object { $_.SysName -eq "Description"}
		$mdescriptionprop = $mCustEntProps | Where-Object { $_.PropDefId -eq $mdescriptiondef.Id}
		$mAssocCustEnt.description = $mdescriptionprop.Val
		
		#set user def properties
		$mUdpDef = $PropDefs | Where-Object { $_.DispName -eq $UIString["ADSK-ClaimMgr-02"]} #date start
		$mUdpProp = $mCustEntProps | Where-Object { $_.PropDefId -eq $mUdpDef.Id}
		IF ($mUdpProp.Val -gt 0) { $mUdpProp.Val = $mUdpProp.Val.ToString("d")}
		$mAssocCustEnt.datestart = $mUdpProp.Val
		#set user def properties
		$mUdpDef = $PropDefs | Where-Object { $_.DispName -eq $UIString["ADSK-ClaimMgr-03"]} #date end
		$mUdpProp = $mCustEntProps | Where-Object { $_.PropDefId -eq $mUdpDef.Id}
		IF ($mUdpProp.Val -gt 0) { $mUdpProp.Val = $mUdpProp.Val.ToString("d")}
		$mAssocCustEnt.dateend = $mUdpProp.Val
		#set user def properties 
		$mUdpDef = $PropDefs | Where-Object { $_.DispName -eq $UIString["ADSK-ClaimMgr-04"]} #customer
		$mUdpProp = $mCustEntProps | Where-Object { $_.PropDefId -eq $mUdpDef.Id}
		$mAssocCustEnt.customer = $mUdpProp.Val
		#set user def properties
		$mUdpDef = $PropDefs | Where-Object { $_.DispName -eq $UIString["ADSK-ClaimMgr-05"]} #reminder
		$mUdpProp = $mCustEntProps | Where-Object { $_.PropDefId -eq $mUdpDef.Id}
		IF ($mUdpProp.Val -gt 0) { $mUdpProp.Val = $mUdpProp.Val.ToString("d")}
		$mAssocCustEnt.reminder = $mUdpProp.Val
		#set user def properties
		$mUdpDef = $PropDefs | Where-Object { $_.DispName -eq $UIString["LBL7"]} #comments
		$mUdpProp = $mCustEntProps | Where-Object { $_.PropDefId -eq $mUdpDef.Id}
		$mAssocCustEnt.comments = $mUdpProp.Val

		#add the filled entity
		$mAssocCustents += $mAssocCustEnt
	}
	return $mAssocCustents

}
