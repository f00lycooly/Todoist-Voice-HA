# custom_components/todoist_voice_ha_integration/config_flow.py
"""Config flow for Todoist Voice HA Integration."""
import logging
import voluptuous as vol
import aiohttp
import async_timeout

from homeassistant import config_entries
from homeassistant.core import HomeAssistant, callback
from homeassistant.data_entry_flow import FlowResult
import homeassistant.helpers.config_validation as cv

from .const import (
    DOMAIN, 
    CONF_ADDON_URL, 
    CONF_AUTO_CREATE_ENTITIES, 
    CONF_CONVERSATION_TIMEOUT,
    DEFAULT_ADDON_URL,
    DEFAULT_TIMEOUT
)

_LOGGER = logging.getLogger(__name__)

STEP_USER_DATA_SCHEMA = vol.Schema({
    vol.Required(CONF_ADDON_URL, default=DEFAULT_ADDON_URL): str,
    vol.Optional(CONF_AUTO_CREATE_ENTITIES, default=True): bool,
    vol.Optional(CONF_CONVERSATION_TIMEOUT, default=DEFAULT_TIMEOUT): vol.All(
        vol.Coerce(int), vol.Range(min=60, max=600)
    ),
})

class TodoistVoiceConfigFlow(config_entries.ConfigFlow, domain=DOMAIN):
    """Handle a config flow for Todoist Voice HA Integration."""

    VERSION = 1

    async def async_step_user(self, user_input=None) -> FlowResult:
        """Handle the initial step."""
        if user_input is None:
            return self.async_show_form(
                step_id="user",
                data_schema=STEP_USER_DATA_SCHEMA,
                description_placeholders={
                    "addon_info": "Configure the Todoist Voice HA add-on integration. This will automatically create all required helpers and sensors."
                }
            )

        errors = {}

        # Validate the add-on URL
        addon_url = user_input[CONF_ADDON_URL].rstrip("/")
        try:
            async with async_timeout.timeout(10):
                async with aiohttp.ClientSession() as session:
                    async with session.get(f"{addon_url}/health") as resp:
                        if resp.status != 200:
                            errors[CONF_ADDON_URL] = "cannot_connect"
                        else:
                            health_data = await resp.json()
                            if not health_data.get("status") == "healthy":
                                errors[CONF_ADDON_URL] = "addon_unhealthy"
        except aiohttp.ClientError:
            errors[CONF_ADDON_URL] = "cannot_connect"
        except Exception as err:
            _LOGGER.error("Unexpected error validating addon URL: %s", err)
            errors[CONF_ADDON_URL] = "unknown_error"

        if errors:
            return self.async_show_form(
                step_id="user",
                data_schema=STEP_USER_DATA_SCHEMA,
                errors=errors
            )

        # Check if already configured
        await self.async_set_unique_id("todoist_voice_ha_main")
        self._abort_if_unique_id_configured()

        # Update the addon URL to remove trailing slash
        user_input[CONF_ADDON_URL] = addon_url

        return self.async_create_entry(
            title="Todoist Voice HA Conversational Assistant",
            data=user_input
        )

    @staticmethod
    @callback
    def async_get_options_flow(config_entry):
        """Get the options flow for this handler."""
        return TodoistVoiceOptionsFlowHandler(config_entry)

class TodoistVoiceOptionsFlowHandler(config_entries.OptionsFlow):
    """Handle a option flow for Todoist Voice HA Integration."""

    def __init__(self, config_entry: config_entries.ConfigEntry) -> None:
        """Initialize options flow."""
        self.config_entry = config_entry

    async def async_step_init(self, user_input=None) -> FlowResult:
        """Handle options flow."""
        if user_input is not None:
            return self.async_create_entry(title="", data=user_input)

        data_schema = vol.Schema({
            vol.Optional(
                CONF_ADDON_URL, 
                default=self.config_entry.data.get(CONF_ADDON_URL, DEFAULT_ADDON_URL)
            ): str,
            vol.Optional(
                CONF_AUTO_CREATE_ENTITIES,
                default=self.config_entry.options.get(CONF_AUTO_CREATE_ENTITIES, True)
            ): bool,
            vol.Optional(
                CONF_CONVERSATION_TIMEOUT,
                default=self.config_entry.options.get(CONF_CONVERSATION_TIMEOUT, DEFAULT_TIMEOUT)
            ): vol.All(vol.Coerce(int), vol.Range(min=60, max=600)),
        })

        return self.async_show_form(
            step_id="init",
            data_schema=data_schema
        )