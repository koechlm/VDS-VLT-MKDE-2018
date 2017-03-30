
Add-Type @"
public class itemData
{
	public string Item {get;set;}
	public string Revision {get;set;}
	public string Title {get;set;}
}
"@

function mSearchItem()
{
	$dsDiag.Trace(">> Item search started... SearchText = $mSearchText")
	$dsWindow.FindName("ItemsFound").ItemsSource = $null
	$dsWindow.FindName("txtBlockNoItemsFound").Visibility = "Collapsed"
	$mSearchText = $dsWindow.FindName("SearchText").Text
	
	#region tab-rendering
	# workaround as the tab is new rendered with activation 
	# and would reread sources or require again user input in controls; property values are in runspace memory
	$_temp1 = $dsWindow.FindName("Categories").SelectedIndex 
	#endregion workaround

	if($mSearchText -eq "") #no searchparameters
	{
		$dsWindow.FindName("ItemsFound").ItemsSource = $null
		$dsWindow.FindName("txtBlockNoItemsFound").Visibility = "Visible"
		return 
	}
	$_NumConds = 1 # Minimum number of search condition = search text in all item properties
	If($dsWindow.FindName("cmbItemCategories").SelectedIndex -ne -1) {$_NumConds = 2}
	$srchConds = New-Object autodesk.Connectivity.WebServices.SrchCond[] $_NumConds
	$_i = 0

	$srchconds[0] = New-Object autodesk.Connectivity.WebServices.SrchCond
		$srchconds[0].PropDefId = 0
		$srchconds[0].SrchOper = 1
		$srchconds[0].SrchTxt = $mSearchText
		$srchconds[0].PropTyp = "AllProperties"
		$srchconds[0].SrchRule = "Must"

	$_i += 1
	$srchConds[$_i]= mCreateItemSearchCond "Kategoriename" $dsWindow.FindName("cmbItemCategories").Text "AND" #Search in "Category Name" = <Item Category Name>
	
	try
	{
		$dsWindow.Cursor = "Wait" #search might take some time...
		$dsDiag.Trace(" -- Item search executes...")
		$bookmark = ""
		$status = New-Object autodesk.Connectivity.WebServices.SrchStatus
		$items = $vault.ItemService.FindItemRevisionsBySearchConditions($srchconds, $null, $true, [ref]$bookmark, [ref]$status)
		$results = @()
		foreach($item in $items)
		{
			$row = New-Object itemData
			$row.Item = $item.ItemNum
			$row.Revision = $item.RevNum
			$row.Title = $item.Title
			$results += $row 
		}
		If($results)
		{
			$dsWindow.FindName("ItemsFound").ItemsSource = $results
			$dsWindow.FindName("txtBlockNoItemsFound").Visibility = "Collapsed"
		}
		#region workaround 
		#		workaround as the combo looses the selection as soon as the search command is used !?
		$dsWindow.FindName("Categories").SelectedIndex = $_temp1 
		#endregion workaround
		$dsDiag.Trace(" -- Item search returned")
		#		$dsWindow.Cursor = $null
	}
	catch
	{
		$dsDiag.Trace("Item search failed")
	}
	finally
	{
		$dsWindow.Cursor = "" #reset to default
	}
}

function mCreateItemSearchCond ([String] $PropName, [String] $mSearchTxt, [String] $AndOr) {
	$dsDiag.Trace("--SearchCond creation starts... for $PropName and $mSearchTxt ---")
	$srchCond = New-Object autodesk.Connectivity.WebServices.SrchCond
	$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("ITEM")
	$propNames = @($PropName) #$UIString["LBL6"]
	$propDefIds = @{}
	foreach($name in $propNames) 
	{
		$propDef = $propDefs | Where-Object { $_.dispName -eq $name }
		$propDefIds[$propDef.Id] = $propDef.DispName
	}
	$srchCond.PropDefId = $propDef.Id
	$srchCond.SrchOper = 1
	$srchCond.SrchTxt = $mSearchTxt
	$srchCond.PropTyp = [Autodesk.Connectivity.WebServices.PropertySearchType]::SingleProperty
	
	IF ($AndOr -eq "AND") {
		$srchCond.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::Must
	}
	Else {
		$srchCond.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::May
	}
	$dsDiag.Trace("--SearchCond creation finished. ---")
	return $srchCond
} 


function mSelectItem {
	$dsDiag.Trace("Item selected to write it's number to the file part number field")
	try 
	{
		$_temp1 = $dsWindow.FindName("Categories").SelectedIndex #workaround as the combo looses the selection as soon as the search command is used !?

		$mSelectedItem = $dsWindow.FindName("ItemsFound").SelectedItem

		IF ($dsWindow.Name -eq "AutoCADWindow")
		{
			If ($Prop["GEN-TITLE-NR"])#ACM Attribute Name Mapping
			{
				$Prop["GEN-TITLE-NR"].Value = $mSelectedItem.Item 
			}
			If ($Prop[$UIString["GEN-TITLE-NR"]])#the UI Translation is used to get Vanilla property name scheme
			{
				$Prop[$UIString["GEN-TITLE-NR"]].Value = $mSelectedItem.Item 
			}
		}
		IF ($dsWindow.Name -eq "InventorWindow")
		{
			$Prop["Part Number"].Value = $mSelectedItem.Item
		}

		IF ($dsWindow.Name -eq "FileWindow")
		{
			$Prop["_XLTN_PARTNUMBER"].Value = $mSelectedItem.Item
		}

		$dsWindow.FindName("btnSearchItem").IsDefault = $false
		$dsWindow.FindName("btnOK").IsDefault = $true

		#region tab rendering
		#returnin to tab 1 causes it's rendering with reset controls; we stored the selections made before
		$dsWindow.FindName("Categories").SelectedIndex = $_temp1 
		#endregion workaround

		$dsWindow.FindName("expItemLookup").Visibility = "Collapsed"
		$dsWindow.FindName("expItemLookup").IsExpanded = $false
		$dsWindow.FindName("expItemLookup").IsEnabled = $false


	}
	Catch 
	{
		$dsDiag.Trace("cannot write item number to property field")
	}
}

function mSelectStockItem {
	$dsDiag.Trace("Item selected to write it's number to the file stock number field")
	try 
	{
		$_temp1 = $dsWindow.FindName("Categories").SelectedIndex #workaround as the combo looses the selection as soon as the search command is used !?

		$mSelectedItem = $dsWindow.FindName("ItemsFound").SelectedItem

		IF ($dsWindow.Name -eq "AutoCADWindow")
		{
			If ($Prop["GEN-TITLE-MAT2"])#ACM Attribute Name Mapping
			{
				$Prop["GEN-TITLE-MAT2"].Value = $mSelectedItem.Item 
			}
			If ($Prop[$UIString["GEN-TITLE-MAT2"]])#the UI Translation is used to get Vanilla property name scheme
			{
				$Prop[$UIString["GEN-TITLE-MAT2"]].Value = $mSelectedItem.Item 
			}
		}
		IF ($dsWindow.Name -eq "InventorWindow")
		{
			$Prop["Stock Number"].Value = $mSelectedItem.Item
			$Prop["Halbzeug"].Value = $mSelectedItem.Title
# 			$dsDiag.Inspect()
		}

		#$dsWindow.FindName("txtPartNumber").Text = $mSelectedItem.Item
		$dsWindow.FindName("tabFileProp").IsSelected = $true

		$dsWindow.FindName("btnSearchItem").IsDefault = $false
		$dsWindow.FindName("btnOK").IsDefault = $true

		#region tab rendering
		#returnin to tab 1 causes it's rendering with reset controls; we stored the selections made before
		$dsWindow.FindName("Categories").SelectedIndex = $_temp1 
		#endregion workaround
	}
	Catch 
	{
		$dsDiag.Trace("cannot write item number to property field")
	}
}
