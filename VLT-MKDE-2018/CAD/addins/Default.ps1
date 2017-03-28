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
			$Global:CAx_Root = $mappedRootPath #we need the path for the run time of the dialog
    	#endregion

		try
		{
			$rootFolder = $vault.DocumentService.GetFolderByPath($mappedRootPath)
    		$root = New-Object PSObject -Property @{ Name = $rootFolder.Name; ID=$rootFolder.Id }
    		AddCombo -data $root
		}
		catch [System.Exception]
		{		
			[System.Windows.MessageBox]::Show("Your Inventor IPJ settings don't match the Vault environment you are logged into. Ensure that the IPJ file and Inventor Workspace set in the IPJ exist in Vault.","Vault MFG Quickstart")
		}		

		#region Quickstart
			$_PathNames = mReadLastUsedFolder
			mActivateBreadCrumbCmbs $_PathNames	
		#endregion
    }

	#end rules applying commonly
	$mWindowName = $dsWindow.Name
	switch($mWindowName)
	{
		"InventorWindow"
		{
			#region Quickstart
			#	initialize the context for Drawings or presentation files as these have Vault Option settings
			$global:mGFN4Special = mReadGFN4S # GFN4S = Option "Generate File Numbers for Drawings & Presentations", IDW/DWG & IPN
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
					#$dsDiag.Trace(">> CreateMode Section executes...")
					# set the category: Quickstart = "3D components" for model files and "Inventor Drawing" for IDW/DWG

					$mCatName = GetCategories | Where {$_.Name -eq $UIString["MSDCE_CAT02"]}
					IF ($mCatName) { $Prop["_Category"].Value = $UIString["MSDCE_CAT02"]}
						# in case the current vault is not quickstart, but a plain MFG default configuration
					Else {
						$mCatName = GetCategories | Where {$_.Name -eq $UIString["CAT1"]} #"Engineering"
						IF ($mCatName) { $Prop["_Category"].Value = $UIString["CAT1"]}
					}

					#set path & filename for IDW/DWG and retrieve 3D model properties (Inventor captures these also, but too late; we are currently before save event transfers model properties to drawing properties) 
					# but don't do this, if the copy mode is active
					if ($Prop["_CopyMode"].Value -eq $false) 
					{
						
						if (($Prop["_FileExt"].Value -eq "idw") -or ($Prop["_FileExt"].Value -eq "dwg" )) 
						{
							[System.Reflection.Assembly]::LoadFrom($Env:ProgramData + "\Autodesk\Vault 2018\Extensions\DataStandard" + '\Vault\addinVault\QuickstartUtilityLibrary.dll')
							$_mInvHelpers = New-Object VDSUtils.InvHelpers #NEW 2018 hand over the parent inventor application, to ensure the correct instance
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
							#set the path to the first drawings view's model path if GFN4S is false
							If ($global:mGFN4Special -eq $false) # The drawing get's saved to it#s first view's model location and name
							{	
								If ($_ModelFullFileName) { 
									$_ModelName = [System.IO.Path]::GetFileNameWithoutExtension($_ModelFullFileName)
									$_ModelFile = Get-ChildItem $_ModelFullFileName
									$_ModelPath = $_ModelFile.DirectoryName	
									$Prop["DocNumber"].Value = $_ModelName
									#retrieve the matching folder selection of the model's path
									$_localPath = $VaultConnection.WorkingFoldersManager.GetWorkingFolder($mappedRootPath)
									$Prop["Folder"].Value = $_ModelPath.Replace($_localPath, "")
								}
							}
						}
						#set path & filename for IPN
						if ($Prop["_FileExt"].Value -eq "ipn") 
						{
							[System.Reflection.Assembly]::LoadFrom($Env:ProgramData + "\Autodesk\Vault 2018\Extensions\DataStandard" + '\Vault\addinVault\QuickstartUtilityLibrary.dll')
							$_mInvHelpers = New-Object VDSUtils.InvHelpers #NEW 2018 hand over the parent inventor application, to ensure the correct instance
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
								#$dsDiag.Trace("Set path, filename and properties for IPN: At least one custom property failed, most likely it did not exist and is not part of the cfg ")
							}
							#set the path to the first model's path if GFN4S is false
							If ($global:mGFN4Special -eq $false) # The drawing get's saved to it#s first view's model location and name
							{
								If ($_ModelFullFileName) { 
									$_ModelName = [System.IO.Path]::GetFileNameWithoutExtension($_ModelFullFileName)
									$_ModelFile = Get-ChildItem $_ModelFullFileName
									$_ModelPath = $_ModelFile.DirectoryName	
									$Prop["DocNumber"].Value = $_ModelName
									#retrieve the matching folder selection of the model's path
									$_localPath = $VaultConnection.WorkingFoldersManager.GetWorkingFolder($mappedRootPath)
									$Prop["Folder"].Value = $_ModelPath.Replace($_localPath, "")
								}
							}
						}

						if (($_ModelFullFileName -eq "") -and ($global:mGFN4Special -eq $false)) 
						{ 
							[System.Windows.MessageBox]::Show($UIString["MSDCE_MSG00"],"Vault MFG Quickstart")
							$dsWindow.add_Loaded({
										#[System.Windows.MessageBox]::Show("Will skip VDS Dialog for Drawings without model view; 
										#	enable Option - Generate File Numbers for Drawings or add model view.","Vault MFG Quickstart")
										$dsWindow.CancelWindowCommand.Execute($this)})
							#$dsWindow.FindName("btnOK").ToolTip = $UIString["MSDCE_MSG00"]
							#$dsWindow.FindName("btnOK").IsEnabled = $false
						}
					} # end of copy mode = false check

					if ($Prop["_CopyMode"].Value -eq $true) 
					{
						if (($Prop["_FileExt"].Value -eq "idw") -or ($Prop["_FileExt"].Value -eq "dwg" )) 
						{
							$mCatName = $UIString["MSDCE_CAT00"] 
							If ($global:mGFN4Special -eq $false) # The drawing get's saved to it#s first view's model location and name
							{
								# differ current doc = drawing -> drawing copy; current doc != drawing -> model incl. drawing copy
								# in both cases the target folder for the drawing = folder of the model. User's have to turn on option "generate file numbers for drawings and presentations, in case folder and or number is a new selection
								If ($Application.ActiveDocument.DocumentType -ne '12292') #we process a drawing of the current active model, get it's model path / name
								{
									# what about a drawing copy, that results from current doc = IAM and drawing is a copy of the new replace-copy model (this model is not active!)
									# => compare current model and %temp% saved model; id identical we are processing a copy only, id different, we are processing a replace by copy
									$_ModelFullFileName = $Application.ActiveDocument.FullFileName
									$m_TempFile = $env:TEMP + "\VDSTempModelPath.txt"
									$_lastCopyfileName = Get-Content $m_TempFile
									if ($_ModelFullFileName -ne $_lastCopyfileName)
									{
										#$dsDiag.Trace("............... processing a 'replace incl. Drawing' copy drawing creation.............")
										$_ModelFullFileName = $_lastCopyfileName
									}
									$_ModelName = [System.IO.Path]::GetFileNameWithoutExtension($_ModelFullFileName)
									$_ModelFile = Get-ChildItem $_ModelFullFileName
									$_ModelPath = $_ModelFile.DirectoryName
									$Prop["_FilePath"].Value = $_ModelPath
									$Prop["DocNumber"].Value = $_ModelName
								}
								If ($Application.ActiveDocument.DocumentType -eq '12292') # = kDrawingDocument, get the main view's model path / name
								{
									[System.Reflection.Assembly]::LoadFrom($Env:ProgramData + "\Autodesk\Vault 2018\Extensions\DataStandard" + '\Vault\addinVault\QuickstartUtilityLibrary.dll')
									$_mInvHelpers = New-Object VDSUtils.InvHelpers
									$_ModelFullFileName = $_mInvHelpers.m_GetMainViewModelPath($Application)
									$_ModelName = [System.IO.Path]::GetFileNameWithoutExtension($_ModelFullFileName)
									$_ModelFile = Get-ChildItem $_ModelFullFileName
									$_ModelPath = $_ModelFile.DirectoryName
									$Prop["_FilePath"].Value = $_ModelPath
									$Prop["DocNumber"].Value = $_ModelName
								}
							}
						}
					} #end of copymode = true 
					#$dsDiag.Trace("CreateMode ended...<<")


					#$dsDiag.Trace("... CreateMode Section finished <<")
				}
				$false # EditMode = True
				{
					#$dsDiag.Trace(">> EditMode Section executes...")

					#$dsDiag.Trace("... EditMode Section finished <<")
				}
				default
				{

				}
			} #end switch Create / Edit Mode
			#endregion Quickstart
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
				}
			}

			#endregion quickstart
		}
		default
		{
			#rules applying for other windows, e.g. FG, DA, TP and CH functional dialogs; SaveCopyAs dialog
		}
	}#end switch windows
#$dsDiag.Trace("... Initialize window end <<")
}#end InitializeWindow

function AddinLoaded
{
	#Executed when DataStandard is loaded in Inventor/AutoCAD
	#region Quickstart
		$m_File = $env:TEMP + "\Folder2017.xml"
		if (!(Test-Path $m_File)){
			$source = $Env:ProgramData + "\Autodesk\Vault 2018\Extensions\DataStandard\Vault\Folder2017.xml"
			Copy-Item $source $env:TEMP\Folder2017.xml
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
				#region Quickstart
					#$numSchems = $numSchems | Sort-Object -Property IsDflt -Descending
					$_FilteredNumSchems = $numSchems | Where { $_.IsDflt -eq $true}
					if ($Prop["_NumSchm"].Value) { $Prop["_NumSchm"].Value = $_FilteredNumSchems[0].Name} #note - functional dialogs don't have the property _NumSchm, therefore we conditionally set the value 
					$dsWindow.FindName("NumSchms").IsEnabled = $false
					return $_FilteredNumSchems
				#end Quickstart
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
					$noneNumSchm.Name = "None"
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
	return $vault.CategoryService.GetCategoriesByEntityClassId("FILE", $true)
}

function OnPostCloseDialog
{
	$mWindowName = $dsWindow.Name
	switch($mWindowName)
	{
		"InventorWindow"
		{
			#region Quickstart
			
				mWriteLastUsedFolder

				if ($Prop["_CopyMode"].Value -eq $true) 
				{
					#register the model's copy to derive it's drawings copy name subsequently
					if (($Prop["_CopyMode"].Value -eq $true) -and ($global:mGFN4Special -eq $false) -and ($Prop["_FileExt"].Value -ne "idw") -and ($Prop["_FileExt"].Value -ne "dwg")) 
					{
						#$dsDiag.Trace("copy of iam, ipt, ipn and no new number for drawings")
						$m_TempFile = $env:TEMP + "\VDSTempModel.txt"
						$Prop["DocNumber"].Value | Out-File $m_TempFile
						$m_TempFile = $env:TEMP + "\VDSTempModelPath.txt"
						$dsWindow.DataContext.PathAndFileNameHandler.FullFileName | Out-File $m_TempFile
					}
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

function m_ReadShortCuts {
	if ($Prop["_CreateMode"].Value -eq $true) {
		#$dsDiag.Trace(">> Looking for Shortcuts...")
		$m_Server = $VaultConnection.Server
		$m_Vault = $VaultConnection.Vault
		$m_AllFiles = @()
		$m_FiltFiles = @()
		$m_Path = $env:APPDATA + '\Autodesk\VaultCommon\Servers\'
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
			#$dsDiag.Trace("... Filtering Shortcuts...")
			$m_ScAll | ForEach-Object { 
				if (($_.NavigationContextType -eq "Connectivity.Explorer.Document.DocFolder") -and ($_.NavigationContext.URI -like "*"+$global:CAxRoot + "/*"))
				{
					try
					{
						$_t = $global:m_ScCAD.Add($_.Name, $_.NavigationContext.URI)
						$mScNames += $_.Name
					}
					catch {
						#$dsDiag.Trace("... ERROR Filtering Shortcuts...")
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
	}
	catch
	{
		#$dsDiag.Trace("mScClick function - error reading selected value")
	}
	
}

function mAddSc {
	try
	{
		$mNewScName = $dsWindow.FindName("txtNewShortCut").Text
		mAddShortCutByName ($mNewScName)
	}
	catch {}
}

function mRemoveSc {
	try
	{
		$_key = $dsWindow.FindName("lstBoxShortCuts").SelectedValue
		mRemoveShortCutByName $_key
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
			#$dsDiag.Trace(" - selecteditem.Name of cmb: $_N ")
			if (($cmb.SelectedItem.Name.Length -gt 0) -and !($cmb.SelectedItem.Name -eq "."))
			{ 
				$newURI = $newURI + "/" + $cmb.SelectedItem.Name
				#$dsDiag.Trace(" - the updated URI  of the shortcut: $newURI")
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
		#$dsDiag.Trace("..successfully added ShortCut <<")
		return $true
	}
	catch 
	{
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
	$m_File = $env:TEMP + "\Folder2017.xml"
	if (Test-Path $m_File)
	{
		#$dsDiag.Trace(">>-- Started to read Folder2017.xml...")
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
	$m_File = $env:TEMP + "\Folder2017.xml"
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
			$m_XML.Save($Env:temp + '\Folder2017.xml')
			#$dsDiag.Trace("..saved last used project/folder <<")
		} #end try
		catch [System.Exception]
		{		
			[System.Windows.MessageBox]::Show($error)
		}
	}
}

function mActivateBreadCrumbCmbs ([System.Collections.ArrayList] $_PathNames)
{
	try
	{	
		for ($index = 0; $index -lt $_PathNames.Count; $index++) 
		{
			#retrieve the comb items index for the given name
			$_activeCombo = $dsWindow.FindName("cmbBreadCrumb_"+$index)
			$_cmbNames = @()
			Foreach ($_cmbItem in $_activeCombo.Items) {
				#$dsDiag.Trace("---$_cmbItem---")
				$_cmbNames += $_cmbItem.Name
			}
			#$dsDiag.Trace("Combo $index Namelist = $_cmbNames")
			#get the index of name in array
			$_CurrentName = $_PathNames[$index] 
			#$dsDiag.Trace("Current Name: $_CurrentName ")
			if ($_CurrentName -eq ".") { break;}
			$i = 0
			$_cmbNames | ForEach-Object {
				$_1 = $_cmbNames.count
				$_2 = $_cmbNames[$i]
				#$dsDiag.Trace(" Counter: $i of $_1 value: $_2  ; CurrentName: $_CurrentName ")
				If ($_cmbNames[$i] -eq $_CurrentName) {
					$_IndexToActivate = $i
				}
				$i +=1
			}
			#$dsDiag.Trace("Index of current name: $_IndexToActivate ")
			$dsWindow.FindName("cmbBreadCrumb_"+$index).SelectedIndex = $_IndexToActivate
			$dsWindow.FindName("cmbBreadCrumb_"+$index).IsDropDownOpen = $false #in general we open the pulldown in breadcrumb.ps1
			#$global:_mBreadCrumbsIndexActivated = $true
		}
	} #end try
	catch [System.Exception]
	{		
		[System.Windows.MessageBox]::Show($error)
	}
}


function mReadGFN4S 
#	Reads the Inventor-Vault Addin Option: Generate File Numbers for Drawing / Presentations
#	used by XAML Checkbox Style + script ($global:mGFN4S.Value) 
{
	$mVltOptionFile = $env:APPDATA + '\Autodesk\Inventor 2018 Vault Addin\ApplicationPreferences.xml'
	if (Test-Path $mVltOptionFile) {
		#$dsDiag.Trace(">> Start reading Vault Addin Options...")
		$global:mAppXML = New-Object XML 
		$mAppXML.Load($mVltOptionFile)
		$mGeneral = $mAppXML.Categories.Category | Where-Object { $_.ID -eq "GeneralOptions" }
		$_Option = $mGeneral.Property | Where-Object { $_.Name -eq "GFN4SpecialFiles" }
		#$dsDiag.Trace("... finished reading Vault Addin Options returning: $_Option <<")
		return $_Option.Value
	}
	#$dsDiag.Trace("...finished reading Vault AddIn Options with ERROR!")
}

#endregion
