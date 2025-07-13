# ============================================================
# custom_components/todoist_voice_ha_integration/entity_creator.py
"""Entity creation utilities for Todoist Voice HA Integration."""
import logging
from typing import Dict, Any

from homeassistant.core import HomeAssistant, callback
from homeassistant.helpers import entity_registry as er, device_registry as dr
from homeassistant.config_entries import ConfigEntry

from .const import DOMAIN, REQUIRED_ENTITIES

_LOGGER = logging.getLogger(__name__)

class EntityCreator:
    """Handle creation of required helper entities."""

    def __init__(self, hass: HomeAssistant, config_entry: ConfigEntry):
        """Initialize the entity creator."""
        self.hass = hass
        self.config_entry = config_entry
        self.entity_registry = er.async_get(hass)
        self.device_registry = dr.async_get(hass)

    async def create_all_entities(self) -> None:
        """Create all required entities for the integration."""
        _LOGGER.info("Creating required entities for Todoist Voice HA")
        
        # Create main device
        device = await self._create_main_device()
        
        # Create all entity types
        for domain, entities in REQUIRED_ENTITIES.items():
            for entity_id, config in entities.items():
                await self._create_entity(domain, entity_id, config, device.id)
        
        _LOGGER.info("All required entities created successfully")

    async def _create_main_device(self) -> dr.DeviceEntry:
        """Create the main device for our integration."""
        return self.device_registry.async_get_or_create(
            config_entry_id=self.config_entry.entry_id,
            identifiers={(DOMAIN, "todoist_voice_ha_main")},
            name="Todoist Voice HA Assistant",
            manufacturer="Todoist Voice HA Integration",
            model="Conversational AI Assistant",
            sw_version="2.0.0"
        )

    async def _create_entity(self, domain: str, entity_id: str, config: Dict[str, Any], device_id: str) -> None:
        """Create a single entity."""
        full_entity_id = f"{domain}.{entity_id}"
        
        # Check if entity already exists
        if self.entity_registry.async_get(full_entity_id):
            _LOGGER.debug("Entity %s already exists, skipping creation", full_entity_id)
            return

        # Create the entity in the registry first
        self.entity_registry.async_get_or_create(
            domain=domain,
            platform=DOMAIN,
            unique_id=f"{DOMAIN}_{entity_id}",
            suggested_object_id=entity_id,
            device_id=device_id,
            original_name=config.get("name", entity_id.replace("_", " ").title()),
            original_icon=config.get("icon")
        )

        # Create the actual helper entity
        try:
            if domain == "input_boolean":
                await self._create_input_boolean(entity_id, config)
            elif domain == "input_text":
                await self._create_input_text(entity_id, config)
            elif domain == "input_select":
                await self._create_input_select(entity_id, config)
            elif domain == "input_number":
                await self._create_input_number(entity_id, config)
            else:
                _LOGGER.warning("Unknown domain: %s", domain)
                return
                
            _LOGGER.info("Created %s entity: %s", domain, full_entity_id)
            
        except Exception as err:
            _LOGGER.error("Failed to create %s entity %s: %s", domain, full_entity_id, err)

    async def _create_input_boolean(self, entity_id: str, config: Dict[str, Any]) -> None:
        """Create an input_boolean entity."""
        # Ensure input_boolean integration is loaded
        if "input_boolean" not in self.hass.config.components:
            await self.hass.config_entries.async_forward_entry_setup(
                next(iter(self.hass.config_entries.async_entries("input_boolean")), None),
                "input_boolean"
            )

        await self.hass.services.async_call(
            "input_boolean",
            "create",
            {
                "object_id": entity_id,
                "name": config.get("name", entity_id.replace("_", " ").title()),
                "icon": config.get("icon", "mdi:toggle-switch"),
                "initial": config.get("initial", False)
            }
        )

    async def _create_input_text(self, entity_id: str, config: Dict[str, Any]) -> None:
        """Create an input_text entity."""
        await self.hass.services.async_call(
            "input_text",
            "create",
            {
                "object_id": entity_id,
                "name": config.get("name", entity_id.replace("_", " ").title()),
                "max": config.get("max", 255),
                "initial": config.get("initial", ""),
                "icon": config.get("icon", "mdi:text-box")
            }
        )

    async def _create_input_select(self, entity_id: str, config: Dict[str, Any]) -> None:
        """Create an input_select entity."""
        await self.hass.services.async_call(
            "input_select",
            "create",
            {
                "object_id": entity_id,
                "name": config.get("name", entity_id.replace("_", " ").title()),
                "options": config.get("options", ["Option 1"]),
                "initial": config.get("initial", config.get("options", ["Option 1"])[0]),
                "icon": config.get("icon", "mdi:format-list-bulleted")
            }
        )

    async def _create_input_number(self, entity_id: str, config: Dict[str, Any]) -> None:
        """Create an input_number entity."""
        service_data = {
            "object_id": entity_id,
            "name": config.get("name", entity_id.replace("_", " ").title()),
            "min": config.get("min", 0),
            "max": config.get("max", 100),
            "step": config.get("step", 1),
            "initial": config.get("initial", config.get("min", 0)),
            "icon": config.get("icon", "mdi:numeric")
        }
        
        if "unit_of_measurement" in config:
            service_data["unit_of_measurement"] = config["unit_of_measurement"]
            
        await self.hass.services.async_call("input_number", "create", service_data)

    async def cleanup_entities(self) -> None:
        """Remove all entities created by this integration."""
        _LOGGER.info("Cleaning up entities for Todoist Voice HA")
        
        for domain, entities in REQUIRED_ENTITIES.items():
            for entity_id in entities:
                full_entity_id = f"{domain}.{entity_id}"
                
                # Remove from entity registry
                entity_entry = self.entity_registry.async_get(full_entity_id)
                if entity_entry and entity_entry.platform == DOMAIN:
                    self.entity_registry.async_remove(full_entity_id)
                    _LOGGER.debug("Removed entity: %s", full_entity_id)
                
                # Remove the actual helper entity
                try:
                    await self.hass.services.async_call(
                        domain, "remove", {"object_id": entity_id}
                    )
                except Exception as err:
                    _LOGGER.debug("Could not remove %s entity %s: %s", domain, entity_id, err)