
Add-Type @"
public class itemData
{
	public string Item {get;set;}
	public string Revision {get;set;}
	public string Title {get;set;}
	public string Material {get;set;}
	public string Category {get;set;}
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
	$mNewTemplateSource = @($dsWindow.DataContext.SelectedTemplate)
		#$dsWindow.FindName("TemplateCB").ItemsSource = $mNewTemplateSource
	#$dsWindow.FindName("btnTemplateReset").IsEnabled = $true
	#$dsWindow.FindName("btnTemplateReset").Opacity = 1
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
			$row.Material = mGetItemPropVal $item "Material"
			$row.Category = $item.Cat.CatName
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
		$dsWindow.FindName("TemplatesCB").ItemsSource = $_temp2
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

function mSelectItem
{
	$mSelectedItem = $dsWindow.FindName("ItemsFound").SelectedItem
	If($mSelectedItem.Category -eq "Halbzeug")
	{
		mSelectStockItem
	}
	else
	{
		mSelectMakeItem
	}
}

function mSelectMakeItem {
	$dsDiag.Trace("Item selected to write it's number to the file part number field")
	try 
	{
		$_temp1 = $dsWindow.FindName("Categories").SelectedIndex #workaround as the combo looses the selection as soon as the search command is used !?
		$global:mSelectedTemplate = $dsWindow.FindName("TemplateCB").SelectedIndex
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
			$Prop["Title"].Value = $mSelectedItem.Title
		}

		IF ($dsWindow.Name -eq "FileWindow")
		{
			$Prop["_XLTN_PARTNUMBER"].Value = $mSelectedItem.Item
			$Prop["_XLTN_TITLE"].Value = $mSelectedItem.Title
		}

		$dsWindow.FindName("btnSearchItem").IsDefault = $false
		$dsWindow.FindName("btnOK").IsDefault = $true

		#region tab rendering
		#returnin to tab 1 causes it's rendering with reset controls; we stored the selections made before
		$dsWindow.FindName("Categories").SelectedIndex = $_temp1
		$dsWindow.FindName("TemplateCB").SelectedIndex = $global:mSelectedTemplate
		#endregion workaround
		$dsWindow.FindName("tabProperties").IsSelected = $true
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

		IF ($dsWindow.Name -eq "FileWindow")
		{
			$Prop["_XLTN_STOCKNUMBER"].Value = $mSelectedItem.Item
			$Prop["Halbzeug"].Value = $mSelectedItem.Title

			# Inventor Material mapping is read from document only; inform the user that the material does not update
			If($Prop["_FileExt"].Value -eq ".ipt")
			{
				[System.Windows.MessageBox]::Show($UIString["ADSK-ItemTab-09"],"Vault MFG Quickstart")
			}
			ELSE
			{
				$Prop["_XLTN_MATERIAL"].Value = $mSelectedItem.Material
			}
		}

		$dsWindow.FindName("btnSearchItem").IsDefault = $false
		$dsWindow.FindName("btnOK").IsDefault = $true

		#region tab rendering
		#returnin to tab 1 causes it's rendering with reset controls; we stored the selections made before
		$dsWindow.FindName("Categories").SelectedIndex = $_temp1
		$dsWindow.FindName("TemplateCB").SelectedIndex = $global:mSelectedTemplate
		#endregion workaround
		$dsWindow.FindName("tabProperties").IsSelected = $true
	}
	Catch 
	{
		$dsDiag.Trace("cannot write item number to property field")
	}
}

function mGetItemCategories
{
	$mItemCats = $vault.CategoryService.GetCategoriesByEntityClassId("ITEM", $true)
	$mItemCatNames = @()
	Foreach ($item in $mItemCats)
	{
		$mItemCatNames += $item.Name

	}
	return $mItemCatNames
}

function mResetItemCatFilter
{
	$dsWindow.FindName("cmbItemCategories").SelectedIndex = -1
}

function mGetItemPropVal($_Item, $_PropDispName)
{
    $propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("ITEM")	
    $properties = $vault.PropertyService.GetPropertiesByEntityIds("ITEM", $_Item.Id) #Properties attached to the Item
    $props = @{}
    foreach ($property in $properties) 
    {
			#$dsDiag.Trace("Iiterates properties to get DefIDs...")
			Try 
            {
				    $propDef = $propDefs | Where-Object { $_.Id -eq $property.PropDefId }
					$props[$propDef.DispName] = $property.Val
			} 
			catch { $dsDiag.Trace("ERROR ---creation of name-value list of properties failed! ---") }
	}
    return $props.Item($_PropDispName)
}