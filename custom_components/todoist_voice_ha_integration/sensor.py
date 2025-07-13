 ============================================================
# custom_components/todoist_voice_ha_integration/sensor.py
"""Sensor platform for Todoist Voice HA Integration."""
import logging
import aiohttp
import async_timeout
from datetime import timedelta

from homeassistant.components.sensor import SensorEntity
from homeassistant.config_entries import ConfigEntry
from homeassistant.core import HomeAssistant
from homeassistant.helpers.entity_platform import AddEntitiesCallback
from homeassistant.helpers.update_coordinator import (
    CoordinatorEntity,
    DataUpdateCoordinator,
    UpdateFailed,
)

from .const import DOMAIN, CONF_ADDON_URL

_LOGGER = logging.getLogger(__name__)

SCAN_INTERVAL = timedelta(seconds=30)

async def async_setup_entry(
    hass: HomeAssistant,
    config_entry: ConfigEntry,
    async_add_entities: AddEntitiesCallback,
) -> None:
    """Set up the sensor platform."""
    addon_url = config_entry.data[CONF_ADDON_URL]
    
    coordinator = TodoistVoiceDataCoordinator(hass, addon_url)
    await coordinator.async_config_entry_first_refresh()
    
    entities = [
        TodoistVoiceAPISensor(coordinator),
        TodoistVoiceProjectsSensor(coordinator),
        TodoistVoiceConversationSensor(coordinator),
    ]
    
    async_add_entities(entities)

class TodoistVoiceDataCoordinator(DataUpdateCoordinator):
    """Class to manage fetching data from the Todoist Voice HA add-on."""

    def __init__(self, hass: HomeAssistant, addon_url: str) -> None:
        """Initialize."""
        self.addon_url = addon_url
        super().__init__(
            hass,
            _LOGGER,
            name=DOMAIN,
            update_interval=SCAN_INTERVAL,
        )

    async def _async_update_data(self):
        """Update data via library."""
        try:
            async with async_timeout.timeout(10):
                async with aiohttp.ClientSession() as session:
                    # Get health status
                    async with session.get(f"{self.addon_url}/health") as resp:
                        health_data = await resp.json()
                    
                    # Get projects data
                    async with session.get(f"{self.addon_url}/ha-services/projects") as resp:
                        projects_data = await resp.json()
                    
                    return {
                        "health": health_data,
                        "projects": projects_data,
                        "last_update": health_data.get("timestamp")
                    }
        except Exception as err:
            raise UpdateFailed(f"Error communicating with add-on: {err}")

class TodoistVoiceAPISensor(CoordinatorEntity, SensorEntity):
    """Sensor for Todoist Voice HA API status."""

    def __init__(self, coordinator: TodoistVoiceDataCoordinator) -> None:
        """Initialize the sensor."""
        super().__init__(coordinator)
        self._attr_name = "Todoist Voice HA API Status"
        self._attr_unique_id = f"{DOMAIN}_api_status"
        self._attr_icon = "mdi:brain"

    @property
    def state(self):
        """Return the state of the sensor."""
        if self.coordinator.data:
            return self.coordinator.data["health"].get("status", "unknown")
        return "unavailable"

    @property
    def extra_state_attributes(self):
        """Return the state attributes."""
        if not self.coordinator.data:
            return {}
        
        health_data = self.coordinator.data["health"]
        return {
            "version": health_data.get("version"),
            "uptime": health_data.get("uptime"),
            "memory_used": health_data.get("memory", {}).get("used"),
            "memory_total": health_data.get("memory", {}).get("total"),
            "project_cache_status": health_data.get("projectCacheStatus"),
            "todoist_status": health_data.get("todoist"),
            "is_addon": health_data.get("isHomeAssistantAddon", False),
            "last_updated": health_data.get("timestamp")
        }

class TodoistVoiceProjectsSensor(CoordinatorEntity, SensorEntity):
    """Sensor for Todoist projects count and info."""

    def __init__(self, coordinator: TodoistVoiceDataCoordinator) -> None:
        """Initialize the sensor."""
        super().__init__(coordinator)
        self._attr_name = "Todoist Voice HA Projects"
        self._attr_unique_id = f"{DOMAIN}_projects"
        self._attr_icon = "mdi:folder-multiple"
        self._attr_unit_of_measurement = "projects"

    @property
    def state(self):
        """Return the state of the sensor."""
        if self.coordinator.data and self.coordinator.data["projects"].get("success"):
            return len(self.coordinator.data["projects"].get("projects", []))
        return 0

    @property
    def extra_state_attributes(self):
        """Return the state attributes."""
        if not self.coordinator.data or not self.coordinator.data["projects"].get("success"):
            return {}
        
        projects_data = self.coordinator.data["projects"]
        return {
            "projects": projects_data.get("projects", []),
            "project_names": projects_data.get("projectNames", []),
            "last_updated": projects_data.get("lastUpdated"),
            "sync_status": "healthy" if projects_data.get("success") else "error"
        }

class TodoistVoiceConversationSensor(CoordinatorEntity, SensorEntity):
    """Sensor for conversation analysis."""

    def __init__(self, coordinator: TodoistVoiceDataCoordinator) -> None:
        """Initialize the sensor."""
        super().__init__(coordinator)
        self._attr_name = "Todoist Voice Conversation Analysis"
        self._attr_unique_id = f"{DOMAIN}_conversation_analysis"
        self._attr_icon = "mdi:chat-processing"

    @property
    def state(self):
        """Return the state of the sensor."""
        # Get conversation state from input_text helper
        conversation_state = self.hass.states.get("input_text.todoist_voice_conversation_state")
        if conversation_state:
            return conversation_state.state
        return "idle"

    @property
    def extra_state_attributes(self):
        """Return the state attributes."""
        attrs = {}
        
        # Get all conversation-related entity states
        entities = [
            "input_text.todoist_voice_conversation_id",
            "input_boolean.todoist_voice_conversation_active", 
            "input_text.todoist_voice_input_buffer",
            "input_text.todoist_voice_project_matches",
            "input_text.todoist_voice_selected_project",
            "input_text.todoist_voice_pending_due_date",
            "input_text.todoist_voice_task_priority"
        ]
        
        for entity_id in entities:
            state = self.hass.states.get(entity_id)
            if state:
                key = entity_id.split(".")[-1].replace("todoist_voice_", "")
                attrs[key] = state.state
        
        # Add derived attributes
        attrs["is_active"] = attrs.get("conversation_active") == "on"
        attrs["has_project_matches"] = bool(attrs.get("project_matches", ""))
        attrs["input_length"] = len(attrs.get("input_buffer", ""))
        
        return attrs