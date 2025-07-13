# ============================================================
# custom_components/todoist_voice_ha_integration/binary_sensor.py
"""Binary sensor platform for Todoist Voice HA Integration."""
import logging
from homeassistant.components.binary_sensor import BinarySensorEntity
from homeassistant.config_entries import ConfigEntry
from homeassistant.core import HomeAssistant
from homeassistant.helpers.entity_platform import AddEntitiesCallback
from homeassistant.helpers.update_coordinator import CoordinatorEntity

from .const import DOMAIN
from .sensor import TodoistVoiceDataCoordinator

_LOGGER = logging.getLogger(__name__)

async def async_setup_entry(
    hass: HomeAssistant,
    config_entry: ConfigEntry,
    async_add_entities: AddEntitiesCallback,
) -> None:
    """Set up the binary sensor platform."""
    coordinator = hass.data[DOMAIN][config_entry.entry_id]["coordinator"]
    
    entities = [
        TodoistVoiceHealthBinarySensor(coordinator),
        TodoistVoiceConversationActiveBinarySensor(coordinator),
    ]
    
    async_add_entities(entities)

class TodoistVoiceHealthBinarySensor(CoordinatorEntity, BinarySensorEntity):
    """Binary sensor for add-on health status."""

    def __init__(self, coordinator: TodoistVoiceDataCoordinator) -> None:
        """Initialize the binary sensor."""
        super().__init__(coordinator)
        self._attr_name = "Todoist Voice HA Add-on Health"
        self._attr_unique_id = f"{DOMAIN}_addon_health"
        self._attr_icon = "mdi:heart-pulse"
        self._attr_device_class = "connectivity"

    @property
    def is_on(self):
        """Return true if the add-on is healthy."""
        if self.coordinator.data:
            return self.coordinator.data["health"].get("status") == "healthy"
        return False

    @property
    def extra_state_attributes(self):
        """Return the state attributes."""
        if not self.coordinator.data:
            return {}
        
        health_data = self.coordinator.data["health"]
        return {
            "status": health_data.get("status"),
            "uptime_seconds": health_data.get("uptime"),
            "last_check": health_data.get("timestamp")
        }

class TodoistVoiceConversationActiveBinarySensor(CoordinatorEntity, BinarySensorEntity):
    """Binary sensor for active conversation status."""

    def __init__(self, coordinator: TodoistVoiceDataCoordinator) -> None:
        """Initialize the binary sensor."""
        super().__init__(coordinator)
        self._attr_name = "Todoist Voice HA Conversation Active"
        self._attr_unique_id = f"{DOMAIN}_conversation_active"
        self._attr_icon = "mdi:chat-processing"

    @property
    def is_on(self):
        """Return true if there's an active conversation."""
        conversation_active = self.hass.states.get("input_boolean.todoist_voice_conversation_active")
        if conversation_active:
            return conversation_active.state == "on"
        return False

    @property
    def extra_state_attributes(self):
        """Return the state attributes."""
        attrs = {}
        
        # Get conversation state details
        state_entity = self.hass.states.get("input_text.todoist_voice_conversation_state")
        if state_entity:
            attrs["conversation_state"] = state_entity.state
        
        conversation_id = self.hass.states.get("input_text.todoist_voice_conversation_id")
        if conversation_id:
            attrs["conversation_id"] = conversation_id.state
            
        return attrs