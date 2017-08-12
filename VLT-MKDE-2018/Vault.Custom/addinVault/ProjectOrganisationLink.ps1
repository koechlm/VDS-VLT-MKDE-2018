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

#region Link_Organisation_Person
function cOinitGetCustomObjects {
	#$dsDiag.Trace(">> cOinitGetCustomObjects")
	cOsaveID -filename cOcompanyID.txt -value $null #workaround, as remove-item did not work
	$dsWindow.FindName("cmbOrganisation").add_SelectionChanged(
		{
			param($sender, $SelectionChangedEventArgs)
			#$dsDiag.Trace("cmbOrganisation.SelectionChanged!")
			cOsaveID -filename cOcontactID.txt -value $null #workaround, as remove-item did not work
			$dsWindow.FindName("cmbPerson").ItemsSource = cOgetContacts
			If($dsWindow.FindName("cmbOrganisation").SelectedIndex -ne -1) 
			{
				If ($Prop["_XLTN_CUSTOMER"]) { $Prop["_XLTN_CUSTOMER"].Value = $dsWindow.FindName("cmbOrganisation").SelectedValue }
				$dsWindow.FindName("btnActivate").IsEnabled = $true
				$dsWindow.FindName("btnOrgLinkReset").IsEnabled = $true
			}
		})

	$dsWindow.FindName("cmbPerson").add_SelectionChanged(
		{
			param($sender, $SelectionChangedEventArgs)
			#$dsDiag.Trace(">> cmbContacts.SelectionChanged!")
			$Global:contact = $dsWindow.FindName("cmbPerson").SelectedValue
			$global:contact = $global:contacts | Where-Object { $_.Name -eq $global:contact }
			If ($Prop["_XLTN_CONTACTNAME"] -and $dsWindow.FindName("cmbPerson").SelectedItem -ne -1)
			{
				$Prop["_XLTN_CONTACTNAME"].Value = $dsWindow.FindName("cmbPerson").SelectedValue
			}
			#$dsDiag.Trace("<< cmbContacts.SelectionChanged!")
		})
	#$dsDiag.Trace("<< cOinitGetCustomObjects")
}

function cOgetCompanies {
	#$dsDiag.Trace(">> cOgetCompanies")
	$customObjects = $vault.CustomEntityService.GetAllCustomEntityDefinitions()
	$global:company = $customObjects | Where-Object { $_.dispName -eq "Organisation" }
	$contacts = $customObjects | Where-Object { $_.dispName -eq "Person" }
	#$dsDiag.Trace(" custom objects  found")

	$srchConds = New-Object autodesk.Connectivity.WebServices.SrchCond[] 1
	$srchCond = New-Object autodesk.Connectivity.WebServices.SrchCond
	$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("CUSTENT")
	$propNames = @("Titel") #$UIString["LBL6"]
	$propDefIds = @{}
	foreach($name in $propNames) 
	{
		$propDef = $propDefs | Where-Object { $_.DispName -eq $name }
		$propDefIds[$propDef.Id] = $propDef.DispName
	}
	#	$dsDiag.Inspect()
	$srchCond.PropDefId = $propDef.Id
	$srchCond.SrchOper = 3
	$srchCond.SrchTxt = '*' #$global:company.Name
	$srchCond.PropTyp = [Autodesk.Connectivity.WebServices.PropertySearchType]::SingleProperty
	$srchCond.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::Must
	$srchConds[0] = $srchCond

	$propNames = @("CategoryName") #$UIString["LBL6"]
	$propDefIds = @{}
	foreach($name in $propNames) 
	{
		$propDef = $propDefs | Where-Object { $_.SysName -eq $name }
		$propDefIds[$propDef.Id] = $propDef.DispName
	}
	$srchCond2 = New-Object autodesk.Connectivity.WebServices.SrchCond
	$srchCond2.PropDefId = $propDef.Id
	$srchCond2.SrchOper = 3
	$srchCond2.SrchTxt = 'Organisation' #$global:company.Name
	$srchCond2.PropTyp = [Autodesk.Connectivity.WebServices.PropertySearchType]::SingleProperty
	$srchCond2.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::Must
	#	$srchConds[1] = $srchCond2

	#$dsDiag.Trace(" search conditions build") 
	$srchSort = New-Object autodesk.Connectivity.WebServices.SrchSort
	$searchStatus = New-Object autodesk.Connectivity.WebServices.SrchStatus
	$bookmark = ""
	$global:companies = $vault.CustomEntityService.FindCustomEntitiesBySearchConditions(@($srchCond,$srchCond2 ),@($srchSort),[ref]$bookmark,[ref]$searchStatus)
	#$dsDiag.Trace(" search perfomed. "+$global:companies.Count+" elements found") 
	$companyNames = @()
	$global:companies | ForEach-Object { $companyNames += $_.Name }
	#$dsDiag.Trace("<< cOgetCompanies $companyNames")

	return $companyNames 
}

function cOsaveID($filename, $value)
{
	$value | Out-File $env:TEMP"\$filename"
}

function cOgetContacts {
	#$dsDiag.Trace(">> cOgetContacts")
	$global:company = $dsWindow.FindName("cmbOrganisation").SelectedValue
	$global:company = $global:companies | Where-Object { $_.Name -eq $global:company }
	try {
		$links = $vault.DocumentService.GetLinksByParentIds(@($global:company.Id),@("CUSTENT"))
		$linkIds = @()
		$_numLinkIds = $linkIds.Count
		$links | ForEach-Object { $linkIds += $_.ToEntId }
		If ($linkIds.Count -ne 0)
		{
			$mLinkedCustObjects = $vault.CustomEntityService.GetCustomEntitiesByIds($linkIds);
			#$dsDiag.Trace(" LinkedObjects: $mLinkedCustObjects ")
			#we need to filter the cat.catID = of the CUSTENT, as the parent links returned all available ones.
			$global:mCoCategories = $vault.CategoryService.GetCategoriesByEntityClassId("CUSTENT", $true)
			$mCoCat = $global:mCoCategories | Where-Object { $_.Name -eq "Person"}		
			$global:contacts = $mLinkedCustObjects | Where-Object { $_.Cat.CatID -eq $mCoCat.Id}
			$contactNames = @()
			$global:contacts | ForEach-Object { $contactNames += $_.Name }
			If ($contactNames.Count -gt 1) { $dsWindow.FindName("cmbPerson").IsDropDownOpen = $true}
			return $contactNames
		}
		
	}
	catch [System.Exception]
	{		
		#[System.Windows.MessageBox]::Show($error)
	}
	#$dsDiag.Trace("<< cOgetContacts")
}

function mOrgLookUpClick()
{
	$dsWindow.FindName("tabFldLinks").IsSelected = $true
}

function mOrgLinkActivate()
{
	If ($Prop["_XLTN_CUSTOMER"]) 
	{ 
		$Prop["_XLTN_CUSTOMER"].Value = $dsWindow.FindName("cmbOrganisation").SelectedValue 
		cOsaveID -filename cOcompanyID.txt -value $global:company.Id
	}
	If ($Prop["_XLTN_CONTACTNAME"] -and $dsWindow.FindName("cmbPerson").SelectedItem -ne -1)
	{
		$Prop["_XLTN_CONTACTNAME"].Value = $dsWindow.FindName("cmbPerson").SelectedValue
		cOsaveID -filename cOcontactID.txt -value $global:contact.Id
	}
	$dsWindow.FindName("tabFldrProps").IsSelected = $true
}

function mOrgLinkReset()
{
	If ($Prop["_XLTN_CUSTOMER"]) 
	{ 
		$Prop["_XLTN_CUSTOMER"].Value = ""
		$dsWindow.FindName("cmbOrganisation").SelectedIndex = -1
		cOsaveID -filename cOcompanyID.txt -value $null
	}
	If ($Prop["_XLTN_CONTACTNAME"] -and $dsWindow.FindName("cmbPerson").SelectedItem -ne -1)
	{
		$Prop["_XLTN_CONTACTNAME"].Value = ""
		$dsWindow.FindName("cmbPerson").SelectedIndex = -1
		cOsaveID -filename cOcontactID.txt -value $null
	}
	$dsWindow.FindName("btnActivate").IsEnabled = $false
	$dsWindow.FindName("btnOrgLinkReset").IsEnabled = $false
	#$dsWindow.FindName("tabFldrProps").IsSelected = $true
}

function CallEditCODataSheet {
	#$vaultContext.ForceRefresh = $true
	#$id=$vaultContext.CurrentSelectionSet[0].Id
	Try {
		$_Temp = $dsCommands
	}
	catch {}
	# 	$dsDiag.Inspect()
	$dialog = $dsCommands.GetEditCustomObjectDialog(1)

	$xamlFile = New-Object CreateObject.WPF.XamlFile "CustomEntityXaml", "%ProgramData%\Autodesk\Vault 2017\Extensions\DataStandard\Vault\Configuration\CustomObject.xaml"
	$dialog.XamlFile = $xamlFile

	$result = $dialog.Execute()
	#$dsDiag.Trace($result)
}

#endregion