

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
		$breadCrumb = $dsWindow.FindName("wrpClassification")
		$_t1 = $breadCrumb.Children[1].SelectedIndex
		IF ($breadCrumb.Children[1].SelectedIndex -ge 0) { $_NumConds +=1}
		IF ($breadCrumb.Children[2].SelectedIndex -ge 0) { $_NumConds +=1}
		IF ($breadCrumb.Children[3].SelectedIndex -ge 0) { $_NumConds +=1}
		IF ($breadCrumb.Children[4].SelectedIndex -ge 0) { $_NumConds +=1}

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
			$srchConds[$_i]= mCreateSearchCond $UIString["ClassTerms_09"] $mSearchText1 "OR" #ToDo: replace by UIString
			$_i += 1
		}
		IF ($dsWindow.FindName("chkEN").IsChecked -eq $true) {
			$srchConds[$_i]= mCreateSearchCond $UIString["ClassTerms_10"] $mSearchText1 "OR" #ToDo: replace by UIString
			$_i += 1
		}
		IF ($dsWindow.FindName("chkFR").IsChecked -eq $true) {
			$srchConds[$_i]= mCreateSearchCond $UIString["ClassTerms_11"] $mSearchText1 "OR" #ToDo: replace by UIString
			$_i += 1
		}
		IF ($dsWindow.FindName("chkIT").IsChecked -eq $true) {
			$srchConds[$_i]= mCreateSearchCond $UIString["ClassTerms_12"] $mSearchText1 "OR" #ToDo: replace by UIString
			$_i += 1
		}
		# if filters are used limit the search to the classification groups. Apply AND conditions
		IF ($breadCrumb.Children[1].SelectedIndex -ge 0) {
			$mSearchGroupName = $breadCrumb.Children[1].Text
			$srchConds[$_i]= mCreateSearchCond $UIString["Class_00"] $mSearchGroupName "AND" #search in Segment class
			$_i += 1
		}
				IF ($breadCrumb.Children[2].SelectedIndex -ge 0) {
			$mSearchGroupName = $breadCrumb.Children[2].Text
			$srchConds[$_i]= mCreateSearchCond $UIString["Class_01"] $mSearchGroupName "AND" #ToDo: replace by UIString
			$_i += 1
		}
		IF ($breadCrumb.Children[3].SelectedIndex -ge 0) {
			$mSearchGroupName = $breadCrumb.Children[3].Text
			$srchConds[$_i]= mCreateSearchCond $UIString["Class_02"] $mSearchGroupName "AND" #ToDo: replace by UIString
			$_i += 1
		}
		IF ($breadCrumb.Children[4].SelectedIndex -ge 0) {
			$mSearchGroupName = $breadCrumb.Children[4].Text
			$srchConds[$_i]= mCreateSearchCond $UIString["Class_03"] $mSearchGroupName "AND" #ToDo: replace by UIString
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
			$row.Term_DE = $props[$UIString["ClassTerms_09"]] #toDo: replace "Begriff xx" by UIString
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
		#region tab-rendering 
			# the tab is rendered with each activation and would re-read sources or require again user input in controls; property values are in runspace memory
			# note - using the tabTerms in different windows (xaml) might require to add a switch node here
			#$_temp1 = $dsWindow.FindName("Categories").Text
			$_temp10 = $dsWindow.FindName("DocTypeCombo").SelectedIndex
			$_temp40 = $dsWindow.FindName("NumSchms").IsEnabled
			$_temp41 = $dsWindow.FindName("btnOK").IsEnabled
		#endregion
		
		$mSelectedItem = $dsWindow.FindName("dataGrdTermsFound").SelectedItem

		IF ($dsWindow.Name -eq "AutoCADWindow")
		{
			If ($Prop["GEN-TITLE-DES1"])#ACM Attribute Name Mapping
			{
				$Prop["GEN-TITLE-DES1"].Value = $mSelectedItem.Item 
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
		IF ($dsWindow.Name -eq "FileWindow") {
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
			#$dsWindow.FindName("Categories").Text = $_temp1
			IF ($_temp10) { $dsWindow.FindName("DocTypeCombo").SelectedIndex = $_temp10}
			IF ($_temp40) { $dsWindow.FindName("NumSchms").IsEnabled = $_temp40}
			IF ($_temp41) { $dsWindow.FindName("btnOK") = $_temp41} 
		#endregion
	}
	Catch 
	{
		$dsDiag.Trace("Error writing term.value(s) to property field")
	}
	
	$dsWindow.FindName("tabFileProperties").IsSelected = $true
}

