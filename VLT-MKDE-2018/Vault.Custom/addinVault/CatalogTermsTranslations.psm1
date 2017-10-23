#region disclaimer
	#===============================================================================#
	# PowerShell script sample														#
	# Author: Markus Koechl															#
	# Copyright (c) Autodesk 2017													#
	#																				#
	# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER     #
	# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES   #
	# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.    #
	#===============================================================================#
#endregion

#region CatalogLookUp
Add-Type @"
public class CatalogData
{
	public string Term_DE {get;set;}
	public string Term_EN {get;set;}	
	public string Term_FR {get;set;}
	public string Term_IT {get;set;}
}
"@

function mSearchTerm() {
	try {
		$dsDiag.Trace(">> catalog search for terms started... mSearchTermText = $mSearchText")
		$dsWindow.Cursor = "Wait" #search might take some time...

		#region tab-rendering 
			# the tab is rendered with each activation and would re-read sources or require again user input in controls; property values are in runspace memory
			# note - using the tabTerms in different windows (xaml) might require to add a switch node here
			$_temp1 = $dsWindow.FindName("Categories").Text
			$_temp10 = $dsWindow.FindName("DocTypeCombo").SelectedIndex
			$_temp40 = $dsWindow.FindName("NumSchms").IsEnabled
			$_temp41 = $dsWindow.FindName("btnOK").IsEnabled
		#endregion

		$dsWindow.FindName("dataGrdTermsFound").ItemsSource = $null
		
		try
		{
			m_SearchTerms $mSearchText
			$dsDiag.Trace("...just returned from m_SearchTerms Call...")
		
			#region tab-rendering restore
			$dsWindow.FindName("Categories").Text = $_temp1
			IF ($_temp10) { $dsWindow.FindName("DocTypeCombo").SelectedIndex = $_temp10}
			IF ($_temp40) { $dsWindow.FindName("NumSchms").IsEnabled = $_temp40}
			IF ($_temp41) { $dsWindow.FindName("btnOK") = $_temp41} 
			#endregion
			$dsDiag.Trace(" -- mSearchTerm command finished (Main) ")
			$dsWindow.Cursor = $null #reset the wait cursor
		}
		catch
		{
			$dsDiag.Trace(" Result Grid ItemsSource could not get filled")
		}
	}
	catch { $dsDiag.Trace(" Error in Function mSearchTerm")}
}

function m_SearchTerms ([STRING] $mSearchText1) {
	Try {
		$dsDiag.Trace(">> search COs terms")
		$mSearchText1 = $dsWindow.FindName("mSearchTermText").Text
		If(!$mSearchText1) { $mSearchText1 = "*"}

		# the search conditions depend on the filters set (4 groups, 4 languages; the number has to match
		$_NumConds = 1 #we have one condition as minimum, as we search for custom entities of category "term" 		
		$mBreadCrumb = $dsWindow.FindName("wrpClassification")
		$_t1 = $mBreadCrumb.Children[1].SelectedIndex
		IF ($mBreadCrumb.Children[1].SelectedIndex -ge 0) { $_NumConds +=1}
		IF ($mBreadCrumb.Children[2].SelectedIndex -ge 0) { $_NumConds +=1}
		IF ($mBreadCrumb.Children[3].SelectedIndex -ge 0) { $_NumConds +=1}
		IF ($mBreadCrumb.Children[4].SelectedIndex -ge 0) { $_NumConds +=1}

		# check the language columns/properties to search in
		IF ($dsWindow.FindName("chkDE").IsChecked -eq $true) { $_NumConds +=1} #default = checked
		IF ($dsWindow.FindName("chkEN").IsChecked -eq $true) { $_NumConds +=1}

		IF ($dsWindow.FindName("chkFR").IsChecked -eq $true) { $_NumConds +=1}
		IF ($dsWindow.FindName("chkIT").IsChecked -eq $true) { $_NumConds +=1}

		# add all selected languages to search in; apply OR conditions
		$srchConds = New-Object autodesk.Connectivity.WebServices.SrchCond[] $_NumConds
		$_i = 0

		#the default search condition object type is custom object "term"
		$srchConds[$_i]= mCreateSearchCond $UIString["ClassTerms_08"] $UIString["ClassTerms_00"] "AND" #Search in "Category Name" = "Term"
		$_i += 1

		#add other conditions by settings read from dialog
		IF ($dsWindow.FindName("chkDE").IsChecked -eq $true) {
			$srchConds[$_i]= mCreateSearchCond $UIString["ClassTerms_09"] $mSearchText1 "OR"
			$_i += 1
		}
		IF ($dsWindow.FindName("chkEN").IsChecked -eq $true) {
			$srchConds[$_i]= mCreateSearchCond $UIString["ClassTerms_10"] $mSearchText1 "OR" 
			$_i += 1
		}
		IF ($dsWindow.FindName("chkFR").IsChecked -eq $true) {
			$srchConds[$_i]= mCreateSearchCond $UIString["ClassTerms_11"] $mSearchText1 "OR" 
			$_i += 1
		}
		IF ($dsWindow.FindName("chkIT").IsChecked -eq $true) {
			$srchConds[$_i]= mCreateSearchCond $UIString["ClassTerms_12"] $mSearchText1 "OR" 
			$_i += 1
		}
		# if filters are used limit the search to the classification groups. Apply AND conditions
		IF ($mBreadCrumb.Children[1].SelectedIndex -ge 0) {
			$mSearchGroupName = $mBreadCrumb.Children[1].Text
			$srchConds[$_i]= mCreateSearchCond $UIString["Class_00"] $mSearchGroupName "AND" #search in Segment class
			$_i += 1
		}
				IF ($mBreadCrumb.Children[2].SelectedIndex -ge 0) {
			$mSearchGroupName = $mBreadCrumb.Children[2].Text
			$srchConds[$_i]= mCreateSearchCond $UIString["Class_01"] $mSearchGroupName "AND" 
			$_i += 1
		}
		IF ($mBreadCrumb.Children[3].SelectedIndex -ge 0) {
			$mSearchGroupName = $mBreadCrumb.Children[3].Text
			$srchConds[$_i]= mCreateSearchCond $UIString["Class_02"] $mSearchGroupName "AND" 
			$_i += 1
		}
		IF ($mBreadCrumb.Children[4].SelectedIndex -ge 0) {
			$mSearchGroupName = $mBreadCrumb.Children[4].Text
			$srchConds[$_i]= mCreateSearchCond $UIString["Class_03"] $mSearchGroupName "AND" 
			$_i += 1
		}
		$dsDiag.Trace(" search conditions build") 
		$srchSort = New-Object autodesk.Connectivity.WebServices.SrchSort
		$searchStatus = New-Object autodesk.Connectivity.WebServices.SrchStatus
		$bookmark = ""
		$global:_SearchResult = $vault.CustomEntityService.FindCustomEntitiesBySearchConditions($srchConds,@($srchSort),[ref]$bookmark,[ref]$searchStatus)
		$dsDiag.Trace(" search result exists") 

		# 	retrieve all properties of the COs found
		$_data = @()
		$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("CUSTENT")
		Foreach ($element in $_SearchResult) {
			$dsDiag.Trace(" ---iterates search result for properties...")

			$properties = $vault.PropertyService.GetPropertiesByEntityIds("CUSTENT",$element.Id) #Properties attached to the CO
			$props = @{}

			foreach ($property in $properties) {
				$dsDiag.Trace("Iiterates properties to get DefIDs...")

				Try {
					$propDef = $propDefs | Where-Object { $_.Id -eq $property.PropDefId }
					$props[$propDef.DispName] = $property.Val
				} 
				catch { $dsDiag.Trace("ERROR ---iterates search result for properties failed !! ---") }
			}

			$dsDiag.Trace(" ---iterates search result for properties finished") 
			#create a row for the element and it's properties
			$row = New-Object CatalogData
			$row.Term_DE = $props[$UIString["ClassTerms_09"]]
			$row.Term_EN = $props[$UIString["ClassTerms_10"]]
			$row.Term_FR = $props[$UIString["ClassTerms_11"]]
			$row.Term_IT = $props[$UIString["ClassTerms_12"]]
		
			$_data += $row
			$dsDiag.Trace("...iterates search result for properties finished.") 
		}
		IF ($_data) { $dsWindow.FindName("txtNoTermFound").Visibility = "Collapsed"}
		ELSE { $dsWindow.FindName("txtNoTermFound").Visibility = "Visible"}

		$dsWindow.FindName("dataGrdTermsFound").ItemsSource = $_data 
	}
	catch {
		$dsDiag.Trace("ERROR --- in m_SearchTerms function") 
	}

}

function mCreateSearchCond ([String] $PropName, [String] $mSearchTxt, [String] $AndOr) {
	$dsDiag.Trace("--SearchCond creation starts... for $PropName and $mSearchTxt ---")
	$srchCond = New-Object autodesk.Connectivity.WebServices.SrchCond
	$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("CUSTENT")
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

function m_SelectTerm {
	$dsDiag.Trace("Term_DE selected to get value written to Title field")
	try 
	{		
		$mSelectedItem = $dsWindow.FindName("dataGrdTermsFound").SelectedItem

		IF ($dsWindow.Name -eq "AutoCADWindow")
		{
			If ($Prop["GEN-TITLE-DES1"]){ $Prop["GEN-TITLE-DES1"].Value = $mSelectedItem.Term_DE} #AutoCAD Mechanical Title Attribute Name
			If ($Prop["Title"]){ $Prop["Title"].Value = $mSelectedItem.Term_DE} #Vanilla AutoCAD Title Attribute Name
			Try{
				$Prop["Title_EN"].Value = $mSelectedItem.Term_EN
			}
			catch{ $dsDiag.Trace("Title_EN does not exist")}
		}
		IF ($dsWindow.Name -eq "InventorWindow")
		{
			#region tab-rendering 
			# the tab is rendered with each activation and would re-read sources or require again user input in controls; property values are in runspace memory
			# note - using the tabTerms in different windows (xaml) might require to add a switch node here
			$_temp1 = $dsWindow.FindName("Categories").SelectedIndex
			#endregion

			$Prop["Title"].Value = $mSelectedItem.Term_DE
			Try{
				$Prop["Title_EN"].Value = $mSelectedItem.Term_EN
			}
			catch{ $dsDiag.Trace("Title_EN does not exist")}
			
		}
		IF ($dsWindow.Name -eq "FileWindow") {
			
			#region tab-rendering 
			# the tab is rendered with each activation and would re-read sources or require again user input in controls; property values are in runspace memory
			# note - using the tabTerms in different windows (xaml) might require to add a switch node here
			$_temp10 = $dsWindow.FindName("DocTypeCombo").SelectedIndex
			$_temp40 = $dsWindow.FindName("NumSchms").IsEnabled
			$_temp41 = $dsWindow.FindName("btnOK").IsEnabled
			#endregion

			$Prop["_XLTN_TITLE"].Value = $mSelectedItem.Term_DE
			Try {
				$Prop["_XLTN_TITLE-DE"].Value = $mSelectedItem.Term_DE
			}
			catch { $dsDiag.Trace("Title DE does not exist")}
			Try {
				$Prop["_XLTN_TITLE-EN"].Value = $mSelectedItem.Term_EN
			}
			catch { $dsDiag.Trace("Title EN does not exist")}
			Try {
				$Prop["_XLTN_TITLE-FR"].Value = $mSelectedItem.Term_FR
			}
			catch { $dsDiag.Trace("Title FR does not exist")}
			Try {
				$Prop["_XLTN_TITLE-IT"].Value = $mSelectedItem.Term_IT
			}
			catch { $dsDiag.Trace("Title IT does not exist")}
		}

		$dsWindow.FindName("btnSearchTerm").IsDefault = $false
		$dsWindow.FindName("btnOK").IsDefault = $true

		#region tab-rendering restore
			IF ($_temp1) {	$dsWindow.FindName("Categories").SelectedIndex = $_temp1}
			IF ($_temp10) { $dsWindow.FindName("DocTypeCombo").SelectedIndex = $_temp10}
			IF ($_temp40) { $dsWindow.FindName("NumSchms").IsEnabled = $_temp40}
			IF ($_temp41) { $dsWindow.FindName("btnOK") = $_temp41} 
		#endregion
	}
	Catch 
	{
		$dsDiag.Trace("Error writing term.value(s) to property field")
	}
	
	$dsWindow.FindName("tabProperties").IsSelected = $true
}

#endregion CatalogLookUp

#region BreadCrumb ClassSelection
function mAddCoCombo ([String] $_CoName, $_classes) {
	$children = mgetCustomEntityList -_CoName $_CoName
	if($children -eq $null) { return }
	$mBreadCrumb = $dsWindow.FindName("wrpClassification")
	$cmb = New-Object System.Windows.Controls.ComboBox
	$cmb.Name = "cmbClassBreadCrumb_" + $mBreadCrumb.Children.Count.ToString();
	$cmb.DisplayMemberPath = "Name";
	$cmb.Tooltip = $UIString["ClassTerms_TT01"] #"Suche auf Hierarchieebene begrenzen..."
	$cmb.ItemsSource = @($children)
	#IF (($Prop["_CreateMode"].Value -eq $true) -or ($_Return -eq "Yes")) {$cmb.IsDropDownOpen = $true}
	$cmb.MinWidth = 140
	$cmb.HorizontalContentAlignment = "Center"
	$cmb.BorderThickness = "1,1,1,1"
	$mWindowName = $dsWindow.Name
		switch($mWindowName)
		{
			"CustomObjectTermWindow"
			{
				IF (($Prop["_CreateMode"].Value -eq $true) -or ($_Return -eq "Yes")) {$cmb.IsDropDownOpen = $true}
			}
			default
			{
				$cmb.IsDropDownOpen = $false
			}
		}
	$cmb.add_SelectionChanged({
			param($sender,$e)
			$dsDiag.Trace("1. SelectionChanged, Sender = $sender, $e")
			mCoComboSelectionChanged -sender $sender
		});
	$mBreadCrumb.RegisterName($cmb.Name, $cmb) #register the name to activate later via indexed name
	$mBreadCrumb.Children.Add($cmb);

	#region EditMode CustomObjectTerm Window
	If ($dsWindow.Name-eq "CustomObjectTermWindow")
	{
		IF ($Prop["_EditMode"].Value -eq $true)
		{
			$_cmbNames = @()
			Foreach ($_cmbItem in $cmb.Items) 
			{
				$dsDiag.Trace("---$_cmbItem---")
				$_cmbNames += $_cmbItem.Name
			}
			$dsDiag.Trace("Combo $index Namelist = $_cmbNames")
			if ($_classes[0]) #avoid activation of null ;)
			{
				$_CurrentName = $_classes[0]
				$dsDiag.Trace("Current Name: $_CurrentName ")
				#get the index of name in array
				$i = 0
				Foreach ($_Name in $_cmbNames) 
				{
					$_1 = $_cmbNames.count
					$_2 = $_cmbNames[$i]
					$dsDiag.Trace(" Counter: $i von $_1 Value: $_2  and CurrentName: $_CurrentName ")
					If ($_cmbNames[$i] -eq $_CurrentName) 
					{
						$_IndexToActivate = $i
					}
					$i +=1
				}
				$dsDiag.Trace("Index of current name: $_IndexToActivate ")
				$cmb.SelectedIndex = $_IndexToActivate			
			} #end if classes[0]
			
		}
	}
	#endregion
} # addCoCombo

function mAddCoComboChild ($data) {
	$children = mGetCustomEntityUsesList -sender $data
	$dsDiag.Trace("check data object: $children")
	if($children -eq $null) { return }
	$mBreadCrumb = $dsWindow.FindName("wrpClassification")
	$cmb = New-Object System.Windows.Controls.ComboBox
	$cmb.Name = "cmbClassBreadCrumb_" + $mBreadCrumb.Children.Count.ToString();
	$cmb.DisplayMemberPath = "Name";
	$cmb.ItemsSource = @($children)	
	$cmb.BorderThickness = "1,1,1,1"
	$cmb.HorizontalContentAlignment = "Center"
	$cmb.MinWidth = 140
	$mWindowName = $dsWindow.Name
		switch($mWindowName)
		{
			"CustomObjectTermWindow"
			{
				IF (($Prop["_CreateMode"].Value -eq $true) -or ($_Return -eq "Yes")) {$cmb.IsDropDownOpen = $true}
			}
			default
			{
				$cmb.IsDropDownOpen = $true
			}
		}
	$cmb.add_SelectionChanged({
			param($sender,$e)
			$dsDiag.Trace("next. SelectionChanged, Sender = $sender")
			mCoComboSelectionChanged -sender $sender
		});
	$mBreadCrumb.RegisterName($cmb.Name, $cmb) #register the name to activate later via indexed name
	$mBreadCrumb.Children.Add($cmb)
	$_i = $mBreadCrumb.Children.Count
	$_Label = "lblGroup_" + $_i
	$dsDiag.Trace("Label to display: $_Label - but not longer used")
	# 	$dsWindow.FindName("$_Label").Visibility = "Visible"
	
	#region EditMode for CustomObjectTerm Window
	If ($dsWindow.Name-eq "CustomObjectTermWindow")
	{
		IF ($Prop["_EditMode"].Value -eq $true)
		{
			Try
			{
				$_cmbNames = @()
				Foreach ($_cmbItem in $cmb.Items) 
				{
					$dsDiag.Trace("---$_cmbItem---")
					$_cmbNames += $_cmbItem.Name
				}
				$dsDiag.Trace("Combo $index Namelist = $_cmbNames")
				#get the index of name in array
				if ($_classes[$_i-2]) #avoid activation of null ;)
				{
					$_CurrentName = $_classes[$_i-2] #remember the number of breadcrumb children is +2 (delete button, and the class start with index 0)
					$dsDiag.Trace("Current Name: $_CurrentName ")
					$i = 0
					Foreach ($_Name in $_cmbNames) 
					{
						$_1 = $_cmbNames.count
						$_2 = $_cmbNames[$i]
						$dsDiag.Trace(" Counter: $i von $_1 Value: $_2  and CurrentName: $_CurrentName ")
						If ($_cmbNames[$i] -eq $_CurrentName) 
						{
							$_IndexToActivate = $i
						}
						$i +=1
					}
					$dsDiag.Trace("Index of current name: $_IndexToActivate ")
					$cmb.SelectedIndex = $_IndexToActivate
				} #end
							
			} #end try
		catch 
		{
			$dsDiag.Trace("Error activating an existing index in edit mode.")
		}
	}
	}
	#endregion
} #addCoComboChild

function mgetCustomEntityList ([String] $_CoName) {
	try {
		$dsDiag.Trace(">> mgetCustomEntityList started")
		$srchConds = New-Object autodesk.Connectivity.WebServices.SrchCond[] 1
		$srchCond = New-Object autodesk.Connectivity.WebServices.SrchCond
		$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("CUSTENT")
		$propNames = @("CustomEntityName")
		$propDefIds = @{}
		foreach($name in $propNames) {
			$propDef = $propDefs | Where-Object { $_.SysName -eq $name }
			$propDefIds[$propDef.Id] = $propDef.DispName
		}
		$srchCond.PropDefId = $propDef.Id
		$srchCond.SrchOper = 3
		$srchCond.SrchTxt = $_CoName
		$srchCond.PropTyp = [Autodesk.Connectivity.WebServices.PropertySearchType]::SingleProperty
		$srchCond.SrchRule = [Autodesk.Connectivity.WebServices.SearchRuleType]::Must
		$srchConds[0] = $srchCond
		$srchSort = New-Object autodesk.Connectivity.WebServices.SrchSort
		$searchStatus = New-Object autodesk.Connectivity.WebServices.SrchStatus
		$bookmark = ""
		$_CustomEnts = $vault.CustomEntityService.FindCustomEntitiesBySearchConditions($srchConds,$null,[ref]$bookmark,[ref]$searchStatus)
		$dsDiag.Trace(".. mgetCustomEntityList finished - returns $_CustomEnts <<")
		return $_CustomEnts
	}
	catch { 
		$dsDiag.Trace("!! Error in mgetCustomEntityList")
	}
}

function mGetCustomEntityUsesList ($sender) {
	try {
		$dsDiag.Trace(">> mGetCustomEntityUsesList started")
		$mBreadCrumb = $dsWindow.FindName("wrpClassification")
		$_i = $mBreadCrumb.Children.Count -1
		$_CurrentCmbName = "cmbBreadCrumb_" + $mBreadCrumb.Children.Count.ToString()
		$_CurrentClass = $mBreadCrumb.Children[$_i].SelectedValue.Name
		#[System.Windows.MessageBox]::Show("Currentclass: $_CurrentClass and Level# is $_i")
        switch($_i-1)
		        {
			        0 { $mSearchFilter = $UIString["Class_00"]}
			        1 { $mSearchFilter = $UIString["Class_01"]}
			        2 { $mSearchFilter = $UIString["Class_02"]}
					3 { $mSearchFilter = $UIString["Class_03"]}
			        default { $mSearchFilter = "*"}
		        }
		$_customObjects = mgetCustomEntityList -_CoName $mSearchFilter
		$_Parent = $_customObjects | Where-Object { $_.Name -eq $_CurrentClass }
		try {
			$links = $vault.DocumentService.GetLinksByParentIds(@($_Parent.Id),@("CUSTENT"))
			$linkIds = @()
			$links | ForEach-Object { $linkIds += $_.ToEntId }
			$mLinkedCustObjects = $vault.CustomEntityService.GetCustomEntitiesByIds($linkIds);
			#todo: check that we need to filter the list returned
			$dsDiag.Trace(".. mgetCustomEntityUsesList finished - returns $mLinkedCustObjects <<")
			return $mLinkedCustObjects #$global:_Groups
		}
		catch {
			$dsDiag.Trace("!! Error getting links of Parent Co !!")
			return $null
		}
	}
	catch { $dsDiag.Trace("!! Error in mAddCoComboChild !!") }
}

function mCoComboSelectionChanged ($sender) {
	$mBreadCrumb = $dsWindow.FindName("wrpClassification")
	$position = [int]::Parse($sender.Name.Split('_')[1]);
	$children = $mBreadCrumb.Children.Count - 1
	while($children -gt $position )
	{
		$cmb = $mBreadCrumb.Children[$children]
		$mBreadCrumb.UnregisterName($cmb.Name) #unregister the name to correct for later addition/registration
		$mBreadCrumb.Children.Remove($mBreadCrumb.Children[$children]);
		$children--;
	}
	Try{
		$Prop["_XLTN_SEGMENT"].Value = $mBreadCrumb.Children[1].SelectedItem.Name
		$Prop["_XLTN_MAINGROUP"].Value = $mBreadCrumb.Children[2].SelectedItem.Name
		$Prop["_XLTN_GROUP"].Value = $mBreadCrumb.Children[3].SelectedItem.Name
		$Prop["_XLTN_SUBGROUP"].Value = $mBreadCrumb.Children[4].SelectedItem.Name
	}
	catch{}
	#$dsDiag.Trace("---combo selection = $_selected, Position $position")
	mAddCoComboChild -sender $sender.SelectedItem
}

function mResetClassFilter
{
    $dsDiag.Trace(">> Reset Filter started...")
	$mWindowName = $dsWindow.Name
        switch($mWindowName)
		{
			"CustomObjectTermWindow"
			{
				IF ($Prop["_EditMode"].Value -eq $true)
				{
					try
					{
						$Global:_Return=[System.Windows.MessageBox]::Show($UIString["ClassTerms_MSG01"], $UIString["ClassTerms_01"], 4)
						If($_Return -eq "No") { return }
					}
					catch
					{
						$dsDiag.Trace("Error - Reset Terms Classification Filter")
					}
			}
				IF (($Prop["_CreateMode"].Value -eq $true) -or ($_Return -eq "Yes"))
				{
					$mBreadCrumb = $dsWindow.FindName("wrpClassification")
					$mBreadCrumb.Children[1].SelectedIndex = -1
				}
			}
			default
			{
				$mBreadCrumb = $dsWindow.FindName("wrpClassification")
				$mBreadCrumb.Children[1].SelectedIndex = -1
			}
		}

	$dsDiag.Trace("...Reset Filter finished <<")
}
#endregion BreadCrumb ClassSelection

function mCatalogClick
{
	$dsWindow.FindName("tabTermsCatalog").IsSelected = $true
}