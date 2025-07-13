# ============================================================
# custom_components/todoist_voice_ha_integration/button.py
"""Button platform for Todoist Voice HA Integration."""
import logging
import aiohttp
import async_timeout

from homeassistant.components.button import ButtonEntity
from homeassistant.config_entries import ConfigEntry
from homeassistant.core import HomeAssistant
from homeassistant.helpers.entity_platform import AddEntitiesCallback
from homeassistant.exceptions import HomeAssistantError

from .const import DOMAIN, CONF_ADDON_URL

_LOGGER = logging.getLogger(__name__)

async def async_setup_entry(
    hass: HomeAssistant,
    config_entry: ConfigEntry,
    async_add_entities: AddEntitiesCallback,
) -> None:
    """Set up the button platform."""
    addon_url = config_entry.data[CONF_ADDON_URL]
    
    entities = [
        TodoistVoiceRefreshProjectsButton(hass, addon_url),
        TodoistVoiceTestConversationButton(hass, addon_url),
        TodoistVoiceCleanupConversationButton(hass),
    ]
    
    async_add_entities(entities)

class TodoistVoiceRefreshProjectsButton(ButtonEntity):
    """Button to refresh Todoist projects cache."""

    def __init__(self, hass: HomeAssistant, addon_url: str) -> None:
        """Initialize the button."""
        self.hass = hass
        self.addon_url = addon_url
        self._attr_name = "Refresh Todoist Projects"
        self._attr_unique_id = f"{DOMAIN}_refresh_projects"
        self._attr_icon = "mdi:refresh"

    async def async_press(self) -> None:
        """Handle the button press."""
        try:
            async with async_timeout.timeout(20):
                async with aiohttp.ClientSession() as session:
                    async with session.post(f"{self.addon_url}/ha-services/refresh-projects") as resp:
                        if resp.status == 200:
                            result = await resp.json()
                            _LOGGER.info(f"Projects refreshed: {result.get('projectCount', 0)} projects")
                        else:
                            raise HomeAssistantError(f"Failed to refresh projects: HTTP {resp.status}")
        except Exception as err:
            _LOGGER.error(f"Error refreshing projects: {err}")
            raise HomeAssistantError(f"Failed to refresh projects: {err}")

class TodoistVoiceTestConversationButton(ButtonEntity):
    """Button to test conversation flow."""

    def __init__(self, hass: HomeAssistant, addon_url: str) -> None:
        """Initialize the button."""
        self.hass = hass
        self.addon_url = addon_url
        self._attr_name = "Test Conversation Flow"
        self._attr_unique_id = f"{DOMAIN}_test_conversation"
        self._attr_icon = "mdi:test-tube"

    async def async_press(self) -> None:
        """Handle the button press."""
        try:
            # Simulate a conversation trigger
            await self.hass.services.async_call(
                "automation",
                "trigger",
                {
                    "entity_id": "automation.todoist_voice_conversation_handler",
                    "variables": {
                        "trigger": {
                            "slots": {
                                "task_items": "test task from button",
                                "project_hint": "test project"
                            }
                        }
                    }
                }
            )
            _LOGGER.info("Test conversation triggered")
        except Exception as err:
            _LOGGER.error(f"Error triggering test conversation: {err}")
            raise HomeAssistantError(f"Failed to trigger test conversation: {err}")

class TodoistVoiceCleanupConversationButton(ButtonEntity):
    """Button to cleanup conversation state."""

    def __init__(self, hass: HomeAssistant) -> None:
        """Initialize the button."""
        self.hass = hass
        self._attr_name = "Cleanup Conversation State"
        self._attr_unique_id = f"{DOMAIN}_cleanup_conversation"
        self._attr_icon = "mdi:broom"

    async def async_press(self) -> None:
        """Handle the button press."""
        try:
            # Reset all conversation-related entities
            cleanup_entities = [
                ("input_boolean.todoist_voice_conversation_active", "turn_off"),
                ("input_boolean.todoist_voice_awaiting_project_selection", "turn_off"),
                ("input_boolean.todoist_voice_awaiting_project_creation", "turn_off"),
                ("input_boolean.todoist_voice_awaiting_date_input", "turn_off"),
                ("input_boolean.todoist_voice_awaiting_final_confirmation", "turn_off"),
            ]
            
            cleanup_text_entities = [
                "input_text.todoist_voice_conversation_id",
                "input_text.todoist_voice_voice_input_buffer",
                "input_text.todoist_voice_parsed_task_items",
                "input_text.todoist_voice_project_matches",
                "input_text.todoist_voice_selected_project",
                "input_text.todoist_voice_pending_due_date",
                "input_text.todoist_voice_conversation_context"
            ]
            
            # Turn off boolean entities
            for entity_id, service in cleanup_entities:
                await self.hass.services.async_call(
                    "input_boolean", service, {"entity_id": entity_id}
                )
            
            # Clear text entities
            for entity_id in cleanup_text_entities:
                await self.hass.services.async_call(
                    "input_text", "set_value", 
                    {"entity_id": entity_id, "value": ""}
                )
            
            # Reset conversation state to idle
            await self.hass.services.async_call(
                "input_text", "set_value",
                {
                    "entity_id": "input_text.todoist_voice_conversation_state",
                    "value": "idle"
                }
            )
            
            # Reset priority to default
            await self.hass.services.async_call(
                "input_text", "set_value",
                {
                    "entity_id": "input_text.todoist_voice_task_priority", 
                    "value": "3"
                }
            )
            
            _LOGGER.info("Conversation state cleaned up successfully")
            
        except Exception as err:
            _LOGGER.error(f"Error cleaning up conversation state: {err}")
            raise HomeAssistantError(f"Failed to cleanup conversation state: {err}")