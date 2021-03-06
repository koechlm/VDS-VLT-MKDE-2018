function VDSReport
{
    #preparing the DataTable with according columns
    $dt = New-Object System.Data.DataTable("DataSet1")
    $dt.Columns.Add("Position")
    $dt.Columns.Add("PartNumber")
    $dt.Columns.Add("Quantity")
    $dt.Columns.Add("ComponentType")
    $dt.Columns.Add("Title")
	$dt.Columns.Add("Description")
    $dt.Columns.Add("Material")
    $dt.Columns.Add("SparePart")
    $dt.Columns.Add("Dimensions")
    $dt.Columns.Add("Length")
	#fill table with BOM data
	$bom | ForEach-Object {	
		$dr = $dt.NewRow()
		$dr.Position = $_.Position
		$dr.PartNumber = $_.PartNumber
		$dr.Quantity = $_.Quantity
		$dr.ComponentType = $_.ComponentType
		$dr.Title = $_.Title
		$dr.Description = $_.Description
		$dr.Material = $_.Material
		$dr.SparePart = $_.SparePart
		$dr.Dimensions = $_.Dimensions
		$dr.Length = $_.Length
		
		$dt.Rows.Add($dr)
	}
	
	#select report type and parameters
	$id = $vaultContext.SelectedObject.Id
	$file = $vault.DocumentService.GetLatestFileByMasterId($id)
	$folderId = $vaultContext.NavSelectionSet[0].Id
    $folder = $vault.DocumentService.GetFolderById($FolderId)
	$params = @{}
	$params["CADBOMLabel"] = $UIString["LBL38"]
	$params["UserLabel"] = $UIString["LBL34"]
	$params["User"] = $VaultConnection.UserName
	$params["CreateLabel"] = $UIString["LBL33"]
	$params["ProjectLabel"] = $UIString["LBL5"]
    $params["Project"] = $folder.FullName
	$params["AssemblyLabel"] = $UIString["LBL6"]
    $params["Assembly"] = $file.Name
	#table column headers
	$params["PosLabel"] = $UIString["LBL15"]
	$params["PartNumberLabel"] = $UIString["LBL16"]
	$params["QuantityLabel"] = $UIString["LBL17"]
	$params["ComponentTypeLabel"] = $UIString["LBL18"]
	$params["TitleLabel"] = $UIString["LBL2"]
	$params["DescriptionLabel"] = $UIString["LBL3"]
	$params["MaterialLabel"] = $UIString["MSDCE_LBL72"]
	$params["SparePartLabel"] = $UIString["MSDCE_LBL63"]
	$params["DimensionLabel"] = $UIString["MSDCE_LBL74"]
	$params["LengthLabel"] = $UIString["MSDCE_LBL78"]
		
	#select parameters for different BOM types
    $mBomType = $dsWindow.FindName("cmbCADBOMFilter").SelectedValue
	try {
	[System.Reflection.Assembly]::LoadFrom("C:\ProgramData\Autodesk\Vault 2018\Extensions\DataStandard\Vault\addinVault\VDSReportViewer.dll")
	
	switch ($mBomType) {
		$UIString["MSDCE_LBL91"]
		{
			$params["Type"] = $UIString["MSDCE_CADBOM02"];
			$report = New-Object VDSReportViewer2008.VDSReportViewer2008("C:\ProgramData\Autodesk\Vault 2018\Extensions\DataStandard\Vault\addinVault\CAD-BOM-Cutlist.rdlc",$dt,$params);
		}
		$UIString["MSDCE_LBL90"]
		{
			$params["Type"] = $UIString["MSDCE_CADBOM03"]
			$report = New-Object VDSReportViewer2008.VDSReportViewer2008("C:\ProgramData\Autodesk\Vault 2018\Extensions\DataStandard\Vault\addinVault\CAD-BOM.rdlc",$dt,$params)
		}	
		default 
		{
			$params["Type"] = $UIString["MSDCE_CADBOM01"]
			$report = New-Object VDSReportViewer2008.VDSReportViewer2008("C:\ProgramData\Autodesk\Vault 2018\Extensions\DataStandard\Vault\addinVault\CAD-BOM.rdlc",$dt,$params)		
		}
	}
    } #end try
	catch {
		[System.Windows.MessageBox]::Show("Report or Report-Viewer not available.", "Vault Quickstart Client")
	}
}