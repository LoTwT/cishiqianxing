class_name RepresentativeRouteContractCatalogResource
extends Resource

const RepresentativeRouteContractScript := preload(
	"res://src/content/definitions/representative_route_contract_resource.gd"
)

@export var catalog_id: StringName = &""
@export var contracts: Array[RepresentativeRouteContractScript] = []


static func snapshot(
	source: RepresentativeRouteContractCatalogResource,
) -> RepresentativeRouteContractCatalogResource:
	var copied_catalog := RepresentativeRouteContractCatalogResource.new()
	copied_catalog.catalog_id = source.catalog_id
	for contract: RepresentativeRouteContractScript in source.contracts:
		copied_catalog.contracts.append(
			RepresentativeRouteContractScript.snapshot(contract)
		)
	return copied_catalog


func is_equal_to(other: RepresentativeRouteContractCatalogResource) -> bool:
	if (
		other == null
		or other.catalog_id != catalog_id
		or other.contracts.size() != contracts.size()
	):
		return false
	for index: int in range(contracts.size()):
		if not contracts[index].is_equal_to(other.contracts[index]):
			return false
	return true
