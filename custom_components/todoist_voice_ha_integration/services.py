# ============================================================
# custom_components/todoist_voice_ha_integration/services.py
"""Services for Todoist Voice HA Integration."""
import logging
import aiohttp
import async_timeout
import voluptuous as vol

from homeassistant.core import HomeAssistant, ServiceCall
from homeassistant.exceptions import HomeAssistantError
import homeassistant.helpers.config_validation as cv

from .const import DOMAIN, CONF_ADDON_URL

_LOGGER = logging.getLogger(__name__)

# Service schemas
CREATE_TASK_SCHEMA = vol.Schema({
    vol.Required("text"): cv.string,
    vol.Optional("project_name"): cv.string,
    vol.Optional("project_id"): cv.string,
    vol.Optional("priority", default=3): vol.All(vol.Coerce(int), vol.Range(min=1, max=4)),
    vol.Optional("due_date"): cv.string,
    vol.Optional("labels", default=[]): vol.All(cv.ensure_list, [cv.string]),
    vol.Optional("main_task_title"): cv.string,
    vol.Optional("conversation_id"): cv.string,
})

FIND_PROJECTS_SCHEMA = vol.Schema({
    vol.Required("query"): cv.string,
    vol.Optional("max_results", default=5): vol.All(vol.Coerce(int), vol.Range(min=1, max=20)),
})

CREATE_PROJECT_SCHEMA = vol.Schema({
    vol.Required("name"): cv.string,
    vol.Optional("color"): cv.string,
    vol.Optional("parent_id"): cv.string,
})

PARSE_VOICE_INPUT_SCHEMA = vol.Schema({
    vol.Required("text"): cv.string,
    vol.Optional("context", default={}): dict,
})

VALIDATE_DATE_SCHEMA = vol.Schema({
    vol.Required("date_input"): cv.string,
    vol.Optional("context"): cv.string,
})

async def async_setup_services(hass: HomeAssistant) -> None:
    """Set up services for the integration."""
    
    async def async_create_task(call: ServiceCall) -> None:
        """Create a task via the add-on API."""
        addon_url = await _get_addon_url(hass)
        if not addon_url:
            raise HomeAssistantError("No Todoist Voice HA integration configured")
        
        try:
            async with async_timeout.timeout(30):
                async with aiohttp.ClientSession() as session:
                    async with session.post(
                        f"{addon_url}/ha-services/create-task",
                        json=dict(call.data)
                    ) as resp:
                        if resp.status != 200:
                            error_data = await resp.json()
                            raise HomeAssistantError(f"Failed to create task: {error_data.get('error', 'Unknown error')}")
                        
                        result = await resp.json()
                        _LOGGER.info("Task created successfully: %s", result.get("message"))
                        return result
        except aiohttp.ClientError as err:
            raise HomeAssistantError(f"Communication error: {err}")
        except Exception as err:
            raise HomeAssistantError(f"Unexpected error: {err}")

    async def async_find_projects(call: ServiceCall) -> None:
        """Find matching projects via the add-on API."""
        addon_url = await _get_addon_url(hass)
        if not addon_url:
            raise HomeAssistantError("No Todoist Voice HA integration configured")
        
        try:
            async with async_timeout.timeout(15):
                async with aiohttp.ClientSession() as session:
                    async with session.post(
                        f"{addon_url}/ha-services/find-projects",
                        json=dict(call.data)
                    ) as resp:
                        if resp.status != 200:
                            error_data = await resp.json()
                            raise HomeAssistantError(f"Failed to find projects: {error_data.get('error', 'Unknown error')}")
                        
                        result = await resp.json()
                        _LOGGER.info("Project search completed: %d matches found", len(result.get("matches", [])))
                        return result
        except aiohttp.ClientError as err:
            raise HomeAssistantError(f"Communication error: {err}")
        except Exception as err:
            raise HomeAssistantError(f"Unexpected error: {err}")

    async def async_create_project(call: ServiceCall) -> None:
        """Create a new project via the add-on API."""
        addon_url = await _get_addon_url(hass)
        if not addon_url:
            raise HomeAssistantError("No Todoist Voice HA integration configured")
        
        try:
            async with async_timeout.timeout(15):
                async with aiohttp.ClientSession() as session:
                    async with session.post(
                        f"{addon_url}/ha-services/create-project",
                        json=dict(call.data)
                    ) as resp:
                        if resp.status != 200:
                            error_data = await resp.json()
                            raise HomeAssistantError(f"Failed to create project: {error_data.get('error', 'Unknown error')}")
                        
                        result = await resp.json()
                        _LOGGER.info("Project created successfully: %s", result.get("project", {}).get("name"))
                        return result
        except aiohttp.ClientError as err:
            raise HomeAssistantError(f"Communication error: {err}")
        except Exception as err:
            raise HomeAssistantError(f"Unexpected error: {err}")

    async def async_parse_voice_input(call: ServiceCall) -> None:
        """Parse voice input via the add-on API."""
        addon_url = await _get_addon_url(hass)
        if not addon_url:
            raise HomeAssistantError("No Todoist Voice HA integration configured")
        
        try:
            async with async_timeout.timeout(15):
                async with aiohttp.ClientSession() as session:
                    async with session.post(
                        f"{addon_url}/ha-services/parse-voice-input",
                        json=dict(call.data)
                    ) as resp:
                        if resp.status != 200:
                            error_data = await resp.json()
                            raise HomeAssistantError(f"Failed to parse voice input: {error_data.get('error', 'Unknown error')}")
                        
                        result = await resp.json()
                        _LOGGER.info("Voice input parsed: %d actions found", len(result.get("analysis", {}).get("extractedActions", [])))
                        return result
        except aiohttp.ClientError as err:
            raise HomeAssistantError(f"Communication error: {err}")
        except Exception as err:
            raise HomeAssistantError(f"Unexpected error: {err}")

    async def async_validate_date(call: ServiceCall) -> None:
        """Validate date input via the add-on API."""
        addon_url = await _get_addon_url(hass)
        if not addon_url:
            raise HomeAssistantError("No Todoist Voice HA integration configured")
        
        try:
            async with async_timeout.timeout(10):
                async with aiohttp.ClientSession() as session:
                    async with session.post(
                        f"{addon_url}/ha-services/validate-date",
                        json=dict(call.data)
                    ) as resp:
                        if resp.status != 200:
                            error_data = await resp.json()
                            raise HomeAssistantError(f"Failed to validate date: {error_data.get('error', 'Unknown error')}")
                        
                        result = await resp.json()
                        _LOGGER.info("Date validation completed: %s -> %s", 
                                   call.data.get("date_input"), 
                                   result.get("parsedDate"))
                        return result
        except aiohttp.ClientError as err:
            raise HomeAssistantError(f"Communication error: {err}")
        except Exception as err:
            raise HomeAssistantError(f"Unexpected error: {err}")

    async def async_refresh_projects(call: ServiceCall) -> None:
        """Refresh project cache via the add-on API."""
        addon_url = await _get_addon_url(hass)
        if not addon_url:
            raise HomeAssistantError("No Todoist Voice HA integration configured")
        
        try:
            async with async_timeout.timeout(20):
                async with aiohttp.ClientSession() as session:
                    async with session.post(f"{addon_url}/ha-services/refresh-projects") as resp:
                        if resp.status != 200:
                            error_data = await resp.json()
                            raise HomeAssistantError(f"Failed to refresh projects: {error_data.get('error', 'Unknown error')}")
                        
                        result = await resp.json()
                        _LOGGER.info("Projects refreshed: %d projects loaded", result.get("projectCount", 0))
                        return result
        except aiohttp.ClientError as err:
            raise HomeAssistantError(f"Communication error: {err}")
        except Exception as err:
            raise HomeAssistantError(f"Unexpected error: {err}")

    # Register services
    hass.services.async_register(
        DOMAIN, "create_task", async_create_task, schema=CREATE_TASK_SCHEMA
    )
    
    hass.services.async_register(
        DOMAIN, "find_projects", async_find_projects, schema=FIND_PROJECTS_SCHEMA
    )
    
    hass.services.async_register(
        DOMAIN, "create_project", async_create_project, schema=CREATE_PROJECT_SCHEMA
    )
    
    hass.services.async_register(
        DOMAIN, "parse_voice_input", async_parse_voice_input, schema=PARSE_VOICE_INPUT_SCHEMA
    )
    
    hass.services.async_register(
        DOMAIN, "validate_date", async_validate_date, schema=VALIDATE_DATE_SCHEMA
    )
    
    hass.services.async_register(
        DOMAIN, "refresh_projects", async_refresh_projects
    )

async def async_unload_services(hass: HomeAssistant) -> None:
    """Unload services."""
    services = [
        "create_task",
        "find_projects", 
        "create_project",
        "parse_voice_input",
        "validate_date",
        "refresh_projects"
    ]
    
    for service in services:
        hass.services.async_remove(DOMAIN, service)

async def _get_addon_url(hass: HomeAssistant) -> str | None:
    """Get the addon URL from the first configured integration."""
    integrations = hass.config_entries.async_entries(DOMAIN)
    if integrations:
        return integrations[0].data.get(CONF_ADDON_URL)
    return None