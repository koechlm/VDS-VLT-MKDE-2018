#=============================================================================#
# PowerShell script sample for Vault Data Standard                            #
#			 Autodesk Vault - Quickstart 2018  								  #
# This sample is based on VDS 2018 RTM and adds functionality and rules       #
# All additions are marked with 'region Quickstart' - 'endregion'			  #
#                                                                             #
# Copyright (c) Autodesk - All rights reserved.                               #
#                                                                             #
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER   #
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES #
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.  #
#=============================================================================#

function InitializeWindow
{
	#$dsDiag.ShowLog()
	#$dsDiag.Clear()

	#begin rules applying commonly
    $dsWindow.Title = SetWindowTitle		
    if ($Prop["_CreateMode"].Value)
    {		
		if (-not $Prop["_SaveCopyAsMode"].Value)
		{
			#region Quickstart comment out default
				#$Prop["_Category"].add_PropertyChanged({
				#	if ($_.PropertyName -eq "Value")
				#	{
				#		$Prop["_NumSchm"].Value = $Prop["_Category"].Value
				#	}	
				#})
				#$Prop["_Category"].Value = $UIString["CAT1"] # quickstart activates different categories for Inventor models, drawings and AutoCAD drawings
			#endregion
        }
		else
        {
            $Prop["_NumSchm"].Value = "None"
        }
        $mappedRootPath = $Prop["_VaultVirtualPath"].Value + $Prop["_WorkspacePath"].Value
    	$mappedRootPath = $mappedRootPath -replace "\\", "/" -replace "//", "/"
        if ($mappedRootPath -eq '')
        {
            $mappedRootPath = '$'
        }

		#region quickstart
			$global:CAx_Root = $mappedRootPath #we need the path for the run time of the dialog
    	#endregion

		try
		{
			$rootFolder = $vault.DocumentService.GetFolderByPath($mappedRootPath)
    		$root = New-Object PSObject -Property @{ Name = $rootFolder.Name; ID=$rootFolder.Id }
			$global:expandBreadCrumb = $false
    		AddCombo -data $root
			$paths = $Prop["_SuggestedVaultPath"].Value.Split('\\',[System.StringSplitOptions]::RemoveEmptyEntries)
		}
		catch [System.Exception]
		{		
			[System.Windows.MessageBox]::Show("Your Inventor IPJ settings don't match the Vault environment you are logged into. Ensure that the IPJ file and Inventor Workspace set in the IPJ exist in Vault.","Vault MFG Quickstart")
		}		

		#region Quickstart
			If(!$paths){ $paths = mReadLastUsedFolder}
			mActivateBreadCrumbCmbs $paths		
		#endregion

		#Set author
		$Prop["Author"].Value = ($vault.AdminService.GetUserByUserId($VaultConnection.UserId)).Name #(FirstName; LastName are available as well)

    }

	#end rules applying commonly
	$mWindowName = $dsWindow.Name
	switch($mWindowName)
	{
		"InventorWindow"
		{
			#region Quickstart
			#	there are some custom functions to enhance functionality:
			[System.Reflection.Assembly]::LoadFrom($Env:ProgramData + "\Autodesk\Vault 2018\Extensions\DataStandard" + '\Vault.Custom\addinVault\QuickstartUtilityLibrary.dll')

			#	initialize the context for Drawings or presentation files as these have Vault Option settings
			$global:mGFN4Special = $Prop["_GenerateFileNumber4SpecialFiles"].Value
			if ($global:mGFN4Special -eq $true)
			{
				$dsWindow.FindName("GFN4Special").IsChecked = $true # this checkbox is used by the XAML dialog styles, to enable / disable or show / hide controls
			}
			$mGFN4STypes = ("IDW", "DWG", "IPN") #to compare that the current new file is one of the special files the option applies to
			if ($mGFN4STypes -contains $Prop["_FileExt"].Value) {
				$global:mIsGFN4 = $true
				$dsWindow.FindName("IsGFN4Type").IsChecked = $true
				If ($global:mIsGFN4-eq $true -and $global:mGFN4Special -eq $false) #IDW/DWG, IPN - Don't generate new document number
				{ 
					$dsWindow.FindName("BreadCrumb").IsEnabled = $false
					$dsWindow.FindName("GroupFolder").Visibility = "Collapsed"
				}
				Else {$dsWindow.FindName("BreadCrumb").IsEnabled = $true} #IDW/DWG, IPN - Generate new document number
			}

			$global:_ModelPath = $null
			switch ($Prop["_CreateMode"].Value) 
			{
				$true 
				{
					$Prop["Part Number"].Value = "" #reset the part number for new files as Inventor writes the file name (no extension) as a default.
					If ($Prop["Replacement"]) {$Prop["Replacement"].Value = "--"}

					#$dsDiag.Trace(">> CreateMode Section executes...")

					# in case the current vault is not quickstart, but a plain MFG default configuration we don't differentiate categories
					$mCatName = GetCategories | Where {$_.Name -eq $UIString["CAT1"]} #"Engineering"
					IF ($mCatName) { $Prop["_Category"].Value = $UIString["CAT1"]}
					Else  # set the category based on file type
					{
						switch($Prop["_FileExt"].Value)
						{
							"ipt"
							{
								#differentiate sheet metal subtype first
								If ($Document.SubType -eq "{9C464203-9BAE-11D3-8BAD-0060B0CE6BB4}")
								{
									$Prop["_Category"].Value = "Blechteil" 
								}
								Else { $Prop["_Category"].Value = "Bauteil" }
							}
							"iam" 
							{
								$Prop["_Category"].Value = "Baugruppe"
							}
							"ipn"
							{
								$Prop["_Category"].Value = "Präsentation"
							}
							"idw"
							{
								$Prop["_Category"].Value = "Zeichnung Inventor"
							}
							"dwg"
							{
								$Prop["_Category"].Value = "Zeichnung Inventor"
							}
							default {}
						}
					}

					#region FDU Support --------------------------------------------------------------------------
					
					# Read FDS related internal meta data; required to manage particular workflows
					$_mInvHelpers = New-Object QuickstartUtilityLibrary.InvHelpers
					If ($_mInvHelpers.m_FDUActive($Application))
					{
						#[System.Windows.MessageBox]::Show("Active FDU-AddIn detected","Vault MFG Quickstart")
						$_mFdsKeys = $_mInvHelpers.m_GetFdsKeys($Application, @{})

						# some FDS workflows require VDS cancellation; add the conditions to the event handler _Loaded below
						$dsWindow.add_Loaded({
							IF ($mSkipVDS -eq $true)
							{
								$dsWindow.CancelWindowCommand.Execute($this)
								#$dsDiag.Trace("FDU-VDS EventHandler: Skip Dialog executed")	
							}
						})

						# FDS workflows with individual settings					
						$dsWindow.FindName("Categories").add_SelectionChanged({
							If ($Prop["_Category"].Value -eq "Factory Asset" -and $Document.FileSaveCounter -eq 0) #don't localize name according FDU fixed naming
							{
								$paths = @("Factory Asset Library Source")
								mActivateBreadCrumbCmbs $paths
							}
						})
				
						If($_mFdsKeys.ContainsKey("FdsType") -and $Document.FileSaveCounter -eq 0 )
						{
							#$dsDiag.Trace(" FDS File Type detected")
							# for new assets we suggest to use the source file folder name, nothing else
							If($_mFdsKeys.Get_Item("FdsType") -eq "FDS-Asset")
							{
								# only the MSDCE FDS configuration template provides a category for assets, check for this otherwise continue with the selection done before
								$mCatName = GetCategories | Where {$_.Name -eq "Factory Asset"}
								IF ($mCatName) { $Prop["_Category"].Value = "Factory Asset"}
							}
							# skip for publishing the 3D temporary file save event for VDS
							If($_mFdsKeys.Get_Item("FdsType") -eq "FDS-Asset" -and $Application.SilentOperation -eq $true)
							{ 
								#$dsDiag.Trace(" FDS publishing 3D - using temporary assembly silent mode: need to skip VDS!")
								$global:mSkipVDS = $true
							}
							If($_mFdsKeys.Get_Item("FdsType") -eq "FDS-Asset" -and $Document.InternalName -ne $Application.ActiveDocument.InternalName)
							{
								#$dsDiag.Trace(" FDS publishing 3D: ActiveDoc.InternalName different from VDSDoc.Internalname: Verbose VDS")
								$global:mSkipVDS = $true
							}

							# 
							If($_mFdsKeys.Get_Item("FdsType") -eq "FDS-Layout" -and $_mFdsKeys.Count -eq 1)
							{
								#$dsDiag.Trace("3DLayout, not synced")
								# only the MSDCE FDS configuration template provides a category for layouts, check for this otherwise continue with the selection done before
								$mCatName = GetCategories | Where {$_.Name -eq "Factory Layout"}
								IF ($mCatName) { $Prop["_Category"].Value = "Factory Layout"}
							}

							# this state is for validation only - you must not get there; if you do then you miss the SkipVDSon1stSave.IAM template
							If($_mFdsKeys.Get_Item("FdsType") -eq "FDS-Layout" -and $_mFdsKeys.Count -gt 1 -and $Document.FileSaveCounter -eq 0)
							{
								#$dsDiag.Trace("3DLayout not saved yet, but already synced")
							}
						}
					}
					#endregion FDU Support --------------------------------------------------------------------------

					#retrieve 3D model properties (Inventor captures these also, but too late; we are currently before save event transfers model properties to drawing properties) 
					# but don't do this, if the copy mode is active
					if ($Prop["_CopyMode"].Value -eq $false) 
					{
						if (($Prop["_FileExt"].Value -eq "idw") -or ($Prop["_FileExt"].Value -eq "dwg" )) 
						{
							$_mInvHelpers = New-Object QuickstartUtilityLibrary.InvHelpers #NEW 2018 hand over the parent inventor application, to ensure the correct instance
							$_ModelFullFileName = $_mInvHelpers.m_GetMainViewModelPath($Application)#NEW 2018 hand over the parent inventor application, to ensure the correct instance
							$Prop["Title"].Value = $_mInvHelpers.m_GetMainViewModelPropValue($Application, $_ModelFullFileName,"Title")
							$Prop["Description"].Value = $_mInvHelpers.m_GetMainViewModelPropValue($Application, $_ModelFullFileName,"Description")
							$Prop["Part Number"].Value = $_mInvHelpers.m_GetMainViewModelPropValue($Application, $_ModelFullFileName,"Part Number") 
							
							# Quickstart sets the category to eliminate the manual step of selection
							$mCatName = GetCategories | Where {$_.Name -eq $UIString["MSDCE_CAT00"]}
							IF ($mCatName) { $Prop["_Category"].Value = $UIString["MSDCE_CAT00"]}
							Else # in case the current vault is not quickstart, but a plain MFG default configuration
							{
								$mCatName = GetCategories | Where {$_.Name -eq $UIString["CAT1"]} #"Engineering"
								IF ($mCatName) { $Prop["_Category"].Value = $UIString["CAT1"]}
							}

							#VLT-MKDE: optimize UI if numbering scheme is not used
							If ($global:mGFN4Special -eq $false) # The drawing get's saved to it#s first view's model location and name
							{	
								If ($_ModelFullFileName) {
									$dsWindow.FindName("NumSchms").Visibility = "Collapsed"
									$dsWindow.FindName("DSNumSchmsCtrl").Visibility = "Collapsed"
								}
							}
						}
						
						if ($Prop["_FileExt"].Value -eq "ipn") 
						{
							$_mInvHelpers = New-Object QuickstartUtilityLibrary.InvHelpers #NEW 2018 hand over the parent inventor application, to ensure the correct instance
							$_ModelFullFileName = $_mInvHelpers.m_GetMainViewModelPath($Application)#NEW 2018 hand over the parent inventor application, to ensure the correct instance
							$Prop["Title"].Value = $_mInvHelpers.m_GetMainViewModelPropValue($Application, $_ModelFullFileName,"Title")
							$Prop["Description"].Value = $_mInvHelpers.m_GetMainViewModelPropValue($Application, $_ModelFullFileName,"Description")
							$Prop["Part Number"].Value = $_mInvHelpers.m_GetMainViewModelPropValue($Application, $_ModelFullFileName,"Part Number")
							$Prop["Stock Number"].Value = $_mInvHelpers.m_GetMainViewModelPropValue($Application, $_ModelFullFileName,"Stock Number")
							# for custom properties there is always a risk that any does not exist
							try {
								$Prop[$_iPropSemiFinished].Value = $_mInvHelpers.m_GetMainViewModelPropValue($Application, $_ModelFullFileName,$_iPropSemiFinished)
								$_t1 = $_mInvHelpers.m_GetMainViewModelPropValue($Application, $_ModelFullFileName, $_iPropSpearWearPart)
								if ($_t1 -ne "") {
									$Prop[$_iPropSpearWearPart].Value = $_t1
								}
							} 
							catch {
								$dsDiag.Trace("Set path, filename and properties for IPN: At least one custom property failed, most likely it did not exist and is not part of the cfg ")
							}
						}

						if (($_ModelFullFileName -eq "") -and ($global:mGFN4Special -eq $false)) 
						{ 
							[System.Windows.MessageBox]::Show($UIString["MSDCE_MSG00"],"Vault MFG Quickstart")
							$dsWindow.add_Loaded({
										# Will skip VDS Dialog for Drawings without model view; 
										$dsWindow.CancelWindowCommand.Execute($this)})
						}
					} # end of copy mode = false check

					if ($Prop["_CopyMode"].Value -and @("DWG","IDW","IPN") -contains $Prop["_FileExt"].Value)
					{
						$mCatName = GetCategories | Where {$_.Name -eq $UIString["MSDCE_CAT00"]} #Drawing Inventor
						IF ($mCatName) { $Prop["_Category"].Value = $UIString["MSDCE_CAT00"]}
							# in case the current vault is not quickstart, but a plain MFG default configuration
						Else {
							$mCatName = GetCategories | Where {$_.Name -eq $UIString["CAT1"]} #"Engineering"
							IF ($mCatName) { $Prop["_Category"].Value = $UIString["CAT1"]}
						}
						$Prop["DocNumber"].Value = $Prop["DocNumber"].Value.TrimStart($UIString["CFG2"])
					} #end of copymode = true

				} #end of CreateMode = true
				
				$false # EditMode = True
				{
					#add specific action rules for edit mode here
				}
				default
				{

				}
			} #end switch Create / Edit Mode
			#endregion Quickstart

			#region ItemLookUp
			If ($dsWindow.FindName("tabItemLookup"))
				{$dsWindow.FindName("cmbItemCategories").ItemsSource = mGetItemCategories
				Try
				{
					$dsWindow.FindName("tabCtrlMain").add_SelectionChanged({
					param($sender, $SelectionChangedEventArgs)
					if ($dsWindow.FindName("tabFileProperties").IsSelected -eq $true)
					{
						$dsWindow.FindName("TemplateCB").SelectedIndex = $global:mSelectedTemplate
					}
				})

				}
				catch{ $dsDiag.Trace("WARNING expander exItemLookup is not present") }
				}
			#endregion
		}

		"InventorFrameWindow"
		{
			mInitializeFGContext
		}
		
		"InventorDesignAcceleratorWindow"
		{
			mInitializeDAContext
		}

		"InventorPipingWindow"
		{
			mInitializeTPContext
		}

		"InventorHarnessWindow"
		{
			mInitializeCHContext
		}

		"AutoCADWindow"
		{
			#rules applying for AutoCAD
			#region Quickstart

			switch ($Prop["_CreateMode"].Value) 
			{
				$true 
				{
					#$dsDiag.Trace(">> CreateMode Section executes...")
					# set the category: Quickstart = "AutoCAD Drawing"
					$mCatName = GetCategories | Where {$_.Name -eq $UIString["MSDCE_CAT01"]}
					IF ($mCatName) { $Prop["_Category"].Value = $UIString["MSDCE_CAT01"]}
						# in case the current vault is not quickstart, but a plain MFG default configuration
					Else {
						$mCatName = GetCategories | Where {$_.Name -eq $UIString["CAT1"]} #"Engineering"
						IF ($mCatName) { $Prop["_Category"].Value = $UIString["CAT1"]}
					}
					#set the root folder to Designs instead of $
					$AutoCadRoot = @("Konstruktion") #folders to activate
					for($i=0;$i -lt $AutoCadRoot.Count;$i++)
						{
							$cmb = $dsWindow.FindName("cmbBreadCrumb_"+$i)
							if ($cmb -ne $null) { $cmb.SelectedValue = $AutoCadRoot[$i] 
							}
						}
				}
			}

			#endregion quickstart
		}
		default
		{
			#rules applying for other windows, e.g. FG, DA, TP and CH functional dialogs; SaveCopyAs dialog
		}
	}#end switch windows

	$global:expandBreadCrumb = $true
	
	#region CatalogTerm
				If ($dsWindow.FindName("tabTermsCatalog"))
				{			
					Try{
						Import-Module -FullyQualifiedName "C:\ProgramData\Autodesk\Vault 2018\Extensions\DataStandard\Vault.Custom\addinVault\CatalogTermsTranslations.psm1"
					}
					catch{
						$dsWindow.FindName("tabTermsCatalog").Visibility = "Collapsed"
						return
					}

					Try 
					{
						$mWindowName = $dsWindow.Name
						switch($mWindowName)
						{
							"InventorWindow"
							{
								$dsWindow.FindName("mSearchTermText").text = $Prop["Title"].Value
				
								$Prop["Title"].add_PropertyChanged({
										param( $parameter)
										$dsWindow.FindName("mSearchTermText").text = $Prop["Title"].Value
									})
							}

							"AutoCADWindow" 
							{
								$dsWindow.FindName("mSearchTermText").text = $Prop["GEN-TITLE-DES1"].Value
				
								$Prop["GEN-TITLE-DES1"].add_PropertyChanged({
										param( $parameter)
										$dsWindow.FindName("mSearchTermText").text = $Prop["GEN-TITLE-DES1"].Value
									})
							}
							default
							{}
						}
 
						mAddCoCombo -_CoName $UIString["Class_00"] #enables classification filter for catalog of terms starting with segment

						$dsWindow.FindName("dataGrdTermsFound").add_SelectionChanged({
							param($sender, $SelectionChangedEventArgs)
							$dsDiag.Trace(".. TermsFoundSelection")
							IF($dsWindow.FindName("dataGrdTermsFound").SelectedItem){
								$dsWindow.FindName("btnAdopt").IsEnabled = $true
								$dsWindow.FindName("btnAdopt").IsDefault = $true
							}
							Else {
								$dsWindow.FindName("btnAdopt").IsEnabled = $false
								$dsWindow.FindName("btnSearchTerm").IsDefault = $true
							}
						})

					} #end try
				catch { $dsDiag.Trace("WARNING tab TermCatalog is not present")}
			}
			#endregionCatalogTerm

	$dsDiag.Trace("... Initialize window end <<")
}#end InitializeWindow

function AddinLoaded
{
	#Executed when DataStandard is loaded in Inventor/AutoCAD
	#region Quickstart
		$m_File = $env:TEMP + "\Folder2018.xml"
		if (!(Test-Path $m_File)){
			$source = $Env:ProgramData + "\Autodesk\Vault 2018\Extensions\DataStandard\Vault.Custom\Folder2018.xml"
			Copy-Item $source $env:TEMP\Folder2018.xml
		}
	#endregion quickstart
}
function AddinUnloaded
{
	#Executed when DataStandard is unloaded in Inventor/AutoCAD
}

function SetWindowTitle
{
	if ($Prop["_CreateMode"].Value)
    {
		if ($Prop["_CopyMode"].Value)
		{
			$windowTitle = "$($UIString["LBL60"]) - $($Prop["_OriginalFileName"].Value)"
		}
		elseif ($Prop["_SaveCopyAsMode"].Value)
		{
			$windowTitle = "$($UIString["LBL72"]) - $($Prop["_OriginalFileName"].Value)"
		}else
		{
			$windowTitle = "$($UIString["LBL24"]) - $($Prop["_OriginalFileName"].Value)"
		}
	}
	else
	{
		$windowTitle = "$($UIString["LBL25"]) - $($Prop["_FileName"].Value)"
	}
	return $windowTitle
}

function GetNumSchms
{
	try
	{
		if (-Not $Prop["_EditMode"].Value)
        {
            #region quickstart - there is the use case that we don't need a number: IDW/DWG, IPN and Option Generate new file number = off
			If ($global:mIsGFN4-eq $true -and $global:mGFN4Special -eq $false) { return}
			#endregion quickstart

			[System.Collections.ArrayList]$numSchems = @($vault.DocumentService.GetNumberingSchemesByType('Activated'))
            if ($numSchems.Count -gt 1 -and !($Prop["_SaveCopyAsMode"].Value -eq $true)) #second condition added by Quickstart
			#if ($numSchems.Count -gt 1)
			{
				#region Quickstart FDU Support----------------
					$_FilteredNumSchems = @()
					$_temp = $numSchems | Where { $_.IsDflt -eq $true}
					$_FilteredNumSchems += ($_temp)
					if ($Prop["_NumSchm"].Value) { $Prop["_NumSchm"].Value = $_FilteredNumSchems[0].Name} #note - functional dialogs don't have the property _NumSchm, therefore we conditionally set the value
					$dsWindow.FindName("NumSchms").IsEnabled = $true
					$noneNumSchm = New-Object 'Autodesk.Connectivity.WebServices.NumSchm'
					$noneNumSchm.Name = $UIString["LBL77"]
					$_FilteredNumSchems += $noneNumSchm
					return $_FilteredNumSchems
				#endregion Quickstart FDU Support ------------
			}
			if ($numSchems.Count -eq 1 -and !($Prop["_SaveCopyAsMode"].Value -eq $true)) 
			{ 
				return $numSchems 
			}
            if ($Prop["_SaveCopyAsMode"].Value)
            {
                #region Quickstart
					$_FilteredNumSchems = @()
					$_temp = $numSchems | Where { $_.IsDflt -eq $true}
					$_FilteredNumSchems += ($_temp)
					$Prop["_NumSchm"].Value = $_FilteredNumSchems[0].Name
					$dsWindow.FindName("NumSchms").IsEnabled = $true
					$noneNumSchm = New-Object 'Autodesk.Connectivity.WebServices.NumSchm'
					$noneNumSchm.Name = $UIString["LBL77"]
					$_FilteredNumSchems += $noneNumSchm
					return $_FilteredNumSchems
				#end Quickstart
            }    
            #return $numSchems #quickstart returns filtered numbering schemes before

        }
	}
	catch [System.Exception]
	{		
		[System.Windows.MessageBox]::Show($error)
	}	
}

function GetCategories
{
	$mAllCats =  $vault.CategoryService.GetCategoriesByEntityClassId("FILE", $true)
	$mFDSFilteredCats = $mAllCats | Where { $_.Name -ne "Asset Library"}
	return $mFDSFilteredCats
}

function OnPostCloseDialog
{
	$mWindowName = $dsWindow.Name
	switch($mWindowName)
	{
		"InventorWindow"
		{
			#region Quickstart
				if (!($Prop["_CopyMode"].Value -and !$Prop["_GenerateFileNumber4SpecialFiles"].Value -and @("DWG","IDW","IPN") -contains $Prop["_FileExt"].Value))
				{
					mWriteLastUsedFolder
				}

				if ($Prop["_CreateMode"].Value -and !$Prop["Part Number"].Value) #we empty the part number on initialize: if there is no other function to provide part numbers we should apply the Inventor default
				{
					$Prop["Part Number"].Value = $Prop["DocNumber"].Value
				}
			#endregion
		}
		"AutoCADWindow"
		{
			#region Quickstart
				mWriteLastUsedFolder
			#endregion
		}
		default
		{
			#rules applying commonly
		}
	}
	
}

#region quickstart
function mHelp ([Int] $mHContext) {
	try
	{
		switch ($mHContext){
			100 {
				$mHPage = "C.2Inventor.html";
			}
			110 {
				$mHPage = "C.2.11FrameGenerator.html";
			}
			120 {
				$mHPage = "C.2.13DesignAccelerator.html";
			}
			130 {
				$mHPage = "C.2.12TubeandPipe.html";
			}
			140 {
				$mHPage = "C.2.14CableandHarness.html";
			}
			200 {
				$mHPage = "C.3AutoCADAutoCAD.html";
			}
			Default {
				$mHPage = "Index.html";
			}
		}
		$mHelpTarget = $Env:ProgramData + "\Autodesk\Vault 2018\Extensions\DataStandard\HelpFiles\"+$mHPage
		$mhelpfile = Invoke-Item $mHelpTarget 
	}
	catch
	{
		[System.Windows.MessageBox]::Show($UIString["MSDCE_MSG02"], "Vault Quickstart Client")
	}
}

function mReadShortCuts {
	if ($Prop["_CreateMode"].Value -eq $true) {
		#$dsDiag.Trace(">> Looking for Shortcuts...")
		$m_Server = $VaultConnection.Server
		$m_Vault = $VaultConnection.Vault
		$m_AllFiles = @()
		$m_FiltFiles = @()
		$m_Path = $env:APPDATA + '\Autodesk\VaultCommon\Servers\Services_Security_1_6_2017\'
		$m_AllFiles += Get-ChildItem -Path $m_Path -Filter 'Shortcuts.xml' -Recurse
		$m_AllFiles | ForEach-Object {
			if ($_.FullName -like "*"+$m_Server + "*" -and $_.FullName -like "*"+$m_Vault + "*") 
			{
				$m_FiltFiles += $_
			} 
		}
		$global:mScFile = $m_FiltFiles.SyncRoot[$m_FiltFiles.Count-1].FullName
		if (Test-Path $global:mScFile) {
			#$dsDiag.Trace(">> Start reading Shortcuts...")
			$global:m_ScXML = New-Object XML 
			$global:m_ScXML.Load($mScFile)
			$m_ScAll = $m_ScXML.Shortcuts.Shortcut
			#the shortcuts need to get filtered by type of document.folder and path information related to CAD workspace
			$global:m_ScCAD = @{}
			$mScNames = @()
			$mDesignRootFilter = "vaultfolderpath:" + $global:CAx_Root + "/*"
			#$dsDiag.Trace("... Filtering Shortcuts. $mDesignRootFilter..")
			$m_ScAll | ForEach-Object {  
				if ($_.NavigationContextType -eq "Connectivity.Explorer.Document.DocFolder" -and $_.NavigationContext.URI -like $mDesignRootFilter) #like '*' + $global:CAxRoot + '/*'
				{
					try
					{
						$_t = $global:m_ScCAD.Add($_.Name, $_.NavigationContext.URI)
						$mScNames += $_.Name
					}
					catch {
						$dsDiag.Trace("... ERROR Filtering Shortcuts...")
					}
				}
			}
		}
		#$dsDiag.Trace("... returning Shortcuts: $mScNames")
		return $mScNames
	}
}

function mScClick {
	try 
	{
		$_key = $dsWindow.FindName("lstBoxShortCuts").SelectedValue
		$_Val = $global:m_ScCAD.get_item($_key)
		$_SPath = @()
		$_SPath = $_Val.Split("/")

		$m_DesignPathNames = $null
		[System.Collections.ArrayList]$m_DesignPathNames = @()
		#differentiate AutoCAD and Inventor: AutoCAD is able to start in $, but Inventor starts in it's mandatory Workspace folder (IPJ)
		IF ($dsWindow.Name -eq "InventorWindow") {$indexStart = 2}
		If ($dsWindow.Name -eq "AutoCADWindow") {$indexStart = 1}
		for ($index = $indexStart; $index -lt $_SPath.Count; $index++) 
		{
			$m_DesignPathNames += $_SPath[$index]
		}
		if ($m_DesignPathNames.Count -eq 1) { $m_DesignPathNames += "."}
		mActivateBreadCrumbCmbs $m_DesignPathNames
		$global:expandBreadCrumb = $true
	}
	catch
	{
		$dsDiag.Trace("mScClick function - error reading selected value")
	}
	
}

function mAddSc {
	try
	{
		$mNewScName = $dsWindow.FindName("txtNewShortCut").Text
		mAddShortCutByName ($mNewScName)
		$dsWindow.FindName("lstBoxShortCuts").ItemsSource = mReadShortCuts
	}
	catch {}
}

function mRemoveSc {
	try
	{
		$_key = $dsWindow.FindName("lstBoxShortCuts").SelectedValue
		mRemoveShortCutByName $_key
		$dsWindow.FindName("lstBoxShortCuts").ItemsSource = mReadShortCuts
	}
	catch { }
}

function mAddShortCutByName([STRING] $mScName)
{
	try #simply check that the name is unique
	{
		#$dsDiag.Trace(">> Start to add ShortCut, check for used name...")
		$global:m_ScCAD.Add($mScName,"Dummy")
		$global:m_ScCAD.Remove($mScName)
	}
	catch #no reason to continue in case of existing name
	{
		[System.Windows.MessageBox]::Show($UIString["MSDCE_MSG01"], "Vault Quickstart Client")
		end function
	}

	try 
	{
		#$dsDiag.Trace(">> Continue to add ShortCut, creating new from template...")
		#read from template
		$m_File = $env:TEMP + "\Folder2018.xml"
		if (Test-Path $m_File)
		{
			#$dsDiag.Trace(">>-- Started to read Folder2017.xml...")
			$global:m_XML = New-Object XML
			$global:m_XML.Load($m_File)
		}
		$mShortCut = $global:m_XML.Folder.Shortcut | where { $_.Name -eq "Template"}
		#clone the template completely and update name attribute and navigationcontext element
		$mNewSc = $mShortCut.Clone() #.CloneNode($true)
		#rename "Template" to new name
		$mNewSc.Name = $mScName 
		#derive the path from current selection
		$breadCrumb = $dsWindow.FindName("BreadCrumb")
		$newURI = "vaultfolderpath:" + $global:CAx_Root
		foreach ($cmb in $breadCrumb.Children) 
		{
			$_N = $cmb.SelectedItem.Name
			$dsDiag.Trace(" - selecteditem.Name of cmb: $_N ")
			if (($cmb.SelectedItem.Name.Length -gt 0) -and !($cmb.SelectedItem.Name -eq "."))
			{ 
				$newURI = $newURI + "/" + $cmb.SelectedItem.Name
				$dsDiag.Trace(" - the updated URI  of the shortcut: $newURI")
			}
			else { break}
		}
		
		#hand over the path in shortcut navigation format
		$mNewSc.NavigationContext.URI = $newURI
		#append the new shortcut and save back to file
		$mImpNode = $global:m_ScXML.ImportNode($mNewSc,$true)
		$global:m_ScXML.Shortcuts.AppendChild($mImpNode)
		$global:m_ScXML.Save($mScFile)
		$dsWindow.FindName("txtNewShortCut").Text = ""
		$dsDiag.Trace("..successfully added ShortCut <<")
		return $true
	}
	catch 
	{
		$dsDiag.Trace("..problem encountered addeding ShortCut <<")
		return $false
	}
}

function mRemoveShortCutByName ([STRING] $mScName)
{
	try 
	{
		#$dsDiag.Trace(">> Start to remove ShortCut from list")
		$mShortCut = @() #Vault allows multiple shortcuts equally named
		$mShortCut = $global:m_ScXML.Shortcuts.Shortcut | where { $_.Name -eq $mScName}
		$mShortCut | ForEach-Object {
			$global:m_ScXML.Shortcuts.RemoveChild($_)
		}
		$global:m_ScXML.Save($global:mScFile)
		#$dsDiag.Trace("..successfully removed ShortCut <<")
		return $true
	}
	catch 
	{
		return $false
	}
}

function mReadLastUsedFolder {
	#------------- The last used project folder is stored in a XML
	$m_File = $env:TEMP + "\Folder2018.xml"
	if (Test-Path $m_File)
	{
		#$dsDiag.Trace(">>-- Started to read Folder2018.xml...")
		$global:m_XML = New-Object XML
		$global:m_XML.Load($m_File)
		If($dsWindow.Name -eq "InventorWindow") { $m_xmlNode = $global:m_XML.Folder.get_Item("LastUsedFolderInv")}
		If($dsWindow.Name -eq "AutoCADWindow") { $m_xmlNode = $global:m_XML.Folder.get_Item("LastUsedFolderAcad")}
		$m_Attributes = $m_xmlNode.Attributes
		$m_PathNames = $null
		[System.Collections.ArrayList]$m_PathNames = @()
		foreach ($_Attrib in $m_Attributes)
		{
			if($_Attrib.Value -ne "") 
			{
				$m_PathNames += $_Attrib.Value
			}
			Else { break; }	
		}
		if ($m_PathNames.Count -eq 1) { $m_PathNames += "."}
		#$dsDiag.Trace(" about to return $m_PathNames, read from $m_Attributes ")
		return $m_PathNames
		#$dsDiag.Trace("........Reading XML succeeded <<")
	}
}

function mWriteLastUsedFolder 
{
	#$dsDiag.Trace(">> Save project info...")
	$m_File = $env:TEMP + "\Folder2018.xml"
	if (Test-Path $m_File)
	{
		try
		{
			#$dsDiag.Trace(">> Save project info...")
			$m_XML = New-Object XML 
			$m_XML.Load($m_File)
			If($dsWindow.Name -eq "InventorWindow") { $m_xmlNode = $m_XML.Folder.get_Item("LastUsedFolderInv")}
			If($dsWindow.Name -eq "AutoCADWindow") { $m_xmlNode = $m_XML.Folder.get_Item("LastUsedFolderAcad")}
			$m_Attributes = $m_xmlNode.Attributes
			$m_Attributes.RemoveAll()
			$breadCrumb = $dsWindow.FindName("BreadCrumb")
			foreach ($cmb in $breadCrumb.Children) 
			{
				if (!($cmb.SelectedItem.Name -eq "") -and !($cmb.SelectedItem.Name -eq "."))
				{
					$m_AttribKey = $cmb.Name
					$m_AttribVal = $cmb.SelectedItem.Name
					$m_xmlNode.SetAttribute($m_AttribKey,$m_AttribVal)
				}	
			}
			$m_XML.Save($Env:temp + '\Folder2018.xml')
			#$dsDiag.Trace("..saved last used project/folder <<")
		} #end try
		catch [System.Exception]
		{		
			[System.Windows.MessageBox]::Show($error)
		}
	}
}

function mActivateBreadCrumbCmbs ($paths)
{
	try
	{	
		$global:expandBreadCrumb = $false
		for($i=0;$i -lt $paths.Count;$i++)
			{
				$cmb = $dsWindow.FindName("cmbBreadCrumb_"+$i)
				if ($cmb -ne $null) { $cmb.SelectedValue = $paths[$i] }
			}
	} #end try
	catch [System.Exception]
	{		
		[System.Windows.MessageBox]::Show($error, "Quickstart-Activate Folder Selection")
	}
}

#endregion


#region DynGridCommands #toDo: modularize ItemLookup and move command to psm1 file; already done for catalog

function mItemLookUpClick1
{
	$dsWindow.FindName("tabItemLookup").IsSelected = $true   
    $mDocType = $Prop["_FileExt"].Value
        switch($mDocType)
		{
			"ipt"
			{
				$dsWindow.FindName("cmbItemCategories").SelectedValue = "Bauteil"
			}

			"iam" 
			{
				$dsWindow.FindName("cmbItemCategories").SelectedValue = "Baugruppe"
			}

			"idw"
			{
				$dsWindow.FindName("cmbItemCategories").SelectedValue = "Dokument"
			}
			default {}
		}
	$dsWindow.FindName("txtItemSearchText").Text = $Prop['Title'].Value
}
function mItemLookUpClick2
{
	$dsWindow.FindName("tabItemLookup").IsSelected = $true
	$dsWindow.FindName("cmbItemCategories").SelectedValue = "Halbzeug"
}

#endregion


#region functional dialogs
#FrameDocuments[], FrameMemberDocuments[] and SkeletonDocuments[]
function mInitializeFGContext {
	#$dsDiag.Trace(">> Init. DataContext for Frame Window")
	#region Frame
	$mFrmDocs = @()
	$mFrmDocs = $dsWindow.DataContext.FrameDocuments

	$mFrmDocs | ForEach-Object {
		#$dsDiag.Trace(">> Frame Assy $mC")
		$mFrmDcProps = $_.Properties.Properties
		$mProp = $mFrmDcProps | Where-Object { $_.Name -eq "Title"}
		$mProp.Value = $UIString["LBL55"]
		$mProp = $mFrmDcProps | Where-Object { $_.Name -eq "Description"}
		$mProp.Value = $UIString["MSDCE_BOMType_01"]
		#$dsDiag.Trace("Frames Assy end <<") 
	}
	#endregion
	#region Skeleton
	$mSkltnDocs = @()
	$mSkltnDocs = $dsWindow.DataContext.SkeletonDocuments
	$mSkltnDocs | ForEach-Object {
		#$dsDiag.Trace(">> Skeleton Assy $mC")
		$mSkltnDcProps = $_.Properties.Properties
		$mProp = $mSkltnDcProps | Where-Object { $_.Name -eq "Title"}
		$mProp.Value = $UIString["LBL56"]
		$mProp = $mSkltnDcProps | Where-Object { $_.Name -eq "Description"}
		$mProp.Value = $UIString["MSDCE_BOMType_04"]
		#$dsDiag.Trace("Skeleton end <<") 
	}
	#endregion
	#region FrameMembers
	$mFrmMmbrDocs = @()
	$mFrmMmbrDocs = $dsWindow.DataContext.FrameMemberDocuments
	$mFrmMmbrDocs | ForEach-Object {
		#$dsDiag.Trace(">> FrameMember Assy $mC")
		$mFrmMmbrDcProps = $_.Properties.Properties
		$mProp = $mFrmMmbrDcProps | Where-Object { $_.Name -eq "Title"}
		$mProp.Value = $UIString["MSDCE_FrameMember_01"]
		#$dsDiag.Trace("FrameMembers $mC end <<") 
	}
	#endregion
	#$dsDiag.Trace("end DataContext for Frame Window<<")
}

function mInitializeDAContext {
	#$dsDiag.Trace(">> Init DataContext for DA Window")
	$mDsgnAccAssys = @() 
	$mDsgnAccAssys = $dsWindow.DataContext.DesignAcceleratorAssemblies
	$mDsgnAccAssys | ForEach-Object {
		#$dsDiag.Trace(">> DA Assy $mC")
		$mDsgnAccAssyProps = $_.Properties.Properties
		$mTitleProp = $mDsgnAccAssyProps | Where-Object { $_.Name -eq "Title"}
		$mPartNumProp = $mDsgnAccAssyProps | Where-Object { $_.Name -eq "Part Number"}
		$mTitleProp.Value = $UIString["MSDCE_BOMType_01"]
		$mPartNumProp.Value = "" #delete the value to get the new number
		$mProp = $mDsgnAccAssyProps | Where-Object { $_.Name -eq "Description"}
		$mProp.Value = $UIString["MSDCE_BOMType_01"] + " " + $mPartNumProp.Value
		#$dsDiag.Trace("DA Assy $mC end <<")
	}
	$mDsgnAccParts = $dsWindow.DataContext.DesignAcceleratorParts
	$mDsgnAccParts | ForEach-Object {
		#$dsDiag.Trace(">> DA component $mC")
		$mDsgnAccProps = $_.Properties.Properties
		$mTitleProp = $mDsgnAccProps | Where-Object { $_.Name -eq "Title"}
		$mPartNumProp = $mDsgnAccProps | Where-Object { $_.Name -eq "Part Number"}
		$mTitleProp.Value = $mPartNumProp.Value
		$mPartNumProp.Value = "" #delete the value to get the new number
		$mProp = $mDsgnAccProps | Where-Object { $_.Name -eq "Description"}
		$mProp.Value = $mTitleProp.Value
		#$dsDiag.Trace("DA Component $mC end <<")
	}
	#$dsDiag.Trace("DataContext for DA Window end <<")
}

function mInitializeTPContext {
	#region RunAssy
	$mRunAssys = @()
	$mRunAssys = $dsWindow.DataContext.RunAssemblies
	$mRunAssys | ForEach-Object {
		$mRunAssyProps = $_.Properties.Properties
		$mTitleProp = $mRunAssyProps | Where-Object { $_.Name -eq "Title"}	
		$mTitleProp.Value = $UIString["LBL41"]
		$mPartNumProp = $mRunAssyProps | Where-Object { $_.Name -eq "Part Number"}
		$mPartNumProp.Value = "" #delete the value to get the new number
		$mProp = $mRunAssyProps | Where-Object { $_.Name -eq "Description"}
		$mProp.Value = $UIString["MSDCE_BOMType_01"] + " " + $UIString["MSDCE_TubePipe_01"]
	}
	#endregion
	#region Route
	$mRouteParts = @()
	$mRouteParts = $dsWindow.DataContext.RouteParts
	$mRouteParts | ForEach-Object {
		$mRouteProps = $_.Properties.Properties
		$mTitleProp = $mRouteProps | Where-Object { $_.Name -eq "Title"}
		$mTitleProp.Value = $UIString["LBL42"]
		$mPartNumProp = $mRouteProps | Where-Object { $_.Name -eq "Part Number"}
		$mPartNumProp.Value = "" #delete the value to get the new number
		$mProp = $mRouteProps | Where-Object { $_.Name -eq "Description"}
		$mProp.Value = $UIString["MSDCE_BOMType_00"] + " " + $UIString["LBL42"]
	}
	#endregion
	#region RunComponents
	$mRunComponents = @()
	$mRunComponents = $dsWindow.DataContext.RunComponents
	$mRunComponents | ForEach-Object {
		$mRunCompProps = $_.Properties.Properties
		$mTitleProp = $mRunCompProps | Where-Object { $_.Name -eq "Title"}
		$m_StockProp = $mRunCompProps | Where-Object { $_.Name -eq "Stock Number"}
		$mTitleProp.Value = $UIString["LBL43"]
		$mPartNumProp = $mRunCompProps | Where-Object { $_.Name -eq "Part Number"}
		$m_PL = $mRunCompProps | Where-Object { $_.Name -eq "PL"}
		$mPartNumProp.Value = $m_StockProp.Value + " - " + $m_PL.Value
	}
	#endregion
}

function mInitializeCHContext {
	#region Harness Assy
	$mHrnsAssys = @()
	$mHrnsAssys = $dsWindow.DataContext.HarnessAssemblies
	$mHrnsAssys | ForEach-Object {
		$mHrnsAssyProps = $_.Properties.Properties
		$mTitleProp = $mHrnsAssyProps | Where-Object { $_.Name -eq "Title"}
		$mTitleProp.Value = $UIString["LBL45"]
		#Elewema addition
		$mProp = $mHrnsAssyProps | Where-Object { $_.Name -eq "Description"}
		$mProp.Value = $UIString["MSDCE_BOMType_00"] + " " + $UIString["LBL45"]
	}
	#endregion
	#region Route parts
	$mHrnsParts = @()
	$mHrnsParts = $dsWindow.DataContext.HarnessParts
	$mHrnsParts | ForEach-Object {
		$mHrnsPrtProps = $_.Properties.Properties
		$mTitleProp = $mHrnsPrtProps | Where-Object { $_.Name -eq "Title"}
		$mTitleProp.Value = $UIString["LBL47"]
		$mProp = $mHrnsPrtProps | Where-Object { $_.Name -eq "Description"}
		$mProp.Value = $UIString["MSDCE_BOMType_00"] + " " + $UIString["LBL47"]
	}
	#endregion route parts
}
#endregion functional dialogs