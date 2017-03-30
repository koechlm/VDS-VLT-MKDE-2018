
Add-Type @"
public class ItemBomData
{
	public string Item {get;set;}
	public string Revision {get;set;}
	public string Title {get;set;}
	public string Description {get;set;}
	public string Category {get;set;}
	public string State {get;set;}
}
"@

function SetItemData($itemId)
{
	$dsDiag.Trace(">> SetItemBomData($itemId)")
	Try
	{
	$properyDefinitions = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("ITEM")
	$properties = $vault.PropertyService.GetPropertiesByEntityIds("ITEM",$itemId)
	$props = @{}
	foreach ($property in $properties) {
		$propDef = $properyDefinitions | Where-Object { $_.Id -eq $property.PropDefId }
		$props[$propDef.DispName] = $property.Val
	}
	$item = New-Object ItemBomData
	$item.Item = $props["Nummer"]
	$item.Revision = $props["Revision"]
	$item.Title = $props["Titel (Artikel, ECO)"]
	$item.Description = $props["Beschreibung (Artikel, ECO)"]
	$item.State = $props["Status"]
	$item.Category = $props["Kategoriename"]
	
	$dsWindow.FindName("ItemBomData").DataContext = $item
	
	$dsDiag.Trace("<< SetItemBomData")
	}
	Catch
	{
		$dsDiag.Trace(" no linked Item exists - SetItemBomData <<")
	}
}

function ResetItemBomData($itemId)
{
		$item = New-Object ItemBomData
		$dsWindow.FindName("ItemBomData").DataContext = $item
		$dsWindow.FindName("bomList").ItemsSource = $null
		$dsWindow.FindName("AssoicatedFiles").ItemsSource = $null
}


function SetItemBomData($itemId)
{
	$dsDiag.Trace("<< SetItemBomData($itemId)")
	Try 
	{
		$BOM = $vault.ItemService.GetItemBOMByItemIdAndDate($itemId, [DateTime]::MinValue, [Autodesk.Connectivity.WebServices.BOMTyp]::Tip, [Autodesk.Connectivity.WebServices.BOMViewEditOptions]::Defaults)
		#only proceed with existing BOM
		$assocs =  $BOM.ItemAssocArray | Where-Object { $_.ParItemId -eq $itemId }
		$childIds = $assocs | ForEach-Object { $_.CldItemId	}
		
		$properyDefinitions = $vault.PropertyService.GetPropertyDefinitionsByEntityClassId("ITEM")
		$properties = $vault.PropertyService.GetPropertiesByEntityIds("ITEM",$childIds)
		
		$data = @()
		foreach ($id in $childIds) {
			$props = @{}
			$ppys = $properties | Where-Object { $_.EntityId -eq $id }
			foreach ($property in $ppys) {
				$propDef = $properyDefinitions | Where-Object { $_.Id -eq $property.PropDefId }
				$props[$propDef.DispName] = $property.Val
			}
			
			$item = New-Object ItemBomData
			$item.Item = $props["Nummer"]
			$item.Revision = $props["Revision"]
			$item.Title = $props["Titel (Artikel, ECO)"]
			$item.Description = $props["Beschreibung (Artikel, ECO)"]
			$item.State = $props["Status"]
			$item.Category = $props["Kategoriename"]
			$data += $item
		}
		$dsWindow.FindName("bomList").ItemsSource = $data
		$dsDiag.Trace("<< SetItemBomData")
	}
	catch 
	{
		$dsDiag.Trace(" no BOM exists - SetItemBomData <<")
		$dsWindow.FindName("bomList").ItemsSource = $null
	}
}


