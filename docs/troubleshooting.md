# Troubleshooting Guide

Common issues and solutions.

## Add-on Issues

### Add-on won't start
- Check Todoist API token is valid
- Verify add-on logs for errors
- Ensure port 8080 is available

### API errors
- Verify token has project access
- Check network connectivity
- Review rate limiting settings

## Integration Issues

### Integration not found
- Restart Home Assistant after installation
- Check custom_components directory
- Verify file permissions

### Entities not created
- Enable auto-create entities option
- Check integration logs
- Manually trigger entity creation

## Voice Command Issues

### Commands not recognized
- Check automation is enabled
- Verify voice assistant integration
- Test with manual triggers

### Project matching problems
- Check project names in Todoist
- Verify project cache refresh
- Review matching algorithms

## Getting Help

- Check logs for error messages
- Review configuration settings
- Search GitHub issues
- Create new issue with details
