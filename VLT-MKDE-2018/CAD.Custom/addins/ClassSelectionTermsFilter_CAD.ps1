#Sample script using breadcrumb objects for any hierarchy selection

function mAddCoCombo ([String] $_CoName) {
	$children = mgetCustomEntityList -_CoName $_CoName
	if($children -eq $null) { return }
	$breadCrumb = $dsWindow.FindName("wrpClassification")
	$cmb = New-Object System.Windows.Controls.ComboBox
	$cmb.Name = "cmbClassBreadCrumb_" + $breadCrumb.Children.Count.ToString();
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
	$breadCrumb.RegisterName($cmb.Name, $cmb) #register the name to activate later via indexed name
	$breadCrumb.Children.Add($cmb);

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
	$breadCrumb = $dsWindow.FindName("wrpClassification")
	$cmb = New-Object System.Windows.Controls.ComboBox
	$cmb.Name = "cmbClassBreadCrumb_" + $breadCrumb.Children.Count.ToString();
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
	$breadCrumb.RegisterName($cmb.Name, $cmb) #register the name to activate later via indexed name
	$breadCrumb.Children.Add($cmb)
	$_i = $breadCrumb.Children.Count
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
		$breadCrumb = $dsWindow.FindName("wrpClassification")
		$_i = $breadCrumb.Children.Count -1
		$_CurrentCmbName = "cmbClassBreadCrumb_" + $breadCrumb.Children.Count.ToString()
		$_CurrentClass = $breadCrumb.Children[$_i].SelectedValue.Name
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
	$breadCrumb = $dsWindow.FindName("wrpClassification")
	$position = [int]::Parse($sender.Name.Split('_')[1]);
	$children = $breadCrumb.Children.Count - 1
	while($children -gt $position )
	{
		$cmb = $breadCrumb.Children[$children]
		$breadCrumb.UnregisterName($cmb.Name) #unregister the name to correct for later addition/registration
		$breadCrumb.Children.Remove($breadCrumb.Children[$children]);
		$children--;
	}
	Try{
		$Prop["_XLTN_SEGMENT"].Value = $breadCrumb.Children[1].SelectedItem.Name
		$Prop["_XLTN_MAINGROUP"].Value = $breadCrumb.Children[2].SelectedItem.Name
		$Prop["_XLTN_GROUP"].Value = $breadCrumb.Children[3].SelectedItem.Name
		$Prop["_XLTN_SUBGROUP"].Value = $breadCrumb.Children[4].SelectedItem.Name
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
						$Global:_Return=[System.Windows.MessageBox]::Show("You are going to change the selected classification, are you sure?", "Autodesk Vault - Catalog", 4)
						If($_Return -eq "No") { return }
					}
					catch
					{
						$dsDiag.Trace("Error - Reset Terms Classification Filter")
					}
			}
				IF (($Prop["_CreateMode"].Value -eq $true) -or ($_Return -eq "Yes"))
				{
					$breadCrumb = $dsWindow.FindName("wrpClassification")
					$breadCrumb.Children[1].SelectedIndex = -1
				}
			}
			default
			{
				$breadCrumb = $dsWindow.FindName("wrpClassification")
				$breadCrumb.Children[1].SelectedIndex = -1
			}
		}
      


	
	
	$dsDiag.Trace("...Reset Filter finished <<")
}