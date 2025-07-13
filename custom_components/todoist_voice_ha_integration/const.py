# custom_components/todoist_voice_ha_integration/const.py
"""Constants for the Todoist Voice HA Integration."""

DOMAIN = "todoist_voice_ha_integration"
CONF_ADDON_URL = "addon_url"
CONF_AUTO_CREATE_ENTITIES = "auto_create_entities"
CONF_CONVERSATION_TIMEOUT = "conversation_timeout"

DEFAULT_ADDON_URL = "http://a0d7b954-todoist-voice-ha:8080"
DEFAULT_TIMEOUT = 300

# Entity configurations for auto-creation
REQUIRED_ENTITIES = {
    "input_boolean": {
        "todoist_voice_conversation_active": {
            "name": "Conversation Active",
            "icon": "mdi:chat-processing",
            "initial": False
        },
        "todoist_voice_awaiting_project_selection": {
            "name": "Awaiting Project Selection", 
            "icon": "mdi:folder-question",
            "initial": False
        },
        "todoist_voice_awaiting_project_creation": {
            "name": "Awaiting Project Creation",
            "icon": "mdi:folder-plus", 
            "initial": False
        },
        "todoist_voice_awaiting_date_input": {
            "name": "Awaiting Date Input",
            "icon": "mdi:calendar-question",
            "initial": False
        },
        "todoist_voice_awaiting_final_confirmation": {
            "name": "Awaiting Final Confirmation",
            "icon": "mdi:check-circle-outline",
            "initial": False
        }
    },
    "input_text": {
        "todoist_voice_conversation_id": {
            "name": "Current Conversation ID",
            "max": 50,
            "icon": "mdi:chat-processing"
        },
        "todoist_voice_conversation_state": {
            "name": "Conversation State",
            "max": 50,
            "initial": "idle",
            "icon": "mdi:state-machine"
        },
        "todoist_voice_input_buffer": {
            "name": "Voice Input Buffer",
            "max": 2000,
            "icon": "mdi:microphone-message"
        },
        "todoist_voice_parsed_task_items": {
            "name": "Parsed Task Items",
            "max": 1000,
            "icon": "mdi:format-list-bulleted"
        },
        "todoist_voice_project_matches": {
            "name": "Found Project Matches",
            "max": 500,
            "icon": "mdi:folder-search"
        },
        "todoist_voice_selected_project": {
            "name": "Selected Project",
            "max": 100,
            "icon": "mdi:folder-check"
        },
        "todoist_voice_pending_due_date": {
            "name": "Pending Due Date",
            "max": 50,
            "icon": "mdi:calendar-clock"
        },
        "todoist_voice_task_priority": {
            "name": "Task Priority",
            "max": 10,
            "initial": "3",
            "icon": "mdi:priority-high"
        },
        "todoist_voice_conversation_context": {
            "name": "Conversation Context (JSON)",
            "max": 2000,
            "initial": "{}",
            "icon": "mdi:code-json"
        }
    },
    "input_select": {
        "todoist_voice_available_projects": {
            "name": "Available Todoist Projects",
            "options": ["Loading..."],
            "initial": "Loading...",
            "icon": "mdi:folder-multiple"
        }
    },
    "input_number": {
        "todoist_voice_conversation_timeout": {
            "name": "Conversation Timeout (seconds)",
            "min": 30,
            "max": 600,
            "step": 30,
            "initial": 300,
            "icon": "mdi:timer-outline",
            "unit_of_measurement": "s"
        }
    }
}