
Add-Type @'
public class my_UDP
{
	public string ItemPropName;
	public string ItemPropValue;
}
'@

Add-Type @'
public class ERP_BOM
{
    public string ItemBomPos;
    public string ItemBomID;
    public string ItemBomTitle;
    public string ItemBomQty;
    public string ItemBomUnit;
    public string ItemBomRev;
}
'@


function FillERPTab($fileId)
{
	$dsDiag.Trace(">> FillMyTab($fileId)")
	$propDefs = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("FILE")
	$propPartNumber = $propDefs | Where-Object { $_.DispName -eq $UIString["MSDCE_LBL61"]}#$UIString["MSDCE_LBL61"]
	$PartNumber = $vault.PropertyService.GetProperties("FILE",@($fileId),@($propPartNumber.Id))
    $PartNumber | Foreach-Object { $m_PartNumberVal = $_.Val }
	$m_ERPFile = "C:\ERPdata\" + $m_PartNumberVal + ".xml"

	If (Test-Path $m_ERPFile){
		$m_ERPXML = New-Object XML
		$m_ERPXML.Load($m_ERPFile)
		$dsWindow.FindName("grdERP").Visibility = "Visible"
		$dsWindow.FindName("scrView1").ToolTip = $null
	}
	Else{
		$dsWindow.FindName("grdERP").Visibility = "Collapsed"
		$dsWindow.FindName("scrView1").ToolTip = "No ERP data available!"
	return
	}
	
	$m_ItemMaster = $m_ERPXML.PackageData.Items
#$dsDiag.Inspect()
	Try 
	{
		$m_ITEM = $m_ItemMaster.get_item("Item") #for assy
	}
	Catch {
		$m_ITEM = $m_ItemMaster.get_item("Item") #for parts
	}

    $m_UDPs = @()
    $m_UDP = New-Object my_UDP
		$m_UDP.ItemPropName = "Title"
		$m_UDP.ItemPropValue = $m_ITEM.title
		$m_UDPs += $m_UDP
    $m_UDP = New-Object my_UDP
    $m_UDP.ItemPropName = "Description"
		$m_UDP.ItemPropValue = $m_ITEM.description
		$m_UDPs += $m_UDP
    $m_UDP = New-Object my_UDP
    $m_UDP.ItemPropName = "Revision"
		$m_UDP.ItemPropValue = $m_ITEM.revisionID
		$m_UDPs += $m_UDP
    $m_UDP = New-Object my_UDP
    $m_UDP.ItemPropName = "Lifecycle State"
		$m_UDP.ItemPropValue = $m_ITEM.globalLifeCyclePhaseOtherDescription
		$m_UDPs += $m_UDP
	
    $_ItemProps = $m_ITEM.OtherAttributes.OtherAttribute
	Foreach ($_Prop in $_ItemProps.SyncRoot) {
		$m_UDP = New-Object my_UDP
		$m_UDP.ItemPropName = $_Prop.Name
		$m_UDP.ItemPropValue = $_Prop.Value
		$m_UDPs += $m_UDP
	}
  
  	$m_BOM = @()
	If ($m_ITEM.itemClassification -eq "Assembly")
	{  
    	$m_BOMItems = $m_ITEM.BillOfMaterial.BillOfMaterialItem
    
    	#$dsDiag.Inspect()
    	IF ($m_BOMItems) 
			{
        		Foreach ($m_BomItem in $m_BOMItems.SyncRoot) 
					{
			            $m_BOMRow = New-Object ERP_BOM
			            $m_BOMRow.ItemBomPos = $m_BomItem.detailID
			            $m_BOMRow.ItemBomID = $m_BomItem.billOfMaterialItemID
			            $m_BOMRow.ItemBomTitle = $m_BomItem.description
			            $m_BOMRow.ItemBomQty = $m_BomItem.itemQuantity
			            $m_BOMRow.ItemBomUnit = $m_BomItem.billOfMaterialUnitOfMeasure
			            $m_BOMRow.ItemBomRev = $m_BomItem.revisionID
			            $m_BOM += $m_BOMRow
        			}
    		}
	}
    #$dsDiag.Inspect()
	Return $m_UDPs, $m_BOM
}