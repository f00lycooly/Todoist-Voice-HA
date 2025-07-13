# custom_components/todoist_voice_ha_integration/__init__.py
"""Todoist Voice HA Integration for Home Assistant."""
import logging
from homeassistant.config_entries import ConfigEntry
from homeassistant.const import Platform
from homeassistant.core import HomeAssistant

from .const import DOMAIN, CONF_AUTO_CREATE_ENTITIES
from .entity_creator import EntityCreator
from .services import async_setup_services, async_unload_services
from .sensor import TodoistVoiceDataCoordinator

_LOGGER = logging.getLogger(__name__)

PLATFORMS = [Platform.SENSOR, Platform.BINARY_SENSOR, Platform.BUTTON]

async def async_setup(hass: HomeAssistant, config: dict):
    """Set up the Todoist Voice HA integration."""
    _LOGGER.info("Setting up Todoist Voice HA Integration")
    
    # Store the integration data
    hass.data.setdefault(DOMAIN, {})
    
    # Set up services
    await async_setup_services(hass)
    
    return True

async def async_setup_entry(hass: HomeAssistant, entry: ConfigEntry):
    """Set up Todoist Voice HA from a config entry."""
    _LOGGER.info("Setting up Todoist Voice HA Integration from config entry")
    
    # Store config entry data
    hass.data.setdefault(DOMAIN, {})
    
    # Create coordinator
    addon_url = entry.data.get("addon_url")
    coordinator = TodoistVoiceDataCoordinator(hass, addon_url)
    
    # Store coordinator in hass data
    hass.data[DOMAIN][entry.entry_id] = {
        "coordinator": coordinator,
        "config": entry.data
    }
    
    # Create required entities if enabled
    if entry.data.get(CONF_AUTO_CREATE_ENTITIES, True):
        entity_creator = EntityCreator(hass, entry)
        try:
            await entity_creator.create_all_entities()
        except Exception as err:
            _LOGGER.error("Failed to create entities: %s", err)
            # Don't fail setup if entity creation fails
    
    # Do initial data fetch
    await coordinator.async_config_entry_first_refresh()
    
    # Set up platforms
    await hass.config_entries.async_forward_entry_setups(entry, PLATFORMS)
    
    return True

async def async_unload_entry(hass: HomeAssistant, entry: ConfigEntry):
    """Unload a config entry."""
    _LOGGER.info("Unloading Todoist Voice HA Integration")
    
    # Unload platforms
    unload_ok = await hass.config_entries.async_unload_platforms(entry, PLATFORMS)
    
    if unload_ok:
        # Clean up stored data
        hass.data[DOMAIN].pop(entry.entry_id)
        
        # If this was the last entry, unload services
        if not hass.config_entries.async_entries(DOMAIN):
            await async_unload_services(hass)
    
    return unload_ok

async def async_remove_entry(hass: HomeAssistant, entry: ConfigEntry):
    """Remove a config entry."""
    _LOGGER.info("Removing Todoist Voice HA Integration")
    
    # Clean up entities if they were auto-created
    if entry.data.get(CONF_AUTO_CREATE_ENTITIES, True):
        entity_creator = EntityCreator(hass, entry)
        try:
            await entity_creator.cleanup_entities()
        except Exception as err:
            _LOGGER.error("Failed to cleanup entities: %s", err)
