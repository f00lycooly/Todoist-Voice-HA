# Todoist Voice HA Add-on

Intelligent conversational task creation for Todoist with Home Assistant integration.

## Installation

1. Add this repository to Home Assistant
2. Install the "Todoist Voice HA" add-on
3. Configure your Todoist API token
4. Start the add-on

## Configuration

### Required
- `todoist_token`: Your Todoist API token from https://todoist.com/app/settings/integrations

### Optional
- `log_level`: Logging level (debug, info, warning, error)
- `default_project_name`: Default project for new tasks
- `auto_create_projects`: Automatically create missing projects
- `conversation_timeout`: How long conversations stay active

## Usage

After installation:
1. Install the custom integration
2. Configure voice assistants with the provided automations
3. Use voice commands like "Add buy milk to my shopping list"

## Support

For issues and feature requests, visit: https://github.com/f00lycooly/Todoist-Voice-HA/issues
